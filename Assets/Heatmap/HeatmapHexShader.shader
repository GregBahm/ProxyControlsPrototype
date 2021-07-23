Shader "Unlit/HeatmapHexShader"
{
    Properties
    {
      _HeatLut("Heat Lut", 2D) = "white" {} 
      _HexAlpha("Hex Alpha", 2D) = "white" {}
      _HeatFalloff("Dispersion Distance", Float) = 1
      _HeatIntensity("Heat Intensity", Float) = 1
      _HeatHeight("Heat Height", Float) = 1
      _HeatSaturation("Heat Saturation", Float) = 1
      _Opacity("Opacity", Float) = 1
      _MaxSigma("Falloff Speed", Float) = 5
      _MaxHeat("Heat Softcap", Float) = 20
      [MaterialToggle] _UseHexShading("Use Hex Shading", Float) = 0
      [MaterialToggle] _UseHeatSoftcap("Use Heat Softcap", Float) = 0
    }
    SubShader
    {
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #define HEAT_POINTS 16
            #define PI 3.14159

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"

            struct HeatData
            {
              float2 position;
              float dispersion;
            };

            StructuredBuffer<HeatData> _HeatDataBuffer;
            StructuredBuffer<float2> _UvsBuffer;
            float _BoxWidth;
            float _BoxDepth;
            float _HeatFalloff;
            float _HeatHeight;
            float _HeatIntensity;
            float _HeatSaturation;
            float _Opacity;
            float _MaxSigma;
            float _MaxHeat;
            float _UseHexShading;
            float _UseHeatSoftcap;

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
            sampler2D _HexAlpha;
            float4x4 _MasterTransform;
            float _Margin;


            float HeatExponent(float dist, float sigma)
            {
                dist = _HeatFalloff * dist;
                return -.5 * pow(dist / sigma, 2);
            }
                
            float AccumulateHeat(float2 uvs, float2 heatPosition, float radiusSize)
            {
                float sigma = radiusSize / _MaxSigma; // this calculates the "variable std dev"
                float dist = length(uvs - heatPosition);
                float centerGratuity = _BoxWidth / sqrt(3);
                dist *= step(centerGratuity, dist); // uv of center hex isnt exactly the center of the data; we fudge it here
                float expVal = HeatExponent(dist, sigma);
                float ret = exp(expVal) / (2 * PI * sigma * sigma); // get the value on the bell curve
                float hexToSquareRatio = 3 * sqrt(3) / 8; // ratio of area taken up by the inscribed hexagon to total area
                ret *= min(1, PI * pow(radiusSize, 2) / (hexToSquareRatio * _BoxWidth * _BoxDepth)); // center now doesnt look insane b/c we mitigate it
                ret = _UseHeatSoftcap == 0 ? ret : min(_MaxHeat, ret) + sqrt(max(1, ret - _MaxHeat)); // implement some kind of softcap
                ret *= 1 - step(radiusSize, dist); // cutoff everything past the max distance
                return max(ret, 0);
            }

            float GetHeat(float2 uvs)
            {
                float heat = 0;
                for (uint i = 0; i < HEAT_POINTS; i++)
                {
                  HeatData heatPoint = _HeatDataBuffer[i];
                  heat += AccumulateHeat(uvs, heatPoint.position, heatPoint.dispersion);
                }
                return heat;
            }

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
#ifdef HMD
              uint bufferId = floor((float)instanceID / 2); // To account for the stereo rendering on the hololens. Also need to 2X the number of instances
              float2 masterUvs = _UvsBuffer[bufferId];
#else
              float2 masterUvs = _UvsBuffer[instanceID];
#endif

                float heat = GetHeat(masterUvs);

                float3 newVert = v.vertex;
                newVert.x *= _BoxWidth;
                newVert.x += masterUvs.x - .5;
                newVert.z *= _BoxDepth * 1.15f; 
                newVert.z += masterUvs.y - .5;
                newVert.y += .5;
                newVert.y *= pow(heat, .67) * sign(heat) * _HeatHeight;
                newVert.y -= .5;

                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 worldPos = mul(_MasterTransform, float4(newVert, 1));
                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = v.uv;
                o.heat = heat;
                o.objSpace = v.vertex;
                o.normal = v.normal;
                return o;
            }

            float3 GetCol(float heat, float3 normal, float3 objSpace)
            {
                float lutUv = saturate(pow(.25, 1 / heat) * _HeatIntensity); // Maps 0..1, to .9 @ ~13, .75 @ ~5, .5 @ 2, .25 @ 1, .1 @ ~.6, .05 @ ~.45, .01 @ ~.3
                lutUv -= _UseHexShading == 0 ? 0 : normal.x * .1;
                float3 ret = tex2D(_HeatLut, float2(lutUv, 0)).xyz;
                ret = _UseHexShading == 0 ? ret : lerp(pow(ret, 2) * .75, ret, normal.y);
                ret = lerp(ret, float3(1, 1, 1), (1 - _HeatSaturation));
                return ret;
            }

            float GetAlpha(v2f i)
            {
              //i.heat *= pow(i.objSpace.y + .5, 10) * .1 + 1;
              float3 alphaFromTex = tex2D(_HexAlpha, i.uv);
              float alpha = saturate(pow(.25, 1 / i.heat) * _Opacity) * pow(alphaFromTex.x, 2);
              return alpha;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float alpha = GetAlpha(i);
              float3 heatColor = GetCol(i.heat, i.normal, i.objSpace);
              return float4(heatColor, alpha);
            }
            ENDCG
        }
    }
}
