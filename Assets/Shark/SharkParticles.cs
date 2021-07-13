using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SharkParticles : MonoBehaviour
{
    [SerializeField]
    private float particleSize;

    [SerializeField]
    private Mesh gridPointMesh;

    [SerializeField]
    private Material particleMat;

    [SerializeField]
    private int particlePointCount;

    private BoxCollider boundsSource;

    private int meshVertCount;
    private ComputeBuffer _meshBuffer;
    private int meshStride = sizeof(float) * 3;

    private ComputeBuffer _particleBuffer;
    private int particleStride = sizeof(float) * 3;

    void Start()
    {
        meshVertCount = gridPointMesh.triangles.Length;
        _meshBuffer = GetMeshBuffer();
        _particleBuffer = GetParticleBuffer();
        boundsSource = GetComponent<BoxCollider>();
    }

    private void Update()
    {
        particleMat.SetBuffer("_MeshBuffer", _meshBuffer);
        particleMat.SetBuffer("_ParticleBuffer", _particleBuffer);
        particleMat.SetMatrix("_MasterTransform", transform.localToWorldMatrix);
        particleMat.SetFloat("_ParticleSize", particleSize);
        Graphics.DrawProcedural(particleMat, boundsSource.bounds, MeshTopology.Triangles, meshVertCount, particlePointCount);
    }

    private ComputeBuffer GetMeshBuffer()
    {
        Vector3[] meshVerts = new Vector3[meshVertCount];
        ComputeBuffer ret = new ComputeBuffer(meshVertCount, meshStride);
        for (int i = 0; i < meshVertCount; i++)
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

    private ComputeBuffer GetParticleBuffer()
    {
        Vector3[] data = new Vector3[particlePointCount];
        ComputeBuffer ret = new ComputeBuffer(particlePointCount, particleStride);
        for (int i = 0; i < particlePointCount; i++)
        {
            data[i] = new Vector3
            (
                GetRandomValue(),
                GetRandomValue(),
                GetRandomValue()
            );
        }
        ret.SetData(data);
        return ret;
    }

    private void OnDestroy()
    {
        _meshBuffer.Dispose();
        _particleBuffer.Dispose();
    }

}