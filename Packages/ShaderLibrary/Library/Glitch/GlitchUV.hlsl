#ifndef SHADER_LIBRARY_GLITCH_UV
#define SHADER_LIBRARY_GLITCH_UV

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Glitch/GlitchCommon.hlsl"

// Glitch 的 UV 变换类效果：只输出位移后的屏幕 UV，颜色采样交给后续节点
// 这样各效果可以在 ShaderGraph 里自由串接、叠加，再统一采样一次纹理
// 注意：返回的 UV 可能超出 [0,1]，需要环绕时接 Frac、需要拉边时接 Saturate

// 错位线条故障（Line Block Glitch）
// 按水平行分块，逐帧以 probability 的概率随机水平错位，模拟数据丢包的横向条纹撕裂
// lineCount 建议 16~64；amount 为 UV 空间位移，建议 0 ~ 0.1
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LineBlockGlitchUV</sg:ProviderKey>
///     <sg:DisplayName>Line Block Glitch UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>LineBlockGlitchUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, LineBlock, Tear, Stripe, Displacement, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "lineCount">
///     <sg:DisplayName>Line Count</sg:DisplayName>
///     <sg:Default>24</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 LineBlockGlitchUV(float2 uv, float time, float amount, float probability, float lineCount)
{
  float slice = GlitchTimeSlice(time, 8.0);
  float line = floor(uv.y * max(lineCount, 1.0));
  float2 rnd = GlitchHash22(float2(line, slice));
  float trigger = GlitchTrigger(line + slice * 31.7, probability);
  float shift = (rnd.x * 2.0 - 1.0) * amount * trigger;

  return float2(uv.x + shift, uv.y);
}

// 错位图块故障（Image Block Glitch）
// 把屏幕切成 blockCount 的矩形网格，命中的图块整体随机位移
// 模拟视频编码错误、显存损坏；纯色块/上一帧缓存替换可在 ShaderGraph 里用 mask + Lerp 追加
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ImageBlockGlitchUV</sg:ProviderKey>
///     <sg:DisplayName>Image Block Glitch UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>ImageBlockGlitchUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, ImageBlock, Block, Mosaic, Displacement, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "blockCount">
///     <sg:DisplayName>Block Count</sg:DisplayName>
///     <sg:Default>12,24</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ImageBlockGlitchUV(float2 uv, float time, float2 blockCount, float amount, float probability)
{
  float slice = GlitchTimeSlice(time, 8.0);
  float2 cell = floor(uv * max(blockCount, float2(1.0, 1.0)));
  float2 rnd = GlitchHash22(cell + float2(slice, slice * 0.73));
  float trigger = GlitchTrigger(cell.x + cell.y * 17.3 + slice * 3.1, probability);
  float2 shift = (rnd * 2.0 - 1.0) * amount * trigger;

  return uv + float2(shift.x, shift.y * 0.5);
}

// 图块抖动故障（Tile Jitter Glitch）
// 网格化小图块逐帧高频随机位移，不做概率筛选，产生细碎颗粒状抖动
// tileCount 建议 32,64 以上；amount 建议 0 ~ 0.01
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.TileJitterUV</sg:ProviderKey>
///     <sg:DisplayName>Tile Jitter UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>TileJitterUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, TileJitter, Jitter, Noise, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "tileCount">
///     <sg:DisplayName>Tile Count</sg:DisplayName>
///     <sg:Default>64,64</sg:Default>
///</paramhints>
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 TileJitterUV(float2 uv, float time, float2 tileCount, float amount)
{
  float slice = GlitchTimeSlice(time, 24.0);
  float2 cell = floor(uv * max(tileCount, float2(1.0, 1.0)));
  float2 rnd = GlitchHash22(cell + float2(slice, slice * 1.31));

  return uv + (rnd * 2.0 - 1.0) * amount;
}

