#ifndef SHADER_LIBRARY_DEBUG
#define SHADER_LIBRARY_DEBUG

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Helper/PrintNumber.hlsl"

// 使用 3x5 位图字体在屏幕上绘制单个 float 值
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DebugFloat</sg:ProviderKey>
///     <sg:DisplayName>Debug Float</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Debug</sg:SearchCategory>
///     <sg:SearchName>DebugFloat</sg:SearchName>
///     <sg:SearchTerms>Debug, Print, Float, Number, Text, HUD, Overlay</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="value">
///     <sg:DisplayName>Value</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name="screenUV">
///     <sg:DisplayName>Screen UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DebugFloat(float value, float2 screenUV)
{
  return PrintFloat(screenUV, value, float2(0.1f, 0.1f), 1.0f);
}

// 调试显示 float2：按 X / Y 两行输出
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DebugFloat2</sg:ProviderKey>
///     <sg:DisplayName>Debug Float2</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Debug</sg:SearchCategory>
///     <sg:SearchName>DebugFloat2</sg:SearchName>
///     <sg:SearchTerms>Debug, Print, Float2, Vector2, HUD, Overlay</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="value">
///     <sg:DisplayName>Value</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name="screenUV">
///     <sg:DisplayName>Screen UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DebugFloat2(float2 value, float2 screenUV)
{
  float lineH = 0.14f;
  float base = 0.0f;
  base = max(base, PrintFloat(screenUV, value.x, float2(0.1f, 0.1f) + float2(0.0, 0.0), 1.0f));
  base = max(base, PrintFloat(screenUV, value.y, float2(0.1f, 0.1f) + float2(0.0, lineH), 1.0f));
  return base;
}

// 调试显示 float3：按 X / Y / Z 三行输出
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DebugFloat3</sg:ProviderKey>
///     <sg:DisplayName>Debug Float3</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Debug</sg:SearchCategory>
///     <sg:SearchName>DebugFloat3</sg:SearchName>
///     <sg:SearchTerms>Debug, Print, Float3, Vector3, Normal, Position, HUD, Overlay</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="value">
///     <sg:DisplayName>Value</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name="screenUV">
///     <sg:DisplayName>Screen UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 DebugFloat3(float3 value, float2 screenUV)
{
  float lineH = 0.14f;
  float base = 0.0f;
  base = max(base, PrintFloat(screenUV, value.x, float2(0.1f, 0.1f) + float2(0.0, 0.0), 1.0f));
  base = max(base, PrintFloat(screenUV, value.y, float2(0.1f, 0.1f) + float2(0.0, lineH), 1.0f));
  base = max(base, PrintFloat(screenUV, value.z, float2(0.1f, 0.1f) + float2(0.0, lineH * 2.0), 1.0f));
  return base;
}


#endif