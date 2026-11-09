#ifndef SHADER_LIBRARY_TEMPORAL_DITHER
#define SHADER_LIBRARY_TEMPORAL_DITHER

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Dither/DitherCommon.hlsl"

// 时序处理机制：抖动透明的视觉可接受度高度依赖抗锯齿与时序累积策略
// 1. 静态抖动：每帧相同图案（BayerDither / BlueNoiseDither 的静态版），近距可见点阵、运动闪烁
// 2. TAA/TSR 协同：本文件的 TemporalDitherOffset，利用子像素 Jitter 让历史帧融合点阵
//    关键约束：Dither 材质必须在 TAA Pass 之前渲染并写入深度/速度缓冲，否则时序累积失效
// 3. 逐帧随机：本文件的 PerFrameRandomOffset，图案完全随机化、消除网格感，
//    但引入高频闪烁，需强时序滤波器收敛，适合烟雾/火焰等混沌效果
// 关闭时序抗锯齿后，方案 2 会退回粗糙点阵状态

// TAA / TSR 子像素抖动偏移
// 用 R2 低差异序列生成每帧的屏幕空间微偏移，可直接叠加到 screenPos 后再查 Bayer / 蓝噪声
// frameIndex 接帧序号或 TAA Jitter 索引，jitterStrength 建议 0.5~2 像素
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.TemporalDitherOffset</sg:ProviderKey>
///     <sg:DisplayName>Temporal Dither Offset</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>TemporalDitherOffset</sg:SearchName>
///     <sg:SearchTerms>Dither, Temporal, TAA, TSR, Jitter, Subpixel, Offset</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "frameIndex">
///     <sg:DisplayName>Frame Index</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "jitterStrength">
///     <sg:DisplayName>Jitter Strength</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 TemporalDitherOffset(float frameIndex, float jitterStrength)
{
  return DitherTemporalOffset(frameIndex, jitterStrength);
}

// 逐帧随机偏移
// 时间按每秒 60 帧量化，向噪声采样坐标注入随机偏移，使抖动图案逐帧完全变化
// strength 建议 4~16 像素；适合烟雾、火焰、体积效果
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.PerFrameRandomOffset</sg:ProviderKey>
///     <sg:DisplayName>Per Frame Random Offset</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>PerFrameRandomOffset</sg:SearchName>
///     <sg:SearchTerms>Dither, Random, PerFrame, Time, Offset, Smoke</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 PerFrameRandomOffset(float2 screenPos, float time, float strength)
{
  return DitherRandomOffset(screenPos, time, strength);
}

#endif