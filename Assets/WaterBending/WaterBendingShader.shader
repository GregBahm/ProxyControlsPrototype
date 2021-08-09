Shader "Unlit/WaterBendingShader"
{
    Properties
    {
        _OutlineSize("Outline Size", Float) = 0
        _MaxDist("Max Dist", Float) = 1
        _HighColor("High Color", Color) = (1,1,1,1)
        _LowColor("Low Color", Color) = (0,0,0,0)
        
    }
    SubShader
    {
        Pass // Interior
        {
        /*
            Stencil
            {
                Ref 2
                Comp Always
                Pass Replace
            } 
            */
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _HighColor; 
            fixed4 _LowColor;
            float _MaxDist;
            float3 _OrbFocusPoint;

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
                float3 viewDir : VIEWDIR;
                float depth : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float GetDepth(float4 vertex)
            {
                float3 worldPos = mul(unity_ObjectToWorld, vertex).xyz;
                float dist = length(worldPos - _WorldSpaceCameraPos);
                float baseDist = length(_OrbFocusPoint - _WorldSpaceCameraPos);
                return abs(dist - baseDist) * _MaxDist;
            }

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.depth = GetDepth(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
            fixed4 ret = lerp(_LowColor, _HighColor, i.depth);

            i.normal = normalize(i.normal);
            i.viewDir = normalize(i.viewDir);
            float theDot = dot(i.normal, i.viewDir);
            float shine = pow(theDot, 100) * 5;
            shine = saturate(shine) * .2;
            shine += pow(theDot, 5) * .2;  
            ret += shine;
            return ret;
            }
            ENDCG
        }
      /*
        ZWrite Off
        //Blend One One
        Blendop Max
        //Cull Front
        Pass // Exterior
        {
             Stencil
             {
                 Ref 2
                 Comp NotEqual
             }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _HighColor;
            fixed4 _LowColor;
            float _MaxDist;
            float _OutlineSize;

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
                float3 viewDir : VIEWDIR;
                float depth : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float GetDepth(float4 vertex)
            {
                float3 worldPos = mul(unity_ObjectToWorld, vertex).xyz;
                float dist = length(worldPos - _WorldSpaceCameraPos);
                return dist * _MaxDist;
            }

            v2f vert(appdata v)
            {
                v.vertex *= _OutlineSize + 1;
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.depth = GetDepth(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              i.normal = normalize(i.normal);
              i.viewDir = normalize(i.viewDir);
              float theDot = dot(i.normal, i.viewDir);
              float alpha = pow(theDot, 1 ) * 3;
            fixed4 ret = lerp(_LowColor, _HighColor, i.depth);
            ret *= saturate(alpha);
            //ret += shine;
            return ret;
            }
            ENDCG
        }
        */
    }
}
