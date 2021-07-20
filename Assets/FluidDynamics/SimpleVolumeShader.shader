Shader "Texture3D/SimpleVolumeShader"
{
    Properties
    {
        _Alpha("Alpha", float) = 0.02
        [NoScaleOffset]  _Gradient("Color Texture", 2D) = "" {}
    }
        SubShader
        {
            Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }

            LOD 100
            //Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            ZTest Always
            ZWrite Off
            Fog { Mode off }

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

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
                sampler2D _Gradient;
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

                fixed4 DataToColor(fixed3 samplePosition)
                {
                    samplePosition = samplePosition + 0.5f;
                    float2 uv = samplePosition.xz;
                    float3 uvw = float3(uv.x, samplePosition.y, uv.y);
                    fixed4 sampledData = tex3D(_MainTex, uvw);

                    float data = sampledData.r;
                    float alpha = sampledData.g;

                    fixed4 sampledColor = fixed4(tex2D(_Gradient, fixed2(data, 0.5)).xyz, data == 0 ? 0 : alpha);
                    sampledColor.a *= _Alpha;

                    return sampledColor;
                }

                fixed4 BlendUnder(fixed4 color, fixed4 newColor)
                {
                  color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                  //color.a += (1.0 - color.a) * newColor.a;
                  return color;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float2 screenCoords = i.screenPosition.xy / i.screenPosition.w;
                    float depthToBeat = tex2D(_CameraDepthTexture, screenCoords).x;
 
                    // Start raymarching at the front surface of the object
                    fixed3 rayOrigin = i.ray_o;

                    // this needs to be normalized here and not in the vert shader, 
                    // as it's linearly interpolated, and would need to be renormalized anyway
                    fixed3 rayDirection = normalize(i.ray_d);
                    fixed3 samplePosition = rayOrigin;
                    fixed4 ret = fixed4(0, 0, 0, 0);

                    float stepSize = sqrt(3) / MAX_STEP_COUNT;
                    [unroll(MAX_STEP_COUNT)]
                    for (int i = 0; i < MAX_STEP_COUNT; i++)
                    {
                        // Accumulate color only within unit cube bounds
                        float3 absSample = abs(samplePosition.xyz);
                        bool isInBox = max(absSample.x, max(absSample.y, absSample.z)) < 0.5f + EPSILON;

                        float sampleDepth = UnityObjectToClipPos(samplePosition).z;
                        bool depthPasses = sampleDepth > depthToBeat;

                        if (isInBox && depthPasses)
                        { 
                            fixed4 colorData = DataToColor(samplePosition);
                            ret = BlendUnder(ret, colorData);
                            samplePosition += rayDirection * stepSize;
                        }
                    }
                  return ret;
              }
              ENDCG
          }
        }
}