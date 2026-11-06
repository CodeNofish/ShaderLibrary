#ifndef SHADER_LIBRARY_ZOOM_BLUR
#define SHADER_LIBRARY_ZOOM_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// Zoom Blur：沿“中心 → 当前像素”方向做多步拉伸采样
// strength 建议使用较小的值，例如 0.005 ~ 0.05
// samples 建议 4~12；移动端可降到 4~6
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ZoomBlur</sg:ProviderKey>
///     <sg:DisplayName>Zoom Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>ZoomBlur</sg:SearchName>
///     <sg:SearchTerms>Blur, RadialBlur, ZoomBlur, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ZoomBlur(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength,
  int samples
)
{
  float2 dir = uv - centerUV;

  float sampleCount = max(1.0, (float)samples);
  float2 step = dir * (strength / sampleCount);

  float4 sum = 0.0;

  for (int i = 0; i < samples; i++)
  {
    float2 sampleUV = uv - step * (float)i;
    sum += SAMPLE_TEXTURE2D(tex, samplerState, sampleUV);
  }

  return sum / sampleCount;
}

// Zoom Blur + 强度混合
// intensity = 0 使用原图，1 使用完整 Zoom Blur
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ZoomBlurIntensity</sg:ProviderKey>
///     <sg:DisplayName>Zoom Blur Intensity</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>ZoomBlurIntensity</sg:SearchName>
///     <sg:SearchTerms>Blur, RadialBlur, ZoomBlur, Intensity, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ZoomBlurIntensity(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength,
  int samples,
  float intensity
)
{
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 blurred = ZoomBlur(tex, samplerState, uv, centerUV, strength, samples);
  return lerp(original, blurred, saturate(intensity));
}

#endif