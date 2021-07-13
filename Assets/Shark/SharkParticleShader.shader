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

      Buffer<float3> _ParticleBuffer;
      Buffer<float3> _MeshBuffer;
      Buffer<float2> _UvOffsetsBuffer;

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
        float depth : TEXCOORD3;
        UNITY_VERTEX_OUTPUT_STEREO
      };

      float _ParticleSize;
      float4x4 _MasterTransform;
      sampler2D _MainTex;

      float2 GetUvs(float2 quadPoint, uint inst)
      {
        float2 offset = _UvOffsetsBuffer[inst % 4];
        quadPoint += .5;
        quadPoint += offset;
        quadPoint *= .5;
        return quadPoint;
      }

      float GetLifespanFactor(float z)
      {
        z = pow(z + .5, 2) - .5;
        float fromMid = 1 - abs(z) * 2;
        return pow(fromMid, .3);
      }

      float GetDepth(float4 worldPos)
      {
        float toCamera = length(worldPos - _WorldSpaceCameraPos);
        float ret = 2 - toCamera * .5;
        ret = saturate(ret);
        return ret;
      }

      v2f vert(input i)
      {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        float3 basePos = _ParticleBuffer[i.inst];
        float4 worldPos = mul(_MasterTransform, float4(basePos, 1));

        float lifeSpanFactor = GetLifespanFactor(basePos.z);

        float3 quadPoint = _MeshBuffer[i.id];
        float3 finalQuadPoint = quadPoint * _ParticleSize * lifeSpanFactor;
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
        o.uvs = GetUvs(quadPoint, i.inst);
        o.depth = GetDepth(worldPos);
        return o;
      }

      fixed4 frag(v2f i) : COLOR
      {
        //return float4(i.uvs, 0, 1);
        fixed alpha = tex2D(_MainTex, i.uvs).x;
        clip(alpha - .5);
        float4 ret = lerp(.5, float4(2, 2.5, 2.5, 1),  i.depth);
        ret *= .3;
        return ret;
      }
      ENDCG
    }
  }
}
