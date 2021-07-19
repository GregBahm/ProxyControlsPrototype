using System;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Rendering;

namespace Jules.FluidDynamics
{
    public class FluidSimulator : MonoBehaviour
    {
        [SerializeField]
        private float dyeDissipation = 0.99f;
        [SerializeField]
        private float velocityDissipation = 0.999f;
        [SerializeField]
        private float timeStep = 0.01f;
        [SerializeField]
        private DyeSprayer dyeSprayerScript = default;

        [SerializeField]
        private bool reset;

        [SerializeField]
        private Texture2D heightMap;

        bool paused;

        private static readonly Vector3 NumThreads = new Vector3(16, 16, 1);
        private static readonly Vector3 FluidSimResolution = new Vector3(64, 64, 64);

        public enum TextureType
        {
            Dye,
            Velocity,
            Divergence,
            Pressure
        }

        private struct BoundaryData
        {
            public Vector3 pixelCoords;
            public Vector3 insideOffset;
        }

        private const int BoundaryDataStride = (4 * 3) * 2;

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

        private ComputeBuffer _boundaryBuffer;

        private int _addDyeSprayKernelIndex;
        private int _advectionKernelIndex;
        private int _clearTexturesKernelIndex;
        private int _computeDivergenceKernelIndex;
        private int _jacobiKernelIndex;
        private int _subtractGradientKernelIndex;
        private int _drawPressureBoundaryKernelIndex;
        private int _drawVelocityBoundaryKernelIndex;

        private int _velocityTextureId;
        private int _readVelocityId;
        private int _dyeTextureId;
        private int _readDyeId;
        private int _resolutionId;
        private int _clearTextureId;
        private int _divergenceTextureId;
        private int _readDivergenceId;
        private int _pressureTextureId;
        private int _readPressureId;
        private int _boundaryValueId;
        private int _boundaryDataBufferId;

        private int _dyeSprayPositionId;
        private int _dyeSprayDirectionId;
        private int _dyeSprayRadiusId;
        private int _dyeColorId;

        private int _mainTexId;
        private int _dyeDissipationId;
        private int _velocityDissipationId;
        private int _timestepId;

        private int _heightmapId;

        private const int JacobiIterations = 50;

        private void Start()
        {
            _addDyeSprayKernelIndex = fluidSimulationShader.FindKernel("AddDyeSpray");
            _advectionKernelIndex = fluidSimulationShader.FindKernel("Advect");
            _clearTexturesKernelIndex = fluidSimulationShader.FindKernel("ClearTextures");
            _computeDivergenceKernelIndex = fluidSimulationShader.FindKernel("ComputeDivergence");
            _jacobiKernelIndex = fluidSimulationShader.FindKernel("Jacobi");
            _subtractGradientKernelIndex = fluidSimulationShader.FindKernel("SubtractGradient");
            _drawPressureBoundaryKernelIndex = fluidSimulationShader.FindKernel("DrawPressureBoundary");
            _drawVelocityBoundaryKernelIndex = fluidSimulationShader.FindKernel("DrawVelocityBoundary");

            _velocityTextureId = Shader.PropertyToID("_Velocity");
            _readVelocityId = Shader.PropertyToID("ReadVelocity");
            _dyeTextureId = Shader.PropertyToID("_Dye");
            _readDyeId = Shader.PropertyToID("ReadDye");
            _resolutionId = Shader.PropertyToID("_Resolution");
            _dyeSprayPositionId = Shader.PropertyToID("_DyeSprayPosition");
            _dyeSprayDirectionId = Shader.PropertyToID("_DyeSprayDirection");
            _dyeSprayRadiusId = Shader.PropertyToID("_DyeSprayRadius");
            _clearTextureId = Shader.PropertyToID("_ClearTexture");
            _divergenceTextureId = Shader.PropertyToID("_Divergence");
            _readDivergenceId = Shader.PropertyToID("ReadDivergence");
            _pressureTextureId = Shader.PropertyToID("_Pressure");
            _readPressureId = Shader.PropertyToID("ReadPressure");
            _boundaryValueId = Shader.PropertyToID("_BoundaryValue");
            _boundaryDataBufferId = Shader.PropertyToID("_BoundaryData");
            _dyeColorId = Shader.PropertyToID("_DyeColor");
            _heightmapId = Shader.PropertyToID("Heightmap");

            _mainTexId = Shader.PropertyToID("_MainTex");
            _dyeDissipationId = Shader.PropertyToID("_DyeDissipation");
            _velocityDissipationId = Shader.PropertyToID("_VelocityDissipation");
            _timestepId = Shader.PropertyToID("_Timestep");

            _dyeTexture = CreateTexture();
            _readDyeTexture = CreateTexture();
            _velocityTexture = CreateTexture();
            _readVelocityTexture = CreateTexture();
            _divergenceTexture = CreateTexture();
            _pressureTexture = CreateTexture();
            _readPressureTexture = CreateTexture();

            // Fluid sim properties
            fluidSimulationShader.SetVector(_resolutionId, FluidSimResolution);

            InitializeBoundaryBuffer();
        }

