Shader "Unlit/SpectrogramShader"
{
  Properties
  {
      _ColorA("Color A", Color) = (1,1,1,1)
      _ColorB("Color B", Color) = (1,1,1,1)
      _ColorC("Color C", Color) = (1,1,1,1)
      _BubbleTopColor("Bubble Top Color", Color) = (1,1,1,1)
      _BubbleBottomColor("Bubble Buttom Color", Color) = (1,1,1,1)
      _MainTex("Texture", 2D) = "white" {}
      _Height("Height", Float) = 1
      _SphereSize("Sphere Size", Float) = 1
      _PlayMode("PlayMode", Range(0, 1)) = 0
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
                float3 newPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height;
            fixed3 _ColorA;
            fixed3 _ColorB;
            fixed3 _ColorC;
            float _SphereSize;
            float _PlayMode;


            float GetPulseAlpha(float heightVal)
            {
              float baseVal = cos(_Time.z + heightVal * 4);
              baseVal += 1;
              float ret = (max(0, baseVal));
              ret = pow(ret, 5) * .05;
              ret = lerp(1, ret, _PlayMode);
              return ret;
            }

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float2 transformedUvs = TRANSFORM_TEX(v.uv, _MainTex);
                fixed val = tex2Dlod(_MainTex, float4(transformedUvs, 0, 1)).x;
                float pulseAlpha = GetPulseAlpha(v.uv.y);
                val *= pulseAlpha;
                float tipAlpha = abs(v.uv.y - .5) < .49;
                v.vertex *= _SphereSize;
                v.vertex.xyz += v.normal * val * _Height * tipAlpha;
                o.newPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float depth = length(i.newPos) - _SphereSize;
                float softDepth = 1 - pow(1 - depth, 2);
                float heightVal = 1 - i.uv.y;
                float3 baseColor = lerp(_ColorC, _ColorB * .5, heightVal);
                baseColor += pow(depth, 2);
                float3 mainColor = lerp(baseColor, _ColorA, softDepth);
                mainColor = saturate(mainColor);
                return float4(mainColor, 1);
            }
            ENDCG
        }
        Pass
        {
            Cull Front
            ZWrite Off
            Blend One One
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
                float3 viewdir : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed3 _ColorA;
            fixed3 _ColorB;
            fixed3 _ColorC;
            fixed3 _BubbleTopColor;
            fixed3 _BubbleBottomColor;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.uv = v.uv;
                o.viewdir = ObjSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                i.normal = normalize(i.normal);
                i.viewdir = normalize(i.viewdir);
                float fresnel = dot(i.normal, i.viewdir);
                float rim = 1 + fresnel;
                float rimRamp = i.normal.z * .5 + .5;

                float innerRing = saturate(1 - abs(rim - .35) * 100 + .1);
                float outerRing = saturate(1 - abs(rim - .9) * 100 + 5);
                rim += innerRing + outerRing;

                float3 rimColor = lerp(_BubbleBottomColor, _BubbleTopColor, rimRamp);
                float innerAlpha = saturate(-fresnel);
                innerAlpha = pow(innerAlpha, 8);
                innerAlpha *= .25;
                float3 innerColor = lerp(_ColorB, _ColorC, .5);
                float3 ret = innerAlpha * innerColor + rim * rimColor;
                return float4(ret, 1);
            }
            ENDCG
        }
      }
}
