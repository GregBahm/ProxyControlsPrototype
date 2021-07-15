using Jules;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeatMapHexController : MonoBehaviour
{
    public struct HeatData
    {
        public Vector2 Position;
        public float Intensity;
        public float Dispersion;
    }

    public const float MagicHexNumber = 1.73f; // Hex Ratio between width and height

    public static Vector2 AscendingTileOffset { get; } = new Vector2(1, MagicHexNumber).normalized;

    [SerializeField]
    private int gridRows;

    private int _gridColumns;

    [SerializeField]
    private Mesh hexMesh;

    [SerializeField]
    private Material hexMeshMat;

    [SerializeField]
    private BoxCollider mapTransform;

    private ComputeBuffer _heatDataBuffer;
    private const int HEAT_POINTS = 16;
    private const int HEAT_DATA_STRIDE = sizeof(float) * 2 // Position
        + sizeof(float) // intensity
        + sizeof(float); // dispersion
    private ComputeBuffer _argsBuffer;
    private ComputeBuffer _uvsBuffer;
    private const int UvsBufferStride = sizeof(float) * 2;

    private void Start()
    {
        _gridColumns = Mathf.FloorToInt(gridRows * 1.15f);
        _argsBuffer = GetArgsBuffer();
        _uvsBuffer = GetUvsBuffer();
        _heatDataBuffer = new ComputeBuffer(HEAT_POINTS, HEAT_DATA_STRIDE);
    }

    public void SetHeatData(HeatData[] data)
    {
        HeatData[] sanitizedData = new HeatData[HEAT_POINTS];
        int dataToUse = Mathf.Min(HEAT_POINTS, data.Length); // We'll toss data if it exceeds HEAT_POINTS
        for (int i = 0; i < dataToUse; i++)
        {
            sanitizedData[i] = data[i];
        }
        _heatDataBuffer.SetData(sanitizedData);
    }

    private Vector2 GetHexCellPosition(int x, int y)
    {
        Vector2 ascendingOffset = AscendingTileOffset * y;
        Vector2 absolutePosition = ascendingOffset + new Vector2(x, 0);

        float u = absolutePosition.x / gridRows;
        float v = absolutePosition.y / gridRows;
        u %= 1;
        return new Vector2(u, v);
    }

    private ComputeBuffer GetUvsBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(gridRows * _gridColumns, UvsBufferStride);
        Vector2[] data = new Vector2[gridRows * _gridColumns];
        int i = 0;
        for (int x = 0; x < gridRows; x++)
        {
            for (int y = 0; y < _gridColumns; y++)
            {
                data[i] = GetHexCellPosition(x, y);
                i++;
            }
        }
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetArgsBuffer()
    {
        uint indexCountPerInstance = hexMesh.GetIndexCount(0);
        uint instanceCount = (uint)(gridRows * _gridColumns);
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
        _argsBuffer.Dispose();
        _uvsBuffer.Dispose();
        _heatDataBuffer.Dispose();
    }

    private void DrawCubes()
    {
        hexMeshMat.SetFloat("_BoxWidth", 1f / gridRows);
        hexMeshMat.SetFloat("_BoxDepth", 1f / _gridColumns);
        hexMeshMat.SetBuffer("_UvsBuffer", _uvsBuffer);
        hexMeshMat.SetMatrix("_MasterTransform", mapTransform.transform.localToWorldMatrix);
        hexMeshMat.SetBuffer("_HeatDataBuffer", _heatDataBuffer);
        Graphics.DrawMeshInstancedIndirect(hexMesh, 0, hexMeshMat, mapTransform.bounds, _argsBuffer);
    }
}
