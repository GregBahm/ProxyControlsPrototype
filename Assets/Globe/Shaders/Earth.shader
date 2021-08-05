Shader "DVDAY/Earth"
{
	Properties{

		_BaseMap ("Base Map", CUBE) = ""{}

		_NormalMap ("Normal Map", 2D) = ""{}
		_NormalScale ("Normal Scale", Range(0,2)) = 0.5

		_GlossMap ("Gloss Map", CUBE) = ""{}
		_Glossiness ("Smoothness", Range(-10,10)) = 0.5

		_CloudMap ("Cloud Map", CUBE) = ""{}
		_CloudColor ("Cloud Color", Color) = (1, 1, 1, 0.5)
		_ScrollSpeed("ScrollSpeed", Range(-1.0, 1.0)) = 1.0

		_LightsMap ("Lights Map", CUBE) = ""{}
		[HDR]_LightsColor ("Lights Color", Color) = (1, 1, 1, 0.5)

		_AtmosphereColor("Atmosphere", Color) = (1,1,1,1)
		_Haze("Haze", Color) = (1,1,1,1)

		_CloudShadowDistance("Cloud Shadow Distance", Range(-1, 1)) = .1
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			
			samplerCUBE _BaseMap;

			sampler2D _NormalMap;
			half _NormalScale;

			samplerCUBE _GlossMap;
			half _Glossiness;

			samplerCUBE _CloudMap;
			fixed4 _CloudColor;
			half _ScrollSpeed;

			samplerCUBE _LightsMap;
			fixed4 _LightsColor;

			fixed4 _AtmosphereColor;
			fixed4 _Haze;
			float _CloudShadowDistance;

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
				half3 localNormal : NORMAL;
				half3 cloudNormal : TEXCOORD2;
				half3 worldNormal : TEXCOORD3;
				half3 worldView : TEXCOORD4;
				half3 forward : TEXCOORD5;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float3 GetCloudNormal(float3 normal)
			{
        float angle = _Time.x * .5;
        float x = normal.x * cos(angle) - normal.z * sin(angle);
        float z = normal.z * cos(angle) + normal.x * sin(angle);
        return float3(x, normal.y, z);
			}

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
				o.cloudNormal = GetCloudNormal(v.normal);
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldView = WorldSpaceViewDir(v.vertex);\
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				i.worldView = normalize(i.worldView);
				i.worldNormal = normalize(i.worldNormal);
				float fresnel = dot(i.worldView, i.worldNormal);

				half3 baseCol = texCUBE(_BaseMap, i.localNormal);
				float3 cloudShadowNormal = lerp(i.cloudNormal, _WorldSpaceLightPos0, _CloudShadowDistance);
				float3 cloudShadow = texCUBElod(_CloudMap, float4(cloudShadowNormal, 5));
				float3 gloss = texCUBE(_GlossMap, i.localNormal);

				float3 clouds = texCUBE(_CloudMap, i.cloudNormal);

				float3 lights = texCUBE(_LightsMap, i.localNormal);

				half baseShade = -dot(i.worldNormal, _WorldSpaceLightPos0);

				float3 halfAngle = normalize(i.worldView + _WorldSpaceLightPos0);
				float spec = dot(i.worldNormal, halfAngle);
				float3 shine = pow(saturate(spec), 90) * float3(1, 1, .5);
				shine += pow(saturate(spec), 30) * float3(1, .2, 0) * .5;
				shine *= saturate(gloss.x * 5);
				shine += pow(saturate(spec), 10) * float3(.3, .1, 0) * (1 - saturate(gloss.x * 5));

				//return float4(shine, 1);
				float3 frontCol = baseCol;
				frontCol += shine;
				frontCol = lerp(frontCol, float3(.3, .5, .6), saturate(gloss.x * 5) * .5);

				float atmosphere = pow(1 - fresnel, 1);// *_AtmosphereColor.a;
				float3 atmosphereCol = lerp(_AtmosphereColor.rgb, _Haze.xyz, atmosphere);

				frontCol = lerp(frontCol, _Haze.xyz, _Haze.a);
				frontCol -= pow(cloudShadow, 2) * .5;
				frontCol = lerp(frontCol, 1, pow(clouds, 1) * 1.2);
				frontCol = lerp(frontCol, atmosphereCol, atmosphere);

				float redShift = pow(1 - abs(baseShade), 10) * pow(fresnel, .5);
				frontCol = lerp(frontCol, frontCol * float3(2, .75, 0), redShift);

				float frontLight = 1 - pow(1 - saturate(-baseShade), 8);
				frontLight = max(frontLight, .1);
				float backLight = 1 - pow(1 - saturate(baseShade), 2);
				float3 backCol = lights * (1 - clouds * .5);
				float3 col = saturate(frontLight * frontCol) + saturate(backLight * backCol);


				return float4(col, 1);
			}
			ENDCG
		}
	}
}