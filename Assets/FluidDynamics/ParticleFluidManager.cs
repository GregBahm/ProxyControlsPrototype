using Jules.FluidDynamics;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(FluidSimulator))]
public class ParticleFluidManager : MonoBehaviour
{
    [SerializeField]
    private float particleSize;

    [SerializeField]
    private float particleLifetime;

    [SerializeField]
    private float velocityPower;

    [SerializeField]
    private Mesh gridPointMesh;

    [SerializeField]
    private Material particleMat;

    [SerializeField]
    private int particleCount;

    [SerializeField]
    private ComputeShader fluidParticleMover;

    [SerializeField]
    private BoxCollider boundsSource;

    private FluidSimulator _fluidSimulator;

    private int _particleMoverKernel;
    private int _groupSize = 128;

    private int _meshVertCount;
    private ComputeBuffer _meshBuffer;
    private int _meshStride = sizeof(float) * 3;

    private ComputeBuffer _sourcePositionsBuffer;
    private ComputeBuffer _particleBuffer;
    private int _particleStride = sizeof(float) * 4;

    private static readonly int _meshBufferId = Shader.PropertyToID("_MeshBuffer");
    private static readonly int _particleBufferId = Shader.PropertyToID("_ParticleBuffer");
    private static readonly int _masterTransformId = Shader.PropertyToID("_MasterTransform");
    private static readonly int _particleSizeId = Shader.PropertyToID("_ParticleSize");
    private static readonly int _particlesCountId = Shader.PropertyToID("_ParticlesCount");
    private static readonly int _dyeVolumeId = Shader.PropertyToID("DyeVolume");
    private static readonly int _velocityFieldId = Shader.PropertyToID("VelocityField");
    private static readonly int _sourcePositionsId = Shader.PropertyToID("_SourcePositions");
    private static readonly int _deltaTimeId = Shader.PropertyToID("_DeltaTime");
    private static readonly int _particleLifetimeId = Shader.PropertyToID("_ParticleLifetime");
    private static readonly int _velocityPowerId = Shader.PropertyToID("_VelocityPower");

    void Start()
    {
        _meshVertCount = gridPointMesh.triangles.Length;
        _meshBuffer = GetMeshBuffer();
        Vector4[] randomPoints = GetRandomPoints();
        _particleBuffer = GetParticleBuffer(randomPoints);
        _sourcePositionsBuffer = GetParticleBuffer(randomPoints);
        _fluidSimulator = GetComponent<FluidSimulator>();
        fluidParticleMover.FindKernel("MoveFluidParticles");
    }

    private Vector4[] GetRandomPoints()
    {
        Vector4[] data = new Vector4[particleCount];
        for (int i = 0; i < particleCount; i++)
        {
            data[i] = new Vector4
            (
                GetRandomValue(),
                GetRandomValue(),
                GetRandomValue(),
                GetRandomValue() * particleLifetime
            );
        }
        return data;
    }

    private void Update()
    {
        MoveParticles();
        Draw();
    }

    private void MoveParticles()
    {
        fluidParticleMover.SetFloat(_velocityPowerId, velocityPower);
        fluidParticleMover.SetFloat(_deltaTimeId, Time.deltaTime);
        fluidParticleMover.SetFloat(_particleLifetimeId, particleLifetime);
        fluidParticleMover.SetTexture(_particleMoverKernel, _velocityFieldId, _fluidSimulator.VelocityTexture);
        fluidParticleMover.SetBuffer(_particleMoverKernel, _particleBufferId, _particleBuffer);
        fluidParticleMover.SetBuffer(_particleMoverKernel, _sourcePositionsId, _sourcePositionsBuffer);

        int groups = Mathf.CeilToInt((float)particleCount / _groupSize);
        fluidParticleMover.Dispatch(_particleMoverKernel, groups, 1, 1);
    }

    private void Draw()
    {
        particleMat.SetBuffer(_meshBufferId, _meshBuffer);
        particleMat.SetBuffer(_particleBufferId, _particleBuffer);
        particleMat.SetMatrix(_masterTransformId, transform.localToWorldMatrix);
        particleMat.SetFloat(_particleSizeId, particleSize);
        particleMat.SetFloat(_particlesCountId, particleCount);
        particleMat.SetTexture(_dyeVolumeId, _fluidSimulator.DyeTexture);
        particleMat.SetTexture(_velocityFieldId, _fluidSimulator.VelocityTexture);
        Graphics.DrawProcedural(particleMat, boundsSource.bounds, MeshTopology.Triangles, _meshVertCount, particleCount);
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

    private ComputeBuffer GetParticleBuffer(Vector4[] data)
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