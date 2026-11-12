#ifndef SHADER_LIBRARY_SDF_COMMON
#define SHADER_LIBRARY_SDF_COMMON

// SDF（有符号距离场）公共算法（内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点）
// 统一约定：距离以世界/对象单位解释——正值在物体外、负值在物体内、0 在表面上
// 内联实现以保证各效果文件自包含，命名统一加 SDF 前缀避免与其它分类冲突
//
// 体积查询契约（供 SDFRayMarching / SDFSoftShadow / SDFAO / SDFCollision 共用）：
//   场景用 Texture3D 表示，R 通道存储"以世界单位表示"的距离值（可为截断/降采样的保守估计，不可高估）；
//   纹理覆盖 AABB：[boundsCenter - boundsSize / 2, boundsCenter + boundsSize / 2]；
//   AABB 外的坐标按 clamp 方式取边界值，因此边界附近的梯度不可靠，烘焙时建议留出安全边距
//   使用本文件的 UnityTexture3D / SAMPLE_TEXTURE3D 依赖调用方先包含
//   ShaderApiReflectionSupport.hlsl（ShaderGraph 路径）或 URP Core.hlsl（手写 Shader 路径）

static float SDFDot2(float2 v)
{
  return dot(v, v);
}

// 多项式 smooth min（IQ 版）：k 必须按世界单位解释（平滑半径），不是无量纲"平滑度"
static float SDFSmoothMin(float a, float b, float k)
{
  float h = clamp(0.5 + 0.5 * (b - a) / max(k, 1e-6), 0.0, 1.0);
  return lerp(b, a, h) - k * h * (1.0 - h);
}

// 多项式 smooth max：与 SDFSmoothMin 对应的"平滑求交"
static float SDFSmoothMax(float a, float b, float k)
{
  float h = clamp(0.5 - 0.5 * (b - a) / max(k, 1e-6), 0.0, 1.0);
  return lerp(b, a, h) + k * h * (1.0 - h);
}

// 交错梯度噪声（Interleaved Gradient Noise）：比白噪声低频闪烁、比 Bayer 少规则纹理，适合屏幕空间抖动
static float SDFInterleavedGradientNoise(float2 p)
{
  return frac(52.9829189 * frac(0.06711056 * p.x + 0.00583715 * p.y));
}

// 2D 点旋转（角度制，正值为逆时针）
static float2 SDFRotatePoint2D(float2 p, float degrees)
{
  float a = radians(degrees);
  float c = cos(a);
  float s = sin(a);
  return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// 3D 点欧拉旋转（角度制，顺序 X → Y → Z）
static float3 SDFRotatePoint3D(float3 p, float3 degrees)
{
  float3 a = radians(degrees);
  float3 c = cos(a);
  float3 s = sin(a);

  // 绕 X
  float3 q = float3(p.x, c.x * p.y - s.x * p.z, s.x * p.y + c.x * p.z);
  // 绕 Y
  q = float3(c.y * q.x + s.y * q.z, q.y, -s.y * q.x + c.y * q.z);
  // 绕 Z
  q = float3(c.z * q.x - s.z * q.y, s.z * q.x + c.z * q.y, q.z);
  return q;
}

// 世界坐标 → 体积纹理 uvw [0,1]（AABB 外饱和到边界）
static float3 SDFVolumeUVW(float3 position, float3 boundsCenter, float3 boundsSize)
{
  float3 invSize = 1.0 / max(boundsSize, 1e-6);
  return saturate((position - (boundsCenter - boundsSize * 0.5)) * invSize);
}

// 采样体积 SDF 距离（世界单位）
static float SDFVolumeDistanceAt(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 boundsCenter,
  float3 boundsSize
)
{
  return SAMPLE_TEXTURE3D(volumeTex, samplerState, SDFVolumeUVW(position, boundsCenter, boundsSize)).r;
}

// 中心差分求体积表面法线：只在接近表面时可靠；梯度接近 0 时回退 (0,1,0) 避免 NaN
static float3 SDFVolumeNormalAt(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 boundsCenter,
  float3 boundsSize,
  float step
)
{
  float h = max(step, 1e-5);
  float dx = SDFVolumeDistanceAt(volumeTex, samplerState, position + float3(h, 0.0, 0.0), boundsCenter, boundsSize)
    - SDFVolumeDistanceAt(volumeTex, samplerState, position - float3(h, 0.0, 0.0), boundsCenter, boundsSize);
  float dy = SDFVolumeDistanceAt(volumeTex, samplerState, position + float3(0.0, h, 0.0), boundsCenter, boundsSize)
    - SDFVolumeDistanceAt(volumeTex, samplerState, position - float3(0.0, h, 0.0), boundsCenter, boundsSize);
  float dz = SDFVolumeDistanceAt(volumeTex, samplerState, position + float3(0.0, 0.0, h), boundsCenter, boundsSize)
    - SDFVolumeDistanceAt(volumeTex, samplerState, position - float3(0.0, 0.0, h), boundsCenter, boundsSize);

  float3 n = float3(dx, dy, dz);
  float len = length(n);
  return (len > 1e-5) ? n / len : float3(0.0, 1.0, 0.0);
}

// 射线-AABB（slab 法）：rayDir 必须已归一化，tEnter 钳制到 0（起点在盒内时从 0 开始）
static bool SDFRayBox(
  float3 rayOrigin,
  float3 rayDir,
  float3 boxMin,
  float3 boxMax,
  out float tEnter,
  out float tExit
)
{
  float3 inv = 1.0 / rayDir;
  float3 t0 = (boxMin - rayOrigin) * inv;
  float3 t1 = (boxMax - rayOrigin) * inv;
  float3 tMin = min(t0, t1);
  float3 tMax = max(t0, t1);

  tEnter = max(max(tMin.x, tMin.y), max(tMin.z, 0.0));
  tExit = min(min(tMax.x, tMax.y), tMax.z);
  return tExit >= tEnter;
}

#endif
