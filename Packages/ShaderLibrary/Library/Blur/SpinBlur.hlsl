#ifndef SHADER_LIBRARY_SPIN_BLUR
#define SHADER_LIBRARY_SPIN_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// 把 UV 绕 centerUV 旋转 angle 弧度
static float2 RotateUV(float2 uv, float2 centerUV, float angle)
{
  float s = sin(angle);
  float c = cos(angle);

  float2 p = uv - centerUV;
  float2 rotated = float2(
    p.x * c - p.y * s,
    p.x * s + p.y * c
  );

  return rotated + centerUV;
}

// Spin Blur：围绕中心点做多步旋转采样
// angle 单位是弧度；例如 10° ≈ 0.1745
// samples 建议 6~16；移动端可降到 4~8
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SpinBlur</sg:ProviderKey>
///     <sg:DisplayName>Spin Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>SpinBlur</sg:SearchName>
///     <sg:SearchTerms>Blur, SpinBlur, RadialBlur, RotationalBlur, PostEffect</sg:SearchTerms>
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
///<paramhints name = "angle">
///     <sg:DisplayName>Angle (Radians)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 SpinBlur(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float angle,
  int samples
)
{
  float sampleCount = max(1.0, (float)samples);
  float perStep = angle / sampleCount;

  float4 sum = 0.0;

  for (int i = 0; i < samples; i++)
  {
    float a = perStep * (float)i;
    float2 sampleUV = RotateUV(uv, centerUV, a);
    sum += SAMPLE_TEXTURE2D(tex, samplerState, sampleUV);
  }

  return sum / sampleCount;
}

// Spin Blur + 强度混合
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SpinBlurIntensity</sg:ProviderKey>
///     <sg:DisplayName>Spin Blur Intensity</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>SpinBlurIntensity</sg:SearchName>
///     <sg:SearchTerms>Blur, SpinBlur, RotationalBlur, Intensity, PostEffect</sg:SearchTerms>
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
///<paramhints name = "angle">
///     <sg:DisplayName>Angle (Radians)</sg:DisplayName>
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
float4 SpinBlurIntensity(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float angle,
  int samples,
  float intensity
)
{
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 blurred = SpinBlur(tex, samplerState, uv, centerUV, angle, samples);
  return lerp(original, blurred, saturate(intensity));
}

#endif