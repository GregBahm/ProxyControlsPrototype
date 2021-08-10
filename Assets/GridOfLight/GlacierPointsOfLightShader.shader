Shader "Unlit/GlacierPointsOfLightShader"
{
    Properties
    {
      _Size("Size", Float) = .01
      _Texture("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend OneMinusDstColor  One
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct DataPoint
            {
                float3 position;
                float2 uvs;
            };

            StructuredBuffer<DataPoint> _Points;

            struct v2g
            {
                float3 worldPos : TEXCOORD0;
                fixed4 color : TEXCOORD1;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                fixed4 color : TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            sampler2D _Texture;
            float _Size;
            float4x4 _Transform;

            v2g vert(uint id : SV_VertexID)
            {
                DataPoint baseVert = _Points[id];
                float3 basePos = baseVert.position;
                float offset = cos(_Time.w + basePos.z * 5) + 1 ;
                offset *= .005;
                basePos.y += offset;
                float3 vert = mul(_Transform, float4(basePos, 1));
                v2g o;
                o.color = tex2Dlod(_Texture, float4(baseVert.uvs, 0, 0));
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
              o.color = p[0].color;
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
              clip(alpha);
              return i.color;
              alpha = saturate(alpha);
              alpha = pow(alpha, .5);
              return alpha * i.color;
            }
            ENDCG
        }
    }
}
