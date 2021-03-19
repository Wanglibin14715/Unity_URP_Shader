// MIT License
// Copyright (c) 2020 NedMakesGames
// 防止该脚本被include两次
#ifndef NMG_GRAPHICS_HELPERS_INCLUDED
#define NMG_GRAPHICS_HELPERS_INCLUDED

// 返回视角方向，世界坐标下
float3 GetViewDirectionFromPosition(float3 positionWS) {
    return normalize(GetCameraPositionWS() - positionWS);
}

//如果是投影的pass, 我们需要灯光方向参数
#ifdef SHADOW_CASTER_PASS
float3 _LightDirection;
#endif

// 计算裁剪空间的position用额外的参数, taking into account various strategies
// 提高shadow caster pass的质量
float4 CalculatePositionCSWithShadowCasterLogic(float3 positionWS, float3 normalWS) {
    float4 positionCS;

#ifdef SHADOW_CASTER_PASS
    // From URP's ShadowCasterPass.hlsl
    // If this is the shadow caster pass, we need to adjust the clip space position to account
    // for shadow bias and offset (this helps reduce shadow artifacts)
    positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif
#else
    // This built in function transforms from world space to clip space
    positionCS = TransformWorldToHClip(positionWS);
#endif

    return positionCS;
}

// Calculates the shadow texture coordinate for lighting calculations
//计算 阴影贴图的坐标 用来计算光照
float4 CalculateShadowCoord(float3 positionWS, float4 positionCS) {
    // Calculate the shadow coordinate depending on the type of shadows currently in use
#if SHADOWS_SCREEN
    return ComputeScreenPos(positionCS);
#else
    return TransformWorldToShadowCoord(positionWS);
#endif
}

#endif