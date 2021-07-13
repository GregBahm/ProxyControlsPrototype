Shader "Chaos/greenlandShark"
{
	Properties{
		[Header(Texture Settings)]
		_MainTex("Texture", 2D) = "white" {}
		[Toggle(ALPHACLIP)]_Enable1Bit("Alpha Clip?", Int) = 0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_Color("Diffuse Material Color", Color) = (1,1,1,1)
		[Toggle(VERTCOLOR)]_VertexColor("Enable Vertex Color", Int) = 0
		_SpecTex("Specular Texture", 2D) = "black" {}
		[Toggle(AO)]_AmbientOcclusion("Enable Ambient Occlusion (2nd UV)", Int) = 0
		_AOTex("AO Texture", 2D) = "black" {}
		_AOTexFade("AO Fade", Range(0.0, 1.0)) = 1.0

		[Toggle(EDGETEXTURE)]_EdgeTexture("Enable Edge Texture", Int) = 0
		_EdgeTex("Edge Texture", 2D) = "black" {}
		[HDR]_EdgeColor("Edge Color", Color) = (0,0,0,1)
		_ColorFade("Color Fade", Range(0.0, 1.0)) = 1
		_EdgeFade("Edge Fade", Range(0.0, 1.0)) = 0

		[Toggle(COLORIZE)]_EnableColorize("Colorize (Requires matching script)", Int) = 0
		[PerRendererData]_Colorize ("Colorize", Color) = (1,1,1,1)
		//for now CLIP must be enabled for this to work
		[Toggle(PLANECLIP)]_EnableClipPlane("Enable CLIPPING Plane", Int) = 0

		[Space(20)]
		[Header(Rim Lighting Settings)]
		[Toggle(RIM)]_EnableRim("Enable Rim Lighting", Int) = 0
		[Toggle(NOAARIM)]_EnableNOAARim("Use No AA rim logic?", Int) = 0
		_RimAmount("Rim Fade", Range(0.0, 1.0)) = 1.0
		[HDR]_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimPower("Rim Power", Range(-5.0, 10.0)) = 3.0
        _RimLowCutoff("Rim Low Cutoff", Range(-1.0, 1.0)) = 0.1
        _RimFWCutoff("Rim FW Cutoff", Range(0.0, 1.0)) = 0.75
        [Toggle]_EnableRimDeltaDamp("Enabme Rim Delta Damp", Int) = 1

		[Space(20)]
		[Header(Clipping Settings)]
		[Toggle(CLIP)]_EnableClip("Enable CLIPPING", Int) = 0
		//for now CLIP must be enabled for this to work
		[Toggle(PLANECLIP)]_EnableClipPlane("Enable CLIPPING Plane", Int) = 0
		[Toggle(REVPLANECLIP)]_EnableRevClipPlane("Enable CLIPPING Plane Reverse Direction", Int) = 0
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_ClipPlane("Clip Plane", Vector) = (0.0, 1.0, 0.0, 0.0)
		_ClipPlaneRadiusLocation("Clip Plane Radius Location", Vector) = (0.0, 0.0, 0.0, 0.0)
		_ClippingRadius("Clipping Plane Radius", Range(0.001, 100.0)) = 0.025
		_ClippingPlaneBorderWidth("Clipping Plane Border Width", Range(0.001, 1.0)) = 0.025
		_ClippingPlaneBorderColor("Clipping Plane Border Color", Color) = (1.0, 0.2, 0.0, 1.0)

		[Space(20)]
		[Header(Triplanner or Caustics Additive Pass)]
		[Toggle(CAUSTICS)]_EnableCaustics("Enable Caustics", Int) = 0
		_CausticTex("Caustic Texture", 2D) = "black" {}
		_CausticAmount("Caustic Add Amount", Range(0.0, 1.5)) = 1.0
		_CausticColor("Caustic Color", Color) = (1,1,1,1)
		_TextureScale ("Texture Scale",float) = 1
		_TriplanarBlendSharpness ("Blend Sharpness",float) = 1
		_CausticFalloff("Caustic Falloff Edge", Range(0.0, 1.0)) = 0.5

		[Space(20)]
		[Header(Color Tweaks)]
		[Toggle(COLORTWEAKS)]_EnableColorTweaks("Enable Color Tweaks", Int) = 0
		_Desaturation("Desaturation", Range(0.0, 1.0)) = 0.0
		_Brightness("Brightness", Range(0.0, 1.0)) = 1.0
		[Toggle(CHAOSLIGHTING)]_UseCHaosLighting("Use Chaos Lighting", Int) = 0

		[Space(20)]
		[Header(Material Render Properties)]
		[Toggle(FOG)]_EnableEnableFog("EnableFog", Int) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
	}

	SubShader
	{
		 Cull [_Cull]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma shader_feature FOG
			#pragma shader_feature EDGETEXTURE
			#pragma shader_feature AO
			#pragma shader_feature ALPHACLIP
			#pragma shader_feature COLORTWEAKS
			#pragma shader_feature CLIP
			#pragma shader_feature RIM
			#pragma shader_feature NOAARIM
			#pragma shader_feature PLANECLIP
			#pragma shader_feature REVPLANECLIP
			#pragma shader_feature CAUSTICS
			#pragma shader_feature VERTCOLOR
			#pragma shader_feature COLORIZE
			#pragma shader_feature CHAOSLIGHTING

            #pragma enable_d3d11_debug_symbols

            #pragma multi_compile __ DISPLAY_MITIGATION_ON
            #pragma multi_compile __ APPLY_CHANNEL_MULTIPLIER_ON

			#include "UnityCG.cginc"


			float _SharkLightIntensity;
			float4 _SharkLightColor;

			//Global Variables for Lighting
			uniform half3 _CHAOSMainLightColor = half3(0.95, 0.92, 0.84);
			uniform half3 _CHAOSAmbientColor = half3(0.079, 0.077, 0.085);
			uniform float _CHAOSLightMultiplier = 2.0;
			uniform fixed3 _CHAOSLightDirection = fixed3(.1, .55, .45);

			sampler2D _MainTex;
			uniform float4 _MainTex_ST;

			uniform sampler2D _BumpMap;
			uniform float4 _BumpMap_ST;

			uniform sampler2D _SpecTex;
			uniform float4 _SpecTex_ST;
#ifdef EDGETEXTURE
			uniform sampler2D _EdgeTex;
			uniform float4 _EdgeTex_ST;
			uniform float4 _EdgeColor;
#endif
			half _EdgeFade;
			half _ColorFade;

			uniform float4 _Color;

#ifdef AO
		uniform sampler2D _AOTex;
		uniform float4 _AOTex_ST;
		half _AOTexFade;
#endif

#ifdef COLORIZE
	half4 _Colorize;
#endif

#ifdef RIM
			uniform float4 _RimColor;
			half _RimAmount;
			half _RimPower;
            half _RimLowCutoff;
            half _RimFWCutoff;
            int _EnableRimDeltaDamp;

#endif

#ifdef COLORTWEAKS
		half _Brightness;
		half _Desaturation;
#endif
			
			fixed _Cutoff;

			float4 _ClipPlane;
			float4 _ClipPlaneRadiusLocation;
			half _ClippingRadius;
			fixed _ClippingPlaneBorderWidth;
			fixed3 _ClippingPlaneBorderColor;
#ifdef CAUSTICS
			uniform sampler2D _CausticTex;
			half _CausticAmount;
			half4 _CausticColor;
			float _TextureScale;
			float _TriplanarBlendSharpness;
			float _CausticFalloff;
#endif
			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float3 color: COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
#ifdef FOG
				UNITY_FOG_COORDS(2)
#endif
				float4 pos : SV_POSITION;
				float3 color: COLOR;
				float3 posWorld : TEXCOORD3;
				half3 wNormal : TEXCOORD4;
				half3 wTangent : TEXCOORD5;
				half3 wBitangent : TEXCOORD6;
				float depth : TEXCOORD7;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			inline float PointVsPlane(float3 worldPosition, float4 plane)
			{
				float3 planePosition = plane.xyz * plane.w;
				return dot(worldPosition - planePosition, plane.xyz);
			}

			float GetDepth(float4 worldPos)
			{
				float toCamera = length(worldPos - _WorldSpaceCameraPos);
				float ret = 2 - toCamera * .5;
				ret = saturate(ret);
				return ret;
			}

			v2f vert(appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.posWorld = worldPos.xyz;
				o.uv = UnityStereoScreenSpaceUVAdjust(v.uv, _MainTex_ST);
#ifdef AO
				o.uv2 = UnityStereoScreenSpaceUVAdjust(v.uv2, _AOTex_ST);
#endif
				o.pos = UnityObjectToClipPos(v.vertex);

				//o.wNormal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.wNormal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz);
				o.wTangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.wBitangent = normalize(cross(o.wNormal, o.wTangent) * v.tangent.w);
#ifdef VERTCOLOR
				o.color = v.color;
#endif
#ifdef FOG
				UNITY_TRANSFER_FOG(o,o.pos);
#endif
				o.depth = GetDepth(worldPos);
				return o;
			}


			float4 frag(v2f i) : COLOR
			{
				//Diffuse Maps And Masks
				fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;
#ifdef ALPHACLIP
				clip(col.a - _Cutoff);
#endif

#ifdef CLIP
				float planeDistance = PointVsPlane(i.posWorld.xyz, _ClipPlane);
				float radiusDistance = length(i.posWorld.xyz - _ClipPlaneRadiusLocation.xyz);

				fixed3 planeBorderColor = lerp(_ClippingPlaneBorderColor, fixed3(0.0, 0.0, 0.0), planeDistance / _ClippingPlaneBorderWidth);

#ifdef PLANECLIP
#ifdef REVPLANECLIP
				col.rgb += planeBorderColor * ((planeDistance > _ClippingPlaneBorderWidth) ? 1.0 : 0.0);
#else 
				col.rgb += planeBorderColor * ((planeDistance < _ClippingPlaneBorderWidth) ? 1.0 : 0.0);
#endif
#endif

				col.rgb += _ClippingPlaneBorderColor * ((radiusDistance + _ClippingPlaneBorderWidth > _ClippingRadius) ? 1.0 : 0.0);
#ifdef PLANECLIP
#ifdef REVPLANECLIP
				col *= (planeDistance < 0.0);
#else 
				col *= (planeDistance > 0.0);
#endif
#endif
				col *= (radiusDistance < _ClippingRadius);

				clip(col.a - _Cutoff);
#endif

				//Normal Mapping
				half3 normalTex = UnpackNormal(tex2D(_BumpMap, i.uv));
				float3x3 local2WorldTranspose = float3x3(
					i.wTangent,
					i.wBitangent,
					i.wNormal);
				float3 normalDirection =
					normalize(mul(normalTex, local2WorldTranspose));
				half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.posWorld));

				//Diffuse Wrap Lighting
				half NdotL = dot(normalDirection, _CHAOSLightDirection);
				half wrap = NdotL * 0.5 + 0.5;
#ifdef CHAOSLIGHTING
				float3 diff = (_CHAOSMainLightColor * _CHAOSLightMultiplier) * wrap;

				//Diffuse Wrap Lighting - Back
				half NdotLBack = dot(1 - normalDirection, _CHAOSLightDirection);
				float3 backFinal = (_CHAOSAmbientColor * NdotLBack);

				//diff += (backFinal * _CHAOSLightMultiplier);

				diff *= col.rgb;
#else
				float3 diff = col.rgb;
#endif
#ifdef RIM
#if NOAARIM
            	// FRESNEL CALCS float 
				float fcbias = 0.20373;
				float facing = saturate(1.0 - max(dot( normalize(viewDirection), normalize(i.wNormal)), 0.0));
                
				float refl2Refr = max(fcbias + (1.0-fcbias) * pow(facing, _RimPower), 0) * _RimAmount; 
				refl2Refr =  saturate(pow(abs(refl2Refr * 2 - 1), 1 / max(1.1, 0.0001)) * sign(refl2Refr - 0.5) + 0.5);
				//refl2Refr *= rimColor
				diff.rgb += (refl2Refr * _RimColor.rgb);
#else

				float rawValue = dot(viewDirection, normalize(i.wNormal));
				if (rawValue >= _RimLowCutoff)
				{
					float rim = 1.0 - saturate(rawValue);

					// Dampen at edges
					float fw = fwidth(rim);
					if (fw > _RimFWCutoff) { rim = 0; }
					else if (_EnableRimDeltaDamp) { rim *= 1 - fw; }

					// Apply
					half3 rimColor = (_RimColor.rgb * pow(rim, _RimPower)) * _RimAmount;
					diff.rgb += rimColor;
				}
#endif
#endif

				//half4 finalResult = float4(diff + specTex, 1.0);
				half4 finalResult = float4(diff, 1.0);

#ifdef AO
				float4 withAO = finalResult * tex2D(_AOTex, i.uv2);
				finalResult = lerp (finalResult, withAO, _AOTexFade);

#endif

#ifdef COLORTWEAKS
				half3 lum = dot(finalResult.rgb, float3(0.22, 0.707, 0.071));
				finalResult.rgb = lerp(finalResult.rgb,  lum, _Desaturation);
				finalResult.rgb *= _Brightness;
#endif

#ifdef FOG
				UNITY_APPLY_FOG(i.fogCoord, finalResult);
#endif

#ifdef VERTCOLOR
				finalResult.rgb *= i.color.rgb;
#endif

				finalResult *= _ColorFade;

#ifdef EDGETEXTURE
				float4 edges = tex2D(_EdgeTex, i.uv);
				///edges.a = edges.r;
				edges.rgb *= _EdgeColor.rgb;
				finalResult.rgb += edges.rgb * _EdgeFade;
				float lumEdges = saturate(Luminance(edges.rgb));
				finalResult.a += lumEdges * _EdgeFade;
		
#endif
#ifdef ALPHACLIP
				clip(finalResult.a - _Cutoff);
#endif
				float spec = tex2D(_SpecTex, i.uv).x;
				half theDot = dot(normalDirection, viewDirection);
				float softDot = theDot * .5 + .5;
				float fakeLightShade = softDot * i.depth;

				float specDot = 1 - theDot;
				float specVal = spec * specDot * .5 * i.depth;
				float4 litResult = fakeLightShade * finalResult * _SharkLightColor * _SharkLightIntensity;
				finalResult = lerp(litResult, finalResult, .5);
				finalResult += specVal;
				finalResult.a = 1;
				return finalResult;
			}
			ENDCG
		}
	}
}