#ifndef SHADER_LIBRARY_TONE_MAPPING
#define SHADER_LIBRARY_TONE_MAPPING

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Color/Common.hlsl"

// Tone Mapping：把 HDR 光照非线性压缩到 SDR 显示范围
// exposure 统一为曝光补偿（EV），内部用 exp2(exposure) 缩放，建议 -2 ~ 2
// 电影级 ACES / 中性 Neutral / 经典 Reinhard / 自定义曲线 Custom 为四类主流算子
// Local Exposure 不属于传统算子，但常作为高对比场景的补充

// 电影级映射 ACES（Academy Color Encoding System）
// 高对比度、高光压缩柔和，在 AP1 空间压缩会轻微改变色相与饱和度以模拟胶片响应
// 影视化质感、高反差场景、3A 项目默认选项
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ACESToneMapping</sg:ProviderKey>
///     <sg:DisplayName>ACES Tone Mapping</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ToneMapping</sg:SearchCategory>
///     <sg:SearchName>ACESToneMapping</sg:SearchName>
///     <sg:SearchTerms>ToneMapping, ACES, Filmic, HDR, Exposure, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ACESToneMapping(float3 color, float exposure)
{
  return ColorACESFit(max(color, 0.0) * exp2(exposure));
}

// 中性映射 Neutral
// 只压缩亮度峰值、RGB 按同一比例缩放，对色相和饱和度影响最小，过渡平缓
// 适合后续还需要大幅 Color Grading、开放世界自然光照
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.NeutralToneMapping</sg:ProviderKey>
///     <sg:DisplayName>Neutral Tone Mapping</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ToneMapping</sg:SearchCategory>
///     <sg:SearchName>NeutralToneMapping</sg:SearchName>
///     <sg:SearchTerms>ToneMapping, Neutral, HDR, Exposure, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 NeutralToneMapping(float3 color, float exposure)
{
  float3 c = max(color, 0.0) * exp2(exposure);
  float peak = max(max(c.r, c.g), c.b);
  float mapped = 1.0 - exp(-peak);

  return c * (mapped / max(peak, 1e-5));
}

// 经典全局映射 Reinhard：L_out = L_in / (1 + L_in)
// 公式简单、性能最低，能保留高光细节，但局部对比度不足、画面易偏灰
// whitePoint 为扩展 Reinhard 的白点，越大越接近原始公式，建议 4~16
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ReinhardToneMapping</sg:ProviderKey>
///     <sg:DisplayName>Reinhard Tone Mapping</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ToneMapping</sg:SearchCategory>
///     <sg:SearchName>ReinhardToneMapping</sg:SearchName>
///     <sg:SearchTerms>ToneMapping, Reinhard, HDR, Exposure, Mobile, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "whitePoint">
///     <sg:DisplayName>White Point</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ReinhardToneMapping(float3 color, float exposure, float whitePoint)
{
  float3 c = max(color, 0.0) * exp2(exposure);
  float w2 = max(whitePoint * whitePoint, 1e-4);

  return saturate(c * (1.0 + c / w2) / (1.0 + c));
}

// 自定义曲线映射 Custom Curve
// toe 抬暗部过渡（0~0.3）、shoulder 控制高光压缩斜率（0~2）、gamma 调中间调（0.5~2）
// 完全可控，适合风格化渲染与特殊艺术调性
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CustomCurveToneMapping</sg:ProviderKey>
///     <sg:DisplayName>Custom Curve Tone Mapping</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ToneMapping</sg:SearchCategory>
///     <sg:SearchName>CustomCurveToneMapping</sg:SearchName>
///     <sg:SearchTerms>ToneMapping, CustomCurve, Toe, Shoulder, Gamma, HDR, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "toe">
///     <sg:DisplayName>Toe</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "shoulder">
///     <sg:DisplayName>Shoulder</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "gamma">
///     <sg:DisplayName>Gamma</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 CustomCurveToneMapping(float3 color, float exposure, float toe, float shoulder, float gamma)
{
  float3 c = max(color, 0.0) * exp2(exposure);

  float3 x = c / (1.0 + max(shoulder, 0.0) * c);
  x += max(toe, 0.0) * (1.0 - exp(-c * 4.0));
  x = pow(max(x, 0.0), 1.0 / max(gamma, 1e-3));

  return saturate(x);
}

// 局部曝光 Local Exposure（高对比场景补充）
// 用 5 点邻域均值近似"边缘感知数据结构"：邻域偏亮则压低曝光、偏暗则提升，保留暗部/高光细节
// radius 为采样半径（像素），strength 建议 0~1，exposure 为全局曝光补偿（EV）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LocalExposure</sg:ProviderKey>
///     <sg:DisplayName>Local Exposure</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ToneMapping</sg:SearchCategory>
///     <sg:SearchName>LocalExposure</sg:SearchName>
///     <sg:SearchTerms>ToneMapping, LocalExposure, Adaptation, HDR, Contrast, PostEffect</sg:SearchTerms>
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
///     <sg:Default>8</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 LocalExposure(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  float strength,
  float exposure
)
{
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float2 o = texelSize * max(radius, 0.0);

  float3 neighbors = SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(o.x, 0.0)).rgb;
  neighbors += SAMPLE_TEXTURE2D(tex, samplerState, uv - float2(o.x, 0.0)).rgb;
  neighbors += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, o.y)).rgb;
  neighbors += SAMPLE_TEXTURE2D(tex, samplerState, uv - float2(0.0, o.y)).rgb;

  float3 average = (c.rgb + neighbors) * 0.2;
  float localLuma = ColorLumaInternal(average);
  float gain = clamp(pow(0.18 / max(localLuma, 1e-4), saturate(strength)), 0.25, 4.0);

  return float4(c.rgb * exp2(exposure) * gain, c.a);
}

#endif