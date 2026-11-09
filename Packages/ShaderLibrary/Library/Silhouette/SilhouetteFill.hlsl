#ifndef SHADER_LIBRARY_SILHOUETTE_FILL
#define SHADER_LIBRARY_SILHOUETTE_FILL

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Silhouette/SilhouetteCommon.hlsl"

// 遮挡判定通过后的视觉表现形式
// 纯色/渐变半透明填充（Fresnel 幽灵）、轮廓描边（顶点膨胀）、结构化透视、动态脉冲
// 执行顺序：X-Ray Pass 需在 Opaque 之后、Transparent 之前（Queue = Geometry+1 或 RenderFeature 注入点）
// Stencil 反向描边请用 OcclusionDetection.hlsl 的 StencilOcclusion，屏幕空间描边见 EdgeDetection.hlsl

// 菲涅尔边缘光 rim = 1 - dot(N, V)
// X-Ray Pass 中最常用的可读性增强手段：边缘亮、中心暗，避免纯色块与背景混淆
// power 控制边缘收窄程度（建议 1~5），bias 可让中心也保留少量亮度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FresnelRim</sg:ProviderKey>
///     <sg:DisplayName>Fresnel Rim</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>FresnelRim</sg:SearchName>
///     <sg:SearchTerms>Silhouette, XRay, Fresnel, Rim, Ghost, Fill</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "viewDir">
///     <sg:DisplayName>View Direction</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "power">
///     <sg:DisplayName>Power</sg:DisplayName>
///     <sg:Default>3</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "bias">
///     <sg:DisplayName>Bias</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float FresnelRim(float3 normal, float3 viewDir, float power, float intensity, float bias)
{
  float ndv = saturate(dot(normalize(normal), normalize(viewDir)));
  float rim = pow(saturate(1.0 - ndv + bias), max(power, 0.001));

  return saturate(rim * intensity);
}

// 幽灵填充（Flat / Ghost Fill）
// 固定颜色 + Alpha，并用菲涅尔调制亮度与不透明度：边缘亮、中心暗的经典半透明人形
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GhostFill</sg:ProviderKey>
///     <sg:DisplayName>Ghost Fill</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>GhostFill</sg:SearchName>
///     <sg:SearchTerms>Silhouette, XRay, Ghost, Flat, Fresnel, Transparent</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "viewDir">
///     <sg:DisplayName>View Direction</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
///<paramhints name = "fillColor">
///     <sg:DisplayName>Fill Color</sg:DisplayName>
///     <sg:Default>0.3,0.8,1</sg:Default>
///</paramhints>
///<paramhints name = "fresnelPower">
///     <sg:DisplayName>Fresnel Power</sg:DisplayName>
///     <sg:Default>3</sg:Default>
///</paramhints>
///<paramhints name = "fresnelIntensity">
///     <sg:DisplayName>Fresnel Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 GhostFill(float3 normal, float3 viewDir, float3 fillColor, float fresnelPower, float fresnelIntensity, float alpha)
{
  float rim = FresnelRim(normal, viewDir, fresnelPower, fresnelIntensity, 0.0);

  return float4(fillColor * (0.35 + 0.65 * rim), saturate(alpha * (0.4 + 0.6 * rim)));
}

// 顶点膨胀描边（Vertex Extrusion Outline）
// 在 X-Ray Pass 中把顶点沿法线外扩，配合 Cull Front 只绘制背面膨胀部分作为外轮廓
// 返回外扩后的顶点位置，需接到 Vertex Position；Cull Front / ZTest 由 Pass 状态配置
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.OutlineVertexOffset</sg:ProviderKey>
///     <sg:DisplayName>Outline Vertex Offset</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>OutlineVertexOffset</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Vertex, Extrusion, Normal, CullFront</sg:SearchTerms>
///     <sg:ReturnDisplayName>Position</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,1,0</sg:Default>
///</paramhints>
///<paramhints name = "width">
///     <sg:DisplayName>Width</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 OutlineVertexOffset(float3 position, float3 normal, float width)
{
  return position + normalize(normal + float3(1e-5, 0.0, 0.0)) * width;
}

// 结构化透视（Structural X-Ray）
// 不用纯色，而是采样内部结构贴图 / 骨骼 / 线框渲染，并用遮挡遮罩限定显示范围
// 传递的是"内部是什么样"而不是"这里有东西"，是 Outline 无法替代的表现形式
// structureTex 接内部结构纹理，occlusionMask 接 OcclusionDetection 的输出
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.StructuralXRay</sg:ProviderKey>
///     <sg:DisplayName>Structural X-Ray</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>StructuralXRay</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Structural, Skeleton, Wireframe, Interior</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "structureTex">
///     <sg:DisplayName>Structure Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "occlusionMask">
///     <sg:DisplayName>Occlusion Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 StructuralXRay(
  UnityTexture2D structureTex,
  UnitySamplerState samplerState,
  float2 uv,
  float occlusionMask,
  float3 tint,
  float intensity
)
{
  float4 s = SAMPLE_TEXTURE2D(structureTex, samplerState, uv);
  float w = saturate(occlusionMask) * saturate(intensity);

  return float4(s.rgb * tint, s.a * w);
}

// 动态脉冲 / 呼吸效果（Animated Pulse）
// 在 X-Ray 输出上叠加 sin(time * speed)，使透明度或亮度周期变化，区分静态障碍与活跃目标
// noise 可接 SilhouetteNoise 的输出轻微扰动相位；不想要噪声时传 0
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.AnimatedPulse</sg:ProviderKey>
///     <sg:DisplayName>Animated Pulse</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>AnimatedPulse</sg:SearchName>
///     <sg:SearchTerms>Silhouette, XRay, Pulse, Breathing, Animation, Noise</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>2</sg:Default>
///</paramhints>
///<paramhints name = "minValue">
///     <sg:DisplayName>Min Value</sg:DisplayName>
///     <sg:Default>0.4</sg:Default>
///</paramhints>
///<paramhints name = "maxValue">
///     <sg:DisplayName>Max Value</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "noise">
///     <sg:DisplayName>Noise</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float AnimatedPulse(float time, float speed, float minValue, float maxValue, float noise)
{
  return lerp(minValue, maxValue, SilhouettePulse(time, speed, noise));
}

// 程序化滚动噪声：噪声纹理滚动的零带宽替代，可用于脉冲相位扰动或透视区域扰动
// 时间按每秒 12 帧量化，scale 为噪声网格密度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SilhouetteNoise</sg:ProviderKey>
///     <sg:DisplayName>Silhouette Noise</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>SilhouetteNoise</sg:SearchName>
///     <sg:SearchTerms>Silhouette, XRay, Noise, Scrolling, Hash, Pulse</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>32</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SilhouetteNoise(float2 uv, float time, float scale)
{
  float2 cell = floor(uv * max(scale, 1.0));
  return SilhouetteHash21(cell + floor(time * 12.0));
}

#endif