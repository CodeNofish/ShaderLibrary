#ifndef SHADER_LIBRARY_UNDERWATER_DISTORTION
#define SHADER_LIBRARY_UNDERWATER_DISTORTION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Underwater/WaterCommon.hlsl"

// 噪声 / 法线贴图驱动扭曲：模拟光线穿过波动水面时的折射偏移
// 用滚动的法线值作为 UV 偏移，对屏幕空间纹理（GrabPass / Scene Color）重采样
// 特点：开销低、美术可控；物理准确性较弱，不随水深自动衰减（配合 DepthAwareDistortion 使用）
// 三个细分：双向滚动混合、Flow Map 驱动、时间错位平滑

// 双向滚动混合
// 同一张法线纹理按两个相差约 90° 的方向滚动采样，混合后得到各向同性扰动
// speedA / speedB 为每秒滚动速度（UV/秒），建议两者方向近似正交
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DualScrollNormalUV</sg:ProviderKey>
///     <sg:DisplayName>Dual Scroll Normal UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>DualScrollNormalUV</sg:SearchName>
///     <sg:SearchTerms>Underwater, Distortion, NormalMap, DualScroll, Refraction, UV</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV Offset</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "normalTex">
///     <sg:DisplayName>Normal Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speedA">
///     <sg:DisplayName>Speed A</sg:DisplayName>
///     <sg:Default>0.1,0.05</sg:Default>
///</paramhints>
///<paramhints name = "speedB">
///     <sg:DisplayName>Speed B</sg:DisplayName>
///     <sg:Default>-0.05,0.1</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 DualScrollNormalUV(
  UnityTexture2D normalTex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float2 speedA,
  float2 speedB,
  float strength
)
{
  float2 nA = WaterDecodeNormal(SAMPLE_TEXTURE2D(normalTex, samplerState, uv + speedA * time).rg, 1.0);
  float2 nB = WaterDecodeNormal(SAMPLE_TEXTURE2D(normalTex, samplerState, uv + speedB * time).rg, 1.0);

  return (nA + nB) * 0.5 * strength;
}

// Flow Map 驱动扭曲
// RG 通道编码局部流向，按流向偏移后分别取 frac(time) 与 frac(time + 0.5) 两组采样
// 用三角权重混合消除循环接缝，避免纯噪声滚动的机械重复感
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FlowMapDistortionUV</sg:ProviderKey>
///     <sg:DisplayName>Flow Map Distortion UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>FlowMapDistortionUV</sg:SearchName>
///     <sg:SearchTerms>Underwater, Distortion, FlowMap, TimeShift, Refraction, UV</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV Offset</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "flowTex">
///     <sg:DisplayName>Flow Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 FlowMapDistortionUV(
  UnityTexture2D flowTex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float speed,
  float strength
)
{
  float t = time * max(speed, 0.001);
  float phase0 = frac(t);
  float phase1 = frac(t + 0.5);

  float2 flow = WaterDecodeNormal(SAMPLE_TEXTURE2D(flowTex, samplerState, uv).rg, 1.0);
  float2 uv0 = uv + flow * phase0 * 0.1;
  float2 uv1 = uv + flow * phase1 * 0.1;

  float2 n0 = WaterDecodeNormal(SAMPLE_TEXTURE2D(flowTex, samplerState, uv0).rg, 1.0);
  float2 n1 = WaterDecodeNormal(SAMPLE_TEXTURE2D(flowTex, samplerState, uv1).rg, 1.0);
  float blend = abs(phase0 * 2.0 - 1.0);

  return lerp(n0, n1, blend) * strength;
}

// 时间错位平滑（纯计算版）
// 用 frac(time) 与 frac(time + 0.5) 生成两组波形偏移并混合，消除循环接缝处的视觉跳变
// 不依赖纹理，适合移动端与风格化水体
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.TimeShiftedDistortionUV</sg:ProviderKey>
///     <sg:DisplayName>Time Shifted Distortion UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>TimeShiftedDistortionUV</sg:SearchName>
///     <sg:SearchTerms>Underwater, Distortion, TimeShift, Wave, UV, Mobile</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV Offset</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>20</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 TimeShiftedDistortionUV(float2 uv, float time, float scale, float strength, float speed)
{
  float t = time * max(speed, 0.001);
  float phase0 = frac(t);
  float phase1 = frac(t + 0.5);

  float2 w0 = WaterWaveOffset(uv, scale, phase0);
  float2 w1 = WaterWaveOffset(uv, scale, phase1);
  float blend = abs(phase0 * 2.0 - 1.0);

  return lerp(w0, w1, blend) * strength;
}

// 折射重采样：把上游算出的 UV 偏移应用到屏幕纹理
// dispersion 让 R/B 沿偏移方向产生微小色散；refrColor 为水体折射色
// 与焦散协同：焦散的 HDR 着色应与此处 refrColor 匹配，且先完成扭曲再叠加焦散
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.UnderwaterRefraction</sg:ProviderKey>
///     <sg:DisplayName>Underwater Refraction</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>UnderwaterRefraction</sg:SearchName>
///     <sg:SearchTerms>Underwater, Distortion, Refraction, Dispersion, RefrColor, PostEffect</sg:SearchTerms>
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
///<paramhints name = "uvOffset">
///     <sg:DisplayName>UV Offset</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
///<paramhints name = "refrColor">
///     <sg:DisplayName>Refraction Color</sg:DisplayName>
///     <sg:Default>0.6,0.85,1</sg:Default>
///</paramhints>
///<paramhints name = "dispersion">
///     <sg:DisplayName>Dispersion</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 UnderwaterRefraction(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 uvOffset,
  float3 refrColor,
  float dispersion,
  float intensity
)
{
  float2 suv = uv + uvOffset;
  float2 d = uvOffset * dispersion;

  float r = SAMPLE_TEXTURE2D(tex, samplerState, suv + d).r;
  float4 g = SAMPLE_TEXTURE2D(tex, samplerState, suv);
  float b = SAMPLE_TEXTURE2D(tex, samplerState, suv - d).b;
  float3 refracted = float3(r, g.g, b) * refrColor;

  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  return float4(lerp(original.rgb, refracted, saturate(intensity)), original.a);
}

#endif