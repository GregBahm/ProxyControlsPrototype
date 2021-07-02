Shader "Unlit/ControlCubeShader"
{
  Properties
  {
      _Color("Color", Color) = (1,1,1,1)
  }
    SubShader
  {
      Tags { "RenderType" = "Opaque" }
      LOD 100

      Pass
      {

          ZWrite Off
          Blend One One
          Cull Off

          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc"

          fixed4 _Color;

          struct appdata
          {
              float4 vertex : POSITION;
              float3 uv : TEXCOORD0;
              UNITY_VERTEX_INPUT_INSTANCE_ID
          };

          struct v2f
          {
              float2 uv : TEXCOORD0;
              float4 vertex : SV_POSITION;
              UNITY_VERTEX_OUTPUT_STEREO
          };

          v2f vert(appdata v)
          {
              v2f o;
              UNITY_SETUP_INSTANCE_ID(v);
              UNITY_INITIALIZE_OUTPUT(v2f, o);
              UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

              o.vertex = UnityObjectToClipPos(v.vertex);
              o.uv = v.uv;
              return o;
          }

          fixed4 frag(v2f i) : SV_Target
          {
              float2 toCenter = abs(i.uv - .5) * 2;
              float toEdge = max(toCenter.x, toCenter.y);
              toEdge = toEdge * 50 - 49;
              float alpha = saturate(toEdge);
              return _Color * alpha;
          }
          ENDCG
      }
  }
}
