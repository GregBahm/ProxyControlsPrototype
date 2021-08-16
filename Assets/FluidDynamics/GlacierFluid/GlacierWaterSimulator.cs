using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Jules.FluidDynamics
{
    [RequireComponent(typeof(MeshRenderer))]
	public class GlacierWaterSimulator : MonoBehaviour
    {
        #region Constants

        private static readonly int _velocityTextureId = Shader.PropertyToID("_Velocity");
        private static readonly int _readVelocityId = Shader.PropertyToID("ReadVelocity");
        private static readonly int _dyeTextureId = Shader.PropertyToID("_Dye");
        private static readonly int _readDyeId = Shader.PropertyToID("ReadDye");
        private static readonly int _resolutionId = Shader.PropertyToID("_Resolution");
        private static readonly int _dyeSprayPositionId = Shader.PropertyToID("_DyeSprayPosition");
        private static readonly int _dyeSprayDirectionId = Shader.PropertyToID("_DyeSprayDirection");
        private static readonly int _dyeSprayRadiusId = Shader.PropertyToID("_DyeSprayRadius");
        private static readonly int _clearTextureId = Shader.PropertyToID("_ClearTexture");
        private static readonly int _divergenceTextureId = Shader.PropertyToID("_Divergence");
        private static readonly int _readDivergenceId = Shader.PropertyToID("ReadDivergence");
        private static readonly int _pressureTextureId = Shader.PropertyToID("_Pressure");
        private static readonly int _readPressureId = Shader.PropertyToID("ReadPressure");
        private static readonly int _dyeColorId = Shader.PropertyToID("_DyeColor");
        private static readonly int _texId = Shader.PropertyToID("_Tex");
        private static readonly int _dyeDissipationId = Shader.PropertyToID("_DyeDissipation");
        private static readonly int _velocityDissipationId = Shader.PropertyToID("_VelocityDissipation");
        private static readonly int _timestepId = Shader.PropertyToID("_Timestep");
        private static readonly int _boundaryDataBufferId = Shader.PropertyToID("boundaryData");
        private static readonly int _pressureId = Shader.PropertyToID("_BoundaryPressure");

        private static readonly Vector3 NumThreads = new Vector3(16, 16, 1);

        #endregion

        [SerializeField]
        private int JacobiIterations = 50;

        [SerializeField]
        private Vector3 simulationResolution = new Vector3(64, 64, 64);

        [SerializeField]
        private float dyeDissipation = 0.99f;

        [SerializeField]
        private float velocityDissipation = 0.999f;

        [SerializeField]
        private float timeStep = 0.01f;

        [SerializeField]
        [Range(0, 1)]
        private float pressure = 0f;

        [SerializeField]
        private ComputeShader fluidSimulationShader = null;

        [SerializeField]
        private List<DyeSprayer> dyeSprayers = new List<DyeSprayer>();

        private struct BoundaryData
        {
            public Vector3 pixelCoords;
            public Vector3 insideOffset;
        }

        private Material fluidMat = null;

        private const int BoundaryDataStride = (4 * 3) * 2;

        private RenderTexture _dyeTexture;
        public RenderTexture DyeTexture => _dyeTexture;
        private RenderTexture _readDyeTexture;
        private RenderTexture _velocityTexture;
        public RenderTexture VelocityTexture => _velocityTexture;
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
        private int _drawPressureBoundaryKernelIndex;
        private int _drawVelocityBoundaryKernelIndex;


        private ComputeBuffer _boundaryBuffer;

        private Vector3 dyeSprayerOffset = new Vector3(0.5f, 0.5f, 0.5f);

        private void Awake()
        {
            _addDyeSprayKernelIndex = fluidSimulationShader.FindKernel("AddCurrentsSpray");
            _advectionKernelIndex = fluidSimulationShader.FindKernel("Advect");
            _clearTexturesKernelIndex = fluidSimulationShader.FindKernel("ClearTextures");
            _computeDivergenceKernelIndex = fluidSimulationShader.FindKernel("ComputeDivergence");
            _jacobiKernelIndex = fluidSimulationShader.FindKernel("Jacobi");
            _subtractGradientKernelIndex = fluidSimulationShader.FindKernel("SubtractGradient");
            _drawPressureBoundaryKernelIndex = fluidSimulationShader.FindKernel("DrawPressureBoundary");
            _drawVelocityBoundaryKernelIndex = fluidSimulationShader.FindKernel("DrawVelocityBoundary");

            CreateTextures();
            InitializeBoundaryBuffer();
        }

        private void Start()
        {
            ClearTextures();
            var renderer = GetComponent<MeshRenderer>();
            fluidMat = renderer.sharedMaterial;
        }

        private void OnDestroy()
        {
            if (_boundaryBuffer != null)
                _boundaryBuffer.Dispose();
            DestroyTextures();
        }

		private void Update()
        {
            SetShaderProperties();
            SprayAllDye();
            RunSimulation();
        }

        public void AddDyeSprayer(DyeSprayer dyeSprayer)
        {
            // Enforce exactly-one reference to a single dye sprayer instance
            if (!dyeSprayers.Contains(dyeSprayer))
            {
                dyeSprayers.Add(dyeSprayer);
            }
        }

        public void RemoveDyeSprayer(DyeSprayer dyeSprayer)
        {
            dyeSprayers.Remove(dyeSprayer);
        }

        private void SprayAllDye()
        {
            foreach (DyeSprayer sprayer in dyeSprayers)
            {
                Vector3 dyeSprayerPosition = this.transform.InverseTransformPoint(sprayer.transform.position) + dyeSprayerOffset;
                SprayDye(sprayer.Color, sprayer.Radius, dyeSprayerPosition, sprayer.transform.forward * sprayer.Force);
            }
        }

        private void SetShaderProperties()
        {
            fluidSimulationShader.SetVector(_resolutionId, simulationResolution);
            fluidSimulationShader.SetFloat(_dyeDissipationId, dyeDissipation);
            fluidSimulationShader.SetFloat(_velocityDissipationId, velocityDissipation);
            fluidSimulationShader.SetFloat(_timestepId, timeStep);
            fluidSimulationShader.SetFloat(_pressureId, pressure);
        }

        private void RunSimulation()
        {

            Advect();
            SwapDyeTextures();
            SwapVelocityTextures();
            DrawVelocityBoundary();
            ComputeDivergence();
            ClearTexture(_readPressureTexture);
            
            for (int i = 0; i < JacobiIterations; i++)
            {
                RunJacobi();
                DrawPressureBoundary();
            }
            
            SubtractGradient();
            SwapVelocityTextures();
            fluidMat.SetTexture(_texId, _readDyeTexture);
        }

        private void DrawVelocityBoundary()
        {
            SwapVelocityTextures();
            SetVelocityTextures(_drawVelocityBoundaryKernelIndex);

            fluidSimulationShader.SetBuffer(_drawVelocityBoundaryKernelIndex, _boundaryDataBufferId, _boundaryBuffer);

            fluidSimulationShader.Dispatch(_drawVelocityBoundaryKernelIndex, Mathf.CeilToInt(_boundaryBuffer.count / NumThreads.x), 1, 1);

            SwapVelocityTextures();
        }
        private void DrawPressureBoundary()
        {
            SetPressureTextures(_drawPressureBoundaryKernelIndex);

            fluidSimulationShader.SetBuffer(_drawPressureBoundaryKernelIndex, _boundaryDataBufferId, _boundaryBuffer);

            fluidSimulationShader.Dispatch(_drawPressureBoundaryKernelIndex, Mathf.CeilToInt(_boundaryBuffer.count / NumThreads.x), 1, 1);

            SwapPressureTextures();
        }

        private void CreateTextures()
        {
            _dyeTexture = CreateTexture();
            _readDyeTexture = CreateTexture();
            _velocityTexture = CreateTexture();
            _readVelocityTexture = CreateTexture();
            _divergenceTexture = CreateTexture();
            _pressureTexture = CreateTexture();
            _readPressureTexture = CreateTexture();
        }

        private void DestroyTextures()
		{
            DestroyTexture(_dyeTexture);
            DestroyTexture(_readDyeTexture);
            DestroyTexture(_velocityTexture);
            DestroyTexture(_readVelocityTexture);
            DestroyTexture(_divergenceTexture);
            DestroyTexture(_pressureTexture);
            DestroyTexture(_readPressureTexture);
        }

        private void ClearTextures()
        {
            ClearTexture(_dyeTexture);
            ClearTexture(_readDyeTexture);
            ClearTexture(_velocityTexture);
            ClearTexture(_readVelocityTexture);
            ClearTexture(_divergenceTexture);
            ClearTexture(_pressureTexture);
            ClearTexture(_readPressureTexture);
        }

        private void ClearTexture(RenderTexture texture)
        {
            fluidSimulationShader.SetTexture(_clearTexturesKernelIndex, _clearTextureId, texture);
            DispatchKernel(_clearTexturesKernelIndex);
        }

        public void SprayDye(Color color, float radius, Vector3 position, Vector3 direction)
        {
            SetDyeTextures(_addDyeSprayKernelIndex);
            SetVelocityTextures(_addDyeSprayKernelIndex);

            fluidSimulationShader.SetVector(_dyeColorId, color);
            fluidSimulationShader.SetFloat(_dyeSprayRadiusId, radius);
            fluidSimulationShader.SetVector(_dyeSprayPositionId, position);
            fluidSimulationShader.SetVector(_dyeSprayDirectionId, direction);

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
            fluidSimulationShader.Dispatch(kernelIndex, Mathf.CeilToInt(simulationResolution.x / NumThreads.x), Mathf.CeilToInt(simulationResolution.y / NumThreads.y), Mathf.CeilToInt(simulationResolution.z / NumThreads.z));
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
        private void InitializeBoundaryBuffer()
        {
            int boundarySize = (int)(simulationResolution.x * simulationResolution.y * 2 +
                                      simulationResolution.x * simulationResolution.z * 2 +
                                      simulationResolution.y * simulationResolution.z * 2);

            _boundaryBuffer = new ComputeBuffer(boundarySize, BoundaryDataStride);

            BoundaryData[] boundaryData = new BoundaryData[boundarySize];

            int currentIndex = 0;
            for (int i = 0; i < simulationResolution.x; i++)
            {
                for (int j = 0; j < simulationResolution.y; j++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(i, j, 0);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 0, 1);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(i, j, simulationResolution.z - 1);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 0, -1);

                    currentIndex++;
                }

                for (int k = 0; k < simulationResolution.z; k++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(i, 0, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, 1, 0);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(i, simulationResolution.y - 1, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(0, -1, 0);

                    currentIndex++;
                }
            }

            for (int j = 0; j < simulationResolution.y; j++)
            {
                for (int k = 0; k < simulationResolution.z; k++)
                {
                    boundaryData[currentIndex].pixelCoords = new Vector3(0, j, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(1, 0, 0);

                    currentIndex++;

                    boundaryData[currentIndex].pixelCoords = new Vector3(simulationResolution.x - 1, j, k);
                    boundaryData[currentIndex].insideOffset = new Vector3(-1, 0, 0);

                    currentIndex++;
                }
            }

            _boundaryBuffer.SetData(boundaryData);
        }

        private RenderTexture CreateTexture()
        {
            RenderTexture texture = new RenderTexture((int)simulationResolution.x, (int)simulationResolution.y, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            texture.dimension = TextureDimension.Tex3D;
            texture.volumeDepth = (int)simulationResolution.z;
            texture.enableRandomWrite = true;
            texture.useMipMap = false;
            texture.filterMode = FilterMode.Bilinear;
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.depth = 0;
            texture.Create();

            return texture;
        }

        private void DestroyTexture(RenderTexture texture)
		{
            if(texture != null)
            {
                texture.Release();
                Destroy(texture);
            }
		}
    }
}
