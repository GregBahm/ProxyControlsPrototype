using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class PointsOfLight : MonoBehaviour
{
    private int vertCount;
    private ComputeBuffer pointsBuffer;
    private const int POINTS_BUFFER_STRIDE = sizeof(float) * 5;

    private MeshRenderer meshRenderer;

    [SerializeField]
    private Material pointsMaterial;

    [SerializeField]
    private float pointsSize;

    private Material matInstance;

    struct LightPoint
    {
        public Vector3 Position;
        public Vector2 Uvs;
    }

    void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        Mesh mesh = GetComponent<MeshFilter>().mesh;
        vertCount = mesh.vertexCount;
        pointsBuffer = new ComputeBuffer(vertCount, POINTS_BUFFER_STRIDE);
        LightPoint[] data = new LightPoint[vertCount];
        for (int i = 0; i < vertCount; i++)
        {
            data[i].Position = mesh.vertices[i];
            data[i].Uvs = mesh.uv[i];
        }
        pointsBuffer.SetData(data);
        matInstance = new Material(pointsMaterial);
    }

    void Update()
    {
        matInstance.SetMatrix("_Transform", transform.localToWorldMatrix);
        matInstance.SetBuffer("_Points", pointsBuffer);
        matInstance.SetFloat("_Size", pointsSize);
        Graphics.DrawProcedural(matInstance, meshRenderer.bounds, MeshTopology.Points, vertCount);
    }

    private void OnDestroy()
    {
        if (pointsBuffer != null)
            pointsBuffer.Dispose();
    }
}
