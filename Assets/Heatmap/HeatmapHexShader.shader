Shader "Unlit/HeatmapHexShader"
{
    Properties
    {
      _HeatLut("Heat Lut", 2D) = "white" {}
      _HeatFalloff("Heat Falloff", Float) = 1
      _HeatDecay("Heat Decay", Float) = 1
    }
    SubShader
    {
        LOD 100

        Pass
        {

            CGPROGRAM
            #define HEAT_POINTS 16

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"

            struct HeatData
            {
              float2 position;
              float intensity;
            };

            StructuredBuffer<HeatData> _HeatDataBuffer;
            StructuredBuffer<float2> _UvsBuffer;
            float _BoxWidth;
            float _BoxDepth;
            float _HeatFalloff;
            float _HeatDecay;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float heat : TEXCOORD1;
                float3 normal : NORMAL;
                float3 objSpace : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _HeatLut;
            float4x4 _MasterTransform;
            float _Margin;

            float AccumulateHeat(float2 uvs, float2 heatPosition, float heatAmount)
            {
                float dist = length(uvs - heatPosition) * _HeatFalloff;
                float ret = 1 - dist;
                ret *= heatAmount;
                return max(0, ret);
            }

            float GetHeat(float2 uvs)
            {
                float heat = 0;
                for (uint i = 0; i < HEAT_POINTS; i++)
                {
                  HeatData heatPoint = _HeatDataBuffer[i];
                  float heatContribution = AccumulateHeat(uvs, heatPoint.position, heatPoint.intensity);
                  heat += heatContribution * heatContribution;
                }
                return sqrt(heat);
            }

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                float2 masterUvs = _UvsBuffer[instanceID];

                float heat = GetHeat(masterUvs);

                float effectiveMargin = heat;

                float3 newVert = v.vertex;
                newVert.x *= _BoxWidth * effectiveMargin;
                newVert.x += masterUvs.x - .5;
                newVert.z *= _BoxDepth * effectiveMargin;
                newVert.z += masterUvs.y - .5;
                newVert.y += .5;
                newVert.y *= pow(heat, 2) * sign(heat);
                newVert.y -= .5;

                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 worldPos = mul(_MasterTransform, float4(newVert, 1));
                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = v.uv;
                o.heat = pow(heat, .5);
                o.objSpace = v.vertex;
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float heatAlpha = pow(i.objSpace.y + .5, i.heat * 2);
              heatAlpha = saturate(heatAlpha) * .7 + saturate(i.normal.y) * .3;
              float3 heatColor = tex2D(_HeatLut, float2(saturate(i.heat - .25), 0)).xyz * 1.5;
              heatColor = pow(heatColor, 1.25);
              float3 sideColor = 0;
              float3 ret = lerp(sideColor, heatColor, saturate(heatAlpha));
              return saturate(float4(ret, i.heat));
            }
            ENDCG
        }
    }
}
