using System;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Rendering;

namespace Jules.FluidDynamics
{
    public class FluidSimulator : MonoBehaviour
    {
        [SerializeField]
        private int jacobiIterations = 50;
        [SerializeField]
        private SimResolution resolution;
        [SerializeField]
        private float dyeDissipation = 0.99f;
        [SerializeField]
        private float velocityDissipation = 0.999f;
        [SerializeField]
        private float timeStep = 0.01f;
        [SerializeField]
        private DyeSprayer dyeSprayerScript = default;

        [SerializeField]
        private Texture2D heightMap;

        private static readonly Vector3 NumThreads = new Vector3(16, 16, 1);
        private static readonly Vector3 FluidSimResolution = new Vector3(64, 64, 64);

        public enum TextureType
        {
            Dye,
            Velocity,
            Divergence,
            Pressure
        }

        public enum SimResolution
        {
            High,
            Low
        }

        [SerializeField]
        private TextureType displayTexture = TextureType.Dye;

        [SerializeField]
        private Material displayCubeMat = null;

        [SerializeField]
        private ComputeShader fluidSimulationShader = null;

        private RenderTexture _dyeTexture;
        private RenderTexture _readDyeTexture;
        private RenderTexture _velocityTexture;
        private RenderTexture _readVelocityTexture;
        private RenderTexture _divergenceTexture;
        private RenderTexture _pressureTexture;
        private RenderTexture _readPressureTexture;

        private int _addDyeSprayKernelIndex;
        private int _advectionKernelIndex;
        private int _clearTexturesKernelIndex;
        private int _computeDivergenceKernelIndex;
        private int _jacobiKernelIndex;
        private int _subtractGradientKernelIndex;
        private int _setTerrainVelocityKernelIndex;

        private static readonly int _velocityTextureId = Shader.PropertyToID("_Velocity");
        private static readonly int _readVelocityId = Shader.PropertyToID("ReadVelocity");
        private static readonly int _dyeTextureId = Shader.PropertyToID("_Dye");
        private static readonly int _readDyeId = Shader.PropertyToID("ReadDye");
        private static readonly int _resolutionId = Shader.PropertyToID("_Resolution");
        private static readonly int _clearTextureId = Shader.PropertyToID("_ClearTexture");
        private static readonly int _divergenceTextureId = Shader.PropertyToID("_Divergence");
        private static readonly int _readDivergenceId = Shader.PropertyToID("ReadDivergence");
        private static readonly int _pressureTextureId = Shader.PropertyToID("_Pressure");
        private static readonly int _readPressureId = Shader.PropertyToID("ReadPressure");
        private static readonly int _dyeSprayPositionId = Shader.PropertyToID("_DyeSprayPosition");
        private static readonly int _dyeSprayDirectionId = Shader.PropertyToID("_DyeSprayDirection");
        private static readonly int _dyeSprayRadiusId = Shader.PropertyToID("_DyeSprayRadius");
        private static readonly int _dyeColorId = Shader.PropertyToID("_DyeColor");
        private static readonly int _mainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int _dyeDissipationId = Shader.PropertyToID("_DyeDissipation");
        private static readonly int _velocityDissipationId = Shader.PropertyToID("_VelocityDissipation");
        private static readonly int _timestepId = Shader.PropertyToID("_Timestep");
        private static readonly int _heightmapId = Shader.PropertyToID("Heightmap");

        private void Start()
        {
            _addDyeSprayKernelIndex = fluidSimulationShader.FindKernel("AddDyeSpray");
            _advectionKernelIndex = fluidSimulationShader.FindKernel("Advect");
            _clearTexturesKernelIndex = fluidSimulationShader.FindKernel("ClearTextures");
            _computeDivergenceKernelIndex = fluidSimulationShader.FindKernel("ComputeDivergence");
            _jacobiKernelIndex = fluidSimulationShader.FindKernel("Jacobi");
            _subtractGradientKernelIndex = fluidSimulationShader.FindKernel("SubtractGradient");
            _setTerrainVelocityKernelIndex = fluidSimulationShader.FindKernel("SetTerrainVelocity");

            _dyeTexture = CreateTexture();
            _readDyeTexture = CreateTexture();
            _velocityTexture = CreateTexture();
            _readVelocityTexture = CreateTexture();
            _divergenceTexture = CreateTexture();
            _pressureTexture = CreateTexture();
            _readPressureTexture = CreateTexture();
        }

        private void SetShaderProperties()
        {
            fluidSimulationShader.SetVector(_resolutionId, FluidSimResolution);
            fluidSimulationShader.SetFloat(_dyeDissipationId, dyeDissipation);
            fluidSimulationShader.SetFloat(_velocityDissipationId, velocityDissipation);
            fluidSimulationShader.SetFloat(_timestepId, timeStep);
        }

        private void Update()
        {
            SetShaderProperties();
            Advect();
            SwapVelocityTextures();
            SetTerrainVelocity();
            SwapDyeTextures();
            SwapVelocityTextures();
            ComputeDivergence();
            ClearTexture(_readPressureTexture);
            for (int i = 0; i < jacobiIterations; i++)
            {
                RunJacobi();
            }
            SwapPressureTextures();
            SubtractGradient();
            SwapVelocityTextures();

            displayCubeMat.SetTexture(_mainTexId, GetTexture(displayTexture));
        }

