#ifndef SHADER_LIBRARY_DUAL_KAWASE_BLUR
#define SHADER_LIBRARY_DUAL_KAWASE_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// Dual Kawase Blur Downsample
// 降采样并施加 Kawase 偏移，输出 1/2 分辨率纹理
// 每次迭代 offset 递增 2.0，例如 0.5, 2.5, 4.5 ...
// tex 为当前较高分辨率输入，uv 为输出像素 UV，texelSize 为输入纹理的像素大小
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DualKawaseBlurDownsample</sg:ProviderKey>
///     <sg:DisplayName>Dual Kawase Blur Downsample</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>DualKawaseBlurDownsample</sg:SearchName>
///     <sg:SearchTerms>Blur, DualBlur, KawaseBlur, Downsample, Bloom, PostProcess</sg:SearchTerms>
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
float4 DualKawaseBlurDownsample(
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

// Dual Kawase Blur Upsample
// 升采样低分辨率模糊结果，并叠加上一级高分辨率纹理
// 每次迭代 offset 递减 2.0，例如 ..., 4.5, 2.5, 0.5
// lowRes 为低分辨率模糊纹理，highRes 为上一级高分辨率纹理
// lowResTexelSize 为低分辨率纹理的像素大小
// 该版本适合 Bloom 金字塔融合；如果只需要纯模糊，可去掉 highRes 叠加
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DualKawaseBlurUpsample</sg:ProviderKey>
///     <sg:DisplayName>Dual Kawase Blur Upsample</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>DualKawaseBlurUpsample</sg:SearchName>
///     <sg:SearchTerms>Blur, DualBlur, KawaseBlur, Upsample, Bloom, PostProcess</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "lowRes">
///     <sg:DisplayName>Low Resolution Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "highRes">
///     <sg:DisplayName>High Resolution Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "lowResTexelSize">
///     <sg:DisplayName>Low Res Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>1.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 DualKawaseBlurUpsample(
  UnityTexture2D lowRes,
  UnityTexture2D highRes,
  UnitySamplerState samplerState,
  float2 uv,
  float2 lowResTexelSize,
  float offset
)
{
  float2 d = lowResTexelSize * offset;

  float4 c = 0.0;
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(-d.x, -d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(d.x, -d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(-d.x, d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(d.x, d.y));

  c *= 0.25;
  c += SAMPLE_TEXTURE2D(highRes, samplerState, uv);

  return c;
}

// Dual Kawase Blur Upsample（纯模糊版）
// 仅对低分辨率结果升采样并继续模糊，不叠加高分辨率纹理
// 适合纯毛玻璃、全屏模糊等不需要金字塔融合的场景
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DualKawaseBlurUpsamplePure</sg:ProviderKey>
///     <sg:DisplayName>Dual Kawase Blur Upsample Pure</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>DualKawaseBlurUpsamplePure</sg:SearchName>
///     <sg:SearchTerms>Blur, DualBlur, KawaseBlur, Upsample, Bloom, PostProcess</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "lowRes">
///     <sg:DisplayName>Low Resolution Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "lowResTexelSize">
///     <sg:DisplayName>Low Res Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>1.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 DualKawaseBlurUpsamplePure(
  UnityTexture2D lowRes,
  UnitySamplerState samplerState,
  float2 uv,
  float2 lowResTexelSize,
  float offset
)
{
  float2 d = lowResTexelSize * offset;

  float4 c = 0.0;
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(-d.x, -d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(d.x, -d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(-d.x, d.y));
  c += SAMPLE_TEXTURE2D(lowRes, samplerState, uv + float2(d.x, d.y));

  return c * 0.25;
}

#endif // SHADER_LIBRARY_DUAL_KAWASE_BLUR