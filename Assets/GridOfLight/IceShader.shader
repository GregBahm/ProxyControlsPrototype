Shader "Unlit/IceShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _HighlightingTex("Highlighting Texture", 2D) = "white" {}
        _Highlighting("Highlighting", Range(0, 1)) = 0
		_Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

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
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD3;
                half3 worldView : TEXCOORD4;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            sampler2D _MainTex;
            sampler2D _HighlightingTex;
            float _Highlighting;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldView = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.worldView = normalize(i.worldView);
                i.worldNormal = normalize(i.worldNormal);
                
                float theDot = dot(i.worldView, i.worldNormal);
                
                float backDot = 1 - pow(theDot, 10);
                fixed4 baseCol = tex2D(_MainTex, i.uv);
                float4 opposing = pow(baseCol, 10);
                float4 backCol = lerp(baseCol, opposing, backDot);

                float4 frontCol = baseCol * pow(theDot, .5);
                float4 ret = backCol * 0 + frontCol * 1;
                ret = lerp(ret, baseCol, .5);

                fixed4 highlighting = tex2D(_HighlightingTex, i.uv);
                baseCol = lerp(baseCol, highlighting, highlighting.a * _Highlighting);

                return baseCol * _Color;
            }
            ENDCG
        }
    }
}
