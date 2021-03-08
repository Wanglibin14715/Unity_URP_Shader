Shader "URP/兰伯特"

{

    Properties

    {

        _MainTex("MainTex",2D)="White"{}

        _BaseColor("BaseColor",Color)=(1,1,1,1)

    }

    SubShader

    {

        Tags{

            "RenderPipeline"="UniversalRenderPipeline"

            "RenderType"="Opaque"

        }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        CBUFFER_END

        TEXTURE2D( _MainTex);

        SAMPLER(sampler_MainTex);

        struct a2v

        {

            float4 positionOS:POSITION;

            float4 normalOS:NORMAL;

            float2 texcoord:TEXCOORD;

        };

        struct v2f

        {

            float4 positionCS:SV_POSITION;

            float2 texcoordUV:TEXCOORD;

            float3 normalWS:TEXCOORD1;

        };

        ENDHLSL



        pass

        {

            Tags{

                "LightMode"="UniversalForward"

            }

            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)

            {

                v2f o;

                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);

                o.texcoordUV=TRANSFORM_TEX(i.texcoord,_MainTex);

                o.normalWS=TransformObjectToWorldNormal(i.normalOS.xyz);
                //o.normalWS=TransformObjectToWorldNormal(i.normalOS.xyz,true);

                return o;

            }

            real4 FRAG(v2f i):SV_TARGET

            {

                half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoordUV)*_BaseColor;//贴图像素

                Light mainlight=GetMainLight();//主光信息

                real4 LightColor=real4(mainlight.color,1);//

                float3 LightDir=normalize( mainlight.direction);

                float LightAten=dot(LightDir,i.normalWS);//光照方向点乘法线方向

                real4 result = saturate(tex*LightAten*LightColor);//兰伯特光照模型

                return result;
            }

            ENDHLSL

        }



    }



    

}