using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaitPlumeTracer : MonoBehaviour
{
    public Mesh StrandMesh;
    public Material PlumeStrandMaterial;
    public BoxCollider PlumeBoundsSource;

    public float Intensity;
    public float StrandThickness;

    public ComputeShader BaitPlumeCompute;
    public VolumeTextureGenerator TextureGenerator;

    [Range(0, 1)]
    public float Timeline;

    public int RootPointsCount;
    public int StrandsCount;

    private int totalStrands;

    private int baitPlumeKernel;
    private ComputeBuffer argsBuffer;

    private const int GROUP_SIZE = 128;
    private const int ROOT_POINTS_STRIDE = sizeof(float) * 3;
    private const int POINTS_PER_STRAND = 16;
    private const int CHAIN_BUFFER_STRIDE = sizeof(float) * 3;

    private ComputeBuffer basePointsBuffer;
    private ComputeBuffer plumeStrandsBuffer;

    private void Start()
    {
        baitPlumeKernel = BaitPlumeCompute.FindKernel("CalculateBaitPlumes");
        totalStrands = RootPointsCount * StrandsCount;
        argsBuffer = GetArgsBuffer();
        basePointsBuffer = GetBasePointsBuffer();
        plumeStrandsBuffer = new ComputeBuffer(totalStrands * POINTS_PER_STRAND, CHAIN_BUFFER_STRIDE);

        Texture3D assembledTexture = TextureGenerator.GetAssembledTexture();
        BaitPlumeCompute.SetTexture(baitPlumeKernel, "MapTexture", assembledTexture);
    }

    private ComputeBuffer GetBasePointsBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(RootPointsCount, ROOT_POINTS_STRIDE);
        Vector3[] dummyData = new Vector3[RootPointsCount];
        Vector3 start = new Vector3(.5f, 1, .5f);
        Vector3 end = new Vector3(.5f, 0, .5f);
        for (int i = 0; i < RootPointsCount; i++)
        {
            float param = (float)i / RootPointsCount;
            dummyData[i] = Vector3.Lerp(start, end, param);
        }
        ret.SetData(dummyData);
        return ret;
    }

    private ComputeBuffer GetArgsBuffer()
    {
        uint indexCountPerInstance = StrandMesh.GetIndexCount(0);
        uint instanceCount = (uint)totalStrands;
        uint startIndexLocation = 0;
        uint baseVertLocation = 0;
        uint startInstanceLocation = 0;
        uint[] args = new uint[5] { indexCountPerInstance, instanceCount, startIndexLocation, baseVertLocation, startInstanceLocation };
        ComputeBuffer ret = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        ret.SetData(args);
        return ret;
    }

    private void Update()
    {
        DispatchCompute();
        DrawStrands();
    }

    private void DrawStrands()
    {
        PlumeStrandMaterial.SetBuffer("_PlumeStrands", plumeStrandsBuffer);
        PlumeStrandMaterial.SetFloat("_StrandThickness", StrandThickness);
        PlumeStrandMaterial.SetFloat("_Timeline", Timeline);
        PlumeStrandMaterial.SetFloat("_TotalStrands", totalStrands);
        Graphics.DrawMeshInstancedIndirect(StrandMesh, 0, PlumeStrandMaterial, PlumeBoundsSource.bounds, argsBuffer);
    }

    private void DispatchCompute()
    {
        BaitPlumeCompute.SetBuffer(baitPlumeKernel, "_BasePositions", basePointsBuffer);
        BaitPlumeCompute.SetBuffer(baitPlumeKernel, "_PlumeStrands", plumeStrandsBuffer);
        BaitPlumeCompute.SetFloat("_Intensity", Intensity);

        int numberofGroups = Mathf.CeilToInt((float)totalStrands / GROUP_SIZE);
        BaitPlumeCompute.Dispatch(baitPlumeKernel, numberofGroups, 1, 1);
    }

    private void OnDestroy()
    {
        argsBuffer.Dispose();
        basePointsBuffer.Dispose();
        plumeStrandsBuffer.Dispose();
    }
}
