Shader "Unlit/GlintExample"
{
    Properties
    {
      _BaseColor("Base Color", Color) = (0, 0, 0, 1)
      _GlintColor("Glint Color", Color) = (1, 1, 1, 1)
      _GlintFrequence("Glint Frequency", Float) = 1
      _GlintSpeed("Glint Speed", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                float3 worldPos : TEXCOORD0;
            };

            float4 _BaseColor;
            float4 _GlintColor;
            float _GlintFrequence;
            float _GlintSpeed;

            float GetGlint(float3 worldPos)
            {
                float wave = _Time.z * _GlintSpeed + worldPos.x + worldPos.y;
                wave %= _GlintFrequence;
                wave = abs(wave - _GlintFrequence * .5);
                return wave;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 ret = _BaseColor;
                float glint = GetGlint(i.worldPos);
                ret = lerp(ret, _GlintColor, glint);
                return ret;
            }
            ENDCG
        }
    }
}
