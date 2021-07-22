using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleFluidManager : MonoBehaviour
{
    [SerializeField]
    private float particleSize;

    [SerializeField]
    private Mesh gridPointMesh;

    [SerializeField]
    private Material particleMat;

    [SerializeField]
    private int particleCount;

    [SerializeField]
    private BoxCollider _boundsSource;

    private int _particleKernel;
    private int _groupSize = 128;

    private int _meshVertCount;
    private ComputeBuffer _meshBuffer;
    private int _meshStride = sizeof(float) * 3;

    private ComputeBuffer _particleBuffer;
    private int _particleStride = sizeof(float) * 3;

    void Start()
    {
        _meshVertCount = gridPointMesh.triangles.Length;
        _meshBuffer = GetMeshBuffer();
        Vector3[] randomPoints = GetRandomPoints();
        _particleBuffer = GetParticleBuffer(randomPoints);
    }

    private Vector3[] GetRandomPoints()
    {
        Vector3[] data = new Vector3[particleCount];
        for (int i = 0; i < particleCount; i++)
        {
            data[i] = new Vector3
            (
                GetRandomValue(),
                GetRandomValue(),
                GetRandomValue()
            );
        }
        return data;
    }

    private void Update()
    {
        Draw();
    }

    private void Draw()
    {
        particleMat.SetBuffer("_MeshBuffer", _meshBuffer);
        particleMat.SetBuffer("_ParticleBuffer", _particleBuffer);
        particleMat.SetMatrix("_MasterTransform", transform.localToWorldMatrix);
        particleMat.SetFloat("_ParticleSize", particleSize);
        particleMat.SetFloat("_ParticlesCount", particleCount);
        Graphics.DrawProcedural(particleMat, _boundsSource.bounds, MeshTopology.Triangles, _meshVertCount, particleCount);
    }

    private ComputeBuffer GetMeshBuffer()
    {
        Vector3[] meshVerts = new Vector3[_meshVertCount];
        ComputeBuffer ret = new ComputeBuffer(_meshVertCount, _meshStride);
        for (int i = 0; i < _meshVertCount; i++)
        {
            meshVerts[i] = gridPointMesh.vertices[gridPointMesh.triangles[i]];
        }
        ret.SetData(meshVerts);
        return ret;
    }

    private float GetRandomValue()
    {
        return Random.value - .5f;
    }

    private ComputeBuffer GetParticleBuffer(Vector3[] data)
    {
        ComputeBuffer ret = new ComputeBuffer(particleCount, _particleStride);
        ret.SetData(data);
        return ret;
    }

    private void OnDestroy()
    {
        _meshBuffer.Dispose();
        _particleBuffer.Dispose();
    }
}