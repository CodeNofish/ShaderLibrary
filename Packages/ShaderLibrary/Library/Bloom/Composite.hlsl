#ifndef SHADER_LIBRARY_BLOOM_COMPOSITE
#define SHADER_LIBRARY_BLOOM_COMPOSITE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Bloom/BloomCommon.hlsl"

// 合成输出与特殊变体
// Additive / Screen Blend：Screen 比 Additive 更自然，避免高光过曝死白
// URP 提供 Auto / Additive / Screen 三种模式，Intensity 控制最终强度
// 特殊变体：Anamorphic Bloom（水平/垂直拉伸）、Lens Dirt Overlay（镜头污迹）
// 调参要点：Threshold > 0 会破坏能量守恒，艺术化提亮建议用 Tint / Intensity；
//           色差在 Bloom 之后计算，Bloom Intensity 过高会压制色差效果；
//           二次元风格常用远高于写实场景的强度弱化硬朗线条，并与 Local Exposure 协同

// 三模式合成
// blendMode：0 = Additive、0.5 = Auto（亮部自动偏向 Screen）、1 = Screen
// tint 用于染色，intensity 控制泛光强度；Screen 模式可避免死白
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomComposite</sg:ProviderKey>
///     <sg:DisplayName>Bloom Composite</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomComposite</sg:SearchName>
///     <sg:SearchTerms>Bloom, Glow, Composite, Additive, Screen, Auto, Intensity</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneColor">
///     <sg:DisplayName>Scene Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "bloomColor">
///     <sg:DisplayName>Bloom Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "blendMode">
///     <sg:DisplayName>Blend Mode</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 BloomComposite(float3 sceneColor, float3 bloomColor, float intensity, float blendMode, float3 tint)
{
  float3 b = bloomColor * tint * max(intensity, 0.0);
  float3 additive = sceneColor + b;
  float3 screen = BloomScreenBlend(sceneColor, b);

  float isScreen = step(0.75, blendMode);
  float isAuto = step(0.25, blendMode) * (1.0 - isScreen);
  float autoW = saturate(BloomLuma(b));
  float screenW = max(isScreen, isAuto * autoW);

  return lerp(additive, screen, screenW);
}

// 镜头污迹叠加（Lens Dirt Overlay）
// 在泛光合成阶段叠加污渍/灰尘纹理，使光晕产生散射衍射效果
// 建议使用低分辨率 Dirt 纹理以减少带宽；dirtIntensity 控制叠加强度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomLensDirt</sg:ProviderKey>
///     <sg:DisplayName>Bloom Lens Dirt</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomLensDirt</sg:SearchName>
///     <sg:SearchTerms>Bloom, LensDirt, Dirt, Diffraction, Overlay, Texture</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "dirtTex">
///     <sg:DisplayName>Dirt Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "bloomColor">
///     <sg:DisplayName>Bloom Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "dirtIntensity">
///     <sg:DisplayName>Dirt Intensity</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 BloomLensDirt(
  UnityTexture2D dirtTex,
  UnitySamplerState samplerState,
  float2 uv,
  float3 bloomColor,
  float dirtIntensity
)
{
  float3 dirt = SAMPLE_TEXTURE2D(dirtTex, samplerState, uv).rgb;
  return bloomColor * (1.0 + dirt * max(dirtIntensity, 0.0));
}

// 变形宽银幕泛光（Anamorphic Bloom）
// 沿 direction 方向拉伸模糊，模拟变形宽银幕镜头的物理光学特性
// direction 常取 (1,0) 水平拉伸；stretch 为拉伸长度（纹素倍数），samples 建议 8~24
// 需配合 Camera 的 Anamorphism 属性使用（HDRP 提供专用开关）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomAnamorphic</sg:ProviderKey>
///     <sg:DisplayName>Bloom Anamorphic</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomAnamorphic</sg:SearchName>
///     <sg:SearchTerms>Bloom, Anamorphic, Streak, Horizontal, Lens, Cinematic</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
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
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "stretch">
///     <sg:DisplayName>Stretch</sg:DisplayName>
///     <sg:Default>16</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>12</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BloomAnamorphic(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float2 direction,
  float stretch,
  int samples
)
{
  float2 stepUV = direction * texelSize * max(stretch, 0.0);
  float4 sum = 0.0;
  float denom = max((float)(samples - 1), 1.0);

  for (int i = 0; i < samples; i++)
  {
    float t = (float)i / denom - 0.5;
    sum += SAMPLE_TEXTURE2D(tex, samplerState, uv + stepUV * t);
  }

  return sum / max((float)samples, 1.0);
}

// 能量守恒合成
// 用 (scene + bloom) / (1 + bloom) 抑制高强度下的全局亮度抬升，保留明暗层次
// 对应 HDRP energy-conserving 思路；配合物理光照单位使用，避免 Standard Bloom 提强度即过曝
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BloomEnergyConserving</sg:ProviderKey>
///     <sg:DisplayName>Bloom Energy Conserving</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Bloom</sg:SearchCategory>
///     <sg:SearchName>BloomEnergyConserving</sg:SearchName>
///     <sg:SearchTerms>Bloom, EnergyConserving, PhysicallyBased, HDRP, Overexposure</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneColor">
///     <sg:DisplayName>Scene Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "bloomColor">
///     <sg:DisplayName>Bloom Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 BloomEnergyConserving(float3 sceneColor, float3 bloomColor, float intensity)
{
  float3 b = max(bloomColor, 0.0) * max(intensity, 0.0);
  return (sceneColor + b) / (1.0 + b);
}

#endif