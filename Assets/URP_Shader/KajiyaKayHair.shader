Shader "URP/KajiyaKayHair"
{
    Properties
    {
        _MainTex("MainTex",2D)="White"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
    }

    SubShader
    {
        Tags{"RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"}

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
            float2 texcoord:TEXCOORD;
            float3 normalWS:TEXCOORD1;
        };

        ENDHLSL

        pass
        {
            Tags{ "LightMode"="UniversalForward"}

            HLSLPROGRAM

            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord=TRANSFORM_TEX(i.texcoord,_MainTex);
                o.normalWS=TransformObjectToWorldNormal(i.normalOS.xyz);
                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;
                Light mylight=GetMainLight();
                real4 LightColor=real4(mylight.color,1);
                float3 LightDir=normalize( mylight.direction);
                float LightAten=dot(LightDir,i.normalWS);
                real4 result = saturate(tex*LightAten*LightColor)*0.5 + 0.5;//半兰伯特光照模型
                return result;
            }

            ENDHLSL
        }
    }
}
