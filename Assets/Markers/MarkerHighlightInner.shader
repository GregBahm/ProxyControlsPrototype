Shader "Unlit/MarkerHighlightInner"
{
  Properties
  {
    _HighColor("High Color", Color) = (1, 1, 1, 1)
    _LowColor("High Color", Color) = (1, 1, 1, 1)
    _RimColor("Rim Color", Color) = (1, 1, 1, 1)
  }
  SubShader
  {
      Tags { "RenderType" = "Opaque" }
      LOD 100

      Pass
      {
          Cull Front
          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc"

          fixed4 _HighColor;
          fixed4 _LowColor;
          fixed4 _RimColor;

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
              UNITY_VERTEX_OUTPUT_STEREO
          };

          v2f vert(appdata v)
          {
              v2f o;

              UNITY_SETUP_INSTANCE_ID(v);
              UNITY_INITIALIZE_OUTPUT(v2f, o);
              UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

              o.vertex = UnityObjectToClipPos(v.vertex);
              o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
              o.worldNormal = mul(unity_ObjectToWorld, -v.normal);
              o.uv = v.uv;
              return o;
          }

          fixed4 frag(v2f i) : SV_Target
          {
            half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPosition));
            half3 normal = normalize(i.worldNormal);
            half theDot = dot(normal, viewDirection);
            float edgeShade = 1 - pow(1 - theDot, 2);
            float key = pow(1 - pow(1 - i.uv.y, 4), 2);
            float4 ret = lerp(_LowColor, _HighColor, key);
            ret = lerp(_RimColor, ret, edgeShade);
            return ret;
          }
          ENDCG
      }
    /*
      Pass
      {
          Cull Back
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
          };

          struct v2f
          {
              float2 uv : TEXCOORD0;
              float4 vertex : SV_POSITION;
              float3 worldPosition : TEXCOORD1;
              float3 worldNormal : TEXCOORD2;
          };

          v2f vert(appdata v)
          {
              v2f o;
              o.vertex = UnityObjectToClipPos(v.vertex);
              o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
              o.worldNormal = mul(unity_ObjectToWorld, v.normal);
              o.uv = v.uv;
              return o;
          }

          fixed4 frag(v2f i) : SV_Target
          {
            float4 lightDir = float4(50, 50, 50, 1);
            half3 lightAngle = mul(unity_ObjectToWorld, lightDir).xyz;
            half3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPosition) + lightDir.xyz);
            half3 normal = normalize(i.worldNormal);
            half theDot = dot(normal, viewDirection);
            float shine = pow(saturate(theDot * 1.005), 500) * .8;
            return shine;
          }
          ENDCG
      }
      */
  }
}
