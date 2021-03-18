Shader "URP/VisualNormal"
{
    Properties
    {
        _BaseColor("CompareColor",Color) = (1,1,1,1)
        [KeywordEnum(ON,OFF)]_NT_SWITCH("ON法线_OFF切线",float)=1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _NT_SWITCH_ON _NT_SWITCH_OFF

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normal        : NORMAL;
                float3 tangent: TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 tangent: TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.tangent = TransformObjectToWorldDir(IN.tangent);
                return OUT;
            }
   
            real4 frag(Varyings IN) : SV_Target
            {
                real4 color = 0;
                #if _NT_SWITCH_ON
                color.rgb = IN.normal*0.5+0.5;
                #else
                color.rgb = IN.tangent*0.5+0.5;
                #endif
                color.a = 1;

                return color;
            }
            ENDHLSL
        }
    }
}