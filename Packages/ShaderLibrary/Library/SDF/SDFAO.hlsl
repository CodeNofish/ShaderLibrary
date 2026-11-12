#ifndef SHADER_LIBRARY_SDF_AO
#define SHADER_LIBRARY_SDF_AO

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// 基于 SDF 的环境光遮蔽近似（IQ calcAO）：沿法线方向在递增半径处采样距离场，
// "采样距离小于采样半径"意味着有近旁几何遮挡，按衰减权重累积得到 AO
// 相比屏幕空间 AO（SSAO）无屏幕边界漏光、无需法线/深度缓冲，适合体积 / 隐式物体
// 场景来源为 Texture3D 体积距离场（契约见 SDFCommon.hlsl）
// 返回 [0,1]：1 无遮挡，0 完全遮蔽；radius 控制遮蔽范围，intensity 控制强度

// 体积距离场环境光遮蔽（固定 5 次采样）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumeAO</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume AO</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume AO</sg:SearchName>
///     <sg:SearchTerms>SDF, AO, AmbientOcclusion, DFAO, Volume, Texture3D, Occlusion</sg:SearchTerms>
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
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFVolumeAO(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 normal,
  float3 boundsCenter,
  float3 boundsSize,
  float radius,
  float intensity
)
{
  float3 n = normalize(normal);
  float r = max(radius, 1e-4);

  float occ = 0.0;
  float sca = 1.0;

  [unroll]
  for (int i = 0; i < 5; i++)
  {
    float h = 0.01 + r * float(i) / 4.0;
    float d = SDFVolumeDistanceAt(volumeTex, samplerState, position + n * h, boundsCenter, boundsSize);
    occ += (h - d) * sca;
    sca *= 0.85;
  }

  return saturate(1.0 - intensity * 2.0 * occ);
}

#endif
