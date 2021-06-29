Shader "Unlit/WindParticleShader"
{
  Properties
  {
        _MainTex("Texture", 2D) = "white" {}
  }
    SubShader
  {
    LOD 100

    Pass
    {
      CGPROGRAM
      #pragma vertex vert  
      #pragma fragment frag
      #pragma target 5.0

      #include "UnityCG.cginc"

      StructuredBuffer<float4> particles;
      StructuredBuffer<float3> quadPoints;

      struct input
      {
        uint id : SV_VertexID;
        uint inst : SV_InstanceID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float3 basePos: TEXCOORD0;
        float3 quadPoint : TEXCOORD1;
        float col : TEXCOORD2;
        UNITY_VERTEX_OUTPUT_STEREO
      };

      sampler3D MapTexture;
      float _CardSize;
      float4x4 masterTransform;
      float _VelocityScale;
      sampler2D _MainTex;

      v2f vert(input i)
      {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        o.basePos = particles[i.inst].yxz;
        float velocity = particles[i.inst].w;
        float3 newPos = particles[i.inst].yxz;
        float4 worldPos = mul(masterTransform, float4(newPos, 1));

        o.quadPoint = quadPoints[i.id];
        float3 finalQuadPoint = o.quadPoint * _CardSize * pow(velocity, _VelocityScale);
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
        o.col = velocity;
        return o;
      }

      fixed4 frag(v2f i) : COLOR
      {
      float lut = pow(i.col, 2);
        fixed4 col = tex2D(_MainTex, lut);
        //col += .5;
        //col *= float4(0.5, 1, 2, 1);
        return col;
        return float4(i.basePos, 1);
      }
      ENDCG
    }
  }
}
