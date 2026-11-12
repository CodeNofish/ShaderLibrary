#ifndef SHADER_LIBRARY_SDF_PRIMITIVES
#define SHADER_LIBRARY_SDF_PRIMITIVES

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 3D 基础原语：输入采样点（物体局部空间，原点为形状中心），返回带符号距离
// 距离为世界/对象单位：正值在外、负值在内、0 在表面
// 全部采用 IQ（Inigo Quilez）的经典解析式，Box / Cylinder / Cone / Octahedron 为精确距离，
// Ellipsoid 为保守边界估计（略有高估，做遮罩/混合时安全，Ray Marching 时需适当减小步长）
// 采样点先用 SDFDomains.hlsl 的域操作变换，再查询原语，最后用 SDFCombiners.hlsl 组合

// 球体
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFSphere</sg:ProviderKey>
///     <sg:DisplayName>SDF Sphere</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Sphere</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Sphere</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFSphere(float3 position, float radius)
{
  return length(position) - max(radius, 0.0);
}

// 椭球体（保守边界估计，非精确距离）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFEllipsoid</sg:ProviderKey>
///     <sg:DisplayName>SDF Ellipsoid</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Ellipsoid</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Ellipsoid</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "radii">
///     <sg:DisplayName>Radii</sg:DisplayName>
///     <sg:Default>0.5,0.5,0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFEllipsoid(float3 position, float3 radii)
{
  float3 r = max(radii, 1e-5);
  float k0 = length(position / r);
  float k1 = length(position / (r * r));
  return k0 * (k0 - 1.0) / max(k1, 1e-5);
}

// 长方体（精确距离），halfSize 为半边长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFBox</sg:ProviderKey>
///     <sg:DisplayName>SDF Box</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Box</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Box, Cube</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "halfSize">
///     <sg:DisplayName>Half Size</sg:DisplayName>
///     <sg:Default>0.5,0.5,0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFBox(float3 position, float3 halfSize)
{
  float3 q = abs(position) - max(halfSize, 0.0);
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// 圆角长方体，cornerRadius 自动钳制到不超过最小半边长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRoundedBox</sg:ProviderKey>
///     <sg:DisplayName>SDF Rounded Box</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Rounded Box</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Box, Rounded, Corner, UI</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "halfSize">
///     <sg:DisplayName>Half Size</sg:DisplayName>
///     <sg:Default>0.5,0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "cornerRadius">
///     <sg:DisplayName>Corner Radius</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFRoundedBox(float3 position, float3 halfSize, float cornerRadius)
{
  float r = clamp(cornerRadius, 0.0, min(halfSize.x, min(halfSize.y, halfSize.z)));
  float3 q = abs(position) - max(halfSize - r, 0.0);
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// 无限水平平面（XZ 平面，高度 height）
// 注意：距离只在 Y 方向精确，平面方向无边界，通常配合 Repeat / Mirror 等域裁剪使用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFPlane</sg:ProviderKey>
///     <sg:DisplayName>SDF Plane</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Plane</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Plane, Ground, Floor</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "height">
///     <sg:DisplayName>Height</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFPlane(float3 position, float height)
{
  return position.y - height;
}

// 圆环（Torus）：majorRadius 主半径（环心到管心），minorRadius 管半径，位于 XZ 平面
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFTorus</sg:ProviderKey>
///     <sg:DisplayName>SDF Torus</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Torus</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Torus, Ring, Donut</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "majorRadius">
///     <sg:DisplayName>Major Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "minorRadius">
///     <sg:DisplayName>Minor Radius</sg:DisplayName>
///     <sg:Default>0.2</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFTorus(float3 position, float majorRadius, float minorRadius)
{
  float2 q = float2(length(position.xz) - majorRadius, position.y);
  return length(q) - minorRadius;
}

// 胶囊体（两端点 pointA / pointB + 半径），常用于角色肢体、连接体
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFCapsule</sg:ProviderKey>
///     <sg:DisplayName>SDF Capsule</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Capsule</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Capsule, Segment, Pill</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "pointA">
///     <sg:DisplayName>Point A</sg:DisplayName>
///     <sg:Default>-0.5,0,0</sg:Default>
///</paramhints>
///<paramhints name = "pointB">
///     <sg:DisplayName>Point B</sg:DisplayName>
///     <sg:Default>0.5,0,0</sg:Default>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.2</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFCapsule(float3 position, float3 pointA, float3 pointB, float radius)
{
  float3 pa = position - pointA;
  float3 ba = pointB - pointA;
  float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
  return length(pa - ba * h) - max(radius, 0.0);
}

// 圆柱体（精确距离）：沿 Y 轴、以原点为中心，halfHeight 为半高，radius 为半径
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFCylinder</sg:ProviderKey>
///     <sg:DisplayName>SDF Cylinder</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Cylinder</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Cylinder, Column, Pillar</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "halfHeight">
///     <sg:DisplayName>Half Height</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.3</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFCylinder(float3 position, float halfHeight, float radius)
{
  float2 d = abs(float2(length(position.xz), position.y)) - float2(max(radius, 0.0), max(halfHeight, 0.0));
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// 圆台 / 圆锥（精确距离）：沿 Y 轴、以原点为中心，halfHeight 为半高
// bottomRadius 底部半径、topRadius 顶部半径，topRadius = 0 即为圆锥
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFCone</sg:ProviderKey>
///     <sg:DisplayName>SDF Cone</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Cone</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Cone, Frustum, Spike</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "halfHeight">
///     <sg:DisplayName>Half Height</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "bottomRadius">
///     <sg:DisplayName>Bottom Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "topRadius">
///     <sg:DisplayName>Top Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFCone(float3 position, float halfHeight, float bottomRadius, float topRadius)
{
  float r1 = max(bottomRadius, 0.0);
  float r2 = max(topRadius, 0.0);
  float h = max(halfHeight, 1e-5);

  float2 q = float2(length(position.xz), position.y);
  float2 k1 = float2(r2, h);
  float2 k2 = float2(r2 - r1, 2.0 * h);
  float2 ca = float2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
  float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / max(SDFDot2(k2), 1e-6), 0.0, 1.0);
  float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
  return s * min(length(ca), length(cb));
}

// 正八面体（精确距离）：size 为顶点到中心的距离
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFOctahedron</sg:ProviderKey>
///     <sg:DisplayName>SDF Octahedron</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Octahedron</sg:SearchName>
///     <sg:SearchTerms>SDF, Distance, Field, Primitive, Octahedron, Gem, Crystal</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDFOctahedron(float3 position, float size)
{
  float3 p = abs(position);
  float m = p.x + p.y + p.z - size;

  float3 q;
  if (3.0 * p.x < m) q = p.xyz;
  else if (3.0 * p.y < m) q = p.yzx;
  else if (3.0 * p.z < m) q = p.zxy;
  else return m * 0.57735027;

  float k = clamp(0.5 * (q.z - q.y + size), 0.0, size);
  return length(float3(q.x, q.y - size + k, q.z - k));
}

#endif
