Shader "Unlit/BufferlessPointsOfLightShader"
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

            struct appdata {
              float4 vertex : POSITION;
              float2 uv : TEXCOORD0;
              float3 normal : NORMAL;
            };

            struct v2g
            {
                float3 worldPos : TEXCOORD0;
                fixed4 color : TEXCOORD1; 
                float4 vertex : POSITION;
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

            v2g vert(appdata v)
            {
                float offset = cos(_Time.w + v.vertex.z * 5) + 1 ;
                offset *= .005;
                v.vertex.y += offset;
                v2g o;

                fixed4 textureColor = tex2Dlod(_Texture, float4(v.uv, 0, 0)) * .3;
                float upVal = pow(v.normal.y, .5);
                textureColor = lerp(float4(.1, .1, .1, 1), textureColor, saturate(upVal));

                float3 viewDir = ObjSpaceViewDir(v.vertex);
                float shine = dot(normalize(viewDir), v.normal);
                shine = saturate(shine);
                shine = pow(shine, 10);

                o.color = textureColor;
                float2 rims = abs(v.vertex.xz);
                float rim = max(rims.x, rims.y);
                rim = pow(rim, 10);
                o.color += saturate(rim * 200);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = v.vertex;
                return o;
            }

            float4 GetPos(v2g i, float2 uv)
            {
              float2 size = _Size;
              float flux = cos(_Time.y + i.vertex.z * 2);
              flux = saturate(flux);
              flux = pow(flux, 50);
              float bump = flux * 10;
              size.y *= 1 + bump;
              i.worldPos.y += bump * .005;
              return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(i.worldPos, 1)) + float4(uv.xy * size, 0, 0));
            }

            void DoPoint(v2g p, inout TriangleStream<g2f> triStream)
            {
                g2f o;
                o.color = p.color;
                o.uv = float2(-.5, -.5);
                o.pos = GetPos(p, o.uv);
                triStream.Append(o);

                o.uv = float2(-.5, .5);
                o.pos = GetPos(p, o.uv);
                triStream.Append(o);

                o.uv = float2(.5, -.5);
                o.pos = GetPos(p, o.uv);
                triStream.Append(o);

                o.uv = float2(.5, .5);
                o.pos = GetPos(p, o.uv);
                triStream.Append(o);
                triStream.RestartStrip();
            }

            [maxvertexcount(12)]
            void geo(triangle v2g p[3], inout TriangleStream<g2f> triStream)
            {
              g2f o;
              DoPoint(p[0], triStream);
              DoPoint(p[1], triStream);
              DoPoint(p[2], triStream);
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
