Shader "Unlit/SpectrogramShader"
{
    Properties
    {
        _ColorA("Color A", Color) = (1,1,1,1)
        _ColorB("Color B", Color) = (1,1,1,1)
        _ColorC("Color C", Color) = (1,1,1,1)
        _ColorD("Color D", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Height ("Height", Float) = 1
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 basePos : TEXCOORD1;
                float3 newPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float _Height;
            fixed3 _ColorA;
            fixed3 _ColorB;
            fixed3 _ColorC;
            fixed3 _ColorD;

            v2f vert(appdata v)
            {
                v2f o;
                fixed val = tex2Dlod(_MainTex, float4(v.uv, 0, 1)).x;
                o.basePos = v.vertex;
                o.basePos.xz *= .01;
                v.vertex.y = (v.vertex.y + .5) * val * _Height;
                o.newPos = v.vertex.xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float heightVal = i.newPos.y * .015;
                //heightVal = pow(heightVal, 2);
                float depth = i.newPos.z;
                depth = depth * 0.005 + .5;
                depth = 1 - pow(1 - depth, 2);
                float3 mainColor = lerp(_ColorA, _ColorB, depth);
                mainColor = lerp(_ColorC, mainColor,  heightVal);
                mainColor *= pow(heightVal, heightVal);
                mainColor = saturate(mainColor);
                //mainColor += saturate(-i.normal.y);

                float2 distToSides = abs(i.uv - .5) * 2;
                float distToSide = max(distToSides.x, distToSides.y);
                float skirt = pow(distToSide, 20);
                float lip = pow(i.basePos.y + .5, 20);
                skirt *= lip;
                float3 skirtColor = float3(1, 1, 1) * skirt * .5;
                mainColor += skirtColor;
                float3 sideColor = mainColor * _ColorD;
                mainColor = lerp(sideColor, mainColor, abs(i.normal.y));
                return float4(mainColor, lip);
            }
            ENDCG
        }
    }
}
