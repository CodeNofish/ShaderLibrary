#ifndef SHADER_LIBRARY_ERROR_DIFFUSION
#define SHADER_LIBRARY_ERROR_DIFFUSION

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Dither/DitherCommon.hlsl"

// Floyd-Steinberg 误差扩散（Error Diffusion）
// 量化误差向右 7/16、左下 3/16、下 5/16、右下 1/16 扩散，灰度还原精度最高
// 严格实现依赖像素间的顺序数据依赖，实时 GPU 片元难以并行化（需 Compute Shader 多 Pass）
// 文档明确指出实时渲染中通常被 Bayer / Blue Noise 取代，也未给出有效的并行化性能基准
// 本函数因此提供"并行近似"：采样左 / 右上 / 上 / 左上四个邻域的量化误差，
// 按 FS 权重补偿当前像素后再量化，适用于离线风格量化、UI 复古特效与后处理节点

// 误差扩散并行近似
// alphaTex 为待量化图（R 通道），levels 为量化级数，返回量化后的值
// 若要用于透明裁剪，可把结果与 BayerThreshold 比较后接 clip
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FloydSteinbergApproximation</sg:ProviderKey>
///     <sg:DisplayName>Floyd-Steinberg Approximation</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Dither</sg:SearchCategory>
///     <sg:SearchName>FloydSteinbergApproximation</sg:SearchName>
///     <sg:SearchTerms>Dither, FloydSteinberg, ErrorDiffusion, Quantization, Retro, Offline</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "alphaTex">
///     <sg:DisplayName>Alpha Texture</sg:DisplayName>
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
///<paramhints name = "alpha">
///     <sg:DisplayName>Alpha</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "levels">
///     <sg:DisplayName>Levels</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float FloydSteinbergApproximation(
  UnityTexture2D alphaTex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float alpha,
  float levels
)
{
  float2 t = texelSize;
  float aL = SAMPLE_TEXTURE2D(alphaTex, samplerState, uv + t * float2(-1.0, 0.0)).r;
  float aRU = SAMPLE_TEXTURE2D(alphaTex, samplerState, uv + t * float2(1.0, -1.0)).r;
  float aU = SAMPLE_TEXTURE2D(alphaTex, samplerState, uv + t * float2(0.0, -1.0)).r;
  float aLU = SAMPLE_TEXTURE2D(alphaTex, samplerState, uv + t * float2(-1.0, -1.0)).r;

  float eL = aL - DitherQuantize(aL, levels);
  float eRU = aRU - DitherQuantize(aRU, levels);
  float eU = aU - DitherQuantize(aU, levels);
  float eLU = aLU - DitherQuantize(aLU, levels);
  float diffusion = (7.0 * eL + 3.0 * eRU + 5.0 * eU + eLU) / 16.0;

  return DitherQuantize(saturate(alpha + diffusion), levels);
}

#endif