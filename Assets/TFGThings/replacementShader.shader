Shader "Unlit/replacementShader"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                //Normals
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                //normals
                float3 viewNormal : TEXCOORD1;
                //Depth
                float zDepth : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV, v.normal));

                float4 clipPos = UnityObjectToClipPos(v.vertex);
                o.zDepth = clipPos.z / clipPos.w;
                //o.viewNormal = v.objectNormal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(i.viewNormal,1);
                return col;
            }
            ENDCG
        }
    }
}
