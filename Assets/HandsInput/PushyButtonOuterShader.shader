Shader "Unlit/PushyButtonOuterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
      SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {

            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.viewDir = ObjSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float theDot = dot(i.normal, normalize(i.viewDir));
                float rim = 1 - theDot;
                rim = rim * 2 - 1.2;
                rim *= pow(theDot, 2);
                rim = saturate(rim);
                rim *= 100;
                return _Color * rim;
            }
            ENDCG
        }
    }
}
