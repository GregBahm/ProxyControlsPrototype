Shader "Unlit/SharkParticleShader"
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

      StructuredBuffer<float3> _ParticleBuffer;
      StructuredBuffer<float3> _MeshBuffer;

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
        UNITY_VERTEX_OUTPUT_STEREO
      };

      float _ParticleSize;
      float4x4 _MasterTransform;
      sampler2D _MainTex;

      v2f vert(input i)
      {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        o.basePos = _ParticleBuffer[i.inst];
        float3 newPos = _ParticleBuffer[i.inst];
        float4 worldPos = mul(_MasterTransform, float4(newPos, 1));

        o.quadPoint = _MeshBuffer[i.id];
        float3 finalQuadPoint = o.quadPoint * _ParticleSize;
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
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
