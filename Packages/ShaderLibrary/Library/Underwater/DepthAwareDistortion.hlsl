#ifndef SHADER_LIBRARY_DEPTH_AWARE_DISTORTION
#define SHADER_LIBRARY_DEPTH_AWARE_DISTORTION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Underwater/WaterCommon.hlsl"

// 深度感知扭曲：读取场景深度缓冲，计算水体厚度（Water Surface Z - Scene Z）
// 把归一化深度差作为扭曲强度的遮罩或缩放因子：近处扭曲弱、深处扭曲强，
// 同时剔除水面前方的物体，避免"前方物体被错误扭曲"的穿帮
// Reverse-Z 适配：反向 Z 缓冲需反转 step 比较方向（Unity URP / Godot 4.3+ 常见）

// 归一化水体厚度遮罩
// sceneDepth 接 Scene Depth 节点；waterSurfaceDepth 为水面处的深度值
// maxWaterDepthDiff 用于把实际深度差归一化，统一控制浅水/深水过渡、焦散范围与泡沫显示
// reverseZ = 1 使用反向 Z 比较逻辑，0 使用常规 Z；返回 [0,1]，水面前方物体为 0
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.WaterDepthMask</sg:ProviderKey>
///     <sg:DisplayName>Water Depth Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>WaterDepthMask</sg:SearchName>
///     <sg:SearchTerms>Underwater, Depth, ReverseZ, WaterDepthDiff, Mask, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneDepth">
///     <sg:DisplayName>Scene Depth</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "waterSurfaceDepth">
///     <sg:DisplayName>Water Surface Depth</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "maxWaterDepthDiff">
///     <sg:DisplayName>Max Water Depth Diff</sg:DisplayName>
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "reverseZ">
///     <sg:DisplayName>Reverse Z</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float WaterDepthMask(float sceneDepth, float waterSurfaceDepth, float maxWaterDepthDiff, float reverseZ)
{
  float reverse = step(0.5, reverseZ);
  float behind = lerp(step(waterSurfaceDepth, sceneDepth), step(sceneDepth, waterSurfaceDepth), reverse);
  float thickness = abs(sceneDepth - waterSurfaceDepth) / max(maxWaterDepthDiff, 1e-4);

  return saturate(thickness) * behind;
}

// 用深度遮罩缩放扭曲强度
// minStrength 保留浅水处的基础扭曲，深水处使用完整强度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScaleDistortionByDepth</sg:ProviderKey>
///     <sg:DisplayName>Scale Distortion By Depth</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>ScaleDistortionByDepth</sg:SearchName>
///     <sg:SearchTerms>Underwater, Depth, Distortion, Strength, UV</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV Offset</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "uvOffset">
///     <sg:DisplayName>UV Offset</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "depthMask">
///     <sg:DisplayName>Depth Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "minStrength">
///     <sg:DisplayName>Min Strength</sg:DisplayName>
///     <sg:Default>0.2</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ScaleDistortionByDepth(float2 uvOffset, float depthMask, float minStrength)
{
  return uvOffset * lerp(saturate(minStrength), 1.0, saturate(depthMask));
}

// 深度感知折射（组合）
// 先按深度缩放 UV 偏移，再重采样并与折射色混合；depthMask 同时作为混合权重
// 因此水面前方的物体（depthMask = 0）保持原样，不会被扭曲或染色
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DepthAwareRefraction</sg:ProviderKey>
///     <sg:DisplayName>Depth Aware Refraction</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>DepthAwareRefraction</sg:SearchName>
///     <sg:SearchTerms>Underwater, Depth, Distortion, Refraction, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "tex">
///     <sg:DisplayName>Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "uvOffset">
///     <sg:DisplayName>UV Offset</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "depthMask">
///     <sg:DisplayName>Depth Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "refrColor">
///     <sg:DisplayName>Refraction Color</sg:DisplayName>
///     <sg:Default>0.6,0.85,1</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 DepthAwareRefraction(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 uvOffset,
  float depthMask,
  float3 refrColor,
  float intensity
)
{
  float2 scaled = ScaleDistortionByDepth(uvOffset, depthMask, 0.2);
  float3 refracted = SAMPLE_TEXTURE2D(tex, samplerState, uv + scaled).rgb * refrColor;
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float w = saturate(intensity) * saturate(depthMask);

  return float4(lerp(original.rgb, refracted, w), original.a);
}

#endif