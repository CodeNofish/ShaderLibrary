#ifndef SHADER_LIBRARY_MOTION_BLUR
#define SHADER_LIBRARY_MOTION_BLUR

// sampleCount 应限制为 [1, 16]
#define MOTION_BLUR_SAMPLE_COUNT_HQ 8
#define MOTION_BLUR_SAMPLE_COUNT 4

#include "ShaderApiReflectionSupport.hlsl"

// Motion Blur：沿速度向量做多采样模糊
// velocity 建议使用 NDC 或 UV 空间位移；若是像素位移，需先乘 _ScreenParams.zw
// maxVelocity 用于限制速度向量最大长度，单位与 velocity 一致
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.MotionBlur</sg:ProviderKey>
///     <sg:DisplayName>Motion Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>MotionBlur</sg:SearchName>
///     <sg:SearchTerms>MotionBlur, VelocityBlur, PostProcess, CameraMotionBlur</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.2</sg:Version>
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
///<paramhints name = "velocity">
///     <sg:DisplayName>Velocity</sg:DisplayName>
///</paramhints>
///<paramhints name = "maxVelocity">
///     <sg:DisplayName>Max Velocity</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 MotionBlur(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 velocity,
  float maxVelocity
)
{
  half2 vel = (half2)velocity;
  half len = length(vel);
  half maxVel = max((half)maxVelocity, 1e-4h);

  if (len <= 1e-4h)
    return SAMPLE_TEXTURE2D(tex, samplerState, uv);

  if (len > maxVel)
    vel = normalize(vel) * maxVel;

  float4 color = 0.0;
  half invSamples = 1.0 / max(MOTION_BLUR_SAMPLE_COUNT, 1);
  half halfCount = (MOTION_BLUR_SAMPLE_COUNT - 1) * 0.5;
  
  [unroll]
  for (int i = 0; i < MOTION_BLUR_SAMPLE_COUNT; i++)
  {
    half t = (i - halfCount) / max(halfCount, 1e-4h);
    color += SAMPLE_TEXTURE2D(tex, samplerState, uv + vel * t);
  }

  return color * invSamples;
}

// Motion Blur：沿速度向量做多采样模糊
// velocity 建议使用 NDC 或 UV 空间位移；若是像素位移，需先乘 _ScreenParams.zw
// maxVelocity 用于限制速度向量最大长度，单位与 velocity 一致
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.MotionBlurHQ</sg:ProviderKey>
///     <sg:DisplayName>Motion Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>MotionBlurHQ</sg:SearchName>
///     <sg:SearchTerms>MotionBlurHQ, VelocityBlur, PostProcess, CameraMotionBlur</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.2</sg:Version>
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
///<paramhints name = "velocity">
///     <sg:DisplayName>Velocity</sg:DisplayName>
///</paramhints>
///<paramhints name = "maxVelocity">
///     <sg:DisplayName>Max Velocity</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 MotionBlurHQ(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 velocity,
  float maxVelocity
)
{
  half2 vel = (half2)velocity;
  half len = length(vel);
  half maxVel = max((half)maxVelocity, 1e-4h);

  if (len <= 1e-4h)
    return SAMPLE_TEXTURE2D(tex, samplerState, uv);

  if (len > maxVel)
    vel = normalize(vel) * maxVel;

  float4 color = 0.0;
  half invSamples = 1.0 / max(MOTION_BLUR_SAMPLE_COUNT_HQ, 1);
  half halfCount = (MOTION_BLUR_SAMPLE_COUNT_HQ - 1) * 0.5;
  
  [unroll]
  for (int i = 0; i < MOTION_BLUR_SAMPLE_COUNT_HQ; i++)
  {
    half t = (i - halfCount) / max(halfCount, 1e-4h);
    color += SAMPLE_TEXTURE2D(tex, samplerState, uv + vel * t);
  }

  return color * invSamples;
}


