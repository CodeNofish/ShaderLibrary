#ifndef SHADER_LIBRARY_SDF_PRIMITIVES_2D
#define SHADER_LIBRARY_SDF_PRIMITIVES_2D

#include "ShaderApiReflectionSupport.hlsl"

// SDF 2D 基础原语：输入采样点（通常直接接 UV），返回带符号距离
// 距离为 UV / 对象单位：负值在形状内、正值在形状外、0 在边缘
// 配合 SDFUtils.hlsl 的抗锯齿遮罩（SDFAAMask / SDFOutlineMask / SDFDitherMask）即可实现
// 分辨率无关的 UI 圆角矩形、描边、转场、遮罩与 VFX 图案
// 全部采用 IQ（Inigo Quilez）的经典 2D 解析式

// 圆形
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DCircle</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Circle</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Circle</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Circle, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DCircle(float2 position, float radius)
{
  return length(position) - max(radius, 0.0);
}

// 矩形（可带圆角）
// halfSize 为半宽半高
// cornerRadius 自动钳制到不超过最小半边长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DBox</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Box</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Box</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Box, Rounded, Corner, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "halfSize">
///     <sg:DisplayName>Half Size</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "cornerRadius">
///     <sg:DisplayName>Corner Radius</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DBox(float2 position, float2 halfSize, float cornerRadius)
{
  float r = clamp(cornerRadius, 0.0, min(halfSize.x, halfSize.y));
  float2 q = abs(position) - max(halfSize - r, 0.0);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// 线段（pointA 到 pointB）
// 本身无宽度，配合描边 / 距离阈值形成任意方向的线条
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DSegment</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Segment</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Segment</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Segment, Line, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "pointA">
///     <sg:DisplayName>Point A</sg:DisplayName>
///     <sg:Default>-0.5,0</sg:Default>
///</paramhints>
///<paramhints name = "pointB">
///     <sg:DisplayName>Point B</sg:DisplayName>
///     <sg:Default>0.5,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DSegment(float2 position, float2 pointA, float2 pointB)
{
  float2 pa = position - pointA;
  float2 ba = pointB - pointA;
  float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
  return length(pa - ba * h);
}

// 菱形
// halfSize 为两对角线的半长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DRhombus</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Rhombus</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Rhombus</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Rhombus, Diamond, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "halfSize">
///     <sg:DisplayName>Half Size</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DRhombus(float2 position, float2 halfSize)
{
  float2 p = abs(position);
  float2 b = max(halfSize, 1e-6);

  // ndot(a, b) = a.x * b.x - a.y * b.y，此处 a = b - 2p
  float h = clamp((b.x * (b.x - 2.0 * p.x) - b.y * (b.y - 2.0 * p.y)) / dot(b, b), -1.0, 1.0);
  float d = length(p - 0.5 * b * float2(1.0 - h, 1.0 + h));
  return d * sign(p.x * b.y + p.y * b.x - b.x * b.y);
}

// 五角星
// outerRadius 外接半径
// innerRatio 内半径比例（0.1~0.9，越小星越尖）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DStar</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Star</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Star</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Star, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "outerRadius">
///     <sg:DisplayName>Outer Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
///<paramhints name = "innerRatio">
///     <sg:DisplayName>Inner Ratio</sg:DisplayName>
///     <sg:Default>0.45</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DStar(float2 position, float outerRadius, float innerRatio)
{
  const float2 k1 = float2(0.809016994, -0.587785252);
  const float2 k2 = float2(-k1.x, k1.y);
  float r = max(outerRadius, 1e-5);
  float rf = clamp(innerRatio, 0.05, 0.95);

  float2 p = position;
  p.x = abs(p.x);
  p -= 2.0 * max(dot(k1, p), 0.0) * k1;
  p -= 2.0 * max(dot(k2, p), 0.0) * k2;
  p.x = abs(p.x);
  p.y -= r;

  float2 ba = rf * float2(-k1.y, k1.x) - float2(0.0, 1.0);
  float h = clamp(dot(p, ba) / max(dot(ba, ba), 1e-6), 0.0, r);
  return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

// 正六边形
// radius 为外接圆半径（尖朝上下方向）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DHexagon</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Hexagon</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Hexagon</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Hexagon, Hex, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DHexagon(float2 position, float radius)
{
  const float3 k = float3(-0.866025404, 0.5, 0.577350269);
  float r = max(radius, 1e-5);

  float2 p = abs(position);
  p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
  p -= float2(clamp(p.x, -k.z * r, k.z * r), r);
  return length(p) * sign(p.y);
}

// 等边三角形
// radius 为外接圆半径，底边朝下
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDF2DTriangle</sg:ProviderKey>
///     <sg:DisplayName>SDF 2D Triangle</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF2D Triangle</sg:SearchName>
///     <sg:SearchTerms>SDF, 2D, Distance, Field, Primitive, Triangle, Equilateral, UI, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SDF2DTriangle(float2 position, float radius)
{
  const float k = 1.7320508;
  float r = max(radius, 1e-5);

  float2 p = position;
  p.x = abs(p.x) - r;
  p.y = p.y + r / k;
  if (p.x + k * p.y > 0.0)
  {
    p = float2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
  }
  p.x -= clamp(p.x, -2.0 * r, 0.0);
  return -length(p) * sign(p.y);
}

#endif
