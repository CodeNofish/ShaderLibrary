#ifndef SHADER_LIBRARY_WATER_COMMON
#define SHADER_LIBRARY_WATER_COMMON

// 水下效果公共算法（内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点）
// 内联实现以保证各效果文件自包含，命名统一加 Water 前缀避免与其它分类冲突

static const float3 WATER_LUMA = float3(0.2126, 0.7152, 0.0722);

static float WaterLuma(float3 c)
{
  return dot(c, WATER_LUMA);
}

// 散列（算法与 Library/Helper/Hash.hlsl 的 Hash21 一致）
static float WaterHash21(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

static float2 WaterHash22(float2 p)
{
  return float2(WaterHash21(p), WaterHash21(p + float2(19.19, 7.31)));
}

// Voronoi：3x3 邻域搜索最近细胞中心，中心随时间摆动，返回 [0,1] 的细胞状光斑
// p 应已按颗粒密度缩放，配合 pow 增强对比即可作为焦散
static float WaterVoronoi(float2 p, float time)
{
  float2 n = floor(p);
  float2 f = frac(p);
  float minDist = 1.0;

  for (int y = -1; y <= 1; y++)
  {
    for (int x = -1; x <= 1; x++)
    {
      float2 g = float2((float)x, (float)y);
      float2 o = WaterHash22(n + g);
      o = 0.5 + 0.5 * sin(time + 6.2831853 * o);
      float2 r = g + o - f;
      minDist = min(minDist, dot(r, r));
    }
  }

  return saturate(1.0 - sqrt(minDist));
}

// RotateMin：矩阵旋转 + 分形最小值合并，形成网状光纹
static float WaterRotateMin(float2 p, float time)
{
  float2x2 rot = float2x2(0.8, -0.6, 0.6, 0.8);
  float2 q = p;
  float result = 1.0;

  for (int i = 0; i < 3; i++)
  {
    q = mul(rot, q) * 1.7 + float2(time * 0.3, -time * 0.2);
    float2 w = frac(q) - 0.5;
    float lines = abs(sin(w.x * 6.2831853 + time) * sin(w.y * 6.2831853 - time));
    result = min(result, lines);
  }

  return saturate(1.0 - result * 2.0);
}

// TriTwist：三角网格错切 + 逐格旋转，产生锐利的几何光斑
static float WaterTriTwist(float2 p, float time)
{
  float2 q = p;
  q.x += q.y * 0.5;
  float2 cell = floor(q);
  float2 f = frac(q) - 0.5;

  float angle = time * 0.5 + WaterHash21(cell) * 6.2831853;
  float s = sin(angle);
  float c = cos(angle);
  f = float2(f.x * c - f.y * s, f.x * s + f.y * c);

  float tri = max(abs(f.x) * 0.8660254 + f.y * 0.5, -f.y);
  return saturate(1.0 - tri * 3.0);
}

// 波动模拟频段：band = 0 高频涟漪（Ripples）、1 低频涌浪（Swell）
// 两个正交方向的正弦带相乘，再取高次幂模拟光线汇聚强度
static float WaterWaveBand(float2 p, float time, float2 direction, float band)
{
  float freq = lerp(48.0, 10.0, saturate(band));
  float2 d = normalize(direction + float2(1e-5, 0.0));
  float2 perp = float2(-d.y, d.x);
  float a = sin(dot(p, d) * freq + time * 1.3);
  float b = sin(dot(p, perp) * freq * 0.83 - time * 0.9);

  return pow(saturate(a * b), 4.0);
}

// 时间错位波形：phase 为 [0,1) 循环相位，乘 2π 保证循环首尾连续
static float2 WaterWaveOffset(float2 uv, float scale, float phase)
{
  float2 p = uv * scale + phase;
  return float2(sin(p.y + phase * 6.2831853), cos(p.x - phase * 6.2831853));
}

static float WaterCausticsContrast(float v, float contrast)
{
  return pow(saturate(v), max(contrast, 0.001));
}

// [0,1] 编码的法线/流向 → [-1,1] 的 UV 偏移
static float2 WaterDecodeNormal(float2 packedNormal, float strength)
{
  return (packedNormal * 2.0 - 1.0) * strength;
}

// 单个 Gerstner 波位移：深水波速 c = sqrt(g/k)，返回可直接加到顶点位置的 XYZ 偏移
static float3 WaterGerstner(
  float3 position,
  float time,
  float2 direction,
  float steepness,
  float wavelength,
  float speed
)
{
  float k = 6.2831853 / max(wavelength, 1e-4);
  float c = sqrt(9.8 / k);
  float2 d = normalize(direction + float2(1e-5, 0.0));
  float f = k * (dot(d, position.xz) - c * time * speed);
  float a = steepness / k;

  return float3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

#endif