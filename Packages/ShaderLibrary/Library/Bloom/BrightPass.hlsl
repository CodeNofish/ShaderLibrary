#ifndef SHADER_LIBRARY_BRIGHT_PASS
#define SHADER_LIBRARY_BRIGHT_PASS

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Bloom/BloomCommon.hlsl"

// 亮度提取（Bright Pass）：仅保留超过阈值的亮部像素作为泛光源
// Threshold + Knee 控制软过渡，避免硬截断导致的闪烁
// HDRP 的 High Quality Prefiltering 用 13 采样替代 4 采样，减少太阳等小光源闪烁
// 调参警告：Threshold > 0 会破坏能量守恒；艺术化提亮应优先用 Tint / Intensity

// 软阈值亮度提取
// threshold 建议 0~2（HDR），knee 建议 0.1~0.5；tint 用于给泛光层染色
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomThreshold</sg:ProviderKey>
///     <sg:DisplayName>Bloom Threshold</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomThreshold</sg:SearchName>
///     <sg:SearchTerms>Bloom, Glow, BrightPass, Threshold, Knee, Prefilter</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "knee">
///     <sg:DisplayName>Knee</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 BloomThreshold(float3 color, float threshold, float knee, float3 tint)
{
  float brightness = max(color.r, max(color.g, color.b));
  return color * BloomKneeCurve(brightness, threshold, knee) * tint;
}

// High Quality Prefiltering（13 采样）
// 3x3 邻域 + 4 个远点共 13 次采样，用 Karis Average（权重 1/(1+luma)）抑制小光源火点闪烁
// 之后再应用 Threshold + Knee；texelSize 接源纹理的 Texel Size
// 开销高于 4 采样版本，适合高光源密度或高动态范围场景
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomPrefilterHighQuality</sg:ProviderKey>
///     <sg:DisplayName>Bloom Prefilter High Quality</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomPrefilterHighQuality</sg:SearchName>
///     <sg:SearchTerms>Bloom, BrightPass, Prefilter, HighQuality, 13Tap, Karis</sg:SearchTerms>
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
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "knee">
///     <sg:DisplayName>Knee</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomPrefilterHighQuality(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float threshold,
  float knee,
  float3 tint
)
{
  float2 t = texelSize;
  float3 sum = 0.0;
  float wsum = 0.0;

  for (int y = -1; y <= 1; y++)
  {
    for (int x = -1; x <= 1; x++)
    {
      float3 c = SAMPLE_TEXTURE2D(tex, samplerState, uv + t * float2((float)x, (float)y)).rgb;
      float w = 1.0 / (1.0 + BloomLuma(c));
      sum += c * w;
      wsum += w;
    }
  }

  for (int i = 0; i < 4; i++)
  {
    float angle = (float)i * 1.5707963;
    float2 o = float2(cos(angle), sin(angle)) * 2.0;
    float3 c = SAMPLE_TEXTURE2D(tex, samplerState, uv + t * o).rgb;
    float w = 1.0 / (1.0 + BloomLuma(c));
    sum += c * w;
    wsum += w;
  }

  float3 avg = sum / max(wsum, 1e-4);
  return float4(BloomThreshold(avg, threshold, knee, tint), 1.0);
}

#endif