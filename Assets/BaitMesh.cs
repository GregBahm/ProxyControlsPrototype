using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaitMesh : MonoBehaviour
{
    public Mesh Mesh;
    public Material MeshMat;
    public VolumeTextureGenerator TextureGenerator;

    public float Speed = .1f;

    private int meshVertCount;

    public ComputeShader BaitMeshComputer;
    private int baitMeshKernel;

    public const int GroupSize = 128;

    private ComputeBuffer baseVelocities;
    private const int baseVelocitiesStride = sizeof(float) * 3; // Current Position
    private ComputeBuffer particlePositionsBuffer;
    private const int particlePositionsStride = sizeof(float) * 3; // Current Position

    private void Start()
    {
        baitMeshKernel = BaitMeshComputer.FindKernel("UpdateMeshPoints");

        meshVertCount = Mesh.vertexCount;
        baseVelocities = GetBaseVelocities();
        particlePositionsBuffer = new ComputeBuffer(meshVertCount, particlePositionsStride);

        Texture3D assembledTexture = TextureGenerator.GetAssembledTexture();
        BaitMeshComputer.SetTexture(baitMeshKernel, "MapTexture", assembledTexture);
        BaitMeshComputer.SetBuffer(baitMeshKernel, "_BaseVelocities", baseVelocities);
        BaitMeshComputer.SetBuffer(baitMeshKernel, "_ParticlePositionsBuffer", particlePositionsBuffer);
        BaitMeshComputer.SetFloat("_Speed", Time.deltaTime * Speed);
    }

    private ComputeBuffer GetBaseVelocities()
    {
        ComputeBuffer ret = new ComputeBuffer(meshVertCount, baseVelocitiesStride);
        ret.SetData(Mesh.vertices);
        return ret;
    }

    private void Update()
    {
        int numberofGroups = Mathf.CeilToInt((float)meshVertCount / GroupSize);
        BaitMeshComputer.Dispatch(baitMeshKernel, numberofGroups, 1, 1);

        MeshMat.SetBuffer("_ParticlePositionsBuffer", particlePositionsBuffer);
    }

    private void OnDestroy()
    {
        baseVelocities.Dispose();
        particlePositionsBuffer.Dispose();
    }
}
