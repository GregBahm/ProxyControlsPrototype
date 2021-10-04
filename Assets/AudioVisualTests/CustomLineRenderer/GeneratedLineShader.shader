Shader "Unlit/LineTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UvVal("UV Val", Float) = 0.5
        _LineThickness("Thickness", Float) = 1
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

#define LINE_RESOLUTION 1024
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
            float _LineThickness;
            float _Height;

            v2g vert (uint vertId : SV_VertexID, uint lineId : SV_InstanceID)
            {
                v2g o;
                o.vertId = vertId;
                o.lineId = lineId;
                return o;
            }

            float4 GetBaseClipPos(float x, float z)
            {
                float textureSample = tex2Dlod(_MainTex, float4(x, z, 0, 0)).x;
                textureSample = sin(x * _UvVal);
                textureSample *= _Height;
                float4 worldSpacePos = float4(x - .5, textureSample, z - .5, 1);
                return UnityObjectToClipPos(worldSpacePos);
            }

            float4 GetVert(float a, float b, float2 c, float z, float thickness, bool floop)
            {

                float4 aPos = GetBaseClipPos(a, z);
                float4 bPos = GetBaseClipPos(b, z);
                float4 cPos = GetBaseClipPos(c, z);

                float2 abNorm = normalize(bPos.xy - aPos.xy);
                float2 bcNorm = normalize(cPos.xy - bPos.xy);


                float2 average = normalize((abNorm + bcNorm) * .5);

                if (average.y < 0)
                {
                  average *= -1;
                }
                //average *= floop;

                float4 finalOffset = float4(-average.y * thickness, average.x * thickness, 0, 0);
                finalOffset /= _ScreenParams;
                return bPos + finalOffset;
            }

            void DoOneSide(v2g start, inout TriangleStream<g2f> triStream, bool floop)
            {
              g2f o;

              uint vertId = start.vertId;
              float lineParam = (float)start.lineId / LINES_COUNT;

              float beforeStartPoint = ((float)vertId - 1) / LINE_RESOLUTION;
              float startPoint = ((float)vertId) / LINE_RESOLUTION;
              float endPoint = ((float)vertId + 1) / LINE_RESOLUTION;
              float afterEndPoint = ((float)vertId + 2) / LINE_RESOLUTION;

              float4 vertA = GetVert(beforeStartPoint, startPoint, endPoint, lineParam, _LineThickness, floop);
              float4 vertB = GetVert(beforeStartPoint, startPoint, endPoint, lineParam, -_LineThickness, floop);
              float4 vertC = GetVert(startPoint, endPoint, afterEndPoint, lineParam, _LineThickness, floop);
              float4 vertD = GetVert(startPoint, endPoint, afterEndPoint, lineParam, -_LineThickness, floop);


              o.vertex = vertA;
              o.uvs = float3(startPoint, 1, lineParam);
              o.height = tex2Dlod(_MainTex, float4(startPoint, lineParam, 0, 0)).x;
              triStream.Append(o);
              o.vertex = vertB;
              o.uvs = float3(startPoint, 0, lineParam);
              triStream.Append(o);
              o.vertex = vertC;
              o.uvs = float3(endPoint, 1, lineParam);
              o.height = tex2Dlod(_MainTex, float4(endPoint, lineParam, 0, 0)).x;
              triStream.Append(o);
              o.vertex = vertD;
              o.uvs = float3(endPoint, 0, lineParam);
              triStream.Append(o);
            }

            [maxvertexcount(8)]
            void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
            {
              DoOneSide(p[0], triStream, true);
              triStream.RestartStrip();
              DoOneSide(p[0], triStream, false);
            }

            fixed4 frag(g2f i) : SV_Target
            {
              return i.uvs.y;
              float col = pow(i.height, 2);
              return float4(i.uvs.x, 0, i.uvs.z, 1);
            }
            ENDCG
        }
    }
}
