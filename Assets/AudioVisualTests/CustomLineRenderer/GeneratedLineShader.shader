Shader "Unlit/LineTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UvVal("UV Val", Float) = 0.5
        _DebugVal("Debug Val", Float) = 0.5
        _Thickness("Thickness", Float) = 1
        _Height("Height", Float) = 1
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

#define LINE_RESOLUTION 64
#define LINES_COUNT 32

            struct v2g
            {
                uint vertId : TEXCOORD0;
                uint lineId : TEXCOORD1;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float3 uvs : TEXCOORD0;
                float height : TEXCOORD1;
            };

            sampler2D _MainTex;
            float _UvVal;
            float _Thickness;
            float _Height;
            float _DebugVal;

            v2g vert (uint vertId : SV_VertexID, uint lineId : SV_InstanceID)
            {
                v2g o;
                o.vertId = vertId;
                o.lineId = lineId;
                return o;
            }

            float3 GetWorldPos(float x, float z)
            {
                float textureSample = tex2Dlod(_MainTex, float4(x, z, 0, 0)).x;
                textureSample = sin(x * _UvVal);
                textureSample *= _Height;
                return float3(x - .5, textureSample, z - .5);
            }

            float4 GetClipPos(float3 worldPos, float2 offset)
            {
                return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(worldPos, 1)) + float4(offset, 0, 0));
            }

            [maxvertexcount(4)]
            void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
            {
              g2f o;

              uint vertId = p[0].vertId;
              float lineParam = (float)p[0].lineId / LINES_COUNT;

              float startPoint = ((float)vertId) / LINE_RESOLUTION;
              float endPoint = ((float)vertId + 1) / LINE_RESOLUTION;

              float3 startWorldPos = GetWorldPos(startPoint, lineParam);
              float3 endWorldPos = GetWorldPos(endPoint, lineParam);

              float3 startViewPos = UnityObjectToViewPos(startWorldPos);
              float3 endViewPos = UnityObjectToViewPos(endWorldPos);

              float2 lineNorm = normalize(startViewPos.xy - endViewPos.xy);
              float2 lineOffset = float2(-lineNorm.y * _Thickness, lineNorm.x * _Thickness);// / _ScreenParams;

              float4 vertA = GetClipPos(startWorldPos, lineOffset);
              float4 vertB = GetClipPos(startWorldPos, -lineOffset);
              float4 vertC = GetClipPos(endWorldPos, lineOffset);
              float4 vertD = GetClipPos(endWorldPos, -lineOffset);

              o.vertex = vertA;
              o.uvs = 0;// float3(startPoint, 1, lineParam);
              o.height = tex2Dlod(_MainTex, float4(startPoint, lineParam, 0, 0)).x;
              triStream.Append(o);
              o.vertex = vertB;
              o.uvs = float3(1, 0, 0);// float3(startPoint, 0, lineParam);
              triStream.Append(o);
              o.vertex = vertC;
              o.uvs = float3(0, 1, 0); float3(endPoint, 1, lineParam);
              o.height = tex2Dlod(_MainTex, float4(endPoint, lineParam, 0, 0)).x;
              triStream.Append(o);
              o.vertex = vertD;
              o.uvs = float3(0, 0, 1);// float3(endPoint, 0, lineParam);
              triStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
              return float4(i.uvs, 1);
              return i.uvs.y;
              float col = pow(i.height, 2);
              return float4(i.uvs.x, 0, i.uvs.z, 1);
            }
            ENDCG
        }
    }
}
