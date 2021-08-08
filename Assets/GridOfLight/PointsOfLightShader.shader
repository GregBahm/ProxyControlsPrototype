Shader "Unlit/PointsOfLightShader"
{
    Properties
    {
      _Size("Size", Float) = .01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend One One
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

            Buffer<float3> _Points;

            struct v2g
            {
                float3 worldPos : TEXCOORD0;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            float _Size;
            float4x4 _Transform;

            v2g vert(uint id : SV_VertexID)
            {
                float3 vert = mul(_Transform, float4(_Points[id], 1));
                v2g o;
                o.worldPos = mul(unity_ObjectToWorld, vert);
                return o;
            }

            float4 GetPos(v2g i, float2 uv)
            {
              return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(i.worldPos, 1)) + float4(uv.xy * _Size, 0, 0));
            }

            [maxvertexcount(4)]
            void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
            {
              g2f o;
              o.uv = float2(-.5, -.5);
              o.pos = GetPos(p[0], o.uv);
              triStream.Append(o);

              o.uv = float2(-.5, .5);
              o.pos = GetPos(p[0], o.uv);
              triStream.Append(o);

              o.uv = float2(.5, -.5);
              o.pos = GetPos(p[0], o.uv);
              triStream.Append(o);

              o.uv = float2(.5, .5);
              o.pos = GetPos(p[0], o.uv);
              triStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
              float toCenter = length(i.uv);
              float alpha = 1 - toCenter * 2;
              return saturate(alpha);
            }
            ENDCG
        }
    }
}
