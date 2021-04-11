Shader"URP/Unlit"

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

        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //CBUFFER_START和CBUFFER_END,对于变量是单个材质独有的时候建议放在这里面，以提高性能。
        //CBUFFER(常量缓冲区)的空间较小，不适合存放纹理贴图这种大量数据的数据类型，适合存放float，half之类的不占空间的数据
        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        CBUFFER_END
        //新的DXD11 HLSL贴图的采样函数和采样器函数，TEXTURE2D (_MainTex)和SAMPLER(sampler_MainTex)，用来定义采样贴图和采样状态代替原来DXD9的sampler2D。
        TEXTURE2D(_MainTex);
        //贴图的采用输出函数采用DXD11 HLSL下的SAMPLE_TEXTURE2D(textureName, samplerName, coord2) ，
        //具有三个变量，分别是TEXTURE2D (_MainTex)的变量和SAMPLER(sampler_MainTex)的变量和uv，用来代替原本DXD9的TEX2D(_MainTex,texcoord)。
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
            float2 texcoord:TEXCOORD;
        };

        ENDHLSL



        pass

        {
            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)

            {

                v2f o;

                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord=TRANSFORM_TEX(i.texcoord,_MainTex);
            //等同于
            //o.texcoord = i.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                return o;

            }

            half4 FRAG(v2f i):SV_TARGET

            {

                half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;

                return tex;

            }

            ENDHLSL

        }



    }





}