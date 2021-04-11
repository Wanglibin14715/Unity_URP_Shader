Shader "URP/布林冯高光+半兰伯特漫反射"

{

    Properties

    {

        _MainTex ("Texture", 2D) = "white" {}

        _BaseColor("Color",Color)=(1,1,1,1)

        _SpecularRange("SpecularRange",Range(10,300))=10

        _SpecularColor("SpecularColor",Color)=(1,1,1,1)

    }

    SubShader

    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        real4 _BaseColor;
        float _SpecularRange;
        real4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float2 texcoord:TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 normalWS:NORMAL;
            float3 viewDirWS:TEXCOORD0;
            float2 texcoord:TEXCOORD1;
        };
        ENDHLSL

        Pass

        {
            NAME"MainPass"

            Tags
            {

                "LightMode"="UniversalForward"

            }

            HLSLPROGRAM
            #pragma vertex vert1

            #pragma fragment frag1

            v2f vert1(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.normalWS = TransformObjectToWorldNormal(i.normalOS);

                o.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(i.positionOS.xyz));
                //得到世界空间的视图方向

                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);

                return o;
            }

            real4 frag1(v2f i):SV_TARGET

            {
                half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;

                Light mylight=GetMainLight();

                real4 LightColor=real4(mylight.color,1);

                float3 LightDir=normalize( mylight.direction);

                float LightAten=dot(LightDir,i.normalWS);

                real4 lamcolor = saturate(tex*LightAten*LightColor)*0.5 + 0.5;//半兰伯特光照模型

                float spe = dot(normalize(LightDir + i.viewDirWS), i.normalWS);

                real4 specolor = pow(spe, _SpecularRange) * _SpecularColor;//布林冯高光
                
                specolor = saturate(specolor);

                real4 result = saturate(lamcolor + specolor);

                return result;
            }
            ENDHLSL

        }

    }

}