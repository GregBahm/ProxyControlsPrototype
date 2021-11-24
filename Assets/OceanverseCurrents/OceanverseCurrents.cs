using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(BoxCollider))]
public class OceanverseCurrents : MonoBehaviour
{
    public Mesh StrandMesh;
    public Material CurrentMaterial;

    public float StrandThickness;

    public ComputeShader CurrentCompute;
    public Texture2D currentsMap;

    public float StrandIntensity;

    public int CurrentDimensionCount;
    public int CurrentsCount { get { return CurrentDimensionCount * CurrentDimensionCount; } }

    private int currentsKernel;
    private ComputeBuffer argsBuffer;

    private const int GROUP_SIZE = 128;
    private const int ROOT_POINTS_STRIDE = sizeof(float) * 2;
    private const int POINTS_PER_STRAND = 16;
    private const int CHAIN_BUFFER_STRIDE = sizeof(float) * 3;

    private ComputeBuffer basePointsBuffer;
    private ComputeBuffer currentStrandsBuffer;

    private BoxCollider boundsSource;

    private void Start()
    {
        boundsSource = GetComponent<BoxCollider>();
        currentsKernel = CurrentCompute.FindKernel("CalculateCurrents");
        argsBuffer = GetArgsBuffer();
        basePointsBuffer = GetBasePoints();
        currentStrandsBuffer = new ComputeBuffer(CurrentsCount * POINTS_PER_STRAND, CHAIN_BUFFER_STRIDE);
    }

    private ComputeBuffer GetBasePoints()
    {
        ComputeBuffer ret = new ComputeBuffer(CurrentsCount, ROOT_POINTS_STRIDE);
        Vector2[] data = new Vector2[CurrentsCount];
        int i = 0;
        for (int x = 0; x < CurrentDimensionCount; x++)
        {
            for (int y = 0; y < CurrentDimensionCount; y++)
            {
                float xPos = (float)x / CurrentDimensionCount;
                float yPos = (float)y / CurrentDimensionCount;
                data[i] = new Vector2(xPos, yPos);
                i++;
            }
        }
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetArgsBuffer()
    {
        uint indexCountPerInstance = StrandMesh.GetIndexCount(0);
        uint instanceCount = (uint)CurrentsCount;
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
        CurrentMaterial.SetBuffer("_PlumeStrands", currentStrandsBuffer);
        CurrentMaterial.SetFloat("_StrandThickness", StrandThickness);
        CurrentMaterial.SetFloat("_TotalStrands", CurrentsCount);
        CurrentMaterial.SetMatrix("masterTransform", transform.localToWorldMatrix);
        Graphics.DrawMeshInstancedIndirect(StrandMesh, 0, CurrentMaterial, boundsSource.bounds, argsBuffer);
    }

    private void DispatchCompute()
    {
        CurrentCompute.SetFloat("_StrandIntensity", StrandIntensity);
        CurrentCompute.SetFloat("_Time", Time.realtimeSinceStartup);

        CurrentCompute.SetBuffer(currentsKernel, "_BasePositions", basePointsBuffer);
        CurrentCompute.SetBuffer(currentsKernel, "_CurrentStrands", currentStrandsBuffer);
        CurrentCompute.SetTexture(currentsKernel, "MapTexture", currentsMap);

        int strandGroups = Mathf.CeilToInt((float)CurrentsCount / GROUP_SIZE);
        CurrentCompute.Dispatch(currentsKernel, strandGroups, 1, 1);
    }

    private void OnDestroy()
    {
        argsBuffer.Dispose();
        basePointsBuffer.Dispose();
        currentStrandsBuffer.Dispose();
    }
}
