#ifndef SHADER_LIBRARY_BLOOM_DOWNSAMPLE
#define SHADER_LIBRARY_BLOOM_DOWNSAMPLE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Bloom/BloomCommon.hlsl"

// 降采样模糊：逐级把纹理分辨率减半（Half → Quarter → ...）
// 用双线性 / 三次滤波的自然模糊特性代替显式高斯核，大幅降低采样开销
// URP Downscale 控制初始分辨率，HDRP 提供 Quarter/Half 选项适配 4K 主机（管线侧参数）
// Standard Bloom 使用可分离高斯或双线性降采样近似高斯，多次迭代累积
// High Quality Filtering 启用 Bicubic 改善平滑度，但低端设备应禁用以避免块状伪影

// 4 采样双线性降采样（Box / Bilinear）
// 在相邻纹素中心取 4 点平均，等价于一次 2x 降采样 + 双线性滤波
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomDownsampleBox</sg:ProviderKey>
///     <sg:DisplayName>Bloom Downsample Box</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomDownsampleBox</sg:SearchName>
///     <sg:SearchTerms>Bloom, Downsample, Bilinear, Box, 4Tap, Mip</sg:SearchTerms>
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
UNITY_EXPORT_REFLECTION
float4 BloomDownsampleBox(UnityTexture2D tex, UnitySamplerState samplerState, float2 uv, float2 texelSize)
{
  float2 t = texelSize * 0.5;
  float3 c = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-t.x, -t.y)).rgb;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(t.x, -t.y)).rgb;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-t.x, t.y)).rgb;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(t.x, t.y)).rgb;

  return float4(c * 0.25, 1.0);
}

// Bicubic 降采样（Catmull-Rom，16 采样）
// High Quality Filtering 路径：比双线性更平滑，减少块状伪影；开销显著更高，低端设备建议禁用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomDownsampleBicubic</sg:ProviderKey>
///     <sg:DisplayName>Bloom Downsample Bicubic</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomDownsampleBicubic</sg:SearchName>
///     <sg:SearchTerms>Bloom, Downsample, Bicubic, CatmullRom, HighQuality, 16Tap</sg:SearchTerms>
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
UNITY_EXPORT_REFLECTION
float4 BloomDownsampleBicubic(UnityTexture2D tex, UnitySamplerState samplerState, float2 uv, float2 texelSize)
{
  float2 t = max(texelSize, float2(1e-6, 1e-6));
  float2 p = uv / t - 0.5;
  float2 base = floor(p);
  float2 f = p - base;

  float3 sum = 0.0;
  float wsum = 0.0;

  for (int y = -1; y <= 2; y++)
  {
    for (int x = -1; x <= 2; x++)
    {
      float w = BloomCatmullRom((float)x - f.x) * BloomCatmullRom((float)y - f.y);
      float2 suv = (base + float2((float)x, (float)y) + 0.5) * t;
      sum += SAMPLE_TEXTURE2D(tex, samplerState, suv).rgb * w;
      wsum += w;
    }
  }

  return float4(sum / max(wsum, 1e-4), 1.0);
}

// 可分离高斯模糊（Standard Bloom 的 SeparableBlur 单 Pass）
// direction 传 (1,0) 或 (0,1)，两个 Pass 组合成一次二维高斯
// radius 为纹素倍数，samples 建议 4~12；移动端取小值
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomSeparableGaussian</sg:ProviderKey>
///     <sg:DisplayName>Bloom Separable Gaussian</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomSeparableGaussian</sg:SearchName>
///     <sg:SearchTerms>Bloom, Gaussian, SeparableBlur, Standard, Blur</sg:SearchTerms>
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
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomSeparableGaussian(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float2 direction,
  float radius,
  int samples
)
{
  float2 stepUV = direction * texelSize * max(radius, 0.0);
  float sigma = max((float)samples * 0.5, 1e-4);
  float center = (float)(samples - 1) * 0.5;
  float4 sum = 0.0;
  float wsum = 0.0;

  for (int i = 0; i < samples; i++)
  {
    float t = (float)i - center;
    float w = BloomGaussianWeight(t, sigma);
    sum += SAMPLE_TEXTURE2D(tex, samplerState, uv + stepUV * t) * w;
    wsum += w;
  }

  return sum / max(wsum, 1e-4);
}

// 水平方向可分离高斯（SeparableBlur 第一 Pass）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomSeparableHorizontal</sg:ProviderKey>
///     <sg:DisplayName>Bloom Separable Horizontal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomSeparableHorizontal</sg:SearchName>
///     <sg:SearchTerms>Bloom, Gaussian, SeparableBlur, Horizontal, Standard</sg:SearchTerms>
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
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomSeparableHorizontal(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  int samples
)
{
  return BloomSeparableGaussian(tex, samplerState, uv, texelSize, float2(1.0, 0.0), radius, samples);
}

// 垂直方向可分离高斯（SeparableBlur 第二 Pass）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomSeparableVertical</sg:ProviderKey>
///     <sg:DisplayName>Bloom Separable Vertical</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomSeparableVertical</sg:SearchName>
///     <sg:SearchTerms>Bloom, Gaussian, SeparableBlur, Vertical, Standard</sg:SearchTerms>
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
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomSeparableVertical(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  int samples
)
{
  return BloomSeparableGaussian(tex, samplerState, uv, texelSize, float2(0.0, 1.0), radius, samples);
}

#endif