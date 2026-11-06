#ifndef SHADER_LIBRARY_CROSS_BLUR
#define SHADER_LIBRARY_CROSS_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// Cross Blur：中心 + 上下左右 5 点采样
// 相比 BoxBlur4Tap，只模糊水平轴和垂直轴，不采样对角线
// 适合做十字形模糊、光线交错、UI 交叉虚化
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CrossBlur5Tap</sg:ProviderKey>
///     <sg:DisplayName>Cross Blur 5-Tap</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>CrossBlur5Tap</sg:SearchName>
///     <sg:SearchTerms>Blur, CrossBlur, CrossBlur5Tap</sg:SearchTerms>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 CrossBlur5Tap(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float2 offset = texelSize * radius;

  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-offset.x, 0.0));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(offset.x, 0.0));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -offset.y));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, offset.y));

  return c * 0.2;
}

// Cross Blur 5-Tap 随机偏移版
// 用 seed 做轻微抖动，减少十字采样带来的规则痕迹
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CrossBlur5TapSeeded</sg:ProviderKey>
///     <sg:DisplayName>Cross Blur 5-Tap Seeded</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>CrossBlur5TapSeeded</sg:SearchName>
///     <sg:SearchTerms>Blur, CrossBlur, CrossBlur5TapSeeded</sg:SearchTerms>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 CrossBlur5TapSeeded(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  float seed
)
{
  float s = frac(seed * 0.1031);
  s *= s + 33.33;
  s *= s + s;
  s = frac(s);

  float2 offset = texelSize * radius;
  float2 jitter = (s * 2.0 - 1.0) * offset * 0.5;

  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-offset.x, 0.0) + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(offset.x, 0.0) + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -offset.y) + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, offset.y) + jitter);

  return c * 0.2;
}

// 水平十字模糊：只沿 X 轴采样中心 + 左右各一点
// 3 次采样，等权平均
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CrossBlurHorizontal</sg:ProviderKey>
///     <sg:DisplayName>Cross Blur Horizontal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>CrossBlurHorizontal</sg:SearchName>
///     <sg:SearchTerms>Blur, CrossBlur, Horizontal</sg:SearchTerms>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 CrossBlurHorizontal(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float offset = texelSize.x * radius;

  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-offset, 0.0));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(offset, 0.0));

  return c * (1.0 / 3.0);
}

// 垂直十字模糊：只沿 Y 轴采样中心 + 上下各一点
// 3 次采样，等权平均
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CrossBlurVertical</sg:ProviderKey>
///     <sg:DisplayName>Cross Blur Vertical</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>CrossBlurVertical</sg:SearchName>
///     <sg:SearchTerms>Blur, CrossBlur, Vertical</sg:SearchTerms>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 CrossBlurVertical(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float offset = texelSize.y * radius;

  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -offset));
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, offset));

  return c * (1.0 / 3.0);
}

#endif