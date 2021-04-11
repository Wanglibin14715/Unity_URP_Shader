Shader "URP/SimpleSSS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _FrontSurfaceDistortion("FrontSurfaceDistortion",float) = 1
        _BackSurfaceDistortion("BackSurfaceDistortion",float) = 1
        _InteriorColor("InteriorColor",Color) = (1,0,0,1)
        _InteriorColorPower("InteriorColorPower",float) = 1
        _FrontSSSIntensity("FrontSSSIntensity",float) = 1
        _Gloss("Gloss",float)=1
        _RimPower("RimPower",float)=1
        _RimIntensity("RimIntensity",float)=1
        _Brightness("透亮",RANGE(0,1)) = 0
        _MoreBlood("红润",RANGE(0,1)) = 0.5
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
        float4 _InteriorColor;
        float4 _BaseColor;
        float _InteriorColorPower;
        float _FrontSurfaceDistortion;
        float _BackSurfaceDistortion;
        float _FrontSSSIntensity;
        float _Gloss;
        float _RimPower;
        float _RimIntensity;
        float _Brightness;
        float _MoreBlood;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;
            };


            float SubSurfaceScattering(float3 viewDir, float3 lightDir, float3 normalDir,
                                       float frontSubSurfaceDistortion, float backSubSurfaceDistortion,
                                       float frontSSSIntensity)
            {
                //计算正面和背面此表面散射
                float3 frontLitDir = normalDir * frontSubSurfaceDistortion - lightDir;
                float3 backLitDir = normalDir * backSubSurfaceDistortion + lightDir;
                float frontSSS = saturate(dot(viewDir, -frontLitDir));
                float backSSS = saturate(dot(viewDir, -backLitDir));
                float result = saturate(frontSSS * frontSSSIntensity + backSSS);
                return result;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv)*_BaseColor;
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                Light mylight=GetMainLight();
                float3 lightDir = normalize( mylight.direction);
                real4 LightColor=real4(mylight.color,1);
                float3 normal = normalize(i.worldNormal.xyz);
                //SSS
                float SSS = SubSurfaceScattering(viewDir, lightDir, normal, _FrontSurfaceDistortion,
                                                 _BackSurfaceDistortion, _FrontSSSIntensity);
                float3 SSSCol = lerp(_InteriorColor, LightColor, saturate(pow(SSS, _InteriorColorPower))).rgb * SSS;
                //Diffuse
                float4 unLitCol = col * _InteriorColor * _MoreBlood;
                float diffuse = dot(normal, lightDir)*(1-_Brightness)+_Brightness;
                float4 diffuseCol = lerp(unLitCol, col, diffuse);
                //Specular
                float specularPow = exp2((1 - _Gloss) * 10 + 1);
                float3 halfDir = normalize(lightDir + viewDir);
                float3 specular = pow(max(0, dot(halfDir, normal)), specularPow);
                specular *= LightColor.rgb;
                //Rim
                float rim = 1.0 - max(0, dot(normal, viewDir));
                float rimValue = lerp(rim, 0, SSS);
                float3 rimCol = lerp(_InteriorColor, LightColor.rgb, rimValue) * pow(rimValue, _RimPower) *
                    _RimIntensity;

                float3 final = SSSCol + diffuseCol.rgb + specular + rimCol;
                return float4(final, 1);
            }
            ENDHLSL
        }
    }
}