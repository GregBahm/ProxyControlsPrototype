Shader "Unlit/WaterPlaneShader"
{
    Properties
    {
      _Color("Color", Color) = (1,1,1,1)
      _EdgeTopColor("Edge Top Color", Color) = (1,1,1,1)
      _EdgeSideColor("Edge Side Color", Color) = (1,1,1,1)
      _OrbSize("Orb Size", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

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
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD1;
                float3 normal : NORMAL;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            fixed4 _EdgeTopColor;
            fixed4 _EdgeSideColor;
            float3 _OrbPosition; 
            float _OrbSize;
            float _OrbFade;

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.vertex + .5;
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float distToOrb = length(i.worldPosition - _OrbPosition);
              float alpha = 1 - distToOrb;
              alpha *= _OrbFade;
              alpha += _OrbSize;
              alpha = pow(saturate(alpha), 20);
              float innerAlpha = saturate(distToOrb / _OrbSize);
              innerAlpha = 1 - pow(innerAlpha, 20);
              innerAlpha *= .6;
              alpha -= innerAlpha;
              fixed4 finalGlow = saturate(fixed4(_Color.xyz, alpha * _Color.a));

              float2 distToEdges = abs(i.uv - .5) * 2;
              float distToEdge = max(distToEdges.x, distToEdges.y);
              float sidesAlpha = pow(distToEdge, 20) * .5;
              float4 sides = lerp(_EdgeSideColor, _EdgeTopColor, abs(i.normal. z));
              float4 ret = lerp(finalGlow, sides, sidesAlpha);
              float sideAlpha = 1 - i.uv.z;
              sideAlpha = pow(sideAlpha, 10);
              ret.a *= sideAlpha;
              ret.a -= innerAlpha * _OrbFade;
              return ret;
            }
            ENDCG
        }
    }
}
