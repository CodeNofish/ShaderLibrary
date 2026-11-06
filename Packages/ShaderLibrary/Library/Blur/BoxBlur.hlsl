#ifndef SHADER_LIBRARY_BOX_BLUR
#define SHADER_LIBRARY_BOX_BLUR

#include "ShaderApiReflectionSupport.hlsl"

// 4-tap Box Blur：采样中心周围四个对角像素并取平均
// 适合做轻量模糊、Sprite 背景虚化、UI 毛玻璃近似
// 如果要更强模糊，可以多次迭代，或改成水平/垂直分离 Pass
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BoxBlur4Tap</sg:ProviderKey>
///     <sg:DisplayName>Box Blur 4-Tap</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>BoxBlur4Tap</sg:SearchName>
///     <sg:SearchTerms>Blur, BoxBlur, BoxBlur4Tap</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "tex">
///     <sg:DisplayName>Texture</sg:DisplayName>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BoxBlur4Tap(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float2 offset = texelSize * radius;

  float4 d = offset.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

  float4 c = 0;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.xy);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.zy);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.xw);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.zw);

  return c * 0.25;
}

// 4-tap Box Blur：采样中心周围四个对角像素并取平均
// 适合做轻量模糊、Sprite 背景虚化、UI 毛玻璃近似
// 如果要更强模糊，可以多次迭代，或改成水平/垂直分离 Pass
// 加一个 seed 做轻微随机偏移(如hash21(uv))，使模糊更自然、减少十字状采样痕迹
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BoxBlur4TapSeeded</sg:ProviderKey>
///     <sg:DisplayName>Box Blur 4-Tap Seeded</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>BoxBlur4TapSeeded</sg:SearchName>
///     <sg:SearchTerms>Blur, BoxBlur, BoxBlur4TapSeeded</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "tex">
///     <sg:DisplayName>Texture</sg:DisplayName>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BoxBlur4TapSeeded(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius,
  float seed
)
{
  float s = frac(seed * 0.1031);
  s *= s + 33.33;
  s *= s + s;
  s = frac(s);

  float2 offset = texelSize * radius;
  float2 jitter = (s * 2.0 - 1.0) * offset * 0.5;

  float4 d = offset.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

  float4 c = 0;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.xy + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.zy + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.xw + jitter);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + d.zw + jitter);

  return c * 0.25;
}

// 水平 Box Blur：固定 5-tap，实际 3 次纹理采样
// 使用双线性采样合并相邻像素，减少纹理采样次数
// radius 建议 >= 1；radius 越大，模糊越强
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BoxBlurHorizontal</sg:ProviderKey>
///     <sg:DisplayName>Box Blur Horizontal</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>BoxBlurHorizontal</sg:SearchName>
///     <sg:SearchTerms>Blur, BoxBlur, Horizontal, Separable</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "tex">
///     <sg:DisplayName>Texture</sg:DisplayName>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BoxBlurHorizontal(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float step = texelSize.x * radius;

  // 五次采样的5-tap 
  // float4 c = 0;
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-2.0 * step, 0.0));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-1.0 * step, 0.0));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv);
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2( 1.0 * step, 0.0));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2( 2.0 * step, 0.0));
  // return c * 0.2;

  // 性能优先 三次采样的5-tap
  float4 c = 0;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(-step, 0.0));
  c += 2.0 * SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(step, 0.0));
  return c * 0.25;
}

// 垂直 Box Blur：固定 5-tap，实际 3 次纹理采样
// 与 BoxBlurHorizontal 配合使用，实现可分离 Box Blur
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.BoxBlurVertical</sg:ProviderKey>
///     <sg:DisplayName>Box Blur Vertical</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>BoxBlurVertical</sg:SearchName>
///     <sg:SearchTerms>Blur, BoxBlur, Vertical, Separable</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "tex">
///     <sg:DisplayName>Texture</sg:DisplayName>
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
///<paramhints name = "radius">
///     <sg:DisplayName>Radius</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 BoxBlurVertical(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 texelSize,
  float radius
)
{
  float step = texelSize.y * radius;

  // 五次采样的5-tap 
  // float4 c = 0;
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -2.0 * step));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -1.0 * step));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv);
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, 1.0 * step));
  // c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, 2.0 * step));
  // return c * 0.2;

  // 性能优先 三次采样的5-tap
  float4 c = 0;
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, -step));
  c += 2.0 * SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c += SAMPLE_TEXTURE2D(tex, samplerState, uv + float2(0.0, step));
  return c * 0.25;
}

#endif