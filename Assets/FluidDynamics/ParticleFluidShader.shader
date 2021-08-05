Shader "Unlit/ParticleFluidShader"
{
  Properties
  {
    [Toggle(COLOR_GRADIENT)] _UseColorGradient("Use Color Gradient", Int) = 0
        _ColorGradient("Color Gradient", 2D) = "white" {}
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
      #pragma shader_feature COLOR_GRADIENT

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
        float2 cardUvs : TEXCOORD2;
        float4 dyeValue : TEXCOORD3;
        UNITY_VERTEX_OUTPUT_STEREO
      };

      float _ParticleSize;
      float _ParticlesCount;
      float4x4 _MasterTransform;
      sampler2D _ColorGradient;
      sampler3D DyeVolume;
      sampler3D VelocityField;

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

        float4 fluidVolumeUvs = float4(basePos + .5, 0);
        fixed4 dyeVal = tex3Dlod(DyeVolume, fluidVolumeUvs);
        fixed3 velocityVal = tex3Dlod(VelocityField, fluidVolumeUvs).xyz;

        float alpha = dyeVal.a;

        float3 quadPoint = _MeshBuffer[i.id];
        float3 finalQuadPoint = quadPoint * _ParticleSize * alpha;
        o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
        o.cardUvs = quadPoint.xy;
        o.dyeValue = dyeVal;
        return o;
      }

      fixed4 frag(v2f i) : COLOR
      {
        float distToCenter = 1 - length(i.cardUvs);
        clip(distToCenter - .5);
#ifdef COLOR_GRADIENT
        return tex2D(_ColorGradient, float2(i.dyeValue.a, 0));
        return i.dyeValue;
#else
        return i.dyeValue;
#endif
         
      }
      ENDCG
    }
  }
}
