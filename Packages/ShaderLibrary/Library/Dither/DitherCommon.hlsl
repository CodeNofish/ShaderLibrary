#ifndef SHADER_LIBRARY_DITHER_COMMON
#define SHADER_LIBRARY_DITHER_COMMON

// 抖动透明公共算法（内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点）
// 核心：用 Alpha Test（clip / discard）代替 Alpha Blend，把连续透明度离散化为像素级"保留/丢弃"
// 导出函数统一返回 alpha - threshold（clip 值）：> 0 保留、<= 0 丢弃，
// 可直接接 ShaderGraph 的 Alpha Clip Threshold 或 clip() 节点，从而走不透明渲染路径

static float DitherHash21(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

// Bayer 2x2 基矩阵 M2 = [[0,2],[3,1]]，用解析式表达避免常量数组与动态索引
static float DitherM2(float2 b)
{
  return 2.0 * b.x + 3.0 * b.y - 4.0 * b.x * b.y;
}

// 递归构造 4x4 / 8x8 Bayer 阈值矩阵，返回 [0,1)
// M4 = 4*M2(低位) + M2(高位)；M8 = 16*M2(低) + 4*M2(中) + M2(高)
// 纯 ALU、零纹理带宽；size 传 4 或 8
static float DitherBayer(float2 screenPos, float size)
{
  float is8 = step(4.5, size);
  float s = lerp(4.0, 8.0, is8);
  float2 p = floor(frac(screenPos / s) * s);
  float2 b0 = fmod(p, 2.0);
  float2 b1 = fmod(floor(p * 0.5), 2.0);
  float2 b2 = fmod(floor(p * 0.25), 2.0);

  float v4 = 4.0 * DitherM2(b0) + DitherM2(b1);
  float v8 = 16.0 * DitherM2(b0) + 4.0 * DitherM2(b1) + DitherM2(b2);
  float v = lerp(v4, v8, is8);

  return (v + 0.5) / lerp(16.0, 64.0, is8);
}

static float DitherClipValue(float alpha, float threshold)
{
  return alpha - threshold;
}

static float DitherQuantize(float v, float levels)
{
  float n = max(floor(levels), 1.0);
  return floor(saturate(v) * n + 0.5) / n;
}

static float3 DitherQuantize3(float3 v, float levels)
{
  float n = max(floor(levels), 1.0);
  return floor(saturate(v) * n + 0.5) / n;
}

// TAA / TSR 子像素 Jitter：R2 低差异序列，让每帧抖动图案在屏幕空间微偏移
// 时序历史帧累积后，离散点阵被融合为平滑的半透明渐变
static float2 DitherTemporalOffset(float frameIndex, float strength)
{
  float2 jitter = frac(float2(frameIndex * 0.7548776662, frameIndex * 0.5698402909));
  return (jitter - 0.5) * 2.0 * strength;
}

// 逐帧随机偏移：向噪声采样坐标注入时间切片，图案完全随机化
// 消除静态网格感，但引入高频闪烁，需强时序滤波器收敛
static float2 DitherRandomOffset(float2 screenPos, float time, float strength)
{
  float slice = floor(time * 60.0);
  float2 rnd = float2(
    DitherHash21(screenPos + float2(slice, slice * 1.37)),
    DitherHash21(screenPos + float2(slice * 0.71 + 19.3, slice))
  );

  return (rnd * 2.0 - 1.0) * strength;
}

#endif