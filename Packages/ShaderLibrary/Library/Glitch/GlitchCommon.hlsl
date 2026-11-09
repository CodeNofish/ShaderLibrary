#ifndef SHADER_LIBRARY_GLITCH_COMMON
#define SHADER_LIBRARY_GLITCH_COMMON

// Glitch / Chromatic Aberration 的公共辅助函数
// 内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点
// 散列算法与 Library/Helper/Hash.hlsl 的 Hash11 / Hash21 一致，内联实现以保证文件自包含

// 一维伪随机，返回 [0,1)
static float GlitchHash11(float p)
{
  p = frac(p * 0.1031);
  p *= p + 33.33;
  p *= p + p;
  return frac(p);
}

// 二维伪随机，返回 [0,1)
static float GlitchHash21(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

// 二维随机向量，两个分量相互独立，适合生成随机 XY 位移
static float2 GlitchHash22(float2 p)
{
  return float2(GlitchHash21(p), GlitchHash21(p + float2(19.19, 7.31)));
}

// 把连续时间量化成离散帧，让故障呈"数字信号"式跳变而不是平滑过渡
// speed 为每秒切换次数，建议 6~30
static float GlitchTimeSlice(float time, float speed)
{
  return floor(time * max(speed, 0.001));
}

// 按概率触发，返回 0 或 1；probability 取 [0,1]
static float GlitchTrigger(float seed, float probability)
{
  return step(GlitchHash11(seed), saturate(probability));
}

// UV 环绕：位移后采样不越界，用于模拟信号翻滚
// 需要边缘拉伸（clamp）效果时不要调用它，直接采样即可
static float2 GlitchWrapUV(float2 uv)
{
  return frac(uv);
}

// 模拟噪点/雪花：屏幕切成 scale × scale 的格子，逐格逐帧取随机数，返回 [0,1)
static float GlitchNoiseValue(float2 uv, float slice, float scale)
{
  float2 cell = floor(uv * max(scale, 1.0));
  return GlitchHash21(cell + float2(slice, slice * 0.37));
}

#endif