// Motion Blur：带权重衰减的版本
// 中心采样权重更高，边缘更弱，可减轻拖影过散的问题
// weightFalloff 建议 [0, 2]；0 表示等权平均
// maxVelocity 用于限制速度向量最大长度，避免过度模糊
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.MotionBlurWeighted</sg:ProviderKey>
///     <sg:DisplayName>Motion Blur Weighted</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>MotionBlurWeighted</sg:SearchName>
///     <sg:SearchTerms>MotionBlur, VelocityBlur, PostProcess, CameraMotionBlur</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.2</sg:Version>
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
///<paramhints name = "velocity">
///     <sg:DisplayName>Velocity</sg:DisplayName>
///</paramhints>
///<paramhints name = "sampleCount">
///     <sg:DisplayName>Sample Count</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
///<paramhints name = "weightFalloff">
///     <sg:DisplayName>Weight Falloff</sg:DisplayName>
///     <sg:Default>1.0</sg:Default>
///</paramhints>
///<paramhints name = "maxVelocity">
///     <sg:DisplayName>Max Velocity</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 MotionBlurWeighted(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 velocity,
  int sampleCount,
  float weightFalloff,
  float maxVelocity
)
{
  half2 vel = (half2)velocity;
  half len = length(vel);
  half maxVel = max((half)maxVelocity, 1e-4h);

  if (len <= 1e-4h)
    return SAMPLE_TEXTURE2D(tex, samplerState, uv);

  if (len > maxVel)
    vel = normalize(vel) * maxVel;

  float4 color = 0.0;
  half totalWeight = 0.0;
  half invSamples = 1.0 / max(sampleCount, 1);
  half halfCount = (sampleCount - 1) * 0.5;
  half falloff = saturate((half)weightFalloff);

  for (int i = 0; i < sampleCount; i++)
  {
    half t = (i - halfCount) / max(halfCount, 1e-4h);
    half weight = lerp(1.0, 1.0 - saturate(abs(t)), falloff);

    color += SAMPLE_TEXTURE2D(tex, samplerState, uv + vel * t) * weight;
    totalWeight += weight;
  }

  return totalWeight > 1e-4h ? color / totalWeight : color * invSamples;
}

// 通过深度重建屏幕像素速度
// 返回 NDC 空间位移；若用于 UV 偏移，通常还需要乘 0.5，并视平台处理 Y 翻转
// depthTex 应为线性深度或 Z-Buffer 深度，配合 zBufferParams 使用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ComputeMotionVelocityFromDepth</sg:ProviderKey>
///     <sg:DisplayName>Compute Motion Velocity From Depth</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>ComputeMotionVelocityFromDepth</sg:SearchName>
///     <sg:SearchTerms>MotionBlur, Velocity, DepthReconstruction, CameraMotion</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "depthTex">
///     <sg:DisplayName>Depth Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "depthSampler">
///     <sg:DisplayName>Depth Sampler</sg:DisplayName>
///</paramhints>
///<paramhints name = "zBufferParams">
///     <sg:DisplayName>Z Buffer Params</sg:DisplayName>
///</paramhints>
///<paramhints name = "inverseVP">
///     <sg:DisplayName>Inverse View Projection</sg:DisplayName>
///</paramhints>
///<paramhints name = "previousVP">
///     <sg:DisplayName>Previous View Projection</sg:DisplayName>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ComputeMotionVelocityFromDepth(
  float2 uv,
  UnityTexture2D depthTex,
  UnitySamplerState depthSampler,
  float4 zBufferParams,
  float4x4 inverseVP,
  float4x4 previousVP
)
{
  float rawDepth = SAMPLE_DEPTH_TEXTURE(depthTex, depthSampler, uv);
  float linear01 = Linear01Depth(rawDepth, zBufferParams);

  float2 ndc = uv * 2.0 - 1.0;
  float4 clipPos = float4(ndc, linear01, 1.0);

  float4 worldPos = mul(inverseVP, clipPos);
  float invW = rcp(max(abs(worldPos.w), 1e-8));
  worldPos *= invW;

  float4 prevClip = mul(previousVP, worldPos);
  float invPrevW = rcp(max(abs(prevClip.w), 1e-8));
  prevClip *= invPrevW;

  return ndc - prevClip.xy;
}

#endif