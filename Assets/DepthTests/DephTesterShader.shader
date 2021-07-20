Shader "Unlit/DephTesterShader"
{
    Properties
    {
    }
    SubShader
    {
            Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZTest Always
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
                float3 viewDir : VIEWDIR;
                float4 objSpace : TEXCOORD2;
                float3 rayBack : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.objSpace = v.vertex; // v.vertex.xyz - o.ray_d;
                o.uv = v.uv;
                return o;
            }

#define STEPS 10

            fixed4 frag(v2f i) : SV_Target
            {
                    float2 screenCoords = i.screenPosition.xy / i.screenPosition.w;
                    float sceneDepth = tex2D(_CameraDepthTexture, screenCoords).x;

                    float retAlpha = 0;
                    float3 sampleOrigin = i.objSpace.xyz;
                    float3 rayDir = -normalize(i.viewDir) / STEPS;
                    float val = 1.0 / STEPS;

                    [unroll(STEPS)]
                    for (int i = 0; i < STEPS; i++)
                    {
                      float3 samplePos = sampleOrigin +rayDir * i;
                      float4 clipPosition = UnityObjectToClipPos(samplePos);
                      float sampleDepth = clipPosition.z / clipPosition.w;
                      bool isHigher = sampleDepth < sceneDepth;
                      retAlpha += isHigher * val;
                    }
                    //return retAlpha;
                    return float4(0, .5, 1, 1- retAlpha);
            }
            ENDCG
        }
    }
}