        private void SetTerrainVelocity()
        {
            SetVelocityTextures(_setTerrainVelocityKernelIndex);
            fluidSimulationShader.SetTexture(_setTerrainVelocityKernelIndex, _heightmapId, heightMap);
            DispatchKernel(_setTerrainVelocityKernelIndex);
        }

        private Texture GetTexture(TextureType displayTexture)
        {
            switch (displayTexture)
            {
                case TextureType.Dye:
                    return _readDyeTexture;
                case TextureType.Velocity:
                    return _readVelocityTexture;
                case TextureType.Divergence:
                    return _divergenceTexture;
                case TextureType.Pressure:
                default:
                    return _readPressureTexture;
            }

        }

        private void ClearTexture(RenderTexture texture)
        {
            fluidSimulationShader.SetTexture(_clearTexturesKernelIndex, _clearTextureId, texture);
            DispatchKernel(_clearTexturesKernelIndex);
        }

        public void SprayDye(Vector3 position, Vector3 direction, float radius, Color color)
        {
            SetDyeTextures(_addDyeSprayKernelIndex);
            SetVelocityTextures(_addDyeSprayKernelIndex);

            fluidSimulationShader.SetVector(_dyeColorId, color);
            fluidSimulationShader.SetFloat(_dyeSprayRadiusId, radius);
            fluidSimulationShader.SetFloats(_dyeSprayPositionId, position.x, position.y, position.z);
            fluidSimulationShader.SetFloats(_dyeSprayDirectionId, direction.x, direction.y, direction.z);

            DispatchKernel(_addDyeSprayKernelIndex);

            SwapDyeTextures();
            SwapVelocityTextures();
        }

        private void Advect()
        {
            SetDyeTextures(_advectionKernelIndex);
            SetVelocityTextures(_advectionKernelIndex);
            DispatchKernel(_advectionKernelIndex);
        }

        private void ComputeDivergence()
        {
            SetVelocityTextures(_computeDivergenceKernelIndex);
            fluidSimulationShader.SetTexture(_computeDivergenceKernelIndex, _divergenceTextureId, _divergenceTexture);
            DispatchKernel(_computeDivergenceKernelIndex);
        }

        private void RunJacobi()
        {
            SetPressureTextures(_jacobiKernelIndex);
            fluidSimulationShader.SetTexture(_jacobiKernelIndex, _readDivergenceId, _divergenceTexture);
            DispatchKernel(_jacobiKernelIndex);
        }

        private void SubtractGradient()
        {
            SetPressureTextures(_subtractGradientKernelIndex);
            SetVelocityTextures(_subtractGradientKernelIndex);

            DispatchKernel(_subtractGradientKernelIndex);
        }

        private void DispatchKernel(int kernelIndex)
        {
            fluidSimulationShader.Dispatch(kernelIndex, Mathf.CeilToInt(FluidSimResolution.x / NumThreads.x), Mathf.CeilToInt(FluidSimResolution.y / NumThreads.y), Mathf.CeilToInt(FluidSimResolution.z / NumThreads.z));
        }

        private void SwapDyeTextures()
        {
            var temp = _readDyeTexture;
            _readDyeTexture = _dyeTexture;
            _dyeTexture = temp;
        }

        private void SetDyeTextures(int kernelIndex)
        {
            fluidSimulationShader.SetTexture(kernelIndex, _dyeTextureId, _dyeTexture);
            fluidSimulationShader.SetTexture(kernelIndex, _readDyeId, _readDyeTexture);
        }

        private void SwapVelocityTextures()
        {
            var temp = _readVelocityTexture;
            _readVelocityTexture = _velocityTexture;
            _velocityTexture = temp;
        }

        private void SetVelocityTextures(int kernelIndex)
        {
            fluidSimulationShader.SetTexture(kernelIndex, _velocityTextureId, _velocityTexture);
            fluidSimulationShader.SetTexture(kernelIndex, _readVelocityId, _readVelocityTexture);
        }

        private void SwapPressureTextures()
        {
            var temp = _readPressureTexture;
            _readPressureTexture = _pressureTexture;
            _pressureTexture = temp;
        }

        private void SetPressureTextures(int kernelIndex)
        {
            fluidSimulationShader.SetTexture(kernelIndex, _pressureTextureId, _pressureTexture);
            fluidSimulationShader.SetTexture(kernelIndex, _readPressureId, _readPressureTexture);
        }

        private static RenderTexture CreateTexture()
        {
            RenderTexture renderTexture = new RenderTexture((int)FluidSimResolution.x, (int)FluidSimResolution.y, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            renderTexture.dimension = TextureDimension.Tex3D;
            renderTexture.volumeDepth = (int)FluidSimResolution.z;
            renderTexture.enableRandomWrite = true;
            renderTexture.useMipMap = false;
            renderTexture.filterMode = FilterMode.Bilinear;
            renderTexture.wrapMode = TextureWrapMode.Clamp;
            renderTexture.Create();

            return renderTexture;
        }
    }
}
