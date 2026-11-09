#ifndef SHADER_LIBRARY_COLOR_SPACE
#define SHADER_LIBRARY_COLOR_SPACE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/ColorGrading/ColorCommon.hlsl"

// 色彩空间感知调色：调色应在 ACEScg / LogC 等空间中进行，而不是在线性 sRGB 中直接处理
// 这样可避免高光压缩与饱和度调整时的色相偏移、高光断层
// 用法：LinearToACEScg → 调色节点 → ACEScgToLinear；HDR LUT 查表用 LinearToLogC 编码

// 线性 sRGB → ACEScg(AP1)：把调色移到 ACES 宽色域空间
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LinearToACEScg</sg:ProviderKey>
///     <sg:DisplayName>Linear To ACEScg</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>LinearToACEScg</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ColorSpace, ACEScg, AP1, Linear, HDR, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 LinearToACEScg(float3 color)
{
  return ColorLinearToACEScg(color);
}

// ACEScg(AP1) → 线性 sRGB：调色结束后转回显示空间
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ACEScgToLinear</sg:ProviderKey>
///     <sg:DisplayName>ACEScg To Linear</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>ACEScgToLinear</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ColorSpace, ACEScg, AP1, Linear, HDR, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ACEScgToLinear(float3 color)
{
  return ColorACEScgToLinear(color);
}

// 线性 sRGB → ARRI LogC EI800（近似）
// Unity URP 的 High Definition Range 调色即用 LogC 编码的 LUT 存储 HDR 结果
// 输出在 LDR 区间，便于把 HDR 颜色作为 LUT 查表坐标
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LinearToLogC</sg:ProviderKey>
///     <sg:DisplayName>Linear To LogC</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>LinearToLogC</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ColorSpace, LogC, ARRI, HDR, LUT, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 LinearToLogC(float3 color)
{
  return ColorLinearToLogC(color);
}

// ARRI LogC EI800（近似）→ 线性 sRGB
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LogCToLinear</sg:ProviderKey>
///     <sg:DisplayName>LogC To Linear</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>LogCToLinear</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ColorSpace, LogC, ARRI, HDR, LUT, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "logC">
///     <sg:DisplayName>LogC</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 LogCToLinear(float3 logC)
{
  return ColorLogCToLinear(logC);
}

#endif