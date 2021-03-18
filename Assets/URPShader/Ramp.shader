Shader "URP/RAMP"

{

    Properties

    {

        _MainTex("RAMP",2D)="White"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

    }

    SubShader

    {

        Tags
        {

            "RenderPipeline"="UniversalRenderPipeline"

            "RenderType"="Opaque"

        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        CBUFFER_END

        sampler2D _MainTex;

        struct a2v

        {
            float4 positionOS:POSITION;

            float3 normalOS:NORMAL;
        };

        struct v2f

        {
            float4 positionCS:SV_POSITION;

            float3 normalWS:NORMAL;
        };
        ENDHLSL



        pass

        {

            Tags
            {

                "LightMode"="UniversalForward"

            }

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS));

                return o;
            }

            half4 FRAG(v2f i):SV_TARGET

            {
                real3 lighdir = normalize(GetMainLight().direction);

                float dott = dot(i.normalWS, lighdir) * 0.5 + 0.5;

                half4 tex = tex2D(_MainTex, float2(dott, 0.5)) * _BaseColor;//根据点乘结果在Ramp上取样决定光线强度
                return tex;
            }
            ENDHLSL

        }



    }

}