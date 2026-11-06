#ifndef SHADER_LIBRARY_KAWASE_BLUR
#define SHADER_LIBRARY_KAWASE_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// Kawase Blur 的核心不是“固定核卷积”，而是：每次迭代采样当前像素周围四个角，且偏移随迭代次数递增。
// 所以它通常要在 C# 侧做多次 Blit / Render Graph Pass，每次传入不同的 offset。

// Kawase Blur：单次迭代 Pass
// 对当前像素的四个角采样并平均，偏移由 offset 控制
// 需要在 C# 侧多次 Blit，每次递增 offset，例如 0.5, 1.5, 2.5 ...
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.KawaseBlur</sg:ProviderKey>
///     <sg:DisplayName>Kawase Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>KawaseBlur</sg:SearchName>
///     <sg:SearchTerms>Blur, KawaseBlur, Bloom, PostProcess</sg:SearchTerms>
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
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 KawaseBlur(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float offset
)
{
  float2 d = texelSize * offset;

  float4 c = 0.0;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-d.x, -d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(d.x, -d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-d.x, d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(d.x, d.y));

  return c * 0.25;
}

// Kawase Blur：带中心采样的单次迭代 Pass
// 采样中心像素 + 四个对角偏移像素，共 5 次采样，等权平均
// 需要在 C# 侧多次 Blit / Render Graph Pass，每次传入递增 offset，例如 0.5, 1.5, 2.5 ...
// 相比 4-Tap 版本，中心采样让弱模糊时更稳定，但单次 Pass 多一次采样
// 适合 Bloom、景深、UI 毛玻璃等需要大半径模糊的场景
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.KawaseBlur5Tap</sg:ProviderKey>
///     <sg:DisplayName>Kawase Blur 5-Tap</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>KawaseBlur5Tap</sg:SearchName>
///     <sg:SearchTerms>Blur, KawaseBlur, KawaseBlur5Tap, Bloom, PostProcess</sg:SearchTerms>
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
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 KawaseBlur5Tap(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float offset
)
{
  float2 d = texelSize * offset;

  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-d.x, -d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(d.x, -d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-d.x, d.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(d.x, d.y));

  return c * 0.2;
}

#endif