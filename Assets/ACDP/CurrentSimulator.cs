using UnityEngine;
using System.Collections;
using System;

public class CurrentSimulator : MonoBehaviour
{
    public VolumeTextureGenerator TextureGenerator;

    [SerializeField]
    private Mesh arrowMesh;

    [SerializeField]
    private Vector3 baseCurrentForce;

    [SerializeField]
    private float ParticleSize;

    [SerializeField]
    private ComputeShader particleUpdater;

    [SerializeField]
    private Material particleMaterial;

    [SerializeField]
    private int particleCount;

    [SerializeField]
    private float particleLifetime = 1;

    [SerializeField]
    private float particleSpeed = .1f;

    [Range(0, 1)]
    [SerializeField]
    private float depthToShow;

    [SerializeField]
    private VisualizationMode mode;
    [Range(0, 1)]
    [SerializeField]
    private float polePosX;
    [Range(0, 1)]
    [SerializeField]
    private float polePosZ;

    private Bounds bounds;

    private ComputeBuffer originalPositions;
    private ComputeBuffer particleComputeData;
    private ComputeBuffer indirectArgs;

    private const int GroupSize = 128;
    private int updateParticlesKernel;

    private const int originalPositionStride =  sizeof(float) * 3;// Original Position 

    private const int particleStride =          sizeof(float) * 2 // Current Position 
                                              + sizeof(float) * 2 // Previous Position
                                              + sizeof(float);    // Time

    struct ParticleComputeData
    {
        public Vector2 currentPosition;
        public Vector2 previousPosition;
        public float time;
    };

    public enum VisualizationMode
    {
        DepthMode,
        PoleMode,
        CubeMode
    }

    void Start()
    {
        updateParticlesKernel = particleUpdater.FindKernel("UpdateParticles");

        SetParticleBuffers();
        indirectArgs = GetIndirectArgs();

        Texture3D assembledTexture = TextureGenerator.GetAssembledTexture();
        particleUpdater.SetTexture(updateParticlesKernel, "MapTexture", assembledTexture);
        particleMaterial.SetTexture("MapTexture", assembledTexture);

        bounds = GetComponent<BoxCollider>().bounds;
    }

    private Vector3 GetRandomPointInCube()
    {
        return new Vector3
            (
                UnityEngine.Random.value,
                UnityEngine.Random.value,
                UnityEngine.Random.value
            );
    }

    private ComputeBuffer GetIndirectArgs()
    {
        ComputeBuffer ret = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        args[0] = arrowMesh.GetIndexCount(0);
        args[1] = (uint)particleCount;
        args[2] = arrowMesh.GetIndexStart(0);
        args[3] = arrowMesh.GetBaseVertex(0);
        ret.SetData(args);
        return ret;
    }
    private void SetParticleBuffers()
    {
        originalPositions = new ComputeBuffer(particleCount, originalPositionStride);
        particleComputeData = new ComputeBuffer(particleCount, particleStride);

        Vector3[] originalPositionsData = new Vector3[particleCount];
        for (int i = 0; i < particleCount; i++)
        {
            originalPositionsData[i] = GetRandomPointInCube();
        }
        originalPositions.SetData(originalPositionsData);

        ParticleComputeData[] data = new ParticleComputeData[particleCount];
        for (int i = 0; i < particleCount; i++)
        {
            Vector3 pos = originalPositionsData[i];
            data[i].currentPosition = new Vector2(pos.x, pos.z);
            data[i].previousPosition = new Vector2(pos.x, pos.z);
            data[i].time = UnityEngine.Random.value * particleLifetime;
        }
        particleComputeData.SetData(data);
    }

    private void Update()
    {
        DispatchCompute();
        DispatchRender();
    }

    private void DispatchRender()
    {
        particleMaterial.SetMatrix("masterTransform", transform.localToWorldMatrix);
        particleMaterial.SetBuffer("originalPositions", originalPositions);
        particleMaterial.SetBuffer("particleComputeData", particleComputeData);
        particleMaterial.SetFloat("particleSize", ParticleSize);
        particleMaterial.SetFloat("particleLifetime", particleLifetime);

        particleMaterial.SetFloat("depthMode", mode == VisualizationMode.DepthMode ? 1 : 0);
        particleMaterial.SetFloat("depthToShow", depthToShow);

        particleMaterial.SetPass(0);
        Graphics.DrawMeshInstancedIndirect(arrowMesh, 0, particleMaterial, bounds, indirectArgs);
    }

    private void DispatchCompute()
    {
        particleUpdater.SetBuffer(updateParticlesKernel, "originalPositions", originalPositions);
        particleUpdater.SetBuffer(updateParticlesKernel, "particleComputeData", particleComputeData);

        particleUpdater.SetFloat("deltaTime", Time.deltaTime);
        particleUpdater.SetFloat("particleLifetime", particleLifetime);
        particleUpdater.SetFloat("particleSpeed", particleSpeed);
        particleUpdater.SetVector("baseCurrentForce", baseCurrentForce);

        particleUpdater.SetFloat("depthMode", mode == VisualizationMode.DepthMode ? 1 : 0);
        particleUpdater.SetFloat("depthToShow", depthToShow);
        particleUpdater.SetFloat("poleMode", mode == VisualizationMode.PoleMode ? 1 : 0);
        particleUpdater.SetFloat("polePosX", polePosX);
        particleUpdater.SetFloat("polePosZ", polePosZ);

        int numberofGroups = Mathf.CeilToInt((float)particleCount / GroupSize);
        particleUpdater.Dispatch(updateParticlesKernel, numberofGroups, 1, 1);
    }

    void OnDestroy()
	{
        originalPositions.Dispose();
        particleComputeData.Dispose();
        indirectArgs.Dispose();
	}
}
