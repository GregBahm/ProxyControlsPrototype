Shader "SkirtExample/SphereShader"
{
    Properties
    {
    }
    SubShader
    {
        Pass
        {
            ColorMask 0
            Tags { "RenderType" = "Opaque" "Queue" = "Geometry+1"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            { 
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              return 0;
            }
            ENDCG
        }
        Pass
        {
        Tags { "RenderType" = "Opaque"}
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
                float3 worldPos : TEXCOORD1;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float3 extents = -abs(i.worldPos) + .5;
              float boxExtent = min(extents.x, min(extents.y, extents.z));
              clip(boxExtent);
              return float4(i.normal, 1);
            }
            ENDCG
        }
    }
}
