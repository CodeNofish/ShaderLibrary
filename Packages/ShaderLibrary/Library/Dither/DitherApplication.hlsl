#ifndef SHADER_LIBRARY_DITHER_APPLICATION
#define SHADER_LIBRARY_DITHER_APPLICATION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Dither/DitherCommon.hlsl"

// 抖动透明的应用维度与组合增强
// 逐物体抖动透明 / Shadow Caster 同步、全屏后处理、Fresnel / Depth / Color-Matched 增强
// 核心优势：支持延迟渲染光照与阴影、写入深度缓冲、无透明排序问题、兼容 MSAA、开销低于 Alpha Blend
// 局限：只有 0/1 遮罩，无法逐像素多层色彩叠加；未开 TAA/TSR 质量显著下降；
//       移动物体可能产生时序残影（Ghosting）；Shadow Caster 必须同步处理否则阴影与本体矛盾

// 逐物体抖动透明（Per-Object Dither Fade）
// dither 即文档中的 _Dither 参数（0 = 完全丢弃、1 = 完全不透明），返回 clip 值
// 典型用例：第三人称相机穿墙消隐、LOD 过渡淡入淡出、角色受击半透明反馈
// 重要：ShadowCaster Pass 必须同步应用相同的 Dither Clip 逻辑，用 ShadowCasterDither
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.PerObjectDitherFade</sg:ProviderKey>
///     <sg:DisplayName>Per Object Dither Fade</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>PerObjectDitherFade</sg:SearchName>
///     <sg:SearchTerms>Dither, PerObject, Fade, AlphaClip, LOD, CameraOcclusion</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "dither">
///     <sg:DisplayName>Dither</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float PerObjectDitherFade(float2 screenPos, float dither, float size)
{
  return DitherClipValue(dither, DitherBayer(screenPos, size));
}

// Shadow Caster 同步抖动
// 在 ShadowCaster Pass 中用与本体相同的 dither / screenPos / size，避免"本体半透明但阴影完整"
// shadowBias 仅在裁剪边界漏光时做微调，通常保持 0
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ShadowCasterDither</sg:ProviderKey>
///     <sg:DisplayName>Shadow Caster Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>ShadowCasterDither</sg:SearchName>
///     <sg:SearchTerms>Dither, ShadowCaster, Shadow, AlphaClip, Consistency</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "dither">
///     <sg:DisplayName>Dither</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "shadowBias">
///     <sg:DisplayName>Shadow Bias</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float ShadowCasterDither(float2 screenPos, float dither, float size, float shadowBias)
{
  return PerObjectDitherFade(screenPos, saturate(dither + shadowBias), size);
}

// Fresnel + Dither 增强
// 用菲涅尔边缘光调制有效 Alpha：边缘先透明、中心后透明，避免均匀点阵的生硬感
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FresnelDither</sg:ProviderKey>
///     <sg:DisplayName>Fresnel Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>FresnelDither</sg:SearchName>
///     <sg:SearchTerms>Dither, Fresnel, Rim, Enhanced, Fade, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "viewDir">
///     <sg:DisplayName>View Direction</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "fresnelPower">
///     <sg:DisplayName>Fresnel Power</sg:DisplayName>
///     <sg:Default>3</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float FresnelDither(float2 screenPos, float alpha, float3 normal, float3 viewDir, float fresnelPower, float size)
{
  float ndv = saturate(dot(normalize(normal), normalize(viewDir)));
  float rim = pow(saturate(1.0 - ndv), max(fresnelPower, 0.001));
  float effective = alpha * (1.0 - rim);

  return DitherClipValue(effective, DitherBayer(screenPos, size));
}

