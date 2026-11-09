#ifndef SHADER_LIBRARY_GLITCH
#define SHADER_LIBRARY_GLITCH

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Glitch/GlitchCommon.hlsl"

// Glitch 组合效果：把常见子效果合成一次采样调用，便于直接做后处理反馈
// 覆盖：错位线条、错位图块、图块抖动、扫描线抖动、屏幕跳跃、屏幕抖动、波动抖动、
//       RGB 分离、模拟噪点、数字条纹，并用离散时间切片 + 概率触发控制信号损坏的节奏
// 需要单独调节某个子效果时，改用同目录下 RgbSplit / GlitchUV / GlitchNoise 的节点自由串接

// 可调分量的组合故障
// time 连 Time 节点的 Time；seed 用于让多个物体/多次触发的随机序列错开
// intensity 0~1 控制整体混合，probability 0~1 控制逐帧触发概率
// rgbAmount 建议 0~0.02、tearAmount 建议 0~0.1、noiseAmount 建议 0~0.3（均为 UV/亮度空间）
// 适合受伤、黑客入侵、传送、系统被干扰等反馈：用脉冲曲线驱动 intensity 即可
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GlitchAdvanced</sg:ProviderKey>
///     <sg:DisplayName>Glitch Advanced</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>GlitchAdvanced</sg:SearchName>
///     <sg:SearchTerms>Glitch, RGBSplit, Tear, Noise, Damage, Hacking, Teleport, PostEffect</sg:SearchTerms>
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
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "rgbAmount">
///     <sg:DisplayName>RGB Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "tearAmount">
///     <sg:DisplayName>Tear Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "noiseAmount">
///     <sg:DisplayName>Noise Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 GlitchAdvanced(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float intensity,
  float rgbAmount,
  float tearAmount,
  float noiseAmount,
  float probability,
  float seed
)
{
  float amount = saturate(intensity);
  float slice = GlitchTimeSlice(time, 12.0) + seed;
  float gate = GlitchTrigger(slice, probability);
  float2 rnd = GlitchHash22(float2(slice, slice + 7.1));

  // 错位线条 / 扫描线：按行随机水平撕裂
  float line = floor(uv.y * 32.0);
  float lineGate = GlitchTrigger(line + slice * 31.7, probability);
  float tear = (GlitchHash21(float2(line + 3.3, slice)) * 2.0 - 1.0) * tearAmount * lineGate;

  // 错位图块 / 图块抖动：网格图块整体随机位移
  float2 cell = floor(uv * float2(12.0, 24.0));
  float2 blockRnd = GlitchHash22(cell + float2(slice, slice * 0.73));
  float blockGate = GlitchTrigger(cell.x + cell.y * 17.3 + slice * 3.1, probability * 0.5);
  float2 block = (blockRnd * 2.0 - 1.0) * tearAmount * 0.25 * blockGate;

  // 屏幕跳跃 / 屏幕抖动 / 波动抖动
  float jump = (GlitchHash11(slice + 19.7) * 2.0 - 1.0) * tearAmount * 0.4 * gate;
  float2 shake = (rnd * 2.0 - 1.0) * tearAmount * 0.1 * gate;
  float wave = sin(uv.y * 40.0 + time * 8.0) * tearAmount * 0.05 * gate;

  float2 glitchUV = GlitchWrapUV(uv + float2(tear + wave + shake.x + block.x, jump + shake.y + block.y));

  // RGB 分离：逐帧随机方向，R 与 B 反向偏移
  float2 split = float2(rnd.x * 2.0 - 1.0, 0.0) * rgbAmount * gate;
  float r = SAMPLE_TEXTURE2D(tex, samplerState, GlitchWrapUV(glitchUV + split)).r;
  float4 g = SAMPLE_TEXTURE2D(tex, samplerState, glitchUV);
  float b = SAMPLE_TEXTURE2D(tex, samplerState, GlitchWrapUV(glitchUV - split)).b;
  float4 result = float4(r, g.g, b, g.a);

  // 模拟噪点：雪花点 + 静电扫描亮度
  float noise = GlitchNoiseValue(glitchUV, slice, 256.0) * 2.0 - 1.0;
  float scan = sin(glitchUV.y * 512.0 + time * 30.0) * 0.5 + 0.5;
  float3 noiseTint = noise * noiseAmount - (1.0 - scan) * 0.15;
  result.rgb += noiseTint * amount * gate;

  // 数字条纹：高对比二进制条纹覆盖
  float band = floor(glitchUV.y * 40.0);
  float stripeGate = GlitchTrigger(band * 0.317 + slice * 5.13, probability * 0.5);
  float2 bitsCell = floor(glitchUV * float2(320.0, 40.0));
  float bits = step(0.5, GlitchHash21(bitsCell + float2(slice, slice * 0.53)));
  result.rgb = lerp(result.rgb, float3(0.1, 0.9, 0.75), stripeGate * bits * amount * gate * 0.4);

  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  return float4(lerp(original.rgb, result.rgb, amount), original.a);
}

// 一键组合故障（基于 GlitchAdvanced 的预设比例）
// 只需连 Time 与 intensity：intensity 同时驱动 RGB 分离、画面撕裂和噪点强度
// probability 控制故障触发的频繁程度（0 完全无故障、1 每帧触发）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Glitch</sg:ProviderKey>
///     <sg:DisplayName>Glitch</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>Glitch</sg:SearchName>
///     <sg:SearchTerms>Glitch, RGBSplit, Tear, Noise, Damage, Hacking, Teleport, PostEffect</sg:SearchTerms>
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
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 Glitch(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float intensity,
  float probability,
  float seed
)
{
  return GlitchAdvanced(
    tex, samplerState, uv, time,
    intensity,
    intensity * 0.012,
    intensity * 0.06,
    intensity * 0.15,
    probability,
    seed
  );
}

#endif