#ifndef SHADER_LIBRARY_LUT
#define SHADER_LIBRARY_LUT

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/ColorGrading/ColorCommon.hlsl"

// 基于 LUT（Look-Up Table）的调色
// External LUT：外部软件（DaVinci Resolve、Photoshop）制作的 .cube 文件，导入后通常为 strip 排布的 2D 纹理
// Internal LUT：引擎根据调色面板参数实时生成 3D LUT，本函数库不生成纹理，
//              可用 ColorAdjustments / LiftGammaGain / SplitToning 等程序化节点等效替代
// LDR LUT：在 SDR 范围直接查表；HDR LUT：先用 LogC 编码再查表（Unity URP High Definition Range 模式）
// 布局假设：纹理宽 lutSize*lutSize、高 lutSize，蓝通道切片沿 X 轴横向排列
// Sampler State 需使用 Linear + Clamp，蓝通道方向由本函数手动做线性插值

// 采样 2D LUT strip（External LUT / Low Definition Range）
// lutSize 为 LUT 边长，常用 32 或 64；输入 color 需为 [0,1]
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SampleLutStrip</sg:ProviderKey>
///     <sg:DisplayName>Sample LUT Strip</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>SampleLutStrip</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, LUT, ExternalLUT, Strip, Cube, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "lutTex">
///     <sg:DisplayName>LUT Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "lutSamplerState">
///     <sg:DisplayName>LUT Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "lutSize">
///     <sg:DisplayName>LUT Size</sg:DisplayName>
///     <sg:Default>32</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SampleLutStrip(
  UnityTexture2D lutTex,
  UnitySamplerState lutSamplerState,
  float3 color,
  float lutSize
)
{
  float size = max(lutSize, 2.0);
  float3 c = saturate(color) * (size - 1.0);

  float slice0 = floor(c.z);
  float slice1 = min(slice0 + 1.0, size - 1.0);
  float f = c.z - slice0;

  float2 uv0 = float2((slice0 * size + c.x + 0.5) / (size * size), (c.y + 0.5) / size);
  float2 uv1 = float2((slice1 * size + c.x + 0.5) / (size * size), (c.y + 0.5) / size);

  float3 a = SAMPLE_TEXTURE2D(lutTex, lutSamplerState, uv0).rgb;
  float3 b = SAMPLE_TEXTURE2D(lutTex, lutSamplerState, uv1).rgb;

  return lerp(a, b, f);
}

// 应用 External LUT 并按强度混合
// hdr = 0 使用 LDR/SDR LUT（直接查表）；hdr = 1 使用 LogC 编码的 HDR 调色 LUT
// intensity = 0 原色、1 完整 LUT 结果；把屏幕纹理采样结果的 RGB 接到 Color 即可
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ApplyExternalLut</sg:ProviderKey>
///     <sg:DisplayName>Apply External LUT</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>ApplyExternalLut</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, LUT, ExternalLUT, HDR, LogC, Cube, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "lutTex">
///     <sg:DisplayName>LUT Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "lutSamplerState">
///     <sg:DisplayName>LUT Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "lutSize">
///     <sg:DisplayName>LUT Size</sg:DisplayName>
///     <sg:Default>32</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "hdr">
///     <sg:DisplayName>HDR</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ApplyExternalLut(
  UnityTexture2D lutTex,
  UnitySamplerState lutSamplerState,
  float3 color,
  float lutSize,
  float intensity,
  float hdr
)
{
  float3 encoded = lerp(
    saturate(color),
    saturate(ColorLinearToLogC(color) / 1.1),
    step(0.5, hdr)
  );

  float3 graded = SampleLutStrip(lutTex, lutSamplerState, encoded, lutSize);
  return lerp(color, graded, saturate(intensity));
}

#endif