#ifndef SHADER_LIBRARY_CONVOLUTION_BLOOM
#define SHADER_LIBRARY_CONVOLUTION_BLOOM

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Bloom/BloomCommon.hlsl"

// 卷积核泛光（Convolution Bloom）
// 使用自定义卷积核在空域卷积，可精确控制光晕形状、产生镜头眩光条纹（Streaks）
// 明暗过渡比 Standard Bloom 更丰富，高强度下仍能保持细节层次（UE5 实践结论），
// 但计算开销显著高于 Standard，适合过场动画、风格化二次元渲染、影视级定制光效
// 本文件用程序化核权重替代 Kernel Texture，便于 ShaderGraph 直接调节光晕形态
// Neural Bloom（2025 arXiv 研究阶段）需神经网络推理，架构与 TAA/TSR 兼容性未披露，此处不实现

// 卷积核权重
// kernelUV 为 [0,1] 核坐标（中心 0.5,0.5），输出该位置的权重
// radius 控制光晕收束，streak 控制沿 direction 的条纹强度
// 可用于生成 Kernel Texture、调试光晕形状，或接入自定义卷积采样
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomKernelWeight</sg:ProviderKey>
///     <sg:DisplayName>Bloom Kernel Weight</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomKernelWeight</sg:SearchName>
///     <sg:SearchTerms>Bloom, Convolution, Kernel, Weight, Streak, Cinematic</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "kernelUV">
///     <sg:DisplayName>Kernel UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "streak">
///     <sg:DisplayName>Streak</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BloomKernelWeight(float2 kernelUV, float radius, float streak, float2 direction)
{
  float2 p = kernelUV * 2.0 - 1.0;
  return BloomKernelWeightCore(p, radius, streak, direction);
}

// 空域卷积泛光
// 以 uv 为中心，在 (2*kernelSize+1)^2 邻域按卷积核权重加权采样
// kernelSize 建议 2~6（4 → 81 次采样）；开销高，仅用于过场或风格化场景
// texelSize 接源纹理 Texel Size；streak > 0 时产生沿 direction 的眩光条纹
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomConvolution</sg:ProviderKey>
///     <sg:DisplayName>Bloom Convolution</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomConvolution</sg:SearchName>
///     <sg:SearchTerms>Bloom, Convolution, Kernel, Streak, Anime, Cinematic, UE5</sg:SearchTerms>
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
///<paramhints name = "streak">
///     <sg:DisplayName>Streak</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "kernelSize">
///     <sg:DisplayName>Kernel Size</sg:DisplayName>
///     <sg:Default>3</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomConvolution(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  float streak,
  float2 direction,
  int kernelSize
)
{
  int k = max(kernelSize, 1);
  float3 sum = 0.0;
  float wsum = 0.0;

  for (int y = -k; y <= k; y++)
  {
    for (int x = -k; x <= k; x++)
    {
      float2 o = float2((float)x, (float)y);
      float2 p = o / (float)k;
      float w = BloomKernelWeightCore(p, radius, streak, direction);
      sum += SAMPLE_TEXTURE2D(tex, samplerState, uv + o * texelSize).rgb * w;
      wsum += w;
    }
  }

  return float4(sum / max(wsum, 1e-4), 1.0);
}

#endif