        private void SetShaderProperties()
        {

            fluidSimulationShader.SetFloat(_dyeDissipationId, dyeDissipation);
            fluidSimulationShader.SetFloat(_velocityDissipationId, velocityDissipation);
            fluidSimulationShader.SetFloat(_timestepId, timeStep);
            fluidSimulationShader.SetTexture(_drawPressureBoundaryKernelIndex, _heightmapId, heightMap);
        }

        private void Update()
        {
            SetShaderProperties();

            if (reset)
            {
                paused = false;
                reset = false;
                ClearTexture(_readVelocityTexture);
                ClearTexture(_readDyeTexture);
            }

            if (paused)
            {
                if (dyeSprayerScript.enabled == true)
                {
                    dyeSprayerScript.enabled = false;
                }
                return;
            }
            if (dyeSprayerScript.enabled == false)
            {
                dyeSprayerScript.enabled = true;
            }

            Advect();

            DrawVelocityBoundary();

            ComputeDivergence();

            ClearTexture(_pressureTexture);
            ClearTexture(_readPressureTexture);

            for (int i = 0; i < JacobiIterations; i++)
            {
                RunJacobi();
                DrawPressureBoundary();
            }

            SubtractGradient();

            displayCubeMat.SetTexture(_mainTexId, GetTexture(displayTexture));
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
                    return _pressureTexture;
            }

        }

        private void OnDestroy()
        {
            _boundaryBuffer.Dispose();
        }


        private void InitializeBoundaryBuffer()
        {
            int boundarySize = (int)(FluidSimResolution.x * FluidSimResolution.y * 2 +
                                      FluidSimResolution.x * FluidSimResolution.z * 2 +
                                      FluidSimResolution.y * FluidSimResolution.z * 2);

            _boundaryBuffer = new ComputeBuffer(boundarySize, BoundaryDataStride);

            BoundaryData[] boundaryData = new BoundaryData[boundarySize];

            int currentIndex = 0;
            for (int i = 0; i < FluidSimResolution.x; i++)
            {
                for (int j = 0; j < FluidSimResolution.y; j++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(i, j, 0);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 0, 1);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(i, j, FluidSimResolution.z - 1);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 0, -1);

                    currentIndex++;
                }

                for (int k = 0; k < FluidSimResolution.z; k++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(i, 0, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 1, 0);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(i, FluidSimResolution.y - 1, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, -1, 0);

                    currentIndex++;
                }
            }

            for (int j = 0; j < FluidSimResolution.y; j++)
            {
                for (int k = 0; k < FluidSimResolution.z; k++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(0, j, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(1, 0, 0);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(FluidSimResolution.x - 1, j, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(-1, 0, 0);

                    currentIndex++;
                }
            }

            _boundaryBuffer.SetData(boundaryData);
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

            SwapDyeTextures();
            SwapVelocityTextures();
        }

        private void DrawVelocityBoundary()
        {
            SwapVelocityTextures();
            SetVelocityTextures(_drawVelocityBoundaryKernelIndex);

            fluidSimulationShader.SetFloat(_boundaryValueId, 0f);
            fluidSimulationShader.SetBuffer(_drawVelocityBoundaryKernelIndex, _boundaryDataBufferId, _boundaryBuffer);

            fluidSimulationShader.Dispatch(_drawVelocityBoundaryKernelIndex, Mathf.CeilToInt(_boundaryBuffer.count / NumThreads.x), 1, 1);

            SwapVelocityTextures();
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

        private void DrawPressureBoundary()
        {
            // TODO: this kernel reads from the previous iteration of the pressure texture.
            // Need a kernel that copies the value as-is if it's not a boundary pixel and
            // copies the "inside pixel" value if it's a boundary pixel.

            SetPressureTextures(_drawPressureBoundaryKernelIndex);

            fluidSimulationShader.SetFloat(_boundaryValueId, 1f);
            fluidSimulationShader.SetBuffer(_drawPressureBoundaryKernelIndex, _boundaryDataBufferId, _boundaryBuffer);

            fluidSimulationShader.Dispatch(_drawPressureBoundaryKernelIndex, Mathf.CeilToInt(_boundaryBuffer.count / NumThreads.x), 1, 1);

            SwapPressureTextures();
        }

        private void SubtractGradient()
        {
            SetPressureTextures(_subtractGradientKernelIndex);
            SetVelocityTextures(_subtractGradientKernelIndex);

            DispatchKernel(_subtractGradientKernelIndex);

            SwapVelocityTextures();
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

        public void ResetSimulation()
        {
            reset = true;
        }

        public void SetPause(bool newVal)
        {
            paused = newVal;
        }
    }
}
