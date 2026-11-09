#ifndef SHADER_LIBRARY_EDGE_DETECTION
#define SHADER_LIBRARY_EDGE_DETECTION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Silhouette/SilhouetteCommon.hlsl"

// 后处理边缘检测 + 目标掩码：不修改目标物体 Shader，
// 用 RenderFeature / 专用相机把目标渲染到临时 RT（目标掩码），再对掩码做卷积差分提取轮廓
// 也可用场景深度、法线纹理的差分辅助判断遮挡边缘；全屏方案固定开销较高但支持任意数量目标
// 轮廓提取后接 OccludedEdge 与场景深度遮挡遮罩相乘，即可叠加"幽灵轮廓"
// 顶点膨胀描边与 Stencil 反向描边见 SilhouetteFill.hlsl / OcclusionDetection.hlsl

// Sobel 掩码轮廓：3x3 卷积的 8 邻域差分，提取目标掩码 RT 的轮廓线
// threshold 建议 0.05~0.3；texelSize 接掩码 RT 的 Texel Size
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SobelMaskEdge</sg:ProviderKey>
///     <sg:DisplayName>Sobel Mask Edge</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>SobelMaskEdge</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Sobel, EdgeDetection, Mask, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "maskTex">
///     <sg:DisplayName>Mask Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float SobelMaskEdge(
  UnityTexture2D maskTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float threshold
)
{
  float2 t = texelSize;
  float s00 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(-1.0, -1.0)).r;
  float s10 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(0.0, -1.0)).r;
  float s20 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(1.0, -1.0)).r;
  float s01 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(-1.0, 0.0)).r;
  float s21 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(1.0, 0.0)).r;
  float s02 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(-1.0, 1.0)).r;
  float s12 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(0.0, 1.0)).r;
  float s22 = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(1.0, 1.0)).r;

  float gx = (s20 + 2.0 * s21 + s22) - (s00 + 2.0 * s01 + s02);
  float gy = (s02 + 2.0 * s12 + s22) - (s00 + 2.0 * s10 + s20);
  float g = sqrt(gx * gx + gy * gy);

  return smoothstep(threshold, threshold + 0.1, g);
}

// Laplacian 掩码轮廓：十字 4 邻域拉普拉斯算子，比 Sobel 更省采样，边缘更细
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LaplacianMaskEdge</sg:ProviderKey>
///     <sg:DisplayName>Laplacian Mask Edge</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>LaplacianMaskEdge</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Laplacian, EdgeDetection, Mask, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "maskTex">
///     <sg:DisplayName>Mask Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float LaplacianMaskEdge(
  UnityTexture2D maskTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float threshold
)
{
  float2 t = texelSize;
  float c = SAMPLE_TEXTURE2D(maskTex, samplerState, uv).r;
  float n = SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(0.0, 1.0)).r;
  n += SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(0.0, -1.0)).r;
  n += SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(1.0, 0.0)).r;
  n += SAMPLE_TEXTURE2D(maskTex, samplerState, uv + t * float2(-1.0, 0.0)).r;

  float lap = abs(4.0 * c - n);
  return smoothstep(threshold, threshold + 0.1, lap);
}

// 深度差分边缘：对场景深度纹理做 4 邻域差分，检测物体与背景的深度断层
// threshold 取深度值差，建议 0.0005~0.005；可接 _CameraDepthTexture
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.DepthEdge</sg:ProviderKey>
///     <sg:DisplayName>Depth Edge</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>DepthEdge</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Depth, EdgeDetection, CameraDepthTexture</sg:SearchTerms>
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
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>0.001</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float DepthEdge(
  UnityTexture2D depthTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float threshold
)
{
  float2 t = texelSize;
  float dx = abs(SAMPLE_TEXTURE2D(depthTex, samplerState, uv + t * float2(1.0, 0.0)).r
    - SAMPLE_TEXTURE2D(depthTex, samplerState, uv + t * float2(-1.0, 0.0)).r);
  float dy = abs(SAMPLE_TEXTURE2D(depthTex, samplerState, uv + t * float2(0.0, 1.0)).r
    - SAMPLE_TEXTURE2D(depthTex, samplerState, uv + t * float2(0.0, -1.0)).r);

  return smoothstep(threshold, threshold * 2.0 + 1e-4, dx + dy);
}

// 法线差分边缘：对法线纹理做 2 邻域差分，补充深度相近但朝向不同的轮廓
// threshold 建议 0.05~0.3；需开启 DepthNormals / 法线缓冲
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.NormalEdge</sg:ProviderKey>
///     <sg:DisplayName>Normal Edge</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>NormalEdge</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Normal, EdgeDetection, DepthNormals</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "normalTex">
///     <sg:DisplayName>Normal Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "texelSize">
///     <sg:DisplayName>Texel Size</sg:DisplayName>
///</paramhints>
///<paramhints name = "threshold">
///     <sg:DisplayName>Threshold</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float NormalEdge(
  UnityTexture2D normalTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float threshold
)
{
  float2 t = texelSize;
  float3 n0 = SAMPLE_TEXTURE2D(normalTex, samplerState, uv).rgb;
  float3 nx = SAMPLE_TEXTURE2D(normalTex, samplerState, uv + t * float2(1.0, 0.0)).rgb;
  float3 ny = SAMPLE_TEXTURE2D(normalTex, samplerState, uv + t * float2(0.0, 1.0)).rgb;

  float d = length(n0 - nx) + length(n0 - ny);
  return smoothstep(threshold, threshold * 2.0 + 1e-4, d);
}

// 组合多源轮廓：取掩码轮廓、深度边缘、法线边缘的最大值
// 只使用其中一两类时，未使用的输入传 0 即可
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CombineEdges</sg:ProviderKey>
///     <sg:DisplayName>Combine Edges</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Silhouette</sg:SearchCategory>
///     <sg:SearchName>CombineEdges</sg:SearchName>
///     <sg:SearchTerms>Silhouette, Outline, Combine, EdgeDetection, Mask</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "maskEdge">
///     <sg:DisplayName>Mask Edge</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "depthEdge">
///     <sg:DisplayName>Depth Edge</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "normalEdge">
///     <sg:DisplayName>Normal Edge</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float CombineEdges(float maskEdge, float depthEdge, float normalEdge)
{
  return saturate(max(max(maskEdge, depthEdge), normalEdge));
}

#endif