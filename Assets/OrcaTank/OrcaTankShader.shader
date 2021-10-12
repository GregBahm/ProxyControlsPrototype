Shader "Unlit/OrcaTankShader"
{
Properties
{
  _LightTilt("Light Tilt", Float) = 0
  _ColA("Color A", Color) = (.2, .5, 1, 1)
  _ColB("Color B", Color) = (.2, .5, 1, 1)
  _ColC("Color C", Color) = (.2, .5, 1, 1)
  _ColD("Color D", Color) = (.2, .5, 1, 1)
}

SubShader
{
    Pass
    {
        Tags { "RenderQueue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Front
        CGPROGRAM

        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float4 objPos : TEXCOORD0;
            float2 uv : TEXCOORD1;
            float3 worldNormal : NORMAL;
            float3 worldView : TEXCOORD2;

            UNITY_VERTEX_OUTPUT_STEREO
        };

        float _LightTilt;
        float3 _ColA;
        float3 _ColB;
        float3 _ColC;
        float3 _ColD;

        v2f vert(appdata v)
        {
            v2f o;

            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_OUTPUT(v2f, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            o.vertex = UnityObjectToClipPos(v.vertex);
            o.objPos = v.vertex;
            o.uv = v.uv;
            o.worldNormal = mul(unity_ObjectToWorld, v.normal).xyz;
            o.worldView = -WorldSpaceViewDir(v.vertex);
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
                i.worldNormal = normalize(i.worldNormal);
                i.worldView = normalize(i.worldView + float3(0, _LightTilt, 0));
                float nh = dot(i.worldNormal, i.worldView);
                nh = max(0, nh);
                float hardSpec = saturate(pow(nh, 200));
                float softSpec = saturate(pow(nh, 2));


                float fresnel = 1 - dot(i.worldNormal, i.worldView);
                fresnel = pow(fresnel, 10);
                float alpha = fresnel;

                float ends = i.objPos.y;
                ends = 1 - ends;
                ends = pow(ends, 20) * .5;
                alpha += ends;

                float3 col = lerp(_ColB, _ColA,  pow(fresnel, .2));
                col = lerp(col, _ColD, ends);
                alpha = saturate(alpha);
                return float4(col, alpha);
            }

            ENDCG
        }

    Pass
    {
        Tags { "RenderQueue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back
        CGPROGRAM

        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float4 objPos : TEXCOORD0;
            float2 uv : TEXCOORD1;
            float3 worldNormal : NORMAL;
            float3 worldView : TEXCOORD2;

            UNITY_VERTEX_OUTPUT_STEREO
        };

        float _LightTilt;
        float3 _ColA;
        float3 _ColB;
        float3 _ColC;

        v2f vert(appdata v)
        {
            v2f o;

            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_OUTPUT(v2f, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            o.vertex = UnityObjectToClipPos(v.vertex);
            o.objPos = v.vertex;
            o.uv = v.uv;
            o.worldNormal = mul(unity_ObjectToWorld, v.normal).xyz;
            o.worldView = WorldSpaceViewDir(v.vertex);
            return o;
        }

            fixed4 frag(v2f i) : SV_Target
            {

                i.worldNormal = normalize(i.worldNormal);
                i.worldView = normalize(i.worldView + float3(0, _LightTilt, 0));
                float nh = dot(i.worldNormal, i.worldView);
                nh = max(0, nh);
                float softSpec = saturate(pow(nh, 2));


                float fresnel = 1 - dot(i.worldNormal, i.worldView);
                fresnel = pow(fresnel, 2);
                float alpha = fresnel;
                alpha += softSpec * .25;

                float ends = 1 - i.objPos.y;
                ends = pow(ends, 20) * .5;
                alpha += ends;
                float colLerp = 1 - pow(1 - fresnel, 5);
                float3 col = lerp(_ColA, _ColB, colLerp);
                col = lerp(col, _ColC, ends);

                float hyperEnds = 1 - i.objPos.y;
                hyperEnds = 1 - saturate(pow(hyperEnds, 200));
                alpha *= hyperEnds;

                return float4(col, alpha);
            }

            ENDCG
        }
  }
}
