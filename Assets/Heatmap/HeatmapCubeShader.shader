Shader "Unlit/HeatmapCubeShader"
{
    Properties
    {
      _HeatSourceA("Heat Source A", 2D) = "white" {}
      _HeatSourceB("Heat Source B", 2D) = "white" {}
      _HeatLut("Heat Lut", 2D) = "white" {}
      _Margin("Margin", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"

            StructuredBuffer<float2> _UvsBuffer;
            float _BoxWidth;
            float _BoxDepth;

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

            sampler2D _HeatSourceA;
            sampler2D _HeatSourceB;
            float4 _HeatSourceB_ST;
            sampler2D _HeatLut;
            fixed4 _Color;
            float4x4 _MasterTransform;
            float _Margin;

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                float2 masterUvs = _UvsBuffer[instanceID];
                float2 heatBUvs = TRANSFORM_TEX(masterUvs, _HeatSourceB);

                fixed heatA = tex2Dlod(_HeatSourceA, float4(masterUvs, 0, 0)) * (_CosTime.w + .5);
                fixed heatB = tex2Dlod(_HeatSourceB, float4(heatBUvs, 0, 0)) * (cos(_Time.w * 1.3) + 1);
                float heat = (heatA + heatB) * .5;

                float3 newVert = v.vertex;
                newVert.x *= _BoxWidth * _Margin;
                newVert.x += masterUvs.x - .5;
                newVert.z *= _BoxDepth * _Margin;
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
              return float4(ret, 1);
            }
            ENDCG
        }
    }
}
