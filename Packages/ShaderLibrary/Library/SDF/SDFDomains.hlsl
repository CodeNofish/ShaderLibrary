#ifndef SHADER_LIBRARY_SDF_DOMAINS
#define SHADER_LIBRARY_SDF_DOMAINS

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/SDF/SDFCommon.hlsl"

// SDF 域操作：变换"采样点"而不是形状本身，输出变换后的坐标，再接原语求距离
// 约定：SDFTranslate / SDFRotate / SDFScale / SDFRepeat / SDFMirror 的参数描述"形状"的变换，
//       函数内部自动做逆变换，链式连接即可得到直觉结果
// 注意两类操作会破坏距离场的 1-Lipschitz 性质，Ray Marching 时需减小步长：
//   1) SDFScale：形状放大 s 倍后，最终距离必须乘回 s 才是真实距离
//   2) SDFTwist / SDFBend：连续变形后距离只是估计值，强度越大越失真

// ---- 2D 域操作 ----

// 2D 平移：形状中心移动到 offset 处
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFTranslate2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Translate 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Translate 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Translate, Offset, Move, Position</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFTranslate2D(float2 position, float2 offset)
{
  return position - offset;
}

// 2D 旋转（角度制，正值为逆时针），绕原点
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRotate2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Rotate 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Rotate 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Rotate, Angle, Spin</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "angle">
///     <sg:DisplayName>Angle (Degrees)</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFRotate2D(float2 position, float angle)
{
  return SDFRotatePoint2D(position, -angle);
}

// 2D 等比缩放：scale > 1 放大形状；最终距离需乘 scale 才是真实距离
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFScale2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Scale 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Scale 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Scale, Zoom</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFScale2D(float2 position, float scale)
{
  return position / max(scale, 1e-6);
}

// 2D 无限平铺：spacing 为单元尺寸；原语尺寸必须小于半个 spacing，否则相邻副本重叠导致距离失真
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRepeat2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Repeat 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Repeat 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Repeat, Tile, Pattern, Grid, Infinite</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "spacing">
///     <sg:DisplayName>Spacing</sg:DisplayName>
///     <sg:Default>1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFRepeat2D(float2 position, float2 spacing)
{
  float2 c = max(spacing, 1e-6);
  return position - c * round(position / c);
}

// 2D 有限平铺：repetitions 为每个轴上的单元总数（含中心，奇数居中对称）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRepeatBounded2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Repeat Bounded 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Repeat Bounded 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Repeat, Tile, Bounded, Limited, Count</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "spacing">
///     <sg:DisplayName>Spacing</sg:DisplayName>
///     <sg:Default>0.25,0.25</sg:Default>
///</paramhints>
///<paramhints name = "repetitions">
///     <sg:DisplayName>Repetitions</sg:DisplayName>
///     <sg:Default>3,3</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFRepeatBounded2D(float2 position, float2 spacing, float2 repetitions)
{
  float2 c = max(spacing, 1e-6);
  float2 l = max(repetitions - 1.0, 0.0) * 0.5;
  return position - c * clamp(round(position / c), -l, l);
}

// 2D 镜像：mirrorX / mirrorY 大于 0.5 时对应轴做 abs，形状沿该轴对称
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFMirror2D</sg:ProviderKey>
///     <sg:DisplayName>SDF Mirror 2D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Mirror 2D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 2D, Mirror, Symmetry, Abs, Flip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>UV0</sg:Default>
///     <UV/>
///</paramhints>
///<paramhints name = "mirrorX">
///     <sg:DisplayName>Mirror X</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "mirrorY">
///     <sg:DisplayName>Mirror Y</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 SDFMirror2D(float2 position, float mirrorX, float mirrorY)
{
  float2 q = position;
  q.x = lerp(q.x, abs(q.x), step(0.5, mirrorX));
  q.y = lerp(q.y, abs(q.y), step(0.5, mirrorY));
  return q;
}

// ---- 3D 域操作 ----

// 3D 平移：形状中心移动到 offset 处
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFTranslate</sg:ProviderKey>
///     <sg:DisplayName>SDF Translate</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Translate</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Translate, Offset, Move, Position</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "offset">
///     <sg:DisplayName>Offset</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFTranslate(float3 position, float3 offset)
{
  return position - offset;
}

