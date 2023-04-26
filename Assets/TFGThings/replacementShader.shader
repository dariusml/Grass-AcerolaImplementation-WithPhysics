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
                float3 worldNormal : TEXCOORD2;
                //Depth
                float zDepth : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV, v.normal));
                o.worldNormal = normalize(mul((float3x3)transpose(unity_WorldToObject), v.normal));

                float4 clipPos = UnityObjectToClipPos(v.vertex);
                o.zDepth = clipPos.z / clipPos.w;
                //o.viewNormal = v.objectNormal;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 normalColor = (i.worldNormal.xyz * 0.5) + 0.5f;
                //float4 col = float4(i.viewNormal,i.zDepth);
                float4 col = float4(normalColor,i.zDepth);
                return col;
            }
            ENDCG
        }
    }
}
