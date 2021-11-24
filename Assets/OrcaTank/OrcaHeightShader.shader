Shader "Unlit/OrcaHeightShader"
{
  Properties
  {
    _Color("Color", Color) = (1,1,1,1)
    _HeightPoint("Height Point", Range(0, 1)) = .5
  }
    SubShader
  {
      Tags { "RenderQueue" = "Transparent" }
      Blend SrcAlpha OneMinusSrcAlpha
      Cull Off
      Pass
      {
          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc"

          struct appdata
          {
              float4 vertex : POSITION;
              float3 normal : NORMAL;
              float2 uv : TEXCOORD0;
          };

          struct v2f
          {
              float2 uv : TEXCOORD0;
              float4 vertex : SV_POSITION;
              float3 objPos : TEXCOORD1;
              float3 normal  : NORMAL;
          };

          float4 _Color;
          float _HeightPoint;

          v2f vert(appdata v)
          {
              v2f o;
              o.vertex = UnityObjectToClipPos(v.vertex);
              o.uv = v.uv;
              o.normal = v.normal;
              o.objPos = v.vertex;
              return o;
          }

          fixed4 frag(v2f i) : SV_Target
          {
             float gridLine = (i.objPos.y + 2.1) % .7;
             gridLine = 1 - saturate(gridLine * 1);
             gridLine *= .3;
            float normalizedHeight = (i.objPos.y + 2) / 4;
            float distToHeightPoint = saturate(abs(normalizedHeight - _HeightPoint)) * 2;
            float cap = abs(i.normal.y);
            float alpha = distToHeightPoint + cap * .5;
            float4 ret = _Color * alpha;
            ret += gridLine;
            ret *= .5;
            return ret;
          }
          ENDCG
      }
  }
}
