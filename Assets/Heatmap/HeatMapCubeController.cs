using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeatMapCubeController : MonoBehaviour
{
    [SerializeField]
    private int gridRows;

    [SerializeField]
    private int gridColumns;

    [SerializeField]
    private Mesh cubeMesh;

    [SerializeField]
    private Material cubeMeshMat;

    [SerializeField]
    private BoxCollider boundsSource;

    private ComputeBuffer argsBuffer;
    private ComputeBuffer uvsBuffer;
    private const int uvsBufferStride = sizeof(float) * 2;

    private void Start()
    {
        argsBuffer = GetArgsBuffer();
        uvsBuffer = GetUvsBuffer();
    }

    private ComputeBuffer GetUvsBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(gridRows * gridColumns, uvsBufferStride);
        Vector2[] data = new Vector2[gridRows * gridColumns];
        int i = 0;
        for (int x = 0; x < gridRows; x++)
        {
            for (int y = 0; y < gridColumns; y++)
            {
                float u = (float)x / gridRows;
                float v = (float)y / gridColumns;
                data[i] = new Vector2(u, v);
                i++;
            }
        }
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetArgsBuffer()
    {
        uint indexCountPerInstance = cubeMesh.GetIndexCount(0);
        uint instanceCount = (uint)(gridRows * gridColumns);
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
        DrawCubes();
    }

    private void OnDestroy()
    {
        argsBuffer.Dispose();
        uvsBuffer.Dispose();
    }

    private void DrawCubes()
    {
        cubeMeshMat.SetFloat("_BoxWidth", 1f / gridRows);
        cubeMeshMat.SetFloat("_BoxDepth", 1f / gridColumns);
        cubeMeshMat.SetBuffer("_UvsBuffer", uvsBuffer);
        cubeMeshMat.SetMatrix("_MasterTransform", boundsSource.transform.localToWorldMatrix);
        Graphics.DrawMeshInstancedIndirect(cubeMesh, 0, cubeMeshMat, boundsSource.bounds, argsBuffer);
    }
}