// 3D 欧拉旋转（角度制，顺序 X → Y → Z，左手系绕轴正向），绕原点
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRotate3D</sg:ProviderKey>
///     <sg:DisplayName>SDF Rotate 3D</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Rotate 3D</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Rotate, Euler, Angle, Spin</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "angles">
///     <sg:DisplayName>Angles (Degrees)</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFRotate3D(float3 position, float3 angles)
{
  return SDFRotatePoint3D(position, -angles);
}

// 3D 等比缩放：scale > 1 放大形状；最终距离需乘 scale 才是真实距离
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFScale</sg:ProviderKey>
///     <sg:DisplayName>SDF Scale</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Scale</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Scale, Zoom</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFScale(float3 position, float scale)
{
  return position / max(scale, 1e-6);
}

// 3D 无限平铺：spacing 为单元尺寸；原语尺寸必须小于半个 spacing，否则相邻副本重叠导致距离失真
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRepeat</sg:ProviderKey>
///     <sg:DisplayName>SDF Repeat</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Repeat</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Repeat, Tile, Grid, Infinite, Instancing</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "spacing">
///     <sg:DisplayName>Spacing</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFRepeat(float3 position, float3 spacing)
{
  float3 c = max(spacing, 1e-6);
  return position - c * round(position / c);
}

// 3D 有限平铺：repetitions 为每个轴上的单元总数（含中心，奇数居中对称）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFRepeatBounded</sg:ProviderKey>
///     <sg:DisplayName>SDF Repeat Bounded</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Repeat Bounded</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Repeat, Tile, Bounded, Limited, Count</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "spacing">
///     <sg:DisplayName>Spacing</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "repetitions">
///     <sg:DisplayName>Repetitions</sg:DisplayName>
///     <sg:Default>3,3,3</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFRepeatBounded(float3 position, float3 spacing, float3 repetitions)
{
  float3 c = max(spacing, 1e-6);
  float3 l = max(repetitions - 1.0, 0.0) * 0.5;
  return position - c * clamp(round(position / c), -l, l);
}

// 3D 镜像：对应轴大于 0.5 时做 abs，形状沿该轴平面（YZ / XZ / XY）对称
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFMirror</sg:ProviderKey>
///     <sg:DisplayName>SDF Mirror</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Mirror</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Mirror, Symmetry, Abs, Flip</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "mirrorX">
///     <sg:DisplayName>Mirror X</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "mirrorY">
///     <sg:DisplayName>Mirror Y</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "mirrorZ">
///     <sg:DisplayName>Mirror Z</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFMirror(float3 position, float mirrorX, float mirrorY, float mirrorZ)
{
  float3 q = position;
  q.x = lerp(q.x, abs(q.x), step(0.5, mirrorX));
  q.y = lerp(q.y, abs(q.y), step(0.5, mirrorY));
  q.z = lerp(q.z, abs(q.z), step(0.5, mirrorZ));
  return q;
}

// 3D 扭曲（绕 Y 轴）：旋转量随高度线性增加，形成螺旋效果
// 注意：距离场为估计值，Ray Marching 时需配合较小步长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFTwist</sg:ProviderKey>
///     <sg:DisplayName>SDF Twist</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Twist</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Twist, Spiral, Swirl, Deform, Warp</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFTwist(float3 position, float strength)
{
  float a = strength * position.y;
  float c = cos(a);
  float s = sin(a);
  return float3(c * position.x - s * position.z, position.y, s * position.x + c * position.z);
}

// 3D 弯折（沿 X 轴）：弯曲量随 X 坐标线性增加，把直柱弯成弧形（IQ cheap bend）
// 注意：距离场为估计值，Ray Marching 时需配合较小步长
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SDFBend</sg:ProviderKey>
///     <sg:DisplayName>SDF Bend</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/SDF</sg:SearchCategory>
///     <sg:SearchName>SDF Bend</sg:SearchName>
///     <sg:SearchTerms>SDF, Domain, 3D, Bend, Curve, Bow, Deform, Warp</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SDFBend(float3 position, float strength)
{
  float a = strength * position.x;
  float c = cos(a);
  float s = sin(a);
  return float3(c * position.x - s * position.y, s * position.x + c * position.y, position.z);
}

#endif
