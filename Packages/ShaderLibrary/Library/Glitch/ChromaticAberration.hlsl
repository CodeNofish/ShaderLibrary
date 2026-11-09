#ifndef SHADER_LIBRARY_CHROMATIC_ABERRATION
#define SHADER_LIBRARY_CHROMATIC_ABERRATION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Glitch/GlitchCommon.hlsl"

// Chromatic Aberration（色差）在实时后处理中分两类：
// - 倍率色差 Lateral / Transverse CA：放大率随波长变化，仅画面边缘出现对称色边，
//   用径向对称的 RGB UV 偏移模拟，是 Shader 中最常见的色差。
// - 轴向色差 Longitudinal / Axial CA：不同波长沿光轴聚焦位置不同，中心也可见彩色光晕，
//   严格模拟需要深度，这里用「每个波长使用不同离焦模糊半径」做轻量近似。
// Glitch 的 RGB Split 与色差底层算法相同，区别是色差径向对称且连续、故障随机离散。

// 倍率色差（Lateral / Transverse CA）
// R 向外、B 向内、G 保持原位；中心几乎无色边，越靠边缘越明显
// strength 建议 0 ~ 0.02（UV 空间）；偏移在 UV 空间计算，非正方形屏幕会略呈椭圆
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ChromaticAberration</sg:ProviderKey>
///     <sg:DisplayName>Chromatic Aberration</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ChromaticAberration</sg:SearchCategory>
///     <sg:SearchName>ChromaticAberration</sg:SearchName>
///     <sg:SearchTerms>ChromaticAberration, Lateral, Transverse, RGBSplit, ColorFringe, Lens, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ChromaticAberration(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength
)
{
  float2 dir = uv - centerUV;
  float edge = saturate(dot(dir, dir) * 4.0);
  float2 offset = dir * strength * edge;

  float r = SAMPLE_TEXTURE2D(tex, samplerState, uv + offset).r;
  float4 g = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float b = SAMPLE_TEXTURE2D(tex, samplerState, uv - offset).b;

  return float4(r, g.g, b, g.a);
}

// 倍率色差 + 强度混合
// intensity = 0 使用原图，1 使用完整色差，适合受击、传送、镜头切换时做动画驱动
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ChromaticAberrationIntensity</sg:ProviderKey>
///     <sg:DisplayName>Chromatic Aberration Intensity</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ChromaticAberration</sg:SearchCategory>
///     <sg:SearchName>ChromaticAberrationIntensity</sg:SearchName>
///     <sg:SearchTerms>ChromaticAberration, Lateral, Intensity, Lens, Damage, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ChromaticAberrationIntensity(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength,
  float intensity
)
{
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 ca = ChromaticAberration(tex, samplerState, uv, centerUV, strength);
  return lerp(original, ca, saturate(intensity));
}

// 轴向色差（Longitudinal / Axial CA）轻量近似
// 不同波长使用不同的离焦模糊半径：R 最小、G 居中、B 最大，模拟焦前紫边/焦后绿边
// radius 为模糊半径（像素），建议 0~4；focus = 0 合焦，1 完全离焦
// 每通道 2 次对角采样 + 1 次中心采样，共 7 次采样，移动端可把 radius 调小
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.AxialChromaticAberration</sg:ProviderKey>
///     <sg:DisplayName>Axial Chromatic Aberration</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ChromaticAberration</sg:SearchCategory>
///     <sg:SearchName>AxialChromaticAberration</sg:SearchName>
///     <sg:SearchTerms>ChromaticAberration, Axial, Longitudinal, Defocus, Bokeh, Lens, PostEffect</sg:SearchTerms>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "focus">
///     <sg:DisplayName>Focus</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 AxialChromaticAberration(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  float focus
)
{
  float2 px = texelSize * max(radius, 0.0);
  float2 dR = px * 0.42;
  float2 dG = px * 0.71;
  float2 dB = px * 1.00;

  float r = (SAMPLE_TEXTURE2D(tex, samplerState, uv + dR).r + SAMPLE_TEXTURE2D(tex, samplerState, uv - dR).r) * 0.5;
  float g = (SAMPLE_TEXTURE2D(tex, samplerState, uv + dG).g + SAMPLE_TEXTURE2D(tex, samplerState, uv - dG).g) * 0.5;
  float b = (SAMPLE_TEXTURE2D(tex, samplerState, uv + dB).b + SAMPLE_TEXTURE2D(tex, samplerState, uv - dB).b) * 0.5;

  float4 center = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  return float4(lerp(center.rgb, float3(r, g, b), saturate(focus)), center.a);
}

#endif