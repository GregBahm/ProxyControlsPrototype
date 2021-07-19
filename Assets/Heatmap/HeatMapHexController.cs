using Jules;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

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

    [SerializeField]
    private DrawMode drawMode;

    public enum DrawMode
    {
        DrawOpacity, // Draws the heatmap as opaque, for debugging
        DrawAlpha, // Draws the heatmap's alpha, for debugging
        Composite // Draws the opaque effect, the alpha, and then combines the opaque effect using the alpha effect in a post process effect
    }

    private ComputeBuffer _heatDataBuffer;
    private ComputeBuffer _remapBuffer;
    private ComputeBuffer _argsBuffer;
    private ComputeBuffer _uvsBuffer;
    private const int HEAT_POINTS = 16;
    private const int HEAT_DATA_STRIDE = sizeof(float) * 2 // Position
        + sizeof(float) // intensity
        + sizeof(float); // dispersion
    private const int UVS_BUFFER_STRIDE = sizeof(float) * 2;
    private const int REMAP_BUFFER_STRIDE = sizeof(int);

    private HexSorter[] hexTransforms;

    private void Start()
    {
        _gridColumns = Mathf.FloorToInt(gridRows * 1.15f);
        _argsBuffer = GetArgsBuffer();
        _uvsBuffer = GetUvsBuffer();
        _heatDataBuffer = new ComputeBuffer(HEAT_POINTS, HEAT_DATA_STRIDE);
        _remapBuffer = new ComputeBuffer(gridRows * _gridColumns, REMAP_BUFFER_STRIDE);

        hexTransforms = CreateHexTransforms().ToArray();
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
        ComputeBuffer ret = new ComputeBuffer(gridRows * _gridColumns, UVS_BUFFER_STRIDE);
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
        SetShaderProperties();
        DrawCubes();
    }

    private void SetShaderProperties()
    {
        hexMeshMat.SetFloat("_BoxWidth", 1f / gridRows);
        hexMeshMat.SetFloat("_BoxDepth", 1f / _gridColumns);
        hexMeshMat.SetBuffer("_UvsBuffer", _uvsBuffer);
        hexMeshMat.SetBuffer("_RemapBuffer", _remapBuffer);
        hexMeshMat.SetMatrix("_MasterTransform", mapTransform.transform.localToWorldMatrix);
        hexMeshMat.SetBuffer("_HeatDataBuffer", _heatDataBuffer);
        hexMeshMat.SetFloat("_DrawAlpha", drawMode == DrawMode.DrawAlpha ? 1 : 0);
    }

    private void OnDestroy()
    {
        _argsBuffer.Dispose();
        _uvsBuffer.Dispose();
        _heatDataBuffer.Dispose();
        _remapBuffer.Dispose();
    }

    private void DrawCubes()
    {
        if(drawMode == DrawMode.DrawAlpha || drawMode == DrawMode.DrawOpacity)
        {
            HexSorter[] sortedHexes = GetMatrixTransformations();
            int[] remap = sortedHexes.Select(item => item.Index).ToArray();
            _remapBuffer.SetData(remap);
            Graphics.DrawMeshInstanced(hexMesh, 0, hexMeshMat, sortedHexes.Select(item => item.Matrix).ToArray());
        }
    }

    private struct HexSorter
    {
        public int Index { get; }
        public Matrix4x4 Matrix { get; }

        public Vector3 LocalPos { get; }

        public HexSorter(int index, Matrix4x4 matrix, Vector3 localPos)
        {
            Index = index;
            Matrix = matrix;
            LocalPos = localPos;
        }
    }

    private HexSorter[] GetMatrixTransformations()
    {
        Vector3 cameraInMapSpace = mapTransform.transform.InverseTransformPoint(Camera.main.transform.position);
        return hexTransforms.OrderBy(item => (item.LocalPos - cameraInMapSpace).magnitude).ToArray();
    }

    private HexSorter CreateHexTransform(Transform helperTransfom, int x, int y, int index)
    {
        Vector2 cellPos = GetHexCellPosition(x, y);

        helperTransfom.localPosition = new Vector3(cellPos.x - .5f, 0, cellPos.y - .5f);
        helperTransfom.localScale = new Vector3(1f / gridRows, 1, (1f / _gridColumns) * 1.15f);
        return new HexSorter(index, helperTransfom.localToWorldMatrix, helperTransfom.localPosition);
    }

    private IEnumerable<HexSorter> CreateHexTransforms()
    {
        Transform helperTransfom = new GameObject("HexHeatmapHelper").transform;
        helperTransfom.parent = mapTransform.transform;
        int index = 0;
        for (int x = 0; x < gridRows; x++)
        {
            for (int y = 0; y < _gridColumns; y++)
            {
                yield return CreateHexTransform(helperTransfom, x, y, index);
                index++;
            }
        }
    }
}
