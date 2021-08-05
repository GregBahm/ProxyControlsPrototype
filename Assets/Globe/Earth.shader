Shader "DVDAY/Earth"
{
	Properties{

		_BaseMap ("Base Map", CUBE) = ""{}
		_GlossMap ("Gloss Map", CUBE) = ""{}
		_CloudMap ("Cloud Map", CUBE) = ""{}
		_LightsMap ("Lights Map", CUBE) = ""{}

		_AtmosphereColor("Atmosphere", Color) = (1,1,1,1)
		_Haze("Haze", Color) = (1,1,1,1)

		_CloudShadowDistance("Cloud Shadow Distance", Range(-1, 1)) = .1
		_Depth("Light Rays Dist", Float) = 1

			[Toggle(DO_EXTRUDE_LIGHT)] _DoExtrudeLight("Do Extrude Light", Int) = 0
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

struct GlobePoint
{
	float3 Position;
	float3 Velocity;
};
			StructuredBuffer<GlobePoint> _PointsBuffer;
			
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
				uint id : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
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

				float4 modifiedPos = float4(_PointsBuffer[v.id].Position, 1);

				o.uv = v.uv;
				o.pos = UnityObjectToClipPos(modifiedPos);

				o.localNormal = v.normal;
				o.cloudNormal = GetCloudNormal(v.normal);
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldView = WorldSpaceViewDir(modifiedPos);
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
			Blend One One
			ZWrite Off
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma geometry geo
				#pragma fragment frag

				#pragma shader_feature DO_EXTRUDE_LIGHT

				#include "UnityCG.cginc"

#ifdef DO_EXTRUDE_LIGHT
				#define SliceCount 20
#else
				#define SliceCount 1
#endif

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2g
				{
						float4 vertex : POSITION;
						float3 normal : NORMAL;
						float shade : TEXCOORD2;
						float3 cloudNormal : TEXCOORD3;
				};

				struct g2f
				{
					float4 vertex : SV_POSITION;
					float dist : TEXCOORD1;
					float3 normal : NORMAL;
					float shade : TEXCOORD2;
					float3 cloudNormal : TEXCOORD3;
				};

				samplerCUBE _LightsMap;
				samplerCUBE _CloudMap;
			  float _Depth;

				float3 GetCloudNormal(float3 normal)
				{
					float angle = _Time.x * .5;
					float x = normal.x * cos(angle) - normal.z * sin(angle);
					float z = normal.z * cos(angle) + normal.x * sin(angle);
					return float3(x, normal.y, z);
				}

				v2g vert(appdata v)
				{
					v2g o;
					o.vertex = v.vertex;
					o.normal = v.normal;

					float3 worldNormal = UnityObjectToWorldNormal(v.normal);
					half baseShade = -dot(worldNormal, _WorldSpaceLightPos0);
					o.shade = 1 - pow(1 - saturate(baseShade), 2);
					o.cloudNormal = GetCloudNormal(v.normal);

					return o;
				}

				void ApplyToTristream(v2g p[3], inout TriangleStream<g2f> triStream, float dist, float offset)
				{
					g2f o;
					o.dist = dist;
					o.normal = p[0].normal;
					o.shade = p[0].shade;
					o.cloudNormal = p[0].cloudNormal;
					o.vertex = UnityObjectToClipPos(p[0].vertex + o.normal * offset);
					triStream.Append(o);

					o.normal = p[1].normal;
					o.shade = p[1].shade;
					o.cloudNormal = p[1].cloudNormal;
					o.vertex = UnityObjectToClipPos(p[1].vertex + o.normal * offset);
					triStream.Append(o);

					o.normal = p[2].normal;
					o.shade = p[2].shade;
					o.cloudNormal = p[2].cloudNormal;
					o.vertex = UnityObjectToClipPos(p[2].vertex + o.normal * offset);
					triStream.Append(o);
				}

				[maxvertexcount(3 * SliceCount)]
				void geo(triangle v2g p[3], inout TriangleStream<g2f> triStream)
				{
						ApplyToTristream(p, triStream, 1, 0);
						triStream.RestartStrip();
						for (int i = 1; i < SliceCount; i++)
						{
								float dist = (float)i / SliceCount;
								float offset = i * _Depth;
								ApplyToTristream(p, triStream, dist, offset);
								triStream.RestartStrip();
						}
				}

				fixed4 frag(g2f i) : SV_Target
				{
						float3 lights = texCUBE(_LightsMap, i.normal);
						float3 softLight = texCUBElod(_LightsMap, float4(i.normal, 5));
						float3 clouds = texCUBE(_CloudMap, i.cloudNormal);
						float3 cloudBase = clouds * .01 * i.shade;;
						float3 cloudLight = pow(softLight * clouds, .9);
						cloudLight *= lerp(float3(0, .5, 1.5), float3(0 , 0,  1), i.dist) * .1;
						cloudLight *= i.shade;

						lights = lerp(lights * float3(1, .5, 0), lights * float3(1, 0, 0), i.dist);
						lights *= 1 - i.dist;
						lights *= i.shade;
						lights *= 1 - clouds;
						float3 ret = lights + cloudBase + cloudLight;
						return float4(ret, 1);
				}
				ENDCG
			}
		}
}