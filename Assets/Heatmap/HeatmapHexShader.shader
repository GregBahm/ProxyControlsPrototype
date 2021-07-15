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
        Blend One OneMinusSrcAlpha
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
                dist = pow(dist, _HeatDecay);
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
                newVert.x *= _BoxWidth;
                newVert.x += masterUvs.x - .5;
                newVert.z *= _BoxDepth * 1.15f;
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

            float3 GetCol(float heat, float3 normal)
            {
              float topHeat = pow(saturate(heat), 2);
              float sideHeat = saturate(heat - .25);
              float lutUv = lerp(sideHeat, topHeat, normal.y);
              lutUv -= normal.x * .1;
              return tex2D(_HeatLut, float2(lutUv, 0)).xyz;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float alpha = lerp(i.heat * .5, i.heat, i.normal.y);
              float3 heatColor = GetCol(i.heat, i.normal);
              heatColor = pow(heatColor, 1.25);
              return float4(heatColor, alpha);
            }
            ENDCG
        }
    }
}
