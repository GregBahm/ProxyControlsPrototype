Shader "Unlit/BaitPlumeShader"
{
  Properties
  {
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float testParam : TEXCOORD1;
                float timeFactor : TEXCOORD2;
                float3 normal : NORMAL;
            };

            float _Timeline;
            float _TotalStrands;
            float _StrandThickness;

            inline float3 ProjectOnPlane(float3 vec, float3 normal)
            {
              return vec - normal * dot(vec, normal);
            }

            float3 GetTimeFactor(float param, uint instanceID)
            {
                float strandsParam = (float)instanceID / _TotalStrands;
                return strandsParam * .5 + param * .5;
            }

            float3 GetStrokeTangent(float3 basePoint, float3 strokeBeginning, float3 strokeEnd, float3 param)
            {
                basePoint = float3(basePoint.x, basePoint.y, 0);
                float3 newNormal = normalize(strokeEnd - strokeBeginning);
                float thickness = (1 - param) * _StrandThickness;
                return ProjectOnPlane(basePoint, newNormal) * _StrandThickness;
            }

            v2f vert(vertexInput v, uint instanceID : SV_InstanceID)
            {
                int startIndex = instanceID * POINTS_PER_STRAND;

                float param = v.vertex.z;
                float scaledParam = param * (POINTS_PER_STRAND - 1);
                int flooredParam = floor(scaledParam);
                int ceilParam = ceil(scaledParam);
                float3 beginning = _PlumeStrands[startIndex + flooredParam];
                float3 end = _PlumeStrands[startIndex + ceilParam];
                float modParam = scaledParam % 1;

                float3 strokeCenter = lerp(beginning, end, modParam);
                
                float3 strokeTangent = GetStrokeTangent(v.vertex, beginning, end, param);

                v.vertex = float4(strokeCenter + strokeTangent, 1);

                v2f o; 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.testParam = param;
                o.timeFactor = GetTimeFactor(param, instanceID);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                clip(_Timeline - i.timeFactor);
                float3 norm = i.normal * .5 + .5;
                float3 lerpColor = lerp(float3(3, 1, 1) * .5, float3(.1, .3, .5), pow(i.testParam, .5));
                norm = lerp(norm, lerpColor, .5);
                norm = pow(norm, 2);
                return float4(norm, 1);
            }
            ENDCG
        }
  }
}
