Shader "Unlit/CurrentParticleShader"
{
	Properties
	{
		_DirectionLut("Texture", 2D) = "white" {}
	}
	SubShader
	{
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"

			struct ParticleComputeData
			{
				float2 currentPosition;
				float2 previousPosition;
				float time;
			};

			StructuredBuffer<float3> originalPositions;
			StructuredBuffer<ParticleComputeData> particleComputeData;

			float particleLifetime;
			float particleSize;

			float depthMode;
			float depthToShow;
			sampler2D _DirectionLut;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 particlePos: TEXCOORD0;
				float2 velocity : TEXCOORD1;
				float livetimeAlpha : TECOORD2;
				float3 normal : NORMAL;
			};

      float4x4 masterTransform;

			float4x4 GetLookMatrix(float3 forward)
			{
				float3 xAxis = cross(forward, float3(0, 1, 0));
				float3 yAxis = cross(forward, xAxis);

				return float4x4( 
					xAxis.x, yAxis.x, forward.x, 0,
					xAxis.y, yAxis.y, forward.y, 0,
					xAxis.z, yAxis.z, forward.z, 0,
					0, 0, 0, 1
					);
			}

			float3 GetRotatedVert(float3 vert, float2 currentPos, float2 previousPos)
			{
				float2 toNew = currentPos - previousPos;
				float2 dir = normalize(toNew);
				float3 forward = float3(dir.x, 0, dir.y);
				float4x4 look = GetLookMatrix(forward);
				float3 newVert = mul(look, vert);
				return newVert;
			}
			
			v2f vert (appdata_full v, uint inst : SV_InstanceID)
			{
				v2f o;

				float3 originalPos = originalPositions[inst];
				ParticleComputeData data = particleComputeData[inst];

				if (depthMode)
				{
					originalPos.y = depthToShow;
				}

				float3 particlePos = float3(data.currentPosition.x, originalPos.y, data.currentPosition.y);
				particlePos -= .5;
				o.particlePos = particlePos;
				float3 rotatedVert = GetRotatedVert(v.vertex.xyz, data.currentPosition, data.previousPosition);

				float lifetime = data.time / particleLifetime;
				float lifetimeAlpha = abs(lifetime - .5) * 2;
				lifetimeAlpha = 1 - pow(lifetimeAlpha, 10);
				o.livetimeAlpha = lifetimeAlpha;

				rotatedVert *= lifetimeAlpha;
				rotatedVert *= particleSize;
				
				float3 objPos = rotatedVert + float4(particlePos, 0);
				o.pos = UnityObjectToClipPos(objPos);
				o.velocity = normalize(data.currentPosition - data.previousPosition);
				o.normal = v.normal;
				return o;
			}
			
			fixed4 frag(v2f i) : COLOR
			{
				float3 edgeDist = abs(i.particlePos) * 2;
				float edgeAlpha = max(edgeDist.x, edgeDist.z);
				edgeAlpha = 1 - pow(edgeAlpha, 20);
				float2 velocityUvs = i.velocity / 2 + .5;
				fixed4 col = tex2D(_DirectionLut, velocityUvs);
				col += (i.normal.x * .5 + .5) * .2;
				col *= i.livetimeAlpha;
				col *= edgeAlpha;
				return col;
			} 
			ENDCG
		}
	}
}