// 扫描线抖动故障（Scan Line Jitter Glitch）
// 比 Line Block 更细密，仅部分扫描线横向位移，并叠加随时间移动的正弦相位
// 模拟 CRT / VHS 磁带信号干扰；lineCount 建议 100~400
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScanLineJitterUV</sg:ProviderKey>
///     <sg:DisplayName>Scan Line Jitter UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>ScanLineJitterUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, ScanLine, VHS, CRT, Jitter, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "lineCount">
///     <sg:DisplayName>Line Count</sg:DisplayName>
///     <sg:Default>200</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ScanLineJitterUV(float2 uv, float time, float amount, float probability, float lineCount)
{
  float slice = GlitchTimeSlice(time, 30.0);
  float lines = max(lineCount, 1.0);
  float line = floor(uv.y * lines);
  float trigger = GlitchTrigger(line * 0.137 + slice * 7.31, probability);
  float rnd = GlitchHash21(float2(line + 7.3, slice));
  float wave = sin(uv.y * lines * 6.2831 + time * 40.0);
  float shift = (rnd * 2.0 - 1.0 + wave * 0.35) * amount * trigger;

  return float2(uv.x + shift, uv.y);
}

// 屏幕跳跃故障（Screen Jump / Vertical Jump Glitch）
// 整幅画面沿 V 轴瞬时跳变，模拟垂直同步失败导致的上下翻滚
// 时间被量化为每秒 6 帧，因此是离散跳跃而不是平滑滚动
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScreenJumpUV</sg:ProviderKey>
///     <sg:DisplayName>Screen Jump UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>ScreenJumpUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, ScreenJump, VerticalJump, VSync, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "probability">
///     <sg:DisplayName>Probability</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ScreenJumpUV(float2 uv, float time, float amount, float probability)
{
  float slice = GlitchTimeSlice(time, 6.0);
  float trigger = GlitchTrigger(slice, probability);
  float jump = (GlitchHash11(slice + 19.7) * 2.0 - 1.0) * amount * trigger;

  return float2(uv.x, uv.y + jump);
}

// 屏幕抖动故障（Screen Shake Glitch）
// 整幅画面逐帧随机 XY 平移，模拟信号冲击或设备震动
// amount 建议 0 ~ 0.02；内部按每秒 30 帧量化
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScreenShakeUV</sg:ProviderKey>
///     <sg:DisplayName>Screen Shake UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>ScreenShakeUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, ScreenShake, Shake, Impact, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "amount">
///     <sg:DisplayName>Amount</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 ScreenShakeUV(float2 uv, float time, float amount)
{
  float slice = GlitchTimeSlice(time, 30.0);
  float2 rnd = GlitchHash22(float2(slice, slice + 3.1));

  return uv + (rnd * 2.0 - 1.0) * amount;
}

// 波动抖动故障（Wave Jitter Glitch）
// 用正弦/余弦对 UV 做非线性扭曲，随时间动画化，呈现液态或磁带式波浪形变
// frequency 建议 10~80，amplitude 建议 0 ~ 0.02，speed 控制波动速度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.WaveJitterUV</sg:ProviderKey>
///     <sg:DisplayName>Wave Jitter UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Glitch</sg:SearchCategory>
///     <sg:SearchName>WaveJitterUV</sg:SearchName>
///     <sg:SearchTerms>Glitch, WaveJitter, Wave, Distort, Warp, VHS, UV, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
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
///<paramhints name = "frequency">
///     <sg:DisplayName>Frequency</sg:DisplayName>
///     <sg:Default>40</sg:Default>
///</paramhints>
///<paramhints name = "amplitude">
///     <sg:DisplayName>Amplitude</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 WaveJitterUV(float2 uv, float time, float frequency, float amplitude, float speed)
{
  float waveX = sin(uv.y * frequency + time * speed);
  float waveY = cos(uv.x * frequency * 0.7 - time * speed * 0.5);

  return uv + float2(waveX, waveY * 0.25) * amplitude;
}

#endif