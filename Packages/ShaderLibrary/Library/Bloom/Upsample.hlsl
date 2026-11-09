#ifndef SHADER_LIBRARY_BLOOM_UPSAMPLE
#define SHADER_LIBRARY_BLOOM_UPSAMPLE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Bloom/BloomCommon.hlsl"

// 上采样混合（Progressive Blur + Add）
// 从最小 Mip 逐级向上采样回高分辨率，每级叠加当前层模糊结果：D' = D + blur(E', radius)
// 半径随 Mip 层级递增，模拟多尺度高斯累积；Scatter 控制散射范围
// URP Max Iterations 限制最大迭代次数以优化移动端性能（管线侧参数）
// URP 建议移动端 Scatter ≤ 0.5

// 3x3 Tent 上采样滤波（9 采样）
// radius 为纹素空间半径，建议由 BloomTexelSpaceRadius 按 Mip 层级计算
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomUpsampleTent</sg:ProviderKey>
///     <sg:DisplayName>Bloom Upsample Tent</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomUpsampleTent</sg:SearchName>
///     <sg:SearchTerms>Bloom, Upsample, Tent, Progressive, Mip, 9Tap</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "lowTex">
///     <sg:DisplayName>Low Mip Texture</sg:DisplayName>
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
UNITY_EXPORT_REFLECTION
float4 BloomUpsampleTent(
  UnityTexture2D lowTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float2 t = texelSize * max(radius, 0.0);
  float4 sum = SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(-1.0, -1.0));
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(0.0, -1.0)) * 2.0;
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(1.0, -1.0));
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(-1.0, 0.0)) * 2.0;
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv) * 4.0;
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(1.0, 0.0)) * 2.0;
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(-1.0, 1.0));
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(0.0, 1.0)) * 2.0;
  sum += SAMPLE_TEXTURE2D(lowTex, samplerState, uv + t * float2(1.0, 1.0));

  return sum / 16.0;
}

// 物理正确泛光的纹素空间半径
// 上采样时使用纹素空间半径而非固定像素半径，使模糊尺度随 Mip 层级指数增长，
// 确保能量守恒与跨分辨率视觉一致性（HDRP energy-conserving 要求物理光照单位）
// mipLevel 为当前金字塔层级，scatter 建议 0~0.7（移动端 ≤ 0.5）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomTexelSpaceRadius</sg:ProviderKey>
///     <sg:DisplayName>Bloom Texel Space Radius</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomTexelSpaceRadius</sg:SearchName>
///     <sg:SearchTerms>Bloom, PhysicallyBased, TexelSpace, Radius, EnergyConserving, Mip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "mipLevel">
///     <sg:DisplayName>Mip Level</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "scatter">
///     <sg:DisplayName>Scatter</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BloomTexelSpaceRadius(float mipLevel, float scatter)
{
  return BloomTexelRadius(mipLevel, scatter);
}

// 渐进上采样混合：D' = D + blur(E', radius) 的加法与 Scatter 缩放
// currentMip 为当前层金字塔颜色，upsampledMip 为下层经 BloomUpsampleTent 模糊后的颜色
// 采样由上游节点完成，避免多 Pass 函数依赖两张 Mip 纹理的同时绑定
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomProgressiveUpsample</sg:ProviderKey>
///     <sg:DisplayName>Bloom Progressive Upsample</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomProgressiveUpsample</sg:SearchName>
///     <sg:SearchTerms>Bloom, Upsample, Progressive, Scatter, Add, Cascade</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "currentMip">
///     <sg:DisplayName>Current Mip</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "upsampledMip">
///     <sg:DisplayName>Upsampled Mip</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "scatter">
///     <sg:DisplayName>Scatter</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 BloomProgressiveUpsample(float3 currentMip, float3 upsampledMip, float scatter)
{
  return currentMip + upsampledMip * max(scatter, 0.0);
}

#endif