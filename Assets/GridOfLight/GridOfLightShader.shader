Shader "Unlit/GridOfLightShader"
{
    Properties
    {
      _LinesColor("Lines Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass // Lines
        { 
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2g
            {
                float3 vertex : TEXCOORD0;
                float4 pos : POSITION;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            fixed4 _LinesColor;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.vertex = v.vertex;
                return o;
            }

            [maxvertexcount(3)]
            void geo(triangle v2g p[3], inout TriangleStream<g2f> triStream)
            {
              g2f o;

              float ab = length(p[0].vertex - p[1].vertex);
              float bc = length(p[1].vertex - p[2].vertex);
              float ac = length(p[0].vertex - p[2].vertex);

              float2 bcUv; // 0
              float2 acUv; // 1
              float2 abUv; // 2

              if (ab > bc)
              {
                if (ab > ac)
                {
                  // ab is longest
                  abUv = 1;
                  bcUv = float2(1, 0);
                  acUv = float2(0, 1);
                }
                else
                {
                  if (bc > ac)
                  {
                    bcUv = 1;
                    abUv = float2(1, 0);
                    acUv = float2(0, 1);
                  }
                  else
                  {
                    acUv = 1;
                    abUv = float2(1, 0);
                    bcUv = float2(0, 1);
                  }
                }
              }
              else
              {
                if (bc > ac)
                {
                  bcUv = 1;
                  abUv = float2(1, 0);
                  acUv = float2(0, 1);
                }
                else
                {
                  acUv = 1;
                  abUv = float2(0, 1);
                  bcUv = float2(1, 0);
                }
              }

              o.uv = bcUv;
              o.pos = p[0].pos;
              triStream.Append(o);
              o.uv = acUv;
              o.pos = p[1].pos;
              triStream.Append(o);
              o.uv = abUv;
              o.pos = p[2].pos;
              triStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
              float val = max(i.uv.x, i.uv.y);
              val = (val - .5) * 2;
              val = pow(val, 10);
              return val * _LinesColor;
            }
            ENDCG
        }
    }
}
