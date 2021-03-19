// MIT License
// Copyright (c) 2020 NedMakesGames
// 防止该脚本被include两次
#ifndef NMG_COMPUTE_HELPERS_INCLUDED
#define NMG_COMPUTE_HELPERS_INCLUDED

//返回由这三个点定义的面的法线
float3 GetNormalFromTriangle(float3 a, float3 b, float3 c) {
    return normalize(cross(b - a, c - a));
}

//返回三点的线性中心点三维
float3 GetTriangleCenter(float3 a, float3 b, float3 c) {
    return (a + b + c) / 3.0;
}
//返回三点的线性中心点二维
float2 GetTriangleCenter(float2 a, float2 b, float2 c) {
    return (a + b + c) / 3.0;
}

#endif