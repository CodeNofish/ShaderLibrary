#ifndef SHADER_LIBRARY_GAUSSIAN_BLUR
#define SHADER_LIBRARY_GAUSSIAN_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// 二维高斯核是“可分离”的，拆成两次一维卷积后，采样次数从 N² 降到 2N，效果一样，但便宜很多。
// 缓存友好
// RT复用方便

// 水平高斯模糊：5-tap 高斯核，拆成 3 次线性采样
// 权重：1 : 4 : 6 : 4 : 1，总和 16
// 与 BoxBlurVertical 配合使用，实现可分离高斯模糊
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GaussianBlurHorizontal</sg:ProviderKey>
///     <sg:DisplayName>Gaussian Blur Horizontal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>GaussianBlurHorizontal</sg:SearchName>
///     <sg:SearchTerms>Blur, GaussianBlur, Horizontal, Separable</sg:SearchTerms>
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
float4 GaussianBlurHorizontal(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float step = texelSize.x * radius;

  float4 c0 = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 c1 = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(step * 0.5, 0.0));
  float4 c2 = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(step * 1.5, 0.0));

  // 6/16 * c0 + 4/16 * (左右合并) + 2/16 * (远端合并)
  return c0 * 0.375 + c1 * 0.25 + c2 * 0.125;
}

// 垂直高斯模糊：5-tap 高斯核，拆成 3 次线性采样
// 权重：1 : 4 : 6 : 4 : 1，总和 16
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GaussianBlurVertical</sg:ProviderKey>
///     <sg:DisplayName>Gaussian Blur Vertical</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>GaussianBlurVertical</sg:SearchName>
///     <sg:SearchTerms>Blur, GaussianBlur, Vertical, Separable</sg:SearchTerms>
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
float4 GaussianBlurVertical(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float step = texelSize.y * radius;

  float4 c0 = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 c1 = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, step * 0.5));
  float4 c2 = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, step * 1.5));

  return c0 * 0.375 + c1 * 0.25 + c2 * 0.125;
}

#endif