#ifndef SHADER_LIBRARY_RADIAL_BLUR
#define SHADER_LIBRARY_RADIAL_BLUR

#include "ShaderApiReflectionSupport.hlsl"

/*
常见的 RadialBlur 算法主要有这几类：

- **均匀步进径向模糊**：沿“中心 → 当前像素”方向做等距采样，最后取平均。111
- **距离加权径向模糊**：采样权重随距离中心远近变化，中心更清晰、边缘更模糊。46
- **预置偏移表采样**：使用一组固定偏移，如 `{0.01, 0.02, 0.03, 0.05, 0.08}`，减少循环开销。45
- **分离式 / 多 Pass 径向模糊**：先在低分辨率纹理上做径向模糊，再与原图混合，适合移动端。57
- **顶点预计算方向向量**：在顶点着色器里算好径向方向，片元只做采样累加，降低 ALU 压力。7
- **带强度混合的径向模糊**：先算模糊结果，再与原图按距离或强度参数做 `lerp`。
*/

// Radial Blur：沿“中心 → 当前像素”方向做多步采样并取平均
// centerUV：模糊中心，屏幕 UV 空间，默认 (0.5, 0.5)
// strength：径向模糊强度，越大拉伸越明显
// samples：采样次数，建议 4~16；值越大质量越高，开销也越大
// 适合做速度线、冲击波、镜头推进、技能爆发等后处理效果
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RadialBlur</sg:ProviderKey>
///     <sg:DisplayName>Radial Blur</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>RadialBlur</sg:SearchName>
///     <sg:SearchTerms>Blur, RadialBlur, Radial, ZoomBlur, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 RadialBlur(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength,
  int samples
)
{
  float2 dir = uv - centerUV;

  float sampleCount = max(1.0, (float)samples);
  float2 step = dir * (strength / sampleCount);

  float4 sum = 0.0;

  for (int i = 0; i < samples; i++)
  {
    float2 sampleUV = uv - step * (float)i;
    sum += SAMPLE_TEXTURE2D(tex, samplerState, sampleUV);
  }

  return sum / sampleCount;
}

// 带强度混合的 Radial Blur
// intensity：0 表示完全使用原图，1 表示完全使用径向模糊结果
// 适合做可调节的后处理强度，例如受击、加速、技能爆发
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RadialBlurIntensity</sg:ProviderKey>
///     <sg:DisplayName>Radial Blur Intensity</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Blur</sg:SearchCategory>
///     <sg:SearchName>RadialBlurIntensity</sg:SearchName>
///     <sg:SearchTerms>Blur, RadialBlur, Intensity, PostEffect</sg:SearchTerms>
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
///<paramhints name = "centerUV">
///     <sg:DisplayName>Center UV</sg:DisplayName>
///     <sg:Default>0.5,0.5</sg:Default>
///</paramhints>
///<paramhints name = "strength">
///     <sg:DisplayName>Strength</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "samples">
///     <sg:DisplayName>Samples</sg:DisplayName>
///     <sg:Default>8</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 RadialBlurIntensity(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float2 centerUV,
  float strength,
  int samples,
  float intensity
)
{
  float4 original = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  float4 blurred = RadialBlur(tex, samplerState, uv, centerUV, strength, samples);
  return lerp(original, blurred, saturate(intensity));
}

#endif