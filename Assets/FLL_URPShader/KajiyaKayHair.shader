Shader "URP/KajiyaKayHair"
{
    Properties
    {
        _MainTex("MainTex",2D)="White"{}
        _ShiftMap("高光偏移",2D)="White"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _Shininess("头发高光",float)=2
        [KeywordEnum(ON,OFF)]_FLIP_UV("FlipUV",float)=1
    }

    SubShader
    {
        Tags
        {"RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque"}

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _ShiftMap_ST;
        half4 _BaseColor;
        float _Shininess;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_ShiftMap);
        SAMPLER(sampler_ShiftMap);

        struct a2v
        {
            float4 positionOS:POSITION;
            float4 normalOS:NORMAL;
            float4 tangent:TANGENT;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoordUV:TEXCOORD;
            float3 normalWS:TEXCOORD1;
            float3 tangentWS:TEXCOORD2;
            float3 viewDirWs:TEXCOORD3;
            float3 btangentWS:TEXCOORD4;
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
            #pragma shader_feature _FLIP_UV_ON _FLIP_UV_OFF

            //切线偏转，制造W形天使环
            float3 ShiftTangent(float T, float N, float shift)
            {
                float3 shiftedT = T + shift * N;
                return normalize(shiftedT);
            }
            //制造天使环高光，参数：切线T,视角方向V，光源方向L，高光指数e
            float StrandSpecular(float3 T, float3 V, float3 L, float exponent)
            {
                float3 H = normalize(L + V);
                float dotTH = dot(T, H);
                float sinTH = sqrt(1.0 - dotTH * dotTH);
                float dirAtten = smoothstep(-1.0, 0.0, dot(T, H));
                return dirAtten * pow(sinTH, exponent);
            }

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoordUV = TRANSFORM_TEX(i.texcoord, _MainTex);
                #if _FLIP_UV_ON
                o.texcoordUV = float2(o.texcoordUV.y,o.texcoordUV.x);
                #endif
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.tangentWS = TransformObjectToWorldDir(i.tangent);
                o.viewDirWs = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(i.positionOS.xyz));
                o.btangentWS = cross(o.normalWS, o.tangentWS) * i.tangent.w;
                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoordUV) * _BaseColor;

                Light mylight = GetMainLight();
                real4 LightColor = real4(mylight.color, 1);
                float3 LightDir = normalize(mylight.direction);
                //半兰伯特漫反射
                float LightAten = dot(LightDir, i.normalWS);
                real4 result = saturate(maintex * LightAten * LightColor);
                //高光计算
                float3 t = i.tangentWS;
                half4 shifttex = SAMPLE_TEXTURE2D(_ShiftMap, sampler_ShiftMap, i.texcoordUV);
                float shift = shifttex.x;
                t = ShiftTangent(t, i.normalWS, shift);
                float spec = StrandSpecular(t, i.viewDirWs, LightDir, _Shininess);
                result += spec;

                return result;
            }
            ENDHLSL
        }
    }
}