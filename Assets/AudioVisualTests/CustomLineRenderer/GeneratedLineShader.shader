Shader "Unlit/LineTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UvVal("UV Val", Range(0, 1)) = 0.5
        _Thickness("Thickness", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

#define LINE_RESOLUTION 128

            struct v2g
            {
                float4 vertex : SV_POSITION;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _UvVal;
            float _Thickness;

            v2g vert (uint vertId : SV_VertexID)
            {
                float baseVertX = (float)vertId / LINE_RESOLUTION;
                float4 vertex = float4(vertId, 0, 0, 1);
                v2g o;
                o.vertex = vertex;
                return o;
            }

            float4 GetPos(float3 basePoint, float3 offset)
            {
               return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, basePoint) + float4(offset, 0));
            }

            [maxvertexcount(4)]
            void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
            {
              g2f o;
              float4 clipPos = p[0].vertex;
              o.vertex = GetPos(clipPos, float3(-_Thickness, -_Thickness, 0));
              triStream.Append(o);
              o.vertex = GetPos(clipPos, float3(-_Thickness, _Thickness, 0));
              triStream.Append(o);
              o.vertex = GetPos(clipPos, float3(_Thickness, -_Thickness, 0));
              triStream.Append(o);
              o.vertex = GetPos(clipPos, float3(_Thickness, _Thickness, 0));
              triStream.Append(o);
              
            }

            fixed4 frag (g2f i) : SV_Target
            {
              return float4(1, 0, 0, 1);
            }
            ENDCG
        }
    }
}
