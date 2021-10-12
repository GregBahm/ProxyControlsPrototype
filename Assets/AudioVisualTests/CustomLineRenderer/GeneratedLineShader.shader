Shader "Unlit/LineTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UvVal("UV Val", Float) = 0.5
        _Softness("Softness", Range(0, 10)) = 0
        _Thickness("Thickness", Float) = 1
        _Height("Height", Float) = 1
        _HeightOffset("Height Offset", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Pass // Tube Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

#define LINE_RESOLUTION 512
#define LINES_COUNT 8

            struct v2g
            {
                uint vertId : TEXCOORD0;
                uint lineId : TEXCOORD1;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float3 uvs : TEXCOORD0;
            };

            sampler2D _MainTex;
            float _Softness;
            float _Thickness;
            float _Height;
            float _HeightOffset;
            float4x4 _Transform;

            v2g vert(uint vertId : SV_VertexID, uint lineId : SV_InstanceID)
            {
                v2g o;
                o.vertId = vertId;
                o.lineId = lineId;
                return o;
            }

            float3 GetWorldPos(float x, float textureSample, float z)
            {
              textureSample *= _Height;
              textureSample += _HeightOffset;
              return float3(x - .5, textureSample, z - .5);
          }

          float4 GetClipPos(float3 worldPos, float2 offset)
          {
              return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(worldPos, 1)) + float4(offset, 0, 0));
          }

          float3 GetNormal(float3 prevWorldPos, float3 currentWorldPos, float3 nextWorldPos)
          {
            float3 prevNorm = normalize(prevWorldPos - currentWorldPos);
            float3 nextNorm = normalize(currentWorldPos - nextWorldPos);
            return normalize((prevNorm + nextNorm) * .5);
          }

          float4 GetFinalPosition(float3 objPos)
          {
            float3 transformedPos = mul(_Transform, float4(objPos, 1));
            return UnityObjectToClipPos(transformedPos);
          }

          [maxvertexcount(10)]
          void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
          {
            uint vertId = p[0].vertId;
            float lineParam = (float)p[0].lineId / LINES_COUNT;

            float prevPoint = ((float)vertId - 1) / LINE_RESOLUTION;
            float startPoint = ((float)vertId) / LINE_RESOLUTION;
            float endPoint = ((float)vertId + 1) / LINE_RESOLUTION;
            float futurePoint = ((float)vertId + 2) / LINE_RESOLUTION;

            float prevSample = tex2Dlod(_MainTex, float4(prevPoint, lineParam, 0, _Softness)).x;
            float startSample = tex2Dlod(_MainTex, float4(startPoint, lineParam, 0, _Softness)).x;
            float endSample = tex2Dlod(_MainTex, float4(endPoint, lineParam, 0, _Softness)).x;
            float futureSample = tex2Dlod(_MainTex, float4(futurePoint, lineParam, 0, _Softness)).x;

            float3 prevWorldPos = GetWorldPos(prevPoint, prevSample, lineParam);
            float3 startWorldPos = GetWorldPos(startPoint, startSample, lineParam);
            float3 endWorldPos = GetWorldPos(endPoint, endSample, lineParam);
            float3 futureWorldPos = GetWorldPos(futurePoint, futureSample, lineParam);

            float3 startNormal = GetNormal(prevWorldPos, startWorldPos, endWorldPos);
            float3 startBinormal = normalize(cross(startNormal, float3(0, 1, 0)));
            float3 startTangent = normalize(cross(startNormal, startBinormal));

            float3 endNormal = GetNormal(startWorldPos, endWorldPos, futureWorldPos);
            float3 endBinormal = normalize(cross(endNormal, float3(0, 1, 0)));
            float3 endTangent = normalize(cross(endNormal, endBinormal));

            float3 startA = startWorldPos + (startBinormal + startTangent) * _Thickness;
            float3 startB = startWorldPos + (startBinormal - startTangent) * _Thickness;
            float3 startC = startWorldPos + (-startBinormal - startTangent) * _Thickness;
            float3 startD = startWorldPos + (-startBinormal + startTangent) * _Thickness;

            float3 endA = endWorldPos + (endBinormal + endTangent) * _Thickness;
            float3 endB = endWorldPos + (endBinormal - endTangent) * _Thickness;
            float3 endC = endWorldPos + (-endBinormal - endTangent) * _Thickness;
            float3 endD = endWorldPos + (-endBinormal + endTangent) * _Thickness;

            float3 startUvs = float3(startPoint, lineParam, startSample);
            float3 endUvs = float3(endPoint, lineParam, endSample);

            g2f o;
            o.vertex = GetFinalPosition(startA);
            o.uvs = startUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(endA);
            o.uvs = endUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(startB);
            o.uvs = startUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(endB);
            o.uvs = endUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(startC);
            o.uvs = startUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(endC);
            o.uvs = endUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(startD);
            o.uvs = startUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(endD);
            o.uvs = endUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(startA);
            o.uvs = startUvs;
            triStream.Append(o);

            o.vertex = GetFinalPosition(endA);
            o.uvs = endUvs;
            triStream.Append(o);
          }

          fixed4 frag(g2f i) : SV_Target
          {
            return 1;
            return float4(i.uvs, 1);
          }
          ENDCG
      }
      Pass // Sheet Pass
      {
        Blend OneMinusDstColor One
        ZWrite Off
          CGPROGRAM
          #pragma vertex vert
          #pragma geometry geo
          #pragma fragment frag

          #include "UnityCG.cginc"

#define LINE_RESOLUTION 512
#define LINES_COUNT 8

            struct v2g
            {
                uint vertId : TEXCOORD0;
                uint lineId : TEXCOORD1;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float3 uvs : TEXCOORD0;
            };

            sampler2D _MainTex;
            float _Softness;
            float _Thickness;
            float _Height;
            float _HeightOffset;
            float4x4 _Transform;

            v2g vert(uint vertId : SV_VertexID, uint lineId : SV_InstanceID)
            {
                v2g o;
                o.vertId = vertId;
                o.lineId = lineId;
                return o;
            }

            float3 GetWorldPos(float x, float textureSample, float z)
            {
              textureSample *= _Height;
              textureSample += _HeightOffset;
              return float3(x - .5, textureSample, z - .5);
          }

          float4 GetClipPos(float3 worldPos, float2 offset)
          {
              return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(worldPos, 1)) + float4(offset, 0, 0));
          }

          float3 GetNormal(float3 prevWorldPos, float3 currentWorldPos, float3 nextWorldPos)
          {
            float3 prevNorm = normalize(prevWorldPos - currentWorldPos);
            float3 nextNorm = normalize(currentWorldPos - nextWorldPos);
            return normalize((prevNorm + nextNorm) * .5);
          }

          float4 GetFinalPosition(float3 objPos)
          {
            float3 transformedPos = mul(_Transform, float4(objPos, 1));
            return UnityObjectToClipPos(transformedPos);
          }

          [maxvertexcount(4)]
          void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
          {
            uint vertId = p[0].vertId;
            float lineParam = (float)p[0].lineId / LINES_COUNT;

            float startPoint = ((float)vertId) / LINE_RESOLUTION;
            float endPoint = ((float)vertId + 1) / LINE_RESOLUTION;

            float startSample = tex2Dlod(_MainTex, float4(startPoint, lineParam, 0, _Softness)).x;
            float endSample = tex2Dlod(_MainTex, float4(endPoint, lineParam, 0, _Softness)).x;

            float3 startWorldPos = GetWorldPos(startPoint, startSample, lineParam);
            float3 endWorldPos = GetWorldPos(endPoint, endSample, lineParam);
            float3 startBottomPos = startWorldPos;
            float3 endBottomPos = endWorldPos;
            startBottomPos.y = 0;
            endBottomPos.y = 0;

            g2f o;
            o.vertex = GetFinalPosition(startWorldPos);
            o.uvs = float3(startPoint, lineParam, startSample);
            triStream.Append(o);

            o.vertex = GetFinalPosition(endWorldPos);
            o.uvs = float3(endPoint, lineParam, endSample);
            triStream.Append(o);

            o.vertex = GetFinalPosition(startBottomPos);
            o.uvs = float3(startPoint, lineParam, 0);
            triStream.Append(o);

            o.vertex = GetFinalPosition(endBottomPos);
            o.uvs = float3(endPoint, lineParam, 0);
            triStream.Append(o);

          }

          fixed4 frag(g2f i) : SV_Target
          {
            float val = i.uvs.z;
            return float4(1 - i.uvs.y, val, i.uvs.y, 1) * .2;
          }
          ENDCG
      }
    }
}
