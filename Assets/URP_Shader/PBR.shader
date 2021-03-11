Shader "URP/PBR"
{
    Properties
    {
        _MainTex("MainTex",2D)="White"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _Roughness("粗糙度", Range(0,1)) = 0
        _F0("高光颜色",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Roughness;
        float4 _F0;
        CBUFFER_END

        TEXTURE2D(_MainTex);
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
            float3 viewDirWS:TEXCOORD2;
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

            //PBR高光项中DGF的D项，法线分布函数，GGX模型
            float GGX_D_Function(float dotNH, float roughness)
            {
                float a_square = pow(roughness, 2);
                float dotNH_square = pow(dotNH, 2);
                float denom = dotNH_square * (a_square - 1) + 1;
                denom = PI * pow(denom, 2);
                return a_square / denom;
            }

            //PBR高光项中DGF的G项，阴影遮蔽函数
            float G_Section(float dot, float k)
            {
                float nom = dot;
                float denom = lerp(dot, 1, k);
                return nom / denom;
            }

            float G_Function(float dotNL, float dotNV, float roughness)
            {
                float k = pow(1 + roughness, 2) / 8;
                float Gnl = G_Section(dotNL, k);
                float Gnv = G_Section(dotNV, k);
                return Gnl * Gnv;
            }

            float G_Function_LeLe(float dotNL, float dotNV, float roughness)
        {
            float k = roughness*roughness/2;
            return 1/lerp(k,1,dotNL)*lerp(k,1,dotNV);
        }

            //PBR高光项中DGF的F项，菲涅尔反射函数
            float F_Function(float dotHL, float f0)
            {
                float fre = exp2((-5.55 * dotHL - 6.98) * dotHL);
                return lerp(fre, 1, f0);
            }

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoordUV = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(i.positionOS.xyz));
                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoordUV) * _BaseColor; //贴图像素
                Light mainlight = GetMainLight(); //主光信息
                real4 light_color = real4(mainlight.color, 1); //
                float3 light_dir = normalize(mainlight.direction);
                float light_aten = dot(light_dir, i.normalWS); //光照方向点乘法线方向
                real4 diffuse = saturate(tex * light_aten * light_color); //兰伯特光照模型
                diffuse = real4(0, 0, 0, 1);
                
                float3 h = normalize(light_dir + i.viewDirWS);
                float d = GGX_D_Function(dot(i.normalWS, h), _Roughness);
                float dotNL = dot(i.normalWS, light_dir);
                float dotNV = dot(i.normalWS, i.viewDirWS);
                float g = G_Function(dotNL, dotNV, _Roughness);
                //if(dotNL<0) g = 0;
                float dotHL = dot(h,light_dir);
                float f = F_Function(dotHL,_F0.xyz);
                
                float BRDFSpec = d*g*f/(4*dotNL*dotNV);
                real4 speclar = light_color*d;
                return saturate(diffuse + speclar);
            }
            ENDHLSL
        }
    }
}