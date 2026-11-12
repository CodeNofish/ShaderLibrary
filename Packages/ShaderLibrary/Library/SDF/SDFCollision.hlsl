#ifndef SHADER_LIBRARY_SDF_COLLISION
#define SHADER_LIBRARY_SDF_COLLISION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 碰撞检测：粒子 / 角色与体积距离场的交互（GPU 粒子碰撞、角色毛发 / 布料推挤、位移约束）
// 距离场天然提供"穿透深度 + 表面法线"，一次采样即可完成传统网格碰撞需要邻域搜索的检测
// 场景来源为 Texture3D 体积距离场（契约见 SDFCommon.hlsl）
// 典型管线（粒子 Shader 或 Compute Shader）：
//   SDFVolumePenetration 判断是否穿透 → SDFCollisionNormal 取推出方向
//   → SDFVolumePushOut 直接得到修正位置 → SDFCollisionReflect 计算反弹速度

// 穿透深度：返回 max(0, -距离)，正值表示陷入物体的深度（在外为 0），可当碰撞强度用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumePenetration</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume Penetration</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume Penetration</sg:SearchName>
///     <sg:SearchTerms>SDF, Collision, Penetration, Depth, Volume, Texture3D</sg:SearchTerms>
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
float SDFVolumePenetration(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float3 boundsCenter,
  float3 boundsSize
)
{
  float d = SDFVolumeDistanceAt(volumeTex, samplerState, position, boundsCenter, boundsSize);
  return max(0.0, -d);
}

// 碰撞表面法线：中心差分梯度，作为把物体推出表面的方向
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFCollisionNormal</sg:ProviderKey>
///     <sg:DisplayName>SDF Collision Normal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Collision Normal</sg:SearchName>
///     <sg:SearchTerms>SDF, Collision, Normal, PushOut, Gradient, Volume, Texture3D</sg:SearchTerms>
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
float3 SDFCollisionNormal(
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

// 碰撞推出（Push Out）：把带半径的球体（粒子 / 毛发根 / 角色骨骼点）约束到距离场表面外
// objectRadius = 0 时退化为投影到表面；未穿透时原样返回 position
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFVolumePushOut</sg:ProviderKey>
///     <sg:DisplayName>SDF Volume Push Out</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Volume Push Out</sg:SearchName>
///     <sg:SearchTerms>SDF, Collision, PushOut, Resolve, Depenetrate, Particle, Volume, Texture3D</sg:SearchTerms>
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
///<paramhints name = "objectRadius">
///     <sg:DisplayName>Object Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
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
float3 SDFVolumePushOut(
  UnityTexture3D volumeTex,
  UnitySamplerState samplerState,
  float3 position,
  float objectRadius,
  float3 boundsCenter,
  float3 boundsSize,
  float sampleStep
)
{
  float d = SDFVolumeDistanceAt(volumeTex, samplerState, position, boundsCenter, boundsSize);
  if (d >= objectRadius)
  {
    return position;
  }

  float3 n = SDFVolumeNormalAt(volumeTex, samplerState, position, boundsCenter, boundsSize, sampleStep);
  return position + n * (objectRadius - d);
}

// 碰撞反弹速度：沿法线反射速度向量（仅处理朝向表面的分量）
// bounciness 0~1 弹性（1 完全反弹），friction 0~1 切向摩擦（1 完全停止切向运动）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFCollisionReflect</sg:ProviderKey>
///     <sg:DisplayName>SDF Collision Reflect</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Collision Reflect</sg:SearchName>
///     <sg:SearchTerms>SDF, Collision, Reflect, Bounce, Velocity, Friction, Particle</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "velocity">
///     <sg:DisplayName>Velocity</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,1,0</sg:Default>
///</paramhints>
///<paramhints name = "bounciness">
///     <sg:DisplayName>Bounciness</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "friction">
///     <sg:DisplayName>Friction</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFCollisionReflect(float3 velocity, float3 normal, float bounciness, float friction)
{
  float3 n = normalize(normal);
  float vn = dot(velocity, n);

  // 只在朝向表面运动时反弹
  if (vn >= 0.0)
  {
    return velocity;
  }

  float3 vNormal = n * vn;
  float3 vTangent = velocity - vNormal;
  return vTangent * (1.0 - saturate(friction)) - vNormal * saturate(bounciness);
}

#endif
