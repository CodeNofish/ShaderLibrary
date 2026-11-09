#ifndef SHADER_LIBRARY_CAUSTICS_MASK
#define SHADER_LIBRARY_CAUSTICS_MASK

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Underwater/WaterCommon.hlsl"

// 焦散的区域限定（Mask）机制
// 深度遮罩：用归一化水体厚度作乘数，焦散仅在浅水区可见、深水区自然衰减
// Z-Height Mask：按世界高度剔除水面以上几何体（UE Light Function 的做法）
// 亮度阈值遮罩：后处理阶段仅对已有亮度的像素叠加焦散，间接排除阴影
// Decal Projector 扩展（HDRP GetCausticsBuffer()）属于脚本侧注入，不在 Shader 函数库实现

// 深度遮罩：浅水可见、深水衰减
// depthMask 接 WaterDepthMask 的归一化水体厚度；shallowStart / deepEnd 控制过渡区间
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DepthCausticsMask</sg:ProviderKey>
///     <sg:DisplayName>Depth Caustics Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>DepthCausticsMask</sg:SearchName>
///     <sg:SearchTerms>Caustics, Mask, Depth, Shallow, Water, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "depthMask">
///     <sg:DisplayName>Depth Mask</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "shallowStart">
///     <sg:DisplayName>Shallow Start</sg:DisplayName>
///     <sg:Default>0.2</sg:Default>
///</paramhints>
///<paramhints name = "deepEnd">
///     <sg:DisplayName>Deep End</sg:DisplayName>
///     <sg:Default>0.8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DepthCausticsMask(float depthMask, float shallowStart, float deepEnd)
{
  float end = max(deepEnd, shallowStart + 1e-4);
  return 1.0 - smoothstep(shallowStart, end, saturate(depthMask));
}

// Z-Height Mask：仅水面以下的几何体接收焦散
// worldHeight 传世界高度分量：Unity（Y-up）传 Position.y，UE（Z-up）传 Position.z
// falloff 为水面附近的软过渡宽度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ZHeightMask</sg:ProviderKey>
///     <sg:DisplayName>Z Height Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>ZHeightMask</sg:SearchName>
///     <sg:SearchTerms>Caustics, Mask, ZHeight, WorldPosition, LightFunction, UE</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "worldHeight">
///     <sg:DisplayName>World Height</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "waterLevel">
///     <sg:DisplayName>Water Level</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "falloff">
///     <sg:DisplayName>Falloff</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float ZHeightMask(float worldHeight, float waterLevel, float falloff)
{
  float f = max(falloff, 1e-4);
  return 1.0 - smoothstep(waterLevel - f, waterLevel + f, worldHeight);
}

// 亮度阈值遮罩：后处理阶段读场景亮度，仅对已有一定亮度的像素叠加焦散
// 可间接排除阴影区域；注意高亮纹理可能被误检，建议配合深度/高度遮罩使用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LuminanceMask</sg:ProviderKey>
///     <sg:DisplayName>Luminance Mask</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>LuminanceMask</sg:SearchName>
///     <sg:SearchTerms>Caustics, Mask, Luminance, Threshold, Shadow, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>0.2</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float LuminanceMask(float3 color, float threshold, float softness)
{
  float s = max(softness, 1e-4);
  return smoothstep(threshold - s, threshold + s, WaterLuma(color));
}

// 组合三种遮罩：相乘得到最终焦散作用区域
// 不使用的遮罩传 1 即可；结果可直接接 ApplyCaustics 的 Mask
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CombineCausticsMasks</sg:ProviderKey>
///     <sg:DisplayName>Combine Caustics Masks</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>CombineCausticsMasks</sg:SearchName>
///     <sg:SearchTerms>Caustics, Mask, Combine, Depth, ZHeight, Luminance</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "depthMask">
///     <sg:DisplayName>Depth Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "zMask">
///     <sg:DisplayName>Z Height Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "lumaMask">
///     <sg:DisplayName>Luminance Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float CombineCausticsMasks(float depthMask, float zMask, float lumaMask)
{
  return saturate(depthMask) * saturate(zMask) * saturate(lumaMask);
}

#endif