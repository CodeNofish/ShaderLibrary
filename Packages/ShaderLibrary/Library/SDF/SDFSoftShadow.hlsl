#ifndef SHADER_LIBRARY_SDF_SOFT_SHADOW
#define SHADER_LIBRARY_SDF_SOFT_SHADOW

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 距离场软阴影（IQ 软阴影）：从表面点沿光照方向步进，
// 用"最近遮挡距离 / 行进距离"的累积最小值估计半影，实现接触硬化（靠得越近阴影越锐）
// 返回 [0,1]：1 完全受光，0 完全被遮挡，中间值为半影过渡
// 场景来源为 Texture3D 体积距离场（契约见 SDFCommon.hlsl）
// 用法：position 接表面命中点（可先沿法线抬升 0.5~1 个体素防自阴影），lightDirection 接指向光源的方向
// softness（k）越大阴影越软：k = 8 中等，k = 32 接近硬阴影

// 体积距离场软阴影（含接触硬化）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumeSoftShadow</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume Soft Shadow</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume Soft Shadow</sg:SearchName>
///     <sg:SearchTerms>SDF, SoftShadow, Penumbra, Light, Occlusion, Volume, Texture3D</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///</funchints>
///<paramhints name = "volumeTex">
///     <sg:DisplayName>Volume Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "lightDirection">
///     <sg:DisplayName>Light Direction</sg:DisplayName>
///     <sg:Default>0,1,0</sg:Default>
///</paramhints>
///<paramhints name = "boundsCenter">
///     <sg:DisplayName>Bounds Center</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "boundsSize">
///     <sg:DisplayName>Bounds Size</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
///<paramhints name = "maxDistance">
///     <sg:DisplayName>Max Distance</sg:DisplayName>
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "maxSteps">
///     <sg:DisplayName>Max Steps</sg:DisplayName>
///     <sg:Default>32</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFVolumeSoftShadow(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 lightDirection,
  float3 boundsCenter,
  float3 boundsSize,
  float softness,
  float maxDistance,
  float maxSteps
)
{
  float3 rd = normalize(lightDirection);
  float3 boxMin = boundsCenter - boundsSize * 0.5;
  float3 boxMax = boundsCenter + boundsSize * 0.5;

  // 与 AABB 求交，限制步进区间；不相交或区间为空视为受光
  float tEnter;
  float tExit;
  if (!SDFRayBox(position, rd, boxMin, boxMax, tEnter, tExit))
  {
    return 1.0;
  }

  float tMax = min(tExit, max(maxDistance, 0.0));
  if (tEnter > tMax)
  {
    return 1.0;
  }

  // 从入点加固定偏移起步，避免表面采样到自身导致全黑
  float t = tEnter + 0.01;
  float k = max(softness, 0.01);
  float res = 1.0;
  int steps = (int)clamp(maxSteps, 1.0, 128.0);

  [loop]
  for (int i = 0; i < steps; i++)
  {
    if (t > tMax)
    {
      break;
    }

    float h = SDFVolumeDistanceAt(volumeTex, samplerState, position + rd * t, boundsCenter, boundsSize);
    res = min(res, k * h / max(t, 1e-4));
    if (res < 0.005)
    {
      break;
    }

    // 钳制单步长度：下限避免量化值停滞，上限避免大步跳过遮挡
    t += clamp(h, 0.01, 0.10);
  }

  return clamp(res, 0.0, 1.0);
}

#endif
