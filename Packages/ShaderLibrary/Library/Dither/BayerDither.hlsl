#ifndef SHADER_LIBRARY_BAYER_DITHER
#define SHADER_LIBRARY_BAYER_DITHER

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Dither/DitherCommon.hlsl"

// Bayer 有序抖动（Ordered Dither）
// 用 4x4 / 8x8 预定义阈值矩阵，按屏幕像素坐标取模索引，与 Alpha 比较后 clip
// 零纹理带宽、纯 ALU，Unity Shader Graph Dither 节点默认采用此算法；
// 局限是规则网格状斜纹与阶梯感，适合移动端、植被/铁丝网等本身带颗粒结构的物体
// 时序机制：静态（每帧相同图案）/ TAA-TSR 协同（子像素 Jitter）/ 逐帧随机（注入时间）

// 4x4 / 8x8 Bayer 阈值
// screenPos 接屏幕像素坐标（Screen Position 的 xy），size 传 4 或 8；返回 [0,1)
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BayerThreshold</sg:ProviderKey>
///     <sg:DisplayName>Bayer Threshold</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BayerThreshold</sg:SearchName>
///     <sg:SearchTerms>Dither, Bayer, Ordered, Matrix, Threshold, ScreenPos</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BayerThreshold(float2 screenPos, float size)
{
  return DitherBayer(screenPos, size);
}

// 静态抖动（Static Dither）
// 每帧使用相同的 Bayer 图案，不做时序混合；近距可见点阵、运动时有闪烁与摩尔纹
// 适合固定视角、低分辨率复古风格或调试基准；返回 clip 值（> 0 保留）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BayerDither</sg:ProviderKey>
///     <sg:DisplayName>Bayer Dither</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BayerDither</sg:SearchName>
///     <sg:SearchTerms>Dither, Bayer, Static, AlphaClip, Transparency, Mobile</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BayerDither(float2 screenPos, float alpha, float size)
{
  return DitherClipValue(alpha, DitherBayer(screenPos, size));
}

// 时序抗锯齿协同抖动（Temporal Dither + TAA/TSR）
// 用低差异序列让每帧图案在屏幕空间微偏移，TAA/TSR 历史帧累积后融合为平滑半透明渐变
// 关键约束：Dither 材质必须在 TAA Pass 之前渲染并写入深度/速度缓冲，否则时序累积失效
// frameIndex 接帧序号或 TAA Jitter 索引，jitterStrength 建议 0.5~2 像素
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BayerDitherTemporal</sg:ProviderKey>
///     <sg:DisplayName>Bayer Dither Temporal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BayerDitherTemporal</sg:SearchName>
///     <sg:SearchTerms>Dither, Bayer, Temporal, TAA, TSR, Jitter, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
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
float BayerDitherTemporal(float2 screenPos, float alpha, float size, float frameIndex, float jitterStrength)
{
  float2 jitter = DitherTemporalOffset(frameIndex, jitterStrength);
  return DitherClipValue(alpha, DitherBayer(screenPos + jitter, size));
}

// 逐帧随机抖动（Per-Frame Randomized Dither）
// 每帧向采样坐标注入时间变量使图案完全随机，消除静态网格感但引入高频闪烁
// 需强时序滤波器才能收敛，适合烟雾、火焰等本身具混沌特性的粒子/体积效果
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BayerDitherRandomized</sg:ProviderKey>
///     <sg:DisplayName>Bayer Dither Randomized</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>BayerDitherRandomized</sg:SearchName>
///     <sg:SearchTerms>Dither, Bayer, Random, PerFrame, Smoke, Fire, AlphaClip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float BayerDitherRandomized(float2 screenPos, float alpha, float size, float time)
{
  float2 jitter = DitherRandomOffset(screenPos, time, 4.0);
  return DitherClipValue(alpha, DitherBayer(screenPos + jitter, size));
}

#endif