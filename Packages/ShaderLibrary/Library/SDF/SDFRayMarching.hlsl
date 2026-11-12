#ifndef SHADER_LIBRARY_SDF_RAY_MARCHING
#define SHADER_LIBRARY_SDF_RAY_MARCHING

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF Ray Marching（Sphere Tracing 光线步进）：沿视线按当前点到表面的距离安全步进求交
// 场景来源为 Texture3D 体积距离场（R 通道存世界单位距离，覆盖 boundsCenter ± boundsSize/2 的 AABB），
// 可由 Mesh 烘焙（Mesh-to-SDF）或程序化生成
// 典型管线：SDFRayMarchVolume 求命中距离 → 命中点 = rayOrigin + rayDir * t
//           → SDFVolumeNormal 求法线 → 基础光照 + SDFSoftShadow + SDFAO
// 性能建议：移动端把 maxSteps 限制在 48~64，surfaceEpsilon 放宽到 1/1000 体积尺寸；
//           烘焙纹理分辨率建议 32~128，配合保守截断距离减少 banding

// 采样体积距离场：查询任意世界坐标处的带符号距离（负值在物体内部）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumeDistance</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume Distance</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume Distance</sg:SearchName>
///     <sg:SearchTerms>SDF, Volume, Texture3D, Sample, Distance, Field</sg:SearchTerms>
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
///<paramhints name = "boundsCenter">
///     <sg:DisplayName>Bounds Center</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "boundsSize">
///     <sg:DisplayName>Bounds Size</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFVolumeDistance(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 boundsCenter,
  float3 boundsSize
)
{
  return SDFVolumeDistanceAt(volumeTex, samplerState, position, boundsCenter, boundsSize);
}

// 体积表面法线：中心差分梯度归一化，只在接近表面（|距离| < sampleStep）时可靠
// sampleStep 建议 1~2 个体素尺寸，过小被纹理量化淹没、过大法线被钝化
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumeNormal</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume Normal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume Normal</sg:SearchName>
///     <sg:SearchTerms>SDF, Volume, Normal, Gradient, CentralDifference, Texture3D</sg:SearchTerms>
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
///<paramhints name = "boundsCenter">
///     <sg:DisplayName>Bounds Center</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "boundsSize">
///     <sg:DisplayName>Bounds Size</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "sampleStep">
///     <sg:DisplayName>Sample Step</sg:DisplayName>
///     <sg:Default>0.01</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFVolumeNormal(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 boundsCenter,
  float3 boundsSize,
  float sampleStep
)
{
  return SDFVolumeNormalAt(volumeTex, samplerState, position, boundsCenter, boundsSize, sampleStep);
}

// 体积 Ray Marching（Sphere Tracing）：返回命中距离 t（命中点 = rayOrigin + rayDir * t），未命中返回 -1
// 先做射线-AABB 求交，从入点开始步进，跳过空区域；maxDistance 限制总长度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRayMarchVolume</sg:ProviderKey>
///     <sg:DisplayName>SDF Ray March Volume</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Ray March Volume</sg:SearchName>
///     <sg:SearchTerms>SDF, RayMarching, SphereTracing, Volume, Texture3D, Hit, Distance, Render</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///</funchints>
///<paramhints name = "volumeTex">
///     <sg:DisplayName>Volume Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "rayOrigin">
///     <sg:DisplayName>Ray Origin</sg:DisplayName>
///     <sg:Default>0,0,-5</sg:Default>
///</paramhints>
///<paramhints name = "rayDirection">
///     <sg:DisplayName>Ray Direction</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "boundsCenter">
///     <sg:DisplayName>Bounds Center</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "boundsSize">
///     <sg:DisplayName>Bounds Size</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "maxSteps">
///     <sg:DisplayName>Max Steps</sg:DisplayName>
///     <sg:Default>64</sg:Default>
///</paramhints>
///<paramhints name = "maxDistance">
///     <sg:DisplayName>Max Distance</sg:DisplayName>
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "surfaceEpsilon">
///     <sg:DisplayName>Surface Epsilon</sg:DisplayName>
///     <sg:Default>0.001</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFRayMarchVolume(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 rayOrigin,
  float3 rayDirection,
  float3 boundsCenter,
  float3 boundsSize,
  float maxSteps,
  float maxDistance,
  float surfaceEpsilon
)
{
  float3 rd = normalize(rayDirection);
  float3 boxMin = boundsCenter - boundsSize * 0.5;
  float3 boxMax = boundsCenter + boundsSize * 0.5;

  float tEnter;
  float tExit;
  if (!SDFRayBox(rayOrigin, rd, boxMin, boxMax, tEnter, tExit))
  {
    return -1.0;
  }

  float tMax = min(tExit, max(maxDistance, 0.0));
  if (tEnter > tMax)
  {
    return -1.0;
  }

  float t = tEnter + 1e-4;
  int steps = (int)clamp(maxSteps, 1.0, 256.0);

  [loop]
  for (int i = 0; i < steps; i++)
  {
    if (t > tMax)
    {
      return -1.0;
    }

    float3 pos = rayOrigin + rd * t;
    float d = SDFVolumeDistanceAt(volumeTex, samplerState, pos, boundsCenter, boundsSize) - surfaceEpsilon;
    if (d <= 0.0)
    {
      return t;
    }

    // 体积距离场是采样值，可能因量化偏小；钳制最小步长避免停滞
    t += max(d, 1e-4);
  }

  return -1.0;
}

#endif
