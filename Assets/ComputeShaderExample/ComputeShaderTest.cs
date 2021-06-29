using UnityEngine;
using System.Collections;
using System;

public class ComputeShaderTest : MonoBehaviour
{
    public VolumeTextureGenerator TextureGenerator;

    public ComputeShader ParticleUpdater;
    public Material ParticleMaterial;
    public int ParticleCount;
    [Range(0, .1f)]
	public float ParticleSize;
	public float VelocityScale;
    
    public float ParticleLifetime = 1;
    public float ParticleSpeed = .1f;

    public const int GroupSize = 128;
    private int updateParticlesKernel;

    private ComputeBuffer particlesBuffer;
    private const int particleStride = sizeof(float) * 3 //Source Velocity 
        + sizeof(float) * 3 // Current Position 
        + sizeof(float); //Time
    private const int particlePositionsStride = sizeof(float) * 3 //Position 
        + sizeof(float); //Speed
    private ComputeBuffer quadPoints;
    private ComputeBuffer particlePositionsBuffer;
    private const int quadStride = 12;

    struct WindData
    {
        public Vector3 sourceVelocity;
        public Vector3 currentPosition;
        public float time;
    };

    private Vector3 GetRandomVelocity()
    {
        return UnityEngine.Random.onUnitSphere;
    }

    void Start()
    {
        updateParticlesKernel = ParticleUpdater.FindKernel("UpdateParticles");

        WindData[] data = new WindData[ParticleCount];
        Vector4[] positionData = new Vector4[ParticleCount];

        particlesBuffer = new ComputeBuffer(ParticleCount, particleStride);
        particlePositionsBuffer = new ComputeBuffer(ParticleCount, particlePositionsStride);

        Vector3 center = new Vector3(.5f, .5f, .5f);
        for (int i = 0; i < ParticleCount; i++)
        {
            data[i].sourceVelocity = GetRandomVelocity();
            data[i].currentPosition = center;
            data[i].time = UnityEngine.Random.value * ParticleLifetime;
        }

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

    void Update()
    {
        // Setting these every frame so that I can noodle with the shader without having to restart the project
        // One the settings are correct this only needs to be set once
        ParticleUpdater.SetBuffer(updateParticlesKernel, "particles", particlesBuffer);
        ParticleUpdater.SetBuffer(updateParticlesKernel, "particlePositions", particlePositionsBuffer);
     
        ParticleUpdater.SetFloat("deltaTime", Time.deltaTime);
        ParticleUpdater.SetFloat("particleLifetime", ParticleLifetime);
        ParticleUpdater.SetFloat("particleSpeed", ParticleSpeed);

        int numberofGroups = Mathf.CeilToInt((float)ParticleCount / GroupSize);
        ParticleUpdater.Dispatch(updateParticlesKernel, numberofGroups, 1, 1);
    }
	
	void OnDestroy()
	{
		quadPoints.Dispose();
		particlesBuffer.Dispose();
		particlePositionsBuffer.Dispose();
	}
     
    void OnRenderObject()
    {
        ParticleMaterial.SetMatrix("masterTransform", transform.localToWorldMatrix);
        ParticleMaterial.SetBuffer("particles", particlePositionsBuffer);
        ParticleMaterial.SetBuffer("quadPoints", quadPoints);
		ParticleMaterial.SetFloat("_CardSize", ParticleSize);
		ParticleMaterial.SetFloat("_VelocityScale", VelocityScale);
        ParticleMaterial.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, ParticleCount);
    }
}
