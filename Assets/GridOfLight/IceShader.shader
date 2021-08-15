Shader "Unlit/IceShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _HighlightingTex("Highlighting Texture", 2D) = "white" {}
        _Highlighting("Highlighting", Range(0, 1)) = 0
		    _Color("Color", Color) = (1,1,1,1)

        _LightPointSize("Light Point Size", Float) = 1
        _Hydrate("Hydrate", Range(0, 10)) = 0
    }
    SubShader
    { 
        Blend SrcAlpha OneMinusSrcAlpha
        //ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 objVertex : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float hydration : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 objVertex : TEXCOORD1;
                float3 triLengths : TEXCOORD2;
                float3 triUvs : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            sampler2D _MainTex;
            sampler2D _HighlightingTex;
            float _Highlighting;
            float4 _Color;

            float _Hydrate;

            float GetHydration(float3 objPos)
            {
              float distToCenter = length(objPos.x) * 2;
              float drop = objPos.y + .5;
              return saturate(pow(1 - drop, _Hydrate) + pow(distToCenter, _Hydrate));
            }


            v2g vert (appdata v)
            {
                v2g o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2g, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = v.vertex;
                o.uv = v.uv;
                o.hydration = GetHydration(v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geo(triangle v2g p[3], inout TriangleStream<g2f> triStream)
            {
              g2f o;
              o.triLengths.x = length(p[0].vertex - p[1].vertex);
              o.triLengths.y = length(p[2].vertex - p[1].vertex);
              o.triLengths.z = length(p[0].vertex - p[2].vertex);

              float3 polyCenter = (p[0].vertex + p[1].vertex + p[2].vertex) / 3;
              float3 hydrationOffset = normalize(polyCenter);
              float maxHydrate = 1 - (_Hydrate / 10);
              hydrationOffset *= pow(p[0].hydration, 4) * .25 * maxHydrate;


              UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(p[0], o);

              o.uv = p[0].uv;
              o.objVertex = p[0].vertex;
              o.vertex = UnityObjectToClipPos(p[0].vertex + hydrationOffset);
              o.triUvs = float3(1, 0, 0);
              triStream.Append(o);

              UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(p[0], o);

              o.uv = p[1].uv;
              o.objVertex = p[1].vertex;
              o.vertex = UnityObjectToClipPos(p[1].vertex + hydrationOffset);
              o.triUvs = float3(0, 1, 0);
              triStream.Append(o);

              UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(p[0], o);

              o.uv = p[2].uv;
              o.objVertex = p[2].vertex;
              o.vertex = UnityObjectToClipPos(p[2].vertex + hydrationOffset);
              o.triUvs = float3(0, 0, 1);
              triStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
                i.triUvs *= i.triLengths;
                float outline = min(i.triUvs.x, min(i.triUvs.y, i.triUvs.z));
                outline = 1 - outline * 500;
                float shard = saturate(outline * 2) * .5;

                //return float4(outline.xxx, 1);
                float hydration = GetHydration(i.objVertex);
                hydration = saturate(pow(hydration + .4, 4) - .1);
                fixed4 baseCol = tex2D(_MainTex, i.uv);

                fixed4 highlighting = tex2D(_HighlightingTex, i.uv);
                baseCol = lerp(baseCol, highlighting, highlighting.a * _Highlighting);
                baseCol = lerp(baseCol, shard, hydration);

                float maxHydrate = (_Hydrate / 10);
                baseCol.a = 1 - hydration;
                return baseCol;
            }
            ENDCG
        }
        Pass // Points Pass
        {
            Blend One One
            ZWrite Off
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
                float4 vertex : POSITION;
                float hydration : TEXCOORD1;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float hydration : TEXCOORD1;
            };

            sampler2D _BaseTexture;
            float _LightPointSize;
            float _WaveHeight;
            float _WobbleHeight;

            float _Hydrate;

            float GetHydration(float3 objPos)
            {
              float distToCenter = length(objPos.x) * 2;
              float drop = objPos.y + .5;
              return saturate(pow(1 - drop, _Hydrate) + pow(distToCenter, _Hydrate));
            }

            float4 GetPos(v2g i, float2 uv)
            {
              float midSize = 1 - abs(i.hydration - .5) * 2;
              float2 size = _LightPointSize * midSize;
              float maxHydrate = 1 - (_Hydrate / 10);
              float fall = midSize * pow(saturate(maxHydrate), 2);
              i.vertex.z += fall * .1;
              size.x *= (fall * 10) + 1;

              float quaziRandom = (i.vertex.y * 100) % 1;
              float bounce = saturate(cos(_Time.x * 2 + quaziRandom * 100));
              bounce = pow(bounce, 100);
              bounce *= .05;
              i.vertex.z += bounce;
              i.vertex.z += 0.005;
              float3 worldPos = mul(unity_ObjectToWorld, i.vertex);
              return mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, float4(worldPos, 1)) + float4(uv.xy * size, 0, 0));
            }

            v2g vert(appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.hydration = GetHydration(v.vertex);
                return o;
            }

            [maxvertexcount(12)] // Redundantly draws some points multiple times. Can be changed to point but will miss certain verts (because we're shoving a mesh in.) Graphics.DrawProceedural() can be used to fix this, but it incurs more overhead 
            void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
            {
              g2f o;
              o.hydration = p[0].hydration;

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
              alpha = saturate(alpha);
              alpha = pow(alpha, .5);
              fixed4 ret = .25;
              return ret * alpha;
            }
            ENDCG
        }
    }
}
