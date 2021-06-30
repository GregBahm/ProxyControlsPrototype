using UnityEngine;
using System.Collections;
using System;

public class FeedDropSim : MonoBehaviour
{
    [Range(.5f, 2.5f)]
    public float CurrentFactor;

    public Transform RootTransform;
    public VolumeTextureGenerator TextureGenerator;

    public ComputeShader ParticleUpdater;
    public Material ParticleMaterial;
    public int ParticleCount;
    [Range(0, .1f)]
	public float ParticleSize;
	public float VelocityScale;
    
    public float ParticleLifetime = 1;
    public float ParticleSpeed = .1f;

    public Transform StartingPoint;
    public bool UpdateComputation;

    public const int GroupSize = 128;
    private int updateParticlesKernel;

    private ComputeBuffer particlesBuffer;
    private const int particleStride = sizeof(float) * 3 // Current Position 
        + sizeof(float); //Time
    private const int particlePositionsStride = sizeof(float) * 3 //Position 
        + sizeof(float); //Speed
    private ComputeBuffer quadPoints;
    private ComputeBuffer baseVelocities;
    private const int baseVelocitiesStride = sizeof(float) * 3; // Current Position
    private ComputeBuffer particlePositionsBuffer;
    private const int quadStride = 12;

    struct BaitData
    {
        public Vector3 currentPosition;
        public float time;
    };

    void Start()
    {
        updateParticlesKernel = ParticleUpdater.FindKernel("UpdateParticles");

        BaitData[] data = new BaitData[ParticleCount];
        Vector3[] baseVelocitiesData = new Vector3[ParticleCount];

        particlesBuffer = new ComputeBuffer(ParticleCount, particleStride);
        particlePositionsBuffer = new ComputeBuffer(ParticleCount, particlePositionsStride);
        baseVelocities = new ComputeBuffer(ParticleCount, baseVelocitiesStride);
        
        for (int i = 0; i < ParticleCount; i++)
        {
            baseVelocitiesData[i] = UnityEngine.Random.onUnitSphere;
            data[i].time = UnityEngine.Random.value * ParticleLifetime;
        }

        baseVelocities.SetData(baseVelocitiesData);
        particlesBuffer.SetData(data);

        quadPoints = new ComputeBuffer(6, quadStride);
        quadPoints.SetData(new[]
        {
            new Vector3(-.5f, .5f),
            new Vector3(.5f, .5f),
            new Vector3(.5f, -.5f),
            new Vector3(.5f, -.5f),
            new Vector3(-.5f, -.5f),
            new Vector3(-.5f, .5f)
        });

        Texture3D assembledTexture = TextureGenerator.GetAssembledTexture();
        ParticleUpdater.SetTexture(updateParticlesKernel, "MapTexture", assembledTexture);
        ParticleMaterial.SetTexture("MapTexture", assembledTexture);
    }

    internal void RestartSimAt(Vector3 position)
    {
        BaitData[] data = new BaitData[ParticleCount];
        StartingPoint.position = position;
        for (int i = 0; i < ParticleCount; i++)
        {
            data[i].currentPosition = StartingPoint.localPosition;
            data[i].time = UnityEngine.Random.value * ParticleLifetime;
        }
        particlesBuffer.SetData(data);
    }

    void Update()
    {
        if(UpdateComputation)
        {
            DoUpdateComputation();
        }
    }

    private void DoUpdateComputation()
    {
        // Setting these every frame so that I can noodle with the shader without having to restart the project
        // One the settings are correct this only needs to be set once
        ParticleUpdater.SetBuffer(updateParticlesKernel, "particles", particlesBuffer);
        ParticleUpdater.SetBuffer(updateParticlesKernel, "baseVelocities", baseVelocities);
        ParticleUpdater.SetBuffer(updateParticlesKernel, "particlePositions", particlePositionsBuffer);

        ParticleUpdater.SetVector("_StartingPoint", StartingPoint.localPosition);
        ParticleUpdater.SetFloat("deltaTime", Time.deltaTime);
        ParticleUpdater.SetFloat("particleLifetime", ParticleLifetime);
        ParticleUpdater.SetFloat("particleSpeed", ParticleSpeed);
        ParticleUpdater.SetFloat("_CurrentFactor", CurrentFactor);

        int numberofGroups = Mathf.CeilToInt((float)ParticleCount / GroupSize);
        ParticleUpdater.Dispatch(updateParticlesKernel, numberofGroups, 1, 1);
    }

    void OnDestroy()
	{
		quadPoints.Dispose();
        baseVelocities.Dispose();
        particlesBuffer.Dispose();
		particlePositionsBuffer.Dispose();
	}
     
    void OnRenderObject()
    {
        ParticleMaterial.SetMatrix("masterTransform", RootTransform.localToWorldMatrix);
        ParticleMaterial.SetBuffer("particles", particlePositionsBuffer);
        ParticleMaterial.SetBuffer("baseVelocities", baseVelocities);
        ParticleMaterial.SetBuffer("quadPoints", quadPoints);
        ParticleMaterial.SetFloat("_CardSize", ParticleSize);
        ParticleMaterial.SetFloat("_VelocityScale", VelocityScale);
        ParticleMaterial.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, ParticleCount);
    }
}
