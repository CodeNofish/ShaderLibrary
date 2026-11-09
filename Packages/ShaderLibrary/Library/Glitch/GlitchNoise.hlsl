#ifndef SHADER_LIBRARY_GLITCH_NOISE
#define SHADER_LIBRARY_GLITCH_NOISE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Glitch/GlitchCommon.hlsl"

// 模拟噪点故障（Analog Noise Glitch）与数字条纹故障（Digital Stripe Glitch）
// 前者叠加基于时间的伪随机雪花和静电扫描线，后者覆盖高对比二进制风格条纹

// 噪点值：把屏幕切成 scale × scale 的格子，逐格逐帧取随机数
// 返回 [0,1)，可单独用来驱动颜色扰动、亮度闪烁或阈值遮罩
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GlitchNoise</sg:ProviderKey>
///     <sg:DisplayName>Glitch Noise</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>GlitchNoise</sg:SearchName>
///     <sg:SearchTerms>Glitch, Noise, Snow, Static, AnalogNoise, Hash, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
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
///     <sg:Default>256</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float GlitchNoise(float2 uv, float time, float scale)
{
  return GlitchNoiseValue(uv, GlitchTimeSlice(time, 24.0), scale);
}

// 模拟噪点故障
// 叠加逐帧雪花点 + 静电扫描亮度调制，模拟模拟信号传输干扰
// amount 建议 0 ~ 0.3；intensity = 0 原图、1 完整噪点
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.AnalogNoiseGlitch</sg:ProviderKey>
///     <sg:DisplayName>Analog Noise Glitch</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>AnalogNoiseGlitch</sg:SearchName>
///     <sg:SearchTerms>Glitch, AnalogNoise, Static, Snow, Scanline, PostEffect</sg:SearchTerms>
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
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>256</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 AnalogNoiseGlitch(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float scale,
  float amount,
  float intensity
)
{
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float noise = GlitchNoise(uv, time, scale) * 2.0 - 1.0;
  float scan = sin(uv.y * scale * 2.0 + time * 30.0) * 0.5 + 0.5;
  float3 glitched = c.rgb * (0.85 + 0.15 * scan) + noise * amount;

  return float4(lerp(c.rgb, glitched, saturate(intensity)), c.a);
}

// 数字条纹故障遮罩（Digital Stripe Glitch）
// 按水平条带概率触发，条带内再用 0/1 随机位生成高对比二进制风格条纹，返回 0 或 1
// density 建议 20~80；可把结果接到 Lerp 的 T 端自定义条纹颜色
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DigitalStripe</sg:ProviderKey>
///     <sg:DisplayName>Digital Stripe</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>DigitalStripe</sg:SearchName>
///     <sg:SearchTerms>Glitch, DigitalStripe, Binary, Stripe, Cyberpunk, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
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
///<paramhints name = "density">
///     <sg:DisplayName>Density</sg:DisplayName>
///     <sg:Default>40</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DigitalStripe(float2 uv, float time, float density, float probability)
{
  float slice = GlitchTimeSlice(time, 10.0);
  float lines = max(density, 1.0);
  float band = floor(uv.y * lines);
  float trigger = GlitchTrigger(band * 0.317 + slice * 5.13, probability);
  float2 cell = floor(uv * float2(lines * 8.0, lines));
  float bits = step(0.5, GlitchHash21(cell + float2(slice, slice * 0.53)));

  return trigger * bits;
}

// 数字条纹颜色叠加
// 在触发的条带上覆盖 stripeColor，用于赛博朋克风格的数字化装饰
// intensity 同时控制条纹可见度与整体混合强度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DigitalStripeGlitch</sg:ProviderKey>
///     <sg:DisplayName>Digital Stripe Glitch</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>DigitalStripeGlitch</sg:SearchName>
///     <sg:SearchTerms>Glitch, DigitalStripe, Binary, Stripe, Cyberpunk, PostEffect</sg:SearchTerms>
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
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "density">
///     <sg:DisplayName>Density</sg:DisplayName>
///     <sg:Default>40</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "stripeColor">
///     <sg:DisplayName>Stripe Color</sg:DisplayName>
///     <sg:Default>0,1,1</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 DigitalStripeGlitch(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float density,
  float probability,
  float3 stripeColor,
  float intensity
)
{
  float mask = DigitalStripe(uv, time, density, probability) * saturate(intensity);
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);

  return float4(lerp(c.rgb, stripeColor, mask), c.a);
}

#endif