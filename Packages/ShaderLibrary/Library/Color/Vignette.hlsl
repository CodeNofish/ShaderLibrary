#ifndef SHADER_LIBRARY_VIGNETTE
#define SHADER_LIBRARY_VIGNETTE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Color/Common.hlsl"

// Vignette（暗角 / 晕影）
// 程序化暗角：实时计算像素到中心的欧氏距离，用 pow(saturate(1 - dist²), smoothness) 生成径向渐变
// 蒙版暗角：采样外部纹理作为遮罩，支持星形、不规则边框、复古取景器等任意形状
// 执行顺序：应在 Bloom 之前执行，先暗化边缘再做泛光，避免光晕在边缘被截断产生断层

// 程序化暗角遮罩
// 返回亮度乘数：中心为 1，边缘逐渐降低；intensity = 0 无暗角
// smoothness 控制过渡（建议 0.2~2），roundness 0 圆形、1 矩形
// center 可偏移聚焦中心，aspect 填屏幕宽高比（如 1.7778）以保持圆形
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.VignetteMask</sg:ProviderKey>
///     <sg:DisplayName>Vignette Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Vignette</sg:SearchCategory>
///     <sg:SearchName>VignetteMask</sg:SearchName>
///     <sg:SearchTerms>Vignette, Mask, Radial, Smoothness, Roundness, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "center">
///     <sg:DisplayName>Center</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "smoothness">
///     <sg:DisplayName>Smoothness</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "roundness">
///     <sg:DisplayName>Roundness</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "aspect">
///     <sg:DisplayName>Aspect</sg:DisplayName>
///     <sg:Default>1.7778</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float VignetteMask(float2 uv, float2 center, float intensity, float smoothness, float roundness, float aspect)
{
  float falloff = ColorVignetteFalloff(uv, center, smoothness, roundness, aspect);
  return lerp(1.0, falloff, saturate(intensity));
}

// 程序化暗角（Procedural Vignette）
// 参数含义同 VignetteMask，一次调用完成采样 + 边缘压暗
// 约 0.3ms @1080p，适合常规视线聚焦引导
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ProceduralVignette</sg:ProviderKey>
///     <sg:DisplayName>Procedural Vignette</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Vignette</sg:SearchCategory>
///     <sg:SearchName>ProceduralVignette</sg:SearchName>
///     <sg:SearchTerms>Vignette, Procedural, Radial, Focus, PostEffect</sg:SearchTerms>
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
///<paramhints name = "center">
///     <sg:DisplayName>Center</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "smoothness">
///     <sg:DisplayName>Smoothness</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "roundness">
///     <sg:DisplayName>Roundness</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "aspect">
///     <sg:DisplayName>Aspect</sg:DisplayName>
///     <sg:Default>1.7778</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ProceduralVignette(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 center,
  float intensity,
  float smoothness,
  float roundness,
  float aspect
)
{
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float mask = VignetteMask(uv, center, intensity, smoothness, roundness, aspect);

  return float4(c.rgb * mask, c.a);
}

// 蒙版暗角（Masked Vignette）
// mask 由上游 Sample Texture2D 节点采样遮罩纹理得到（白 = 保留画面，黑 = 完全暗角）
// vignetteColor 可设为黑色之外的颜色，用于艺术化效果、复古取景器、UI 聚焦
// 相比程序化版本增加一次纹理采样与内存带宽开销
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.MaskedVignette</sg:ProviderKey>
///     <sg:DisplayName>Masked Vignette</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Vignette</sg:SearchCategory>
///     <sg:SearchName>MaskedVignette</sg:SearchName>
///     <sg:SearchTerms>Vignette, Masked, Mask, Texture, Artistic, PostEffect</sg:SearchTerms>
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
///<paramhints name = "mask">
///     <sg:DisplayName>Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "vignetteColor">
///     <sg:DisplayName>Vignette Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 MaskedVignette(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float mask,
  float intensity,
  float3 vignetteColor
)
{
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float m = lerp(1.0, saturate(mask), saturate(intensity));

  return float4(lerp(vignetteColor, c.rgb, m), c.a);
}

#endif