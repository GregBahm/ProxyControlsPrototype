Shader "Unlit/ParticleFluidShader"
{
  Properties
  {
        _MainTex("Texture", 2D) = "white" {}
  }
    SubShader
  {
    LOD 100
    Blend SrcAlpha OneMinusSrcAlpha
    ZWrite Off

    Pass
    {
      CGPROGRAM
      #pragma vertex vert  
      #pragma fragment frag
      #pragma target 5.0

      #include "UnityCG.cginc"

      Buffer<float3> _ParticleBuffer;
      Buffer<float3> _MeshBuffer;

      struct input
      {
        uint id : SV_VertexID;
        uint inst : SV_InstanceID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uvs : TEXCOORD2;
        UNITY_VERTEX_OUTPUT_STEREO
      };

      float _ParticleSize;
      float _ParticlesCount;
      float4x4 _MasterTransform;
      sampler2D _MainTex;

      float GetLifespanFactor(float z)
      {
        z = pow(z + .5, 2) - .5;
        float fromMid = 1 - abs(z) * 2;
        return pow(fromMid, .3);
      }

      v2f vert(input i)
      {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        float3 basePos = _ParticleBuffer[i.inst];
        float4 worldPos = mul(_MasterTransform, float4(basePos, 1));

        float3 quadPoint = _MeshBuffer[i.id];
        float3 finalQuadPoint = quadPoint * _ParticleSize;
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
        o.uvs = quadPoint.xy;
        return o;
      }

      fixed4 frag(v2f i) : COLOR
      {
        return 1;
      }
      ENDCG
    }
  }
}
