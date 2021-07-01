using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaitPlumeTracer : MonoBehaviour
{
    public Mesh StrandMesh;
    public Material PlumeStrandMaterial;
    public BoxCollider PlumeBoundsSource;

    public float StrandThickness;

    public ComputeShader BaitPlumeCompute;
    public VolumeTextureGenerator TextureGenerator;

    [Range(0, 1)]
    public float Timeline;
    public float FeedDropGravity;
    public float BaseIntensity;
    public float StrandIntensity;
    public float DispersionBaseIntensity;
    public float DispersionDecay;

    public int RootPointsCount;
    public int StrandsCount;
    public int Dispersions;

    private int totalStrands;

    private int plumeStrandsKernel;
    private int basePositionsKernel;
    private ComputeBuffer argsBuffer;

    private const int GROUP_SIZE = 128;
    private const int ROOT_POINTS_STRIDE = sizeof(float) * 3;
    private const int POINTS_PER_STRAND = 16;
    private const int CHAIN_BUFFER_STRIDE = sizeof(float) * 3;
    private const int DISPERSION_BUFFER_STRIDE = sizeof(float) * 3;

    private ComputeBuffer dispersionBuffer;
    private ComputeBuffer basePointsBuffer;
    private ComputeBuffer plumeStrandsBuffer;
    Texture3D assembledTexture;

    private void Start()
    {
        basePositionsKernel = BaitPlumeCompute.FindKernel("CalculateBasePositions");
        plumeStrandsKernel = BaitPlumeCompute.FindKernel("CalculatePlumesStrands");
        totalStrands = RootPointsCount * StrandsCount;
        argsBuffer = GetArgsBuffer();
        basePointsBuffer = new ComputeBuffer(RootPointsCount, ROOT_POINTS_STRIDE);
        plumeStrandsBuffer = new ComputeBuffer(totalStrands * POINTS_PER_STRAND, CHAIN_BUFFER_STRIDE);
        dispersionBuffer = GetDispersionsBuffer();

        assembledTexture = TextureGenerator.GetAssembledTexture();
    }

    private ComputeBuffer GetDispersionsBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(Dispersions, DISPERSION_BUFFER_STRIDE);
        Vector3[] data = new Vector3[Dispersions];
        for (int i = 0; i < Dispersions; i++)
        {
            data[i] = UnityEngine.Random.onUnitSphere;
        }
        ret.SetData(data);
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
        BaitPlumeCompute.SetFloat("_DispersionsCount", Dispersions);
        BaitPlumeCompute.SetFloat("_StrandIntensity", StrandIntensity);
        BaitPlumeCompute.SetFloat("_BaseIntensity", BaseIntensity);
        BaitPlumeCompute.SetFloat("_FeedDropGravity", FeedDropGravity);
        BaitPlumeCompute.SetFloat("_DispersionDecay", DispersionBaseIntensity);
        BaitPlumeCompute.SetFloat("_DispersionBaseIntensity", DispersionBaseIntensity);
        BaitPlumeCompute.SetFloat("_Time", Time.realtimeSinceStartup);

        BaitPlumeCompute.SetBuffer(plumeStrandsKernel, "_BasePositions", basePointsBuffer);
        BaitPlumeCompute.SetBuffer(plumeStrandsKernel, "_PlumeStrands", plumeStrandsBuffer);
        BaitPlumeCompute.SetBuffer(plumeStrandsKernel, "_Dispersions", dispersionBuffer);
        BaitPlumeCompute.SetTexture(plumeStrandsKernel, "MapTexture", assembledTexture);

        int strandGroups = Mathf.CeilToInt((float)totalStrands / GROUP_SIZE);
        BaitPlumeCompute.Dispatch(plumeStrandsKernel, strandGroups, 1, 1);

        BaitPlumeCompute.SetBuffer(basePositionsKernel, "_BasePositions", basePointsBuffer);
        BaitPlumeCompute.SetBuffer(basePositionsKernel, "_PlumeStrands", plumeStrandsBuffer);
        BaitPlumeCompute.SetTexture(basePositionsKernel, "MapTexture", assembledTexture);

        int basePointGroups = Mathf.CeilToInt((float)RootPointsCount / GROUP_SIZE);
        BaitPlumeCompute.Dispatch(basePositionsKernel, basePointGroups, 1, 1);
    }

    private void OnDestroy()
    {
        argsBuffer.Dispose();
        basePointsBuffer.Dispose();
        plumeStrandsBuffer.Dispose();
        dispersionBuffer.Dispose();
    }
}
