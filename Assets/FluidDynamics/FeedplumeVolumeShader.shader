Shader "Texture3D/FeedPlumeVolumeShader"
{
  Properties
  {
      _Alpha("Alpha", float) = 0.02
      [Toggle(DO_DEPTH_SORT)] _DoDepthSort("Do Depth Sorting", Int) = 0
    [Toggle(COLOR_GRADIENT)] _UseColorGradient("Use Color Gradient", Int) = 0
        _ColorGradient("Color Gradient", 2D) = "white" {}
  }
    SubShader
  {
      Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }

      LOD 100
      Blend SrcAlpha OneMinusSrcAlpha
      Cull Back
      ZTest Always
      ZWrite Off
      Fog { Mode off }

      Pass
      {
          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag
          #pragma shader_feature DO_DEPTH_SORT
          #pragma shader_feature COLOR_GRADIENT

          #include "UnityCG.cginc"

          // Maximum amount of raymarching samples
          #define MAX_STEP_COUNT 128

          // Allowed floating point inaccuracy
          #define EPSILON 0.00001f

          struct appdata
          {
              fixed4 vertex : POSITION;
              UNITY_VERTEX_INPUT_INSTANCE_ID
          };

          struct v2f
          {
              fixed4 vertex : SV_POSITION;
              float4 screenPosition : TEXCOORD0;
              fixed3 ray_o : TEXCOORD1; // ray origin
              fixed3 ray_d : TEXCOORD2; // ray direction
              UNITY_VERTEX_INPUT_INSTANCE_ID
              UNITY_VERTEX_OUTPUT_STEREO
          };

          sampler3D _MainTex;
          float _Alpha;
          sampler2D _ColorGradient;
          sampler2D _CameraDepthTexture;

          v2f vert(appdata v)
          {
              v2f o;
              UNITY_SETUP_INSTANCE_ID(v);
              UNITY_INITIALIZE_OUTPUT(v2f, o);
              UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

              // calculate eye ray in object space
              o.ray_d = -ObjSpaceViewDir(v.vertex);
              o.ray_o = v.vertex; // v.vertex.xyz - o.ray_d;
              o.vertex = UnityObjectToClipPos(v.vertex);

              o.screenPosition = ComputeScreenPos(o.vertex);
              return o;
          }

          fixed4 BlendUnder(fixed4 color, fixed4 newColor)
          {
            float maxPower = 1 - color.a;
            float effectiveAlpha = pow(newColor.a * _Alpha, 2) * maxPower;
            color.rgb = lerp(color.rgb, saturate(newColor.rgb * (1.0 / newColor.a)), effectiveAlpha);
            color.a += effectiveAlpha;
            color.a = saturate(color.a);
            return color;
          }

          bool GetDoesDepthPass(float3 samplePosition, float depthToBeat)
          {
            float4 clipPosition = UnityObjectToClipPos(samplePosition);
            float rayDepth = clipPosition.z / clipPosition.w;
            return rayDepth > depthToBeat;
          }

          fixed4 frag(v2f i) : SV_Target
          {
#ifdef DO_DEPTH_SORT
              float2 screenCoords = i.screenPosition.xy / i.screenPosition.w;
              float depthToBeat = tex2D(_CameraDepthTexture, screenCoords).x;
#endif

              // Start raymarching at the front surface of the object
              fixed3 rayOrigin = i.ray_o;

              // this needs to be normalized here and not in the vert shader, 
              // as it's linearly interpolated, and would need to be renormalized anyway
              fixed3 rayDirection = normalize(i.ray_d);
              fixed3 samplePosition = rayOrigin;
              fixed4 ret = 0;

              float stepSize = sqrt(3) / MAX_STEP_COUNT;
              [unroll(MAX_STEP_COUNT)]
              for (int i = 0; i < MAX_STEP_COUNT; i++)
              {
                // Accumulate color only within unit cube bounds
                float3 absSample = abs(samplePosition.xyz);
                bool depthpasses = max(absSample.x, max(absSample.y, absSample.z)) < 0.5f + EPSILON;

#ifdef DO_DEPTH_SORT
                depthpasses = depthpasses && GetDoesDepthPass(samplePosition, depthToBeat);
#endif

                if (depthpasses)
                {
                    fixed4 colorData = tex3D(_MainTex, samplePosition + 0.5f);
                    ret = BlendUnder(ret, colorData);
                    samplePosition += rayDirection * stepSize;
                }
            }

#ifdef COLOR_GRADIENT
              fixed4 gradient = tex2D(_ColorGradient, float2(ret.a, 0));
              return float4(gradient.xyz, ret.a);
#else
              return ret;
#endif
      }
      ENDCG
  }
  }
}