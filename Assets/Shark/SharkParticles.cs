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
    private Material sharkMat;

    [SerializeField]
    private int particleCount;

    [SerializeField]
    private float speed;

    [SerializeField]
    private Transform sharkHeadPosition;

    [SerializeField]
    private Transform blueLightPosition;

    [SerializeField]
    private Color lightColor;

    [SerializeField]
    private float lightIntensity;

    [SerializeField]
    private ComputeShader particleMover;

    private BoxCollider _boundsSource;

    private int _particleKernel;
    private int _groupSize = 128;

    private int _meshVertCount;
    private ComputeBuffer _meshBuffer;
    private int _meshStride = sizeof(float) * 3;

    private ComputeBuffer _particleBuffer;
    private int _particleStride = sizeof(float) * 3;

    private ComputeBuffer _originalXYBuffer;
    private int _originalXYStride = sizeof(float) * 2;

    private ComputeBuffer _uvsOffsetsBuffer;
    private int _uvsBufferStride = sizeof(float) * 2;

    void Start()
    {
        _particleKernel = particleMover.FindKernel("UpdateParticles");
        _meshVertCount = gridPointMesh.triangles.Length;
        _meshBuffer = GetMeshBuffer();
        Vector3[] randomPoints = GetRandomPoints();
        _particleBuffer = GetParticleBuffer(randomPoints);
        _originalXYBuffer = GetOriginalXYBuffer(randomPoints);
        _uvsOffsetsBuffer = GetUvsBuffer();
        _boundsSource = GetComponent<BoxCollider>();
    }

    private ComputeBuffer GetUvsBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(4, _uvsBufferStride);

        Vector2[] data = new Vector2[]
        {
            new Vector2(0, 0),
            new Vector2(0, 1f),
            new Vector2(1f, 0),
            new Vector2(1f, 1f),
        };
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetOriginalXYBuffer(Vector3[] randomPoints)
    {

        Vector2[] data = new Vector2[particleCount];
        for (int i = 0; i < particleCount; i++)
        {
            data[i] = new Vector2(randomPoints[i].x, randomPoints[i].y);
        }
        ComputeBuffer ret = new ComputeBuffer(particleCount, _originalXYStride);
        ret.SetData(data);
        return ret;
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
        UpdateParticlePositions();
        Draw();

        sharkMat.SetColor("_SharkLightColor", lightColor);
        sharkMat.SetFloat("_SharkLightIntensity", lightIntensity);
        sharkMat.SetVector("_BlueLightPosition", blueLightPosition.position);
    }

    private void UpdateParticlePositions()
    {
        particleMover.SetFloat("_DeltaTime", Time.deltaTime);
        particleMover.SetFloat("_ParticleSpeed", speed);
        particleMover.SetBuffer(_particleKernel, "_ParticleBuffer", _particleBuffer);
        particleMover.SetBuffer(_particleKernel, "_OriginalXYBuffer", _originalXYBuffer);
        
        Vector3 localSharkHead = transform.InverseTransformPoint(sharkHeadPosition.position);
        particleMover.SetVector("_SharkHeadPosition", localSharkHead);

        int groups = Mathf.CeilToInt((float)particleCount / _groupSize);
        particleMover.Dispatch(_particleKernel, groups, 1, 1);
    }

    private void Draw()
    {
        particleMat.SetBuffer("_MeshBuffer", _meshBuffer);
        particleMat.SetBuffer("_ParticleBuffer", _particleBuffer);
        particleMat.SetMatrix("_MasterTransform", transform.localToWorldMatrix);
        particleMat.SetFloat("_ParticleSize", particleSize);
        particleMat.SetBuffer("_UvOffsetsBuffer", _uvsOffsetsBuffer);
        particleMat.SetFloat("_ParticlesCount", particleCount);

        particleMat.SetColor("_SharkLightColor", lightColor);
        particleMat.SetFloat("_SharkLightIntensity", lightIntensity);
        particleMat.SetVector("_BlueLightPosition", blueLightPosition.position);
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
        _originalXYBuffer.Dispose();
        _uvsOffsetsBuffer.Dispose();
    }

}