// Depth-Based Dither 增强
// 按物体与相机的距离动态调整 dither 强度：近处完全不透明，远处逐渐抖动消散
// 用于 LOD 无缝过渡，避免 popping；distance 为到相机的距离
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DepthBasedDither</sg:ProviderKey>
///     <sg:DisplayName>Depth Based Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>DepthBasedDither</sg:SearchName>
///     <sg:SearchTerms>Dither, Depth, Distance, LOD, Enhanced, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "nearDistance">
///     <sg:DisplayName>Near Distance</sg:DisplayName>
///     <sg:Default>5</sg:Default>
///</paramhints>
///<paramhints name = "farDistance">
///     <sg:DisplayName>Far Distance</sg:DisplayName>
///     <sg:Default>20</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DepthBasedDither(float2 screenPos, float alpha, float distance, float nearDistance, float farDistance, float size)
{
  float end = max(farDistance, nearDistance + 1e-4);
  float near = 1.0 - smoothstep(nearDistance, end, distance);
  float effective = lerp(alpha, 1.0, near);

  return DitherClipValue(effective, DitherBayer(screenPos, size));
}

// 全屏抖动后处理（Full-Screen Dither Post-Process）
// 对整屏颜色做色深量化并叠加 Bayer 抖动，不修改任何物体材质
// 典型用例：复古 CRT/GB 风格滤镜、热成像/夜视等感知模式、全局色彩深度降级模拟
// levels 为每通道量化级数（如 GB 风格取 4），screenPos 为屏幕像素坐标
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FullScreenDither</sg:ProviderKey>
///     <sg:DisplayName>Full Screen Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>FullScreenDither</sg:SearchName>
///     <sg:SearchTerms>Dither, FullScreen, PostProcess, Quantization, CRT, Retro</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneTex">
///     <sg:DisplayName>Scene Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "levels">
///     <sg:DisplayName>Levels</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 FullScreenDither(
  UnityTexture2D sceneTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 screenPos,
  float levels,
  float size
)
{
  float4 c = SAMPLE_TEXTURE2D(sceneTex, samplerState, uv);
  float n = max(floor(levels), 2.0);
  float noise = (DitherBayer(screenPos, size) - 0.5) / n;

  return float4(DitherQuantize3(c.rgb + noise, levels), c.a);
}

// Color-Matched Dither 增强（后处理配合）
// 对被丢弃的像素用 4 邻域平均色替代，让抖动丢弃的像素参与周围像素的平均计算，
// 减少透明度变化时的亮度跳变；keepMask 由 DitherKeepMask 从 clip 值生成
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ColorMatchedDither</sg:ProviderKey>
///     <sg:DisplayName>Color Matched Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>ColorMatchedDither</sg:SearchName>
///     <sg:SearchTerms>Dither, ColorMatched, Average, Enhanced, PostProcess</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneTex">
///     <sg:DisplayName>Scene Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "keepMask">
///     <sg:DisplayName>Keep Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ColorMatchedDither(
  UnityTexture2D sceneTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float keepMask
)
{
  float2 t = texelSize;
  float4 c = SAMPLE_TEXTURE2D(sceneTex, samplerState, uv);
  float3 avg = c.rgb;
  avg += SAMPLE_TEXTURE2D(sceneTex, samplerState, uv + t * float2(1.0, 0.0)).rgb;
  avg += SAMPLE_TEXTURE2D(sceneTex, samplerState, uv + t * float2(-1.0, 0.0)).rgb;
  avg += SAMPLE_TEXTURE2D(sceneTex, samplerState, uv + t * float2(0.0, 1.0)).rgb;
  avg += SAMPLE_TEXTURE2D(sceneTex, samplerState, uv + t * float2(0.0, -1.0)).rgb;
  avg *= 0.2;

  return float4(lerp(avg, c.rgb, saturate(keepMask)), c.a);
}

// clip 值 → 0/1 保留遮罩（> 0 保留）
// 供 ColorMatchedDither 或后处理混合使用；把任一 Dither 函数的输出接入即可
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DitherKeepMask</sg:ProviderKey>
///     <sg:DisplayName>Dither Keep Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>DitherKeepMask</sg:SearchName>
///     <sg:SearchTerms>Dither, Mask, Clip, Step, Keep, Binary</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "clipValue">
///     <sg:DisplayName>Clip Value</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DitherKeepMask(float clipValue)
{
  return step(0.0, clipValue);
}

#endif