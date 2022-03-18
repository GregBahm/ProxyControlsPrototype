Shader "Unlit/MarkerHighlightOuter"
{
    Properties
    {
      _HighColor("High Color", Color) = (1,1,1,1)
      _LowColor("High Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _HighColor;
            fixed4 _LowColor;

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
                float3 worldPosition : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = mul(unity_ObjectToWorld, -v.normal);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPosition));
              half3 normal = normalize(i.worldNormal);
              half theDot = dot(normal, viewDirection);
              float edgeShade = 1 - pow(1 - theDot, 4);
              float key = i.uv.y;
              return lerp(_LowColor, _HighColor, key) * edgeShade;
            }
            ENDCG
        }
    }
}
