Shader "Unlit/OrcaTankBottomShader"
{
    Properties
    {
      _InnerColor("Inner Color", Color) = (1,1,1,1)
      _OuterColor("Outer Color", Color) = (1,1,1,1)
      _Ramp("Ramp", Float) = 1
    }
    SubShader
    {
        LOD 100
        Blend One One
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float3 _InnerColor;
            float3 _OuterColor;
            float _Ramp;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float distToCenter = length(i.uv - .5) * 2;
              float colorRamp = pow(distToCenter, _Ramp);
              float superDist = pow(distToCenter, 50);
              superDist = saturate(1 - superDist);
              float3 col = lerp(_InnerColor, _OuterColor, colorRamp);
              col *= superDist;
              return float4(col, 1);
            }
            ENDCG
        }
    }
}
