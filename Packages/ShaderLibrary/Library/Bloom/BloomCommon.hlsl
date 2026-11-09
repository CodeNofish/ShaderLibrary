#ifndef SHADER_LIBRARY_BLOOM_COMMON
#define SHADER_LIBRARY_BLOOM_COMMON

// 泛光公共算法（内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点）
// 内联实现以保证各效果文件自包含，命名统一加 Bloom 前缀避免与其它分类冲突
// 注意：级联降采样-上采样架构由 RenderFeature / RenderGraph 的多个 Pass 与 Mip 组织，
//       本库只实现各阶段单 Pass 的算法（Brightpass / Downsample / SeparableBlur / Upsample / Composite）

static const float3 BLOOM_LUMA = float3(0.2126, 0.7152, 0.0722);

static float BloomLuma(float3 c)
{
  return dot(c, BLOOM_LUMA);
}

// Threshold + Knee 软阈值曲线（URP Prefilter 同款）
// knee 控制阈值附近的软过渡，避免硬截断导致小光源闪烁；返回的是亮度贡献系数
static float BloomKneeCurve(float brightness, float threshold, float knee)
{
  float k = max(knee, 1e-4);
  float soft = clamp(brightness - threshold + k, 0.0, 2.0 * k);
  soft = soft * soft / (4.0 * k + 1e-4);
  float contribution = max(soft, brightness - threshold);

  return contribution / max(brightness, 1e-4);
}

// Screen 混合：1 - (1-a)(1-b)，比 Additive 更自然，避免高光过曝死白
static float3 BloomScreenBlend(float3 a, float3 b)
{
  return 1.0 - (1.0 - saturate(a)) * (1.0 - saturate(b));
}

// Catmull-Rom 核，用于 High Quality Filtering 的 Bicubic 降采样
static float BloomCatmullRom(float x)
{
  x = abs(x);
  if (x < 1.0)
  {
    return (1.5 * x - 2.5) * x * x + 1.0;
  }
  if (x < 2.0)
  {
    return ((-0.5 * x + 2.5) * x - 4.0) * x + 2.0;
  }

  return 0.0;
}

static float BloomGaussianWeight(float x, float sigma)
{
  float s = max(sigma, 1e-4);
  return exp(-0.5 * (x * x) / (s * s));
}

// 物理正确泛光：纹素空间半径随 Mip 层级指数增长，模糊尺度自适应
// 使不同分辨率、不同 Mip 的模糊保持能量守恒与视觉一致（HDRP energy-conserving 思路）
static float BloomTexelRadius(float mipLevel, float scatter)
{
  return scatter * exp2(max(mipLevel, 0.0));
}

// 卷积核权重：高斯光晕 + 沿 direction 拉伸的 Streak 条纹
// p 为 [-1,1] 的核坐标；radius 控制光晕收束，streak 控制条纹强度
static float BloomKernelWeightCore(float2 p, float radius, float streak, float2 direction)
{
  float2 d = normalize(direction + float2(1e-5, 0.0));
  float2 perp = float2(-d.y, d.x);
  float r2 = dot(p, p);

  float gauss = exp(-r2 * max(radius, 1e-4) * 4.0);
  float along = abs(dot(p, perp));
  float streakW = exp(-along * 12.0 / (1.0 + max(streak, 0.0) * 8.0)) * exp(-r2 * 2.0);

  return saturate(gauss + max(streak, 0.0) * streakW);
}

#endif