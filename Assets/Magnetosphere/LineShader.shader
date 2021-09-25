Shader "Unlit/LineShader"
{
    Properties
    {
      _StartColor("Start Color", Color) = (1,1,1,1)
      _EndColor("End Color", Color) = (1,1,1,1)
      _PulseParam("Pulse Param", Range(0, 1)) = .5
    }
    SubShader
    { 
        Blend SrcAlpha OneMinusSrcAlpha
        Tags { "RenderType"="Transparent" }
        LOD 100

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _StartColor;
            float4 _EndColor;
            float _PulseParam;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float4 col = lerp(_StartColor, _EndColor, i.uv.x);
              float alpha = abs(i.uv.x - .5) * 2;
              alpha = 1 - pow(alpha, 10);
              col.a = alpha;  

              float pulseParam = _Time.y % 1;
              float toPulse = abs(i.uv.x - pulseParam);
              toPulse = abs(toPulse - .5) * 2;
              toPulse -= .5;
              toPulse *= .4;
              col += saturate(toPulse);
              return col;
            }
            ENDCG
        }
    }
}
