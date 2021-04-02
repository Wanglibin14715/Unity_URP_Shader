#ifndef GRASSBLADES_INCLUDED
#define GRASSBLADES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "NMGGrassBladeGraphicsHelpers.hlsl"

//描述生成网格的顶点位置
struct DrawVertex {
    float3 positionWS; //世界空间位置
    float height; //草的高度
};
//生成网格的三角面
struct DrawTriangle {
    float3 lightingNormalWS; //世界空间面法线方向, 光照算法要使用
    DrawVertex vertices[3]; // 三角面的三个顶点
};
// 声名生成Mesh的buffer
StructuredBuffer<DrawTriangle> _DrawTriangles;

struct VertexOutput {
    float uv            : TEXCOORD0; // The height of this vertex on the grass blade
    float3 positionWS   : TEXCOORD1; // Position in world space
    float3 normalWS     : TEXCOORD2; // Normal vector in world space
    float4 positionCS   : SV_POSITION; // Position in clip space
};

// Properties
float4 _BaseColor;
float4 _TipColor;//草尖端的颜色

// Vertex functions

VertexOutput Vertex(uint vertexID: SV_VertexID) {
    //初始化输出结构体 Initialize the output struct
    VertexOutput output = (VertexOutput)0;

    //从buffer中取得vertex Get the vertex from the buffer
    //因为buffer中是三角面，我们把vertexID除以三 Since the buffer is structured in triangles, we need to divide the vertexID by three
    //为了得到三角面，取余3 to get the triangle, and then modulo by 3 to get the vertex on the triangle
    DrawTriangle tri = _DrawTriangles[vertexID / 3];
    DrawVertex input = tri.vertices[vertexID % 3];

    output.positionWS = input.positionWS;
    output.normalWS = tri.lightingNormalWS;
    output.uv = input.height;
    output.positionCS = TransformWorldToHClip(input.positionWS);

    return output;
}

// Fragment functions

half4 Fragment(VertexOutput input) : SV_Target {
    // 为光照计算准备一下
    InputData lightingInput = (InputData)0;
    lightingInput.positionWS = input.positionWS;
    lightingInput.normalWS = input.normalWS; // No need to normalize, triangles share a normal
    lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.positionWS); // Calculate the view direction
    lightingInput.shadowCoord = CalculateShadowCoord(input.positionWS, input.positionCS);

    //根据高度，对草从底部到顶部做插值 Lerp between the base and tip color based on the blade height
    float colorLerp = input.uv;
    float3 albedo = lerp(_BaseColor.rgb, _TipColor.rgb, input.uv);

    // The URP simple lit algorithm套一个简单的布林光照
    // The arguments are lighting input data, albedo color, specular color, smoothness, emission color, and alpha
    return UniversalFragmentBlinnPhong(lightingInput, albedo, 1, 0, 0, 1);
}

#endif