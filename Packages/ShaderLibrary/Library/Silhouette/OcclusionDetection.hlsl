#ifndef SHADER_LIBRARY_OCCLUSION_DETECTION
#define SHADER_LIBRARY_OCCLUSION_DETECTION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Silhouette/SilhouetteCommon.hlsl"

// 遮挡判定机制：文档列出四类，本文件实现其中三类可在 Shader 函数层完成的判定
// 第四类（后处理边缘检测 + 目标掩码）见 EdgeDetection.hlsl 与 XRayComposite.hlsl
// 管线配置要求：X-Ray Pass 需在 Opaque 之后、Transparent 之前渲染
// （Queue = Geometry+1 或用 Scriptable Renderer Feature 精确控制注入点）
// URP 不支持 GrabPass，必须使用 _CameraDepthTexture；多 Pass 方案需留意 SRP Batcher 兼容性

// 深度测试驱动（Multi-Pass ZTest Greater）的深度判定
// 经典两 Pass 方案：X-Ray Pass 用 ZTest Greater + ZWrite Off 绘制被遮挡部分，
// Normal Pass 用 ZTest LEqual 正常绘制可见部分；本函数等价于该 Pass 的逐像素深度比较
// 局限：模型自身背对相机的面也会满足 Greater，转身时会出现面部/手臂穿透躯干的"自透视"
// fragmentDepth 接当前片元深度，sceneDepth 接已写入的深度缓冲值；两者需同为 Raw 或同为 Linear
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ZTestGreaterOcclusion</sg:ProviderKey>
///     <sg:DisplayName>ZTest Greater Occlusion</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>ZTestGreaterOcclusion</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Occlusion, ZTest, MultiPass, Depth</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "fragmentDepth">
///     <sg:DisplayName>Fragment Depth</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "sceneDepth">
///     <sg:DisplayName>Scene Depth</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "bias">
///     <sg:DisplayName>Bias</sg:DisplayName>
///     <sg:Default>0.001</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>0.002</sg:Default>
///</paramhints>
///<paramhints name = "reverseZ">
///     <sg:DisplayName>Reverse Z</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float ZTestGreaterOcclusion(float fragmentDepth, float sceneDepth, float bias, float softness, float reverseZ)
{
  return SilhouetteOcclusion(fragmentDepth, sceneDepth, bias, softness, reverseZ);
}

// 模板缓冲驱动（Stencil Masking）的遮罩逻辑
// 生产环境解决自遮挡的推荐方案：第一 Pass 正常渲染并向 Stencil 写入 Ref（如 254），
// X-Ray Pass 用 Stencil Comp NotEqual + ZTest Greater，只排除"自身可见"像素
// selfVisibleMask = 1 表示该像素被标记为自身可见（等效 NotEqual 判定失败）
// Shader 函数无法直接读写 Stencil，该标记需由 Pass 的 Stencil{} 状态或 RenderFeature 提供
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.StencilOcclusion</sg:ProviderKey>
///     <sg:DisplayName>Stencil Occlusion</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>StencilOcclusion</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Occlusion, Stencil, SelfOcclusion, MOBA</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "selfVisibleMask">
///     <sg:DisplayName>Self Visible Mask</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "depthOccluded">
///     <sg:DisplayName>Depth Occluded</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float StencilOcclusion(float selfVisibleMask, float depthOccluded)
{
  return saturate(depthOccluded) * (1.0 - saturate(selfVisibleMask));
}

// 屏幕空间深度纹理比较（Depth Texture Compare）
// URP/HDRP 单 Pass 方案：采样 _CameraDepthTexture 与当前片元深度逐像素比较
// 需开启管线的 Depth Texture，会增加一次纹理采样带宽；优势是无需多 Pass、兼容 SRP Batcher
// screenUV 接 Screen Position，depthTex 接 _CameraDepthTexture；可配合 NormalEdge 做边缘检测
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DepthTextureOcclusion</sg:ProviderKey>
///     <sg:DisplayName>Depth Texture Occlusion</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/XRay</sg:SearchCategory>
///     <sg:SearchName>DepthTextureOcclusion</sg:SearchName>
///     <sg:SearchTerms>XRay, Silhouette, Occlusion, CameraDepthTexture, URP, SinglePass</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "depthTex">
///     <sg:DisplayName>Depth Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "screenUV">
///     <sg:DisplayName>Screen UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "fragmentDepth">
///     <sg:DisplayName>Fragment Depth</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "bias">
///     <sg:DisplayName>Bias</sg:DisplayName>
///     <sg:Default>0.001</sg:Default>
///</paramhints>
///<paramhints name = "softness">
///     <sg:DisplayName>Softness</sg:DisplayName>
///     <sg:Default>0.002</sg:Default>
///</paramhints>
///<paramhints name = "reverseZ">
///     <sg:DisplayName>Reverse Z</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DepthTextureOcclusion(
  UnityTexture2D depthTex,
  UnitySamplerState samplerState,
  float2 screenUV,
  float fragmentDepth,
  float bias,
  float softness,
  float reverseZ
)
{
  float sceneDepth = SAMPLE_TEXTURE2D(depthTex, samplerState, screenUV).r;
  return SilhouetteOcclusion(fragmentDepth, sceneDepth, bias, softness, reverseZ);
}

#endif