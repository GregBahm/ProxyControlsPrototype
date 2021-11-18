Shader "Unlit/PancakeGlacierHeightmap"
{
    Properties
    {
        _MainTex("Texture (R shade G height)", 2D) = "white" {}
        _Lut("Lut", 2D) = "white" {}
        _TopHigh("Top High", Color) = (1,1,1,1)
        _TopLow("Top Low", Color) = (0,1,1,1)
        _SideHigh("Side High", Color) = (0,0,1,1)
        _SideLow("Side Low", Color) = (0,0,0,1)
        _Synch("Synch", Float) = 0

        _Tint("Tint", Color) = (1,1,1,1)

        _MajorContourLineColor("Major Contour Line", Color) = (1, 1, 1 ,1)
        _MinorContourLineColor("Minor Contour Line", Color) = (1, 1, 1 ,1)

        _HalfMajorContourLinePixelSize("_HalfMajorContourLinePixelSize", Float) = 1
        _HalfMinorContourLinePixelSize("_HalfMinorContourLinePixelSize", Float) = 1
        _NumMinorContourIntervalSections("_NumMinorContourIntervalSections", Float) = 1
        _MinorContourLineIntervalInMeters("_MinorContourLineIntervalInMeters", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float3 normal : NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 height : TEXCOORD1;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _Lut;

            fixed3 _SideHigh;
            fixed3 _SideLow;
            fixed3 _TopHigh;
            fixed3 _TopLow;

            fixed3 _Tint;
            float _Synch;

            fixed4 _MajorContourLineColor;
            fixed4 _MinorContourLineColor;
            float _HalfMajorContourLinePixelSize;
            float _HalfMinorContourLinePixelSize;
            float _NumMinorContourIntervalSections;
            float _MinorContourLineIntervalInMeters;

            fixed4 ApplyContourLines(fixed4 color, float elevation /* in meters */)
            {
              // Compute the opacity of the contour line.
              float changeInIntervalForOnePixel = fwidth(elevation / _MinorContourLineIntervalInMeters);

              // Normalize the range and make it continuous... Instead of going 0... 0.999, 1.0, 0.000 etc., the range goes 0 ... 0.499, 0.5, 0.499 ... 0.0 etc.
              float minorNormalizedFrac = 0.5 - distance(frac(elevation / _MinorContourLineIntervalInMeters), 0.5);

              // Determine if this is a major or minor contour line.
              float majorMinorIntervalInMeters = _NumMinorContourIntervalSections * _MinorContourLineIntervalInMeters;
              float majorNormalizedFrac = 0.5 - distance(frac(elevation / majorMinorIntervalInMeters), 0.5);
              bool isMajor = majorNormalizedFrac < (1.0 / (2.0 * _NumMinorContourIntervalSections));

              // Change pixel width based on major/minor.
              float halfPixelWidth = isMajor ? _HalfMajorContourLinePixelSize : _HalfMinorContourLinePixelSize;

              float lowerSmoothStepBound = changeInIntervalForOnePixel * max(halfPixelWidth - 0.5, 0.0);

              // Adding 'changeInIntervalForOnePixel' ensures the edge AA is at least one pixel.
              float upperSmoothStepBound = lowerSmoothStepBound + changeInIntervalForOnePixel;
              float alpha = 1.0 - smoothstep(lowerSmoothStepBound, upperSmoothStepBound, minorNormalizedFrac);

              float4 preMultipliedAlphaColor = alpha * (isMajor ? _MajorContourLineColor : _MinorContourLineColor);
              return preMultipliedAlphaColor + (1.0f - preMultipliedAlphaColor.a) * color;
            }


            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                v.uv.y = 1 - (1 - v.uv.y) * _Synch;
                float height = tex2Dlod(_MainTex, float4(v.uv, 0, 3)).g * v.vertex.y;
                v.vertex.y = height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.height = v.vertex.y;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                fixed4 tex = tex2D(_MainTex, i.uv);

                fixed shade = tex.x;
                fixed height = tex.y;

                float isSide = i.normal.y;
                float3 top = lerp(_TopLow, _TopHigh, height);
                top *= shade;
                float3 side = lerp(_SideLow, _SideHigh, i.height * 100);
                float3 col = lerp(side, top, isSide);
                col.xyz = ApplyContourLines(float4(col, 1), i.height * 10000).xyz;
                return fixed4(col * _Tint, 1);
            }
            ENDCG
        }
    }
}
