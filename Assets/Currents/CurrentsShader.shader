Shader "Unlit/CurrentsShader"
{
  Properties
  {
        _Lut("Lut", 2D) = "white" {}
  }
    SubShader
  {
      Tags { "RenderType" = "Opaque" }
      LOD 100

      Pass
      {
          Cull Off

          CGPROGRAM

          #pragma vertex vert
          #pragma fragment frag
          #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

          #include "UnityCG.cginc"

#define POINTS_PER_STRAND 16

            StructuredBuffer<float3> _PlumeStrands;

            struct vertexInput
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
                float thickness : TEXCOORD1;
                float lengthVal : TEXCOORD1;
                float3 normal : NORMAL;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4x4 masterTransform;

            float _Timeline;
            float _TotalStrands;
            float _StrandThickness;
            sampler2D _Lut;


            float4x4 GetLookMatrix(float3 forward)
            {
              float3 xAxis = cross(forward, float3(0, 1, 0));
              float3 yAxis = cross(forward, xAxis);

              return float4x4(
                xAxis.x, yAxis.x, forward.x, 0,
                xAxis.y, yAxis.y, forward.y, 0,
                xAxis.z, yAxis.z, forward.z, 0,
                0, 0, 0, 1
                );
            }

            float4 GetRenormalized(float3 vertex, float3 newForward)
            {
              float4x4 lookMatrix = GetLookMatrix(newForward);
              return mul(lookMatrix, vertex);
            }

            float GetThickness(float param, uint instanceID)
            {
              float strandsParam = (float)instanceID / _TotalStrands;

              float time = _Time.x * 10 + strandsParam * 20;
              time %= 1;
              time = time * 2 - 1;

              float strandsAlpha = 1 - saturate(abs(strandsParam - .5 - time) * 2);

              float mainAlpha = 1 - saturate(abs(param - .5 - time) * 2);
              float endAlpha = 1 - saturate(abs(param - .5) * 2);
              mainAlpha *= endAlpha;
              mainAlpha *= strandsAlpha;
              return mainAlpha;
            }

            float3 GetStrokeTangent(float3 basePoint, float3 strokeBeginning, float3 strokeEnd, float param)
            {
                basePoint = float3(basePoint.x, basePoint.y, 0);
                float3 newForward = normalize(strokeEnd - strokeBeginning);

                return GetRenormalized(basePoint, newForward);
            }

            v2f vert(vertexInput v, uint instanceID : SV_InstanceID)
            {
                int startIndex = instanceID * POINTS_PER_STRAND;

                float param = v.vertex.z;
                float scaledParam = param * (POINTS_PER_STRAND - 1);
                int flooredParam = floor(scaledParam);
                int ceilParam = flooredParam + 1;
                float3 beginning = _PlumeStrands[startIndex + flooredParam];
                float3 end = _PlumeStrands[startIndex + ceilParam];
                float modParam = scaledParam % 1;

                float thickness = GetThickness(param, instanceID);

                float3 strokeCenter = lerp(beginning, end, modParam);
                
                float3 strokeTangent = GetStrokeTangent(v.vertex, beginning, end, param);

                float3 newPos = strokeCenter + strokeTangent * thickness * _StrandThickness;
                v.vertex = float4(newPos, 1);

                float4 worldPos = mul(masterTransform, float4(newPos, 1));

                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos));
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.thickness = thickness;
                o.normal = v.normal;
                o.lengthVal = param;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              fixed4 lut = tex2D(_Lut, float2(pow(i.thickness, .5), 0));
              return lut;
                float3 norm = i.normal * .5 + .5;
                float3 lerpColor = lerp(float3(3, 1, 1) * .5, float3(.2, .4, 2), pow(i.thickness, .5));
                float shade = 1 - norm.y * .5;
                float3 col = lerpColor;
                //col *= shade;
                //norm = lerp(norm, lerpColor, .6);
                //col = pow(col, 2);
                return float4(col, 1);
            }
            ENDCG
        }
  }
}
