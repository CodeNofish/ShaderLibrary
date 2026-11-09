#ifndef SHADER_LIBRARY_BLUE_NOISE_DITHER
#define SHADER_LIBRARY_BLUE_NOISE_DITHER

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Dither/DitherCommon.hlsl"

// 蓝噪声抖动（Blue Noise Dither）
// 采样预烘焙蓝噪声纹理作为阈值源：频域抑制低频、保留高频，颗粒分布极度均匀，
// 无规则条纹或聚集色块，视觉平滑度远优于 Bayer
// 与 Lumen / TSR / TAA 降噪器的数学分布契合，时序累积后收敛更快（UE5 Dithered Opacity 推荐）
// 代价是额外一次纹理采样；blueNoiseTex 需为平铺的单通道蓝噪声，noiseTexelSize 接其 Texel Size

// 静态蓝噪声抖动
// screenPos 为屏幕像素坐标，用 frac(screenPos * noiseTexelSize) 平铺采样；返回 clip 值
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BlueNoiseDither</sg:ProviderKey>
///     <sg:DisplayName>Blue Noise Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BlueNoiseDither</sg:SearchName>
///     <sg:SearchTerms>Dither, BlueNoise, Static, AlphaClip, Texture, Console</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "blueNoiseTex">
///     <sg:DisplayName>Blue Noise Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "noiseTexelSize">
///     <sg:DisplayName>Noise Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BlueNoiseDither(
  UnityTexture2D blueNoiseTex,
  UnitySamplerState samplerState,
  float2 screenPos,
  float2 noiseTexelSize,
  float alpha
)
{
  float2 uv = frac(screenPos * noiseTexelSize);
  float threshold = SAMPLE_TEXTURE2D(blueNoiseTex, samplerState, uv).r;

  return DitherClipValue(alpha, threshold);
}

// 蓝噪声 + TAA/TSR 协同
// 每帧用子像素 Jitter 微移采样坐标，时序累积后达到以假乱真的半透明效果
// 关闭时序抗锯齿会退回粗糙点阵；Dither 材质必须在 TAA Pass 之前渲染并写入深度/速度缓冲
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BlueNoiseDitherTemporal</sg:ProviderKey>
///     <sg:DisplayName>Blue Noise Dither Temporal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BlueNoiseDitherTemporal</sg:SearchName>
///     <sg:SearchTerms>Dither, BlueNoise, Temporal, TAA, TSR, Jitter, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "blueNoiseTex">
///     <sg:DisplayName>Blue Noise Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "noiseTexelSize">
///     <sg:DisplayName>Noise Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "frameIndex">
///     <sg:DisplayName>Frame Index</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "jitterStrength">
///     <sg:DisplayName>Jitter Strength</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BlueNoiseDitherTemporal(
  UnityTexture2D blueNoiseTex,
  UnitySamplerState samplerState,
  float2 screenPos,
  float2 noiseTexelSize,
  float alpha,
  float frameIndex,
  float jitterStrength
)
{
  float2 jitter = DitherTemporalOffset(frameIndex, jitterStrength);
  float2 uv = frac((screenPos + jitter) * noiseTexelSize);
  float threshold = SAMPLE_TEXTURE2D(blueNoiseTex, samplerState, uv).r;

  return DitherClipValue(alpha, threshold);
}

// 蓝噪声 + 逐帧随机
// 每帧注入时间变量使采样完全随机化，适合烟雾、火焰等混沌效果；需强时序滤波收敛
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BlueNoiseDitherRandomized</sg:ProviderKey>
///     <sg:DisplayName>Blue Noise Dither Randomized</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BlueNoiseDitherRandomized</sg:SearchName>
///     <sg:SearchTerms>Dither, BlueNoise, Random, PerFrame, Smoke, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "blueNoiseTex">
///     <sg:DisplayName>Blue Noise Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "noiseTexelSize">
///     <sg:DisplayName>Noise Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BlueNoiseDitherRandomized(
  UnityTexture2D blueNoiseTex,
  UnitySamplerState samplerState,
  float2 screenPos,
  float2 noiseTexelSize,
  float alpha,
  float time
)
{
  float2 jitter = DitherRandomOffset(screenPos, time, 8.0);
  float2 uv = frac((screenPos + jitter) * noiseTexelSize);
  float threshold = SAMPLE_TEXTURE2D(blueNoiseTex, samplerState, uv).r;

  return DitherClipValue(alpha, threshold);
}

#endif