#ifndef SHADER_LIBRARY_COLOR
#define SHADER_LIBRARY_COLOR

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Color/Common.hlsl"

// 获取颜色的亮度值
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ColorLuma</sg:ProviderKey>
///     <sg:DisplayName>Color Luma</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Color</sg:SearchCategory>
///     <sg:SearchName>Color Luma</sg:SearchName>
///     <sg:SearchTerms>Color</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float ColorLuma(float3 color)
{
  return ColorLumaInternal(color);
}

#endif