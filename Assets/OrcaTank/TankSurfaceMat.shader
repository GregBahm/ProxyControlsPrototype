Shader "Unlit/TankSurfaceMat"
{
    Properties
    {
        _LitColor("Lit Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,1)
        _AreaLightEffect("Area Light Effect", Range(0, 1)) = 0
        _MainTex("Texture", 2D) = "black" {}
        _Overbright("Overbright", Float) = 0
        _OutlineThickness("Outline Thickness", Float) = 0
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _OutlineOverbright("Outline Overbright", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass // Core Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
            };

            float3 _LitColor;
            float3 _ShadowColor;
            float _AreaLightEffect;
            sampler2D _MainTex;
            float _Overbright;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float4 tex = tex2D(_MainTex, i.uv);
              float shade = (dot(_WorldSpaceLightPos0, normalize(i.worldNormal)));

              float areaLightMultiple = lerp(1, .5, _AreaLightEffect);
              float areaLightOffset = .5 * _AreaLightEffect;
              shade = (shade * areaLightMultiple) + areaLightOffset;
              shade = saturate(shade);
              shade = 1 - pow(1 - shade, 5);
              float3 col = lerp(_ShadowColor, _LitColor, shade);
              col += tex.rgb * .5;
              return float4(col, 1) * (1 + _Overbright);
            }
            ENDCG
        }

        Pass // Outline Pass
        {

            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
            };

            float _OutlineThickness;
            float4 _OutlineColor;
            float _OutlineOverbright;

            v2f vert(appdata v)
            {
                v2f o;
                float3 extrudedVert = v.vertex + v.normal * _OutlineThickness;
                o.vertex = UnityObjectToClipPos(float4(extrudedVert, v.vertex.w));
                o.uv = v.uv;
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              return _OutlineColor * (1 + _OutlineOverbright);
            }
            ENDCG
        }
    }
}
