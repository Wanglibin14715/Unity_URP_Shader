// 这个shader给mesh填充一个固定的颜色
Shader "Example/VisualNormal"
{
    // shader的属性，这个例子里面是空的，就代表没有对外暴露的属性
    Properties
    {
    }

    // SubShader块包含Shader代码
    SubShader
    {
        // Tags定义了subshader块何时以及在什么条件下执行
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
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
                float4 positionOS   : POSITION;
                // 声明需要法线数据
                half3 normal        : NORMAL;
            };

            struct Varyings
            {
                // 这个结构体里必须包含SV_POSITION
                float4 positionHCS : SV_POSITION;
                // 用于存储法线的数据
                half3 normal : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                // 定义输出的结构体
                Varyings OUT;
                // TransformObjectToHClip函数可以将顶点位置从物体空间转换到齐次裁剪空间
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 计算法线到世界坐标系
                OUT.normal = TransformObjectToWorldNormal(IN.normal);   

                return OUT;
            }

            // 片元着色器        
            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = 0;
                color.rgb = IN.normal * 0.5 + 0.5;
                return color;
            }
            ENDHLSL
        }
    }
}