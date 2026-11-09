#ifndef SHADER_LIBRARY_RGB_SPLIT
#define SHADER_LIBRARY_RGB_SPLIT

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Glitch/GlitchCommon.hlsl"

// RGB Split / Color Shift Glitch：Glitch 艺术最基础的子类
// 对 R、G、B 使用不同 UV 采样并重组，产生红/青、绿/紫的错位重影
// 与 ChromaticAberration 的区别：这里是方向性、离散且可随机的偏移，而非径向对称的镜头缺陷

// 方向型 RGB 分离
// direction 为分离方向，默认 (1,0) 即水平分离；amount 为 UV 空间偏移，建议 0 ~ 0.02
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RgbSplit</sg:ProviderKey>
///     <sg:DisplayName>RGB Split</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>RgbSplit</sg:SearchName>
///     <sg:SearchTerms>Glitch, RGBSplit, RGB Split, ColorShift, ChromaticAberration, PostEffect</sg:SearchTerms>
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
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 RgbSplit(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 direction,
  float amount
)
{
  float2 offset = direction * amount;

  float r = SAMPLE_TEXTURE2D(tex, samplerState, uv + offset).r;
  float4 g = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float b = SAMPLE_TEXTURE2D(tex, samplerState, uv - offset).b;

  return float4(r, g.g, b, g.a);
}

// 随机抖动型 RGB 分离
// seed 变化时分离方向与幅度随机翻转，模拟信号丢失导致的离散色偏
// 把 Time（或量化后的时间）连到 seed 即可得到逐帧跳动的故障重影
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RgbSplitSeeded</sg:ProviderKey>
///     <sg:DisplayName>RGB Split Seeded</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>RgbSplitSeeded</sg:SearchName>
///     <sg:SearchTerms>Glitch, RGBSplit, Seeded, Random, Jitter, PostEffect</sg:SearchTerms>
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
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 RgbSplitSeeded(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 direction,
  float amount,
  float seed
)
{
  float2 rnd = GlitchHash22(float2(seed, seed * 1.37));
  float flip = step(0.5, rnd.x) * 2.0 - 1.0;
  float2 jitter = (rnd * 2.0 - 1.0);
  float2 offset = (direction * flip + jitter * 0.5) * amount;

  float r = SAMPLE_TEXTURE2D(tex, samplerState, GlitchWrapUV(uv + offset)).r;
  float4 g = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float b = SAMPLE_TEXTURE2D(tex, samplerState, GlitchWrapUV(uv - offset)).b;

  return float4(r, g.g, b, g.a);
}

// RGB 分离 + 强度混合
// intensity = 0 使用原图，1 使用完整分离；适合受击、黑客入侵、传送等反馈做脉冲动画
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RgbSplitIntensity</sg:ProviderKey>
///     <sg:DisplayName>RGB Split Intensity</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>RgbSplitIntensity</sg:SearchName>
///     <sg:SearchTerms>Glitch, RGBSplit, Intensity, Damage, Hacking, Teleport, PostEffect</sg:SearchTerms>
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
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 RgbSplitIntensity(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 direction,
  float amount,
  float intensity
)
{
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 split = RgbSplit(tex, samplerState, uv, direction, amount);
  return lerp(original, split, saturate(intensity));
}

#endif