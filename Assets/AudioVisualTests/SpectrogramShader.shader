Shader "Unlit/SpectrogramShader"
{
    Properties
    {
        _ColorA("Color A", Color) = (1,1,1,1)
        _ColorB("Color B", Color) = (1,1,1,1)
        _ColorC("Color C", Color) = (1,1,1,1)
        _ColorD("Color D", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Height ("Height", Float) = 1
        _SphereSize("Sphere Size", Float) = 1
    }
    SubShader
    {
        //Blend SrcAlpha OneMinusSrcAlpha
        //Tags { "Queue" = "Transparent" }
        //Cull Off
        //ZWrite Off

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
                float3 normal : NORMAL;
                float3 basePos : TEXCOORD1;
                float3 newPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height;
            fixed3 _ColorA;
            fixed3 _ColorB;
            fixed3 _ColorC;
            fixed4 _ColorD;
            float _SphereSize;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float2 transformedUvs = TRANSFORM_TEX(v.uv, _MainTex);
                fixed val = tex2Dlod(_MainTex, float4(transformedUvs, 0, 1)).x;

                o.basePos = v.vertex;
                v.vertex *= _SphereSize;
                v.vertex.xyz += v.normal * val * _Height;
                o.newPos = v.vertex.xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float heightVal = length(i.newPos);
                return heightVal;
                float depth = heightVal;
                depth = depth * 0.005 + .5;
                depth = 1 - pow(1 - depth, 2);
                float3 mainColor = lerp(_ColorA, _ColorB, depth);
                mainColor = lerp(_ColorC, mainColor,  heightVal);
                mainColor *= pow(heightVal, heightVal);
                mainColor = saturate(mainColor);
                return float4(mainColor, 1);
            }
            ENDCG
        }
    }
}
