using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class PointsOfLight : MonoBehaviour
{
    private int vertCount;
    private ComputeBuffer pointsBuffer;
    private const int POINTS_BUFFER_STRIDE = sizeof(float) * 3;

    private MeshRenderer meshRenderer;

    [SerializeField]
    private Material pointsMaterial;
    private Material matInstance;

    void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        Mesh mesh = GetComponent<MeshFilter>().mesh;
        vertCount = mesh.vertexCount;
        pointsBuffer = new ComputeBuffer(vertCount, POINTS_BUFFER_STRIDE);
        pointsBuffer.SetData(mesh.vertices);
        matInstance = new Material(pointsMaterial);
    }

    void Update()
    {
        matInstance.SetMatrix("_Transform", transform.localToWorldMatrix);
        matInstance.SetBuffer("_Points", pointsBuffer);
        Graphics.DrawProcedural(matInstance, meshRenderer.bounds, MeshTopology.Points, vertCount);
    }

    private void OnDestroy()
    {
        if (pointsBuffer != null)
            pointsBuffer.Dispose();
    }
}
