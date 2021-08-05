Shader "DVDAY/Earth"
{
	Properties{

		_Fade ("Fade", Range(0,1)) = 1
		_GrayScale ("Gray Scale", Range(0,1)) = 1
        _BaseMap ("Base Map", CUBE) = ""{}
        _SeaColor ("Sea Color", Color) = (0, 0, 1, 0)
        _Saturation ("Saturation", Range(0,2)) = 1

		[HDR]_ConflictColor ("Conflict Color", Color) = (1, 1, 1, 0.5)
		_ConflictFade("Conflict Fade", Range(0.0, 1.0)) = 1.0

        _NormalMap ("Normal Map", 2D) = ""{}
        _NormalScale ("Normal Scale", Range(0,2)) = 0.5

        _GlossMap ("Gloss Map", CUBE) = ""{}
        _Glossiness ("Smoothness", Range(-10,10)) = 0.5

        _CloudMap ("Cloud Map", CUBE) = ""{}
        _CloudColor ("Cloud Color", Color) = (1, 1, 1, 0.5)
        _ScrollSpeed("ScrollSpeed", Range(-1.0, 1.0)) = 1.0

        _LightsMap ("Lights Map", CUBE) = ""{}
        [HDR]_LightsColor ("Lights Color", Color) = (1, 1, 1, 0.5)

	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			//Global Variables for Lighting
			uniform half3 _CHAOSMainLightColor = half3(0.95, 0.92, 0.84);
			uniform half3 _CHAOSAmbientColor = half3(0.079, 0.077, 0.085);
			uniform float _CHAOSLightMultiplier = 2.0;
			uniform fixed3 _CHAOSLightDirection = fixed3(.1, .55, .45);

            half _Fade;

			half _GrayScale;

			samplerCUBE _BaseMap;
            half4 _SeaColor;
            half _Saturation;

			half4 _ConflictColor;
			half _ConflictFade;

            sampler2D _NormalMap;
            half _NormalScale;

            samplerCUBE _GlossMap;
            half _Glossiness;

            samplerCUBE _CloudMap;
            fixed4 _CloudColor;
            half _ScrollSpeed;

            samplerCUBE _LightsMap;
            fixed4 _LightsColor;

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 posWorld : TEXCOORD0;
				float2 uv : TEXCOORD1;
				half3 localNormal : TEXCOORD2;
				half3 worldNormal : TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = v.uv;
				o.pos = UnityObjectToClipPos(v.vertex);

                o.localNormal = v.normal;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			inline float PointVsPlane(float3 worldPosition, float4 plane)
			{
				float3 planePosition = plane.xyz * plane.w;
				return dot(worldPosition - planePosition, plane.xyz);
			}


			float4 frag(v2f i) : COLOR
			{
                half3 baseCol = texCUBE(_BaseMap, i.localNormal);
								float3 clouds = texCUBE(_CloudMap, i.localNormal);
								float3 lights = texCUBE(_LightsMap, i.localNormal);

								half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.posWorld));
								half baseShade = dot(i.worldNormal, _WorldSpaceLightPos0);

								float frontLight = 1 - pow(1 - saturate(-baseShade), 2);
								float3 frontCol = baseCol + clouds;

								float backLight = 1 - pow(1 - saturate(baseShade), 2);
								float3 backCol = lights * 1 - clouds;
								float3 col = (frontLight * frontCol) + (backLight * backCol);

								return float4(col, 1);
			}
			ENDCG
		}
	}
}