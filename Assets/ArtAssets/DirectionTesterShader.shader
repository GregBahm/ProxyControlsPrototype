Shader "Unlit/DirectionTesterShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float3 _Direction;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };
            
            float4x4 axis_matrix(float3 right, float3 up, float3 forward)
            {
              float3 xaxis = right;
              float3 yaxis = up;
              float3 zaxis = forward;
              return float4x4(
                xaxis.x, yaxis.x, zaxis.x, 0,
                xaxis.y, yaxis.y, zaxis.y, 0,
                xaxis.z, yaxis.z, zaxis.z, 0,
                0, 0, 0, 1
                );
            }

            float4x4 look_at_matrix(float3 forward, float3 up)
            {
              float3 xaxis = normalize(cross(forward, up));
              float3 yaxis = up;
              float3 zaxis = forward;
              return axis_matrix(xaxis, yaxis, zaxis);
            }

            float4x4 GetLookMatrix(float3 forward)
            {
              float3 xAxis = cross(forward, float3(0, 1, 0));
              float3 yAxis = cross(forward, xAxis);

              return float4x4(
                xAxis.x, yAxis.x, forward.x, 0,
                xAxis.y, yAxis.y, forward.y, 0,
                xAxis.z, yAxis.z, forward.z, 0,
                0, 0, 0, 1
                );
            }

            float4 GetRenormalized(float4 vertex)
            {
              float4x4 lookMatrix = GetLookMatrix(_Direction);
              return mul(lookMatrix, vertex);
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = GetRenormalized(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float3 col = i.normal * .5 + .5;
              return float4(col, 1);
            }
            ENDCG
        }
    }
}
