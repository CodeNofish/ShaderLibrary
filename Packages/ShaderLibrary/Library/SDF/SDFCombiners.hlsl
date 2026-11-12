#ifndef SHADER_LIBRARY_SDF_COMBINERS
#define SHADER_LIBRARY_SDF_COMBINERS

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 布尔 / 平滑组合：输入两个形状的距离值，输出组合后的距离值
// 布尔版精确保持距离场；平滑版（IQ 多项式 smooth min/max）在交界处融合出圆润过渡，
// 适合有机体、溶解 / 融合效果
// 重要：smoothness（k）是按世界单位解释的"平滑半径"，不是 0~1 的无量纲"平滑度"；
//       k = 0 时退化为硬布尔
// 在 Shader Graph 中组合顺序：各原语 → Combiners 链式相连；平滑参数建议从 0.1~0.5 起调

// 并集（Union / 合并两个形状）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFUnion</sg:ProviderKey>
///     <sg:DisplayName>SDF Union</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Union</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Boolean, Union, Min, Merge</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFUnion(float distanceA, float distanceB)
{
  return min(distanceA, distanceB);
}

// 交集（Intersection / 取两个形状的公共部分）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFIntersection</sg:ProviderKey>
///     <sg:DisplayName>SDF Intersection</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Intersection</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Boolean, Intersection, Max</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFIntersection(float distanceA, float distanceB)
{
  return max(distanceA, distanceB);
}

// 减法（从 B 中挖去 A，保留 B 的部分）：B − A
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFSubtraction</sg:ProviderKey>
///     <sg:DisplayName>SDF Subtraction</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Subtraction</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Boolean, Subtraction, Cut, Difference, Carve</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A (Subtracted)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B (Kept)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFSubtraction(float distanceA, float distanceB)
{
  return max(-distanceA, distanceB);
}

// 平滑并集（有机融合）：smoothness 为世界单位的融合半径
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFSmoothUnion</sg:ProviderKey>
///     <sg:DisplayName>SDF Smooth Union</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Smooth Union</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Smooth, Union, Blend, Metaball, Organic, Dissolve</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "smoothness">
///     <sg:DisplayName>Smoothness</sg:DisplayName>
///     <sg:Default>0.25</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFSmoothUnion(float distanceA, float distanceB, float smoothness)
{
  return SDFSmoothMin(distanceA, distanceB, smoothness);
}

// 平滑交集：交界处圆滑过渡，smoothness 为世界单位
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFSmoothIntersection</sg:ProviderKey>
///     <sg:DisplayName>SDF Smooth Intersection</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Smooth Intersection</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Smooth, Intersection, Blend</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "smoothness">
///     <sg:DisplayName>Smoothness</sg:DisplayName>
///     <sg:Default>0.25</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFSmoothIntersection(float distanceA, float distanceB, float smoothness)
{
  return SDFSmoothMax(distanceA, distanceB, smoothness);
}

// 平滑减法（从 B 中挖去 A，切口带圆润边缘）：B − A
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFSmoothSubtraction</sg:ProviderKey>
///     <sg:DisplayName>SDF Smooth Subtraction</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Smooth Subtraction</sg:SearchName>
///     <sg:SearchTerms>SDF, Combine, Smooth, Subtraction, Cut, Carve, Blend</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "distanceA">
///     <sg:DisplayName>Distance A (Subtracted)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "distanceB">
///     <sg:DisplayName>Distance B (Kept)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "smoothness">
///     <sg:DisplayName>Smoothness</sg:DisplayName>
///     <sg:Default>0.25</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFSmoothSubtraction(float distanceA, float distanceB, float smoothness)
{
  float k = max(smoothness, 1e-6);
  float h = clamp(0.5 - 0.5 * (distanceB + distanceA) / k, 0.0, 1.0);
  return lerp(distanceB, -distanceA, h) + k * h * (1.0 - h);
}

#endif
