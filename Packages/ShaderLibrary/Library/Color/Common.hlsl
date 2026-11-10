#ifndef SHADER_LIBRARY_COLOR_COMMON
#define SHADER_LIBRARY_COLOR_COMMON

// Rec.709 亮度权重
static const float3 COLOR_LUMA = float3(0.2126, 0.7152, 0.0722);

// 计算颜色的亮度值
static float ColorLumaInternal(float3 c)
{
  return dot(c, COLOR_LUMA);
}

// 散列内部使用
static float ColorHash31(float3 p)
{
  p = frac(p * 0.1031);
  p += dot(p, p.zyx + 31.32);
  return frac((p.x + p.y) * p.z);
}

// 生成近似高斯分布（正态分布）的单色噪声
static float ColorGaussianNoise(float2 uv, float slice, float size, float seed)
{
  float2 cell = floor(uv * max(size, 1.0));
  float3 p = float3(cell + float2(slice, seed), slice);
  float h = (ColorHash31(p) + ColorHash31(p + 17.13) + ColorHash31(p + 41.71)) / 3.0;
  return clamp((h - 0.5) * 6.0, -2.0, 2.0) * 0.5;
}

// 计算胶片颗粒的权重。
// 基于亮度计算，使得颗粒感在中间调（灰色区域）最明显，而在纯黑或纯白区域减弱，模拟真实胶片的物理特性。
// 胶片颗粒的亮度权重：中间调最明显，纯黑与纯白处减弱
static float ColorGrainWeight(float3 color)
{
  float d = abs(saturate(ColorLumaInternal(color)) - 0.5) * 2.0;
  return 1.0 - d * d;
}

// 将 sRGB 线性颜色转换为 ACEScg (AP1) 色彩空间。这是进行高质量电影级色调映射的前置步骤。
// ACES RRT + ODT fit 使用的 sRGB linear ↔ AP1(ACEScg) 矩阵
static float3 ColorLinearToACEScg(float3 c)
{
  return mul(float3x3(
               0.59719, 0.35458, 0.04823,
               0.07600, 0.90834, 0.01566,
               0.02840, 0.13383, 0.83777
             ), c);
}

// 将 ACEScg (AP1) 色彩空间转换回 sRGB 线性空间。
static float3 ColorACEScgToLinear(float3 c)
{
  return mul(float3x3(
               1.60475, -0.53108, -0.07367,
               -0.10208, 1.10813, -0.00605,
               -0.00327, -0.07276, 1.07602
             ), c);
}

// 实现 ACES 电影级色调映射（基于 Stephen Hill 的拟合公式）。
// 它先将颜色转换到 AP1 空间进行动态范围压缩，再转回线性空间，能有效保留高光细节并提升画面质感。
// ACES filmic tone mapping（Stephen Hill fit），在 AP1 空间压缩并回到 sRGB linear
static float3 ColorACESFit(float3 color)
{
  float3 v = ColorLinearToACEScg(color);
  float3 a = v * (v + 0.0245786) - 0.000090537;
  float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  v = a / b;
  return saturate(ColorACEScgToLinear(v));
}

// 将线性颜色转换为 ARRI LogC (EI800) 对数编码空间。
// 这种编码常用于存储 HDR 调色结果，能更好地保留高动态范围信息。
// Unity URP 的 HDR LUT 即使用 LogC 编码存储 HDR 调色结果
static float3 ColorLinearToLogC(float3 color)
{
  float3 x = max(color, 0.0);
  float3 high = 0.247190 * log10(5.555556 * x + 0.052272) + 0.385537;
  float3 low = 5.367655 * x + 0.092809;
  return lerp(low, high, step(0.010591, x));
}

// 将 ARRI LogC 对数编码颜色还原为线性颜色。
static float3 ColorLogCToLinear(float3 logC)
{
  float3 high = (exp2((logC - 0.385537) / 0.247190 * 3.3219281) - 0.052272) / 5.555556;
  float3 low = (logC - 0.092809) / 5.367655;
  return max(lerp(low, high, step(0.149659, logC)), 0.0);
}

// 程序化暗角衰减：中心亮、边缘暗
// aspect 为屏幕宽高比，用于把 UV 距离换算为像素等距；roundness 0 圆形、1 矩形
static float ColorVignetteFalloff(float2 uv, float2 center, float smoothness, float roundness, float aspect)
{
  float2 p = (uv - center) * float2(max(aspect, 0.001), 1.0);
  float dist = lerp(length(p), max(abs(p.x), abs(p.y)), saturate(roundness));
  return pow(saturate(1.0 - dist * dist), max(smoothness, 0.001));
}

#endif