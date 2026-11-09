#ifndef SHADER_LIBRARY_XRAY_COMPOSITE
#define SHADER_LIBRARY_XRAY_COMPOSITE

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Silhouette/SilhouetteCommon.hlsl"

// 剪影 / 透视的最终合成：把遮挡遮罩、幽灵填充、轮廓与脉冲组合到场景颜色上
// 典型串接：OcclusionDetection → GhostFill / StructuralXRay → AnimatedPulse → XRayComposite
//           批量目标方案可改用 EdgeDetection → OccludedEdge → XRayComposite
// 管线注意事项：
// - X-Ray Pass 必须在 Opaque 之后、Transparent 之前（Queue = Geometry+1 或 RenderFeature 注入点）
// - URP 不支持 GrabPass，深度比较须使用 _CameraDepthTexture
// - 纯 ZTest Greater 会有自透视；队友标记等生产场景应使用 Stencil 方案排除自身可见像素
// - 少量目标用 Per-Object 多 Pass（DrawCall 翻倍），大批量目标用后处理全屏（固定开销高）
// - 文档未涵盖光线追踪可见性缓冲（RT Visibility Buffer），此处仅实现传统光栅化方案

// 幽灵轮廓：掩码轮廓 × 遮挡遮罩，只在被遮挡区域显示外轮廓，内部保持透明
// edgeMask 接 SobelMaskEdge / CombineEdges，occlusionMask 接 OcclusionDetection 的输出
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.OccludedEdge</sg:ProviderKey>
///     <sg:DisplayName>Occluded Edge</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>OccludedEdge</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Edge, Outline, Occlusion, Ghost</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "edgeMask">
///     <sg:DisplayName>Edge Mask</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "occlusionMask">
///     <sg:DisplayName>Occlusion Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float OccludedEdge(float edgeMask, float occlusionMask)
{
  return saturate(edgeMask) * saturate(occlusionMask);
}

// 遮挡透明度：合并遮挡遮罩、脉冲与基础 Alpha，可直接接 ShaderGraph 的 Alpha 端口
// pulse 传 1 表示不做动画；min/max 值由 AnimatedPulse 控制
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.OcclusionAlpha</sg:ProviderKey>
///     <sg:DisplayName>Occlusion Alpha</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>OcclusionAlpha</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Alpha, Occlusion, Pulse, Transparent</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "occlusionMask">
///     <sg:DisplayName>Occlusion Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "pulse">
///     <sg:DisplayName>Pulse</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float OcclusionAlpha(float occlusionMask, float pulse, float alpha)
{
  return saturate(occlusionMask) * max(pulse, 0.0) * saturate(alpha);
}

// X-Ray 合成（组合）
// 被遮挡区域按 xrayColor 叠加幽灵色，边缘按 edgeColor 覆盖描边；两者都受遮挡遮罩约束
// xrayColor 可接 GhostFill 的 RGB 或 StructuralXRay 的结果，pulse 接 AnimatedPulse
// edgeMask 传 0 即为纯色/渐变填充；alpha 传 0 且只给 edgeMask 即为"仅轮廓内部透明"
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.XRayComposite</sg:ProviderKey>
///     <sg:DisplayName>X-Ray Composite</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>XRayComposite</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Composite, Ghost, Outline, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "sceneColor">
///     <sg:DisplayName>Scene Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "xrayColor">
///     <sg:DisplayName>X-Ray Color</sg:DisplayName>
///     <sg:Default>0.3,0.8,1</sg:Default>
///</paramhints>
///<paramhints name = "occlusionMask">
///     <sg:DisplayName>Occlusion Mask</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "edgeMask">
///     <sg:DisplayName>Edge Mask</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "edgeColor">
///     <sg:DisplayName>Edge Color</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "pulse">
///     <sg:DisplayName>Pulse</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 XRayComposite(
  float3 sceneColor,
  float3 xrayColor,
  float occlusionMask,
  float edgeMask,
  float3 edgeColor,
  float pulse,
  float alpha
)
{
  float w = OcclusionAlpha(occlusionMask, pulse, alpha);
  float3 result = lerp(sceneColor, xrayColor, w);
  float e = OccludedEdge(edgeMask, occlusionMask);

  return lerp(result, edgeColor, e);
}

#endif