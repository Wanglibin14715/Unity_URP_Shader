Shader "Example/BasicOutline"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap("Base Map", 2D) = "white"
        _OutLine("Outline",float)=0.05
    }
    // 描边代码,这是邪道渲染方法，使用两种LightMode实现双Pass渲染，正道使用RenderObject
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        
        Pass
        {
            Tags
            {"LightMode" = "SRPDefaultUnlit"}
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor; //定义和Property中同名的变量使之关联
            float _OutLine;
            CBUFFER_END

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                // 定义输出的结构体
                Varyings OUT;
                IN.positionOS.xyz += IN.normal * _OutLine;
                // TransformObjectToHClip函数可以将顶点位置从物体空间转换到齐次裁剪空间
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            // 片元着色器        
            half4 frag() : SV_Target
            {
                return _BaseColor;
            }
            ENDHLSL
        }
        Pass
        {
            Tags
            {"LightMode" = "UniversalForward"}
            // HLSL代码块，Unity SRP使用HLSL语言
            HLSLPROGRAM
            // 定义顶点shader的名字
            #pragma vertex vert
            // 定义片元shader的名字
            #pragma fragment frag

            // 这个Core.hlsl文件包含了常用的HLSL宏定义以及函数，也包括了对其他常用HLSL文件的引用
            // 例如Common.hlsl, SpaceTransforms.hlsl等
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 下面结构体包含了顶点着色器的输入数据
            struct Attributes
            {
                // positionOS变量包含了物体空间的顶点位置
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                // 这个结构体里必须包含SV_POSITION
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap); //定义贴图， TEXTURE2D和SAMPLER宏是在Core.hlsl文件中中定义的
            SAMPLER(sampler_BaseMap); //定义贴图采样器

            CBUFFER_START(UnityPerMaterial) //Cbuffer只能放float之类轻量数据类型，texture太占空间
            float4 _BaseMap_ST;
            CBUFFER_END

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                // 定义输出的结构体
                Varyings OUT;
                // TransformObjectToHClip函数可以将顶点位置从物体空间转换到齐次裁剪空间
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            // 片元着色器        
            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                return color;
            }
            ENDHLSL
        }
    }
}