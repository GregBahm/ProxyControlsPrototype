Shader "Unlit/MarkerSelectionOrb"
{
    Properties
    {
      _AboveWaterColor("Above Color", Color) = (1,1,1,1)
      _BelowWaterColor("Below Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Front
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
                float3 worldPosition : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 objPos : TEXCOOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _AboveWaterColor;
            fixed4 _BelowWaterColor;
            float _WaterLevel;
            float _OrbFade;

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = mul(unity_ObjectToWorld, -v.normal);
                o.objPos = v.vertex;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPosition));
              half3 normal = normalize(i.worldNormal);
              half theDot = dot(normal, viewDirection);
              float orbAlpha = 1 - theDot;
              orbAlpha = pow(orbAlpha, 1);
              float4 col = i.worldPosition.y < _WaterLevel ? _BelowWaterColor : _AboveWaterColor;

              float2 edgeDists = abs(i.worldPosition.xz);
              float maxEdge = max(edgeDists.x, edgeDists.y);
              //bool shouldClip = maxEdge < 1;
              //clip(shouldClip - .5);

              float outerFade = pow(1 - theDot, 2);
              orbAlpha *= 1 - saturate(outerFade);
              return fixed4(col.xyz * 2, orbAlpha * col.a);// *_OrbFade);
            }
            ENDCG
        }
    }
}
