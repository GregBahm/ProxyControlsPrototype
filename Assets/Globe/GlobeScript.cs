using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class GlobeScript : MonoBehaviour
{
    private Mesh globeMesh;
    private Material globeMat;

    private ComputeBuffer pointsBuffer;
    private ComputeBuffer basePointsBuffer;

    private int pointsMoverKernel;

    [SerializeField]
    private ComputeShader globePointsMover;
    private const int BasePositionsStride = sizeof(float) * 3;
    private const int PointsStride = sizeof(float) * 3 // Position
        + sizeof(float) * 3; // Velocity
    private const int GroupSize = 128;
    private int meshVertCount;

    [SerializeField]
    private Transform Effector;

    struct GlobePoint
    {
        public Vector3 Position;
        public Vector3 Velocity;
    }

    private void Start()
    {
        globeMat = GetComponent<MeshRenderer>().material;
        globeMesh = GetComponent<MeshFilter>().mesh;

        pointsMoverKernel = globePointsMover.FindKernel("GlobePointsMover");
        meshVertCount = globeMesh.vertices.Length;

        Vector3[] meshVerts = globeMesh.vertices;
        pointsBuffer = GetPointsBuffer(meshVerts);

        basePointsBuffer = new ComputeBuffer(meshVertCount, BasePositionsStride);
        basePointsBuffer.SetData(meshVerts);
    }

    private ComputeBuffer GetPointsBuffer(Vector3[] meshVerts)
    {
        ComputeBuffer ret = new ComputeBuffer(meshVertCount, PointsStride);
        GlobePoint[] data = new GlobePoint[meshVerts.Length];
        for (int i = 0; i < meshVerts.Length; i++)
        {
            data[i] = new GlobePoint { Position = meshVerts[i] };
        }
        ret.SetData(data);
        return ret;
    }

    private void Update()
    {
        globePointsMover.SetVector("_EffectorPos", Effector.localPosition);
        globePointsMover.SetFloat("_EffectorRadius", Effector.localScale.x);
        globePointsMover.SetBuffer(pointsMoverKernel, "_PointsBuffer", pointsBuffer);
        globePointsMover.SetBuffer(pointsMoverKernel, "_BasePositionsBuffer", basePointsBuffer);
        int groups = Mathf.CeilToInt((float)meshVertCount / GroupSize);
        globePointsMover.Dispatch(pointsMoverKernel, groups, 1, 1);

        globeMat.SetBuffer("_PointsBuffer", pointsBuffer);
    }

    private void OnDestroy()
    {
        if(pointsBuffer != null)
            pointsBuffer.Dispose();
        if(basePointsBuffer != null)
            basePointsBuffer.Dispose();
    }
}
