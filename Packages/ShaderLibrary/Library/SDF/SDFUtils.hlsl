#ifndef SHADER_LIBRARY_SDF_UTILS
#define SHADER_LIBRARY_SDF_UTILS

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 距离 → 遮罩工具：把连续距离值转成填充 / 描边 / 发光 / 抖动遮罩
// 距离负值在形状内、正值在形状外、0 在边缘；输出遮罩 [0,1]
// 抗锯齿原理：用 fwidth(距离) 得到"距离在屏幕上一个像素内的变化量"作为过渡宽度，
//             任何缩放 / 旋转 / 分辨率下边缘都保持约 1 像素宽的平滑过渡（SDF 字体同理）
// SDFDitherMask 适合配合 Alpha Clip 走不透明路径，避免半透明排序问题（详见 Library/Dither）
// fwidth 只能在像素阶段使用，这些函数请连到片元输出而非顶点 / 顶点位移

// 屏幕空间抗锯齿填充遮罩：过渡宽度自动取 1 像素对应的距离变化量，无需手调参数
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFAAMask</sg:ProviderKey>
///     <sg:DisplayName>SDF AA Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF AA Mask</sg:SearchName>
///     <sg:SearchTerms>SDF, Mask, Fill, AntiAlias, AA, fwidth, UI, Shape</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFAAMask(float distance)
{
  float aa = max(fwidth(distance), 1e-5);
  return 1.0 - smoothstep(-aa, aa, distance);
}

// 固定软边填充遮罩：softness 为以世界/UV 单位表示的边缘过渡宽度，适合做整体羽化 / 转场
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFMask</sg:ProviderKey>
///     <sg:DisplayName>SDF Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Mask</sg:SearchName>
///     <sg:SearchTerms>SDF, Mask, Fill, Smooth, Soft, Feather, Transition</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>0.01</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFMask(float distance, float softness)
{
  float s = max(softness, 1e-6);
  return 1.0 - smoothstep(-s, s, distance);
}

// 抗锯齿描边遮罩：以边缘为中心、总宽 width 的线条（width = 0 时为约 1 像素的细线）
// softness > 0 时用固定软边，否则自动用屏幕空间 1.5 像素过渡
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFOutlineMask</sg:ProviderKey>
///     <sg:DisplayName>SDF Outline Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Outline Mask</sg:SearchName>
///     <sg:SearchTerms>SDF, Outline, Stroke, Border, Edge, AA, UI</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "width">
///     <sg:DisplayName>Width</sg:DisplayName>
///     <sg:Default>0.02</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFOutlineMask(float distance, float width, float softness)
{
  float w = max(width * 0.5, 0.0);
  float aa = (softness > 0.0) ? softness : max(fwidth(distance) * 1.5, 1e-5);
  return 1.0 - smoothstep(w - aa, w + aa, abs(distance));
}

// 边缘发光遮罩：从表面向外指数衰减，falloff 控制衰减半径；表面及内部为 1
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFGlowMask</sg:ProviderKey>
///     <sg:DisplayName>SDF Glow Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Glow Mask</sg:SearchName>
///     <sg:SearchTerms>SDF, Glow, Rim, Edge, Light, Bloom, Falloff</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "falloff">
///     <sg:DisplayName>Falloff</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFGlowMask(float distance, float falloff)
{
  return exp(-max(distance, 0.0) / max(falloff, 1e-5));
}

// 抖动填充遮罩：把连续距离二值化为像素级保留 / 丢弃（交错梯度噪声阈值）
// screenPos 接屏幕像素坐标（Screen Position 的 xy）；输出 0/1，可直接做 Alpha Clip，走不透明渲染路径
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFDitherMask</sg:ProviderKey>
///     <sg:DisplayName>SDF Dither Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Dither Mask</sg:SearchName>
///     <sg:SearchTerms>SDF, Dither, Mask, Stipple, InterleavedGradientNoise, AlphaClip, Dissolve, UI</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distance">
///     <sg:DisplayName>Distance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "screenPos">
///     <sg:DisplayName>Screen Position</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFDitherMask(float distance, float2 screenPos)
{
  float aa = max(fwidth(distance), 1e-5);
  float coverage = saturate(0.5 - distance / aa);
  float noise = SDFInterleavedGradientNoise(floor(screenPos));
  return step(noise, coverage);
}

#endif
