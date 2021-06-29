Shader "Unlit/BaitParticleShader"
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
      StructuredBuffer<float3> baseVelocities;
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
        float lifespan : TEXCOORD2;
        float3 col : TEXCOORD3;
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
        float lifespan = particles[i.inst].w;
        float3 newPos = particles[i.inst];
        float4 worldPos = mul(masterTransform, float4(newPos, 1));

        o.quadPoint = quadPoints[i.id];
        float lifetimeCardSize = pow(1 - lifespan, .1);
        float3 finalQuadPoint = o.quadPoint * _CardSize * lifetimeCardSize;
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
        o.lifespan = lifespan;
        o.col = baseVelocities[i.inst];
        return o;
      }

      fixed4 frag(v2f i) : COLOR
      {
        float3 col = i.col * .5 + .5;

        float lutUv = pow(i.lifespan, 2);
        fixed4 lut = tex2D(_MainTex, lutUv);
        lut = lerp(lut, float4(col, 1), .2);
        return lut;
      }
      ENDCG
    }
  }
}
