#ifndef SHADER_LIBRARY_FILM_GRAIN
#define SHADER_LIBRARY_FILM_GRAIN

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Color/Common.hlsl"

// Film Grain（胶片颗粒）：银盐晶体随机分布的物理特性模拟，与数码噪点不同
// 时间按每秒 24 帧量化；颗粒按亮度加权，中间调最明显、纯黑纯白处减弱
// 四类实现：单色高斯颗粒、通道分离颗粒、色彩校准颗粒、分辨率自适应颗粒
// 管线建议：胶片颗粒最后叠加（Color Grading → Vignette → DoF → Bloom → Motion Blur → Film Grain）

// 单色高斯颗粒
// 用三个均匀随机数之和近似高斯分布，避免彩色噪点的"数码脏感"
// intensity 建议 0.06~0.10（人像）；size 为颗粒网格密度，越大颗粒越细
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FilmGrain</sg:ProviderKey>
///     <sg:DisplayName>Film Grain</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/FilmGrain</sg:SearchCategory>
///     <sg:SearchName>FilmGrain</sg:SearchName>
///     <sg:SearchTerms>FilmGrain, Grain, Gaussian, Monochrome, Noise, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>512</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 FilmGrain(float3 color, float2 uv, float time, float intensity, float size, float seed)
{
  float slice = floor(time * 24.0);
  float grain = ColorGaussianNoise(uv, slice, size, seed);

  return max(color + grain * intensity * ColorGrainWeight(color), 0.0);
}

// 通道分离颗粒
// 对 RGB 三层分别使用不同颗粒大小与强度：红层最柔和（粗）、绿层噪点最多、蓝层最锐利（细）
// channelStrength 为三通道强度，默认 (0.06, 0.10, 0.08) 对应真实胶片三层乳剂特性
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FilmGrainRGB</sg:ProviderKey>
///     <sg:DisplayName>Film Grain RGB</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/FilmGrain</sg:SearchCategory>
///     <sg:SearchName>FilmGrainRGB</sg:SearchName>
///     <sg:SearchTerms>FilmGrain, Grain, Channel, Emulsion, RGB, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "channelStrength">
///     <sg:DisplayName>Channel Strength</sg:DisplayName>
///     <sg:Default>0.06,0.10,0.08</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>512</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 FilmGrainRGB(float3 color, float2 uv, float time, float3 channelStrength, float size, float seed)
{
  float slice = floor(time * 24.0);
  float3 grain = float3(
    ColorGaussianNoise(uv, slice, size * 0.5, seed),
    ColorGaussianNoise(uv, slice + 11.0, size, seed + 3.0),
    ColorGaussianNoise(uv, slice + 23.0, size * 2.0, seed + 7.0)
  );

  return max(color + grain * channelStrength * ColorGrainWeight(color), 0.0);
}

// 色彩校准颗粒
// 颗粒颜色随场景主色调匹配（如森林场景偏绿），避免与 Color Grading 叠加时出现偏色
// sceneTint 可接场景平均色或调色后的主色；白色表示退化为单色颗粒
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FilmGrainColorCalibrated</sg:ProviderKey>
///     <sg:DisplayName>Film Grain Color Calibrated</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/FilmGrain</sg:SearchCategory>
///     <sg:SearchName>FilmGrainColorCalibrated</sg:SearchName>
///     <sg:SearchTerms>FilmGrain, Grain, ColorCalibrated, Tint, Grading, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "sceneTint">
///     <sg:DisplayName>Scene Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>512</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 FilmGrainColorCalibrated(
  float3 color,
  float3 sceneTint,
  float2 uv,
  float time,
  float intensity,
  float size,
  float seed
)
{
  float slice = floor(time * 24.0);
  float grain = ColorGaussianNoise(uv, slice, size, seed);
  float3 tint = sceneTint / max(max(sceneTint.r, max(sceneTint.g, sceneTint.b)), 1e-4);

  return max(color + grain * intensity * ColorGrainWeight(color) * tint, 0.0);
}

// 分辨率自适应颗粒
// 依据输出高度动态调整颗粒大小与强度：720P 关闭、1080P 约 0.2、2K 约 0.15（文档经验值）
// 高分辨率使用更细的颗粒网格，避免低分辨率下颗粒过粗破坏画质
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.FilmGrainResolutionAdaptive</sg:ProviderKey>
///     <sg:DisplayName>Film Grain Resolution Adaptive</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/FilmGrain</sg:SearchCategory>
///     <sg:SearchName>FilmGrainResolutionAdaptive</sg:SearchName>
///     <sg:SearchTerms>FilmGrain, Grain, Resolution, Adaptive, 1080p, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name = "screenSize">
///     <sg:DisplayName>Screen Size</sg:DisplayName>
///     <sg:Default>1920,1080</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 FilmGrainResolutionAdaptive(
  float3 color,
  float2 uv,
  float2 screenSize,
  float time,
  float intensity,
  float seed
)
{
  float h = max(screenSize.y, 1.0);
  float strength = intensity * smoothstep(720.0, 1080.0, h) * lerp(1.0, 0.75, saturate((h - 1080.0) / 360.0));
  float size = lerp(256.0, 768.0, saturate((h - 720.0) / 720.0));
  float slice = floor(time * 24.0);
  float grain = ColorGaussianNoise(uv, slice, size, seed);

  return max(color + grain * strength * ColorGrainWeight(color), 0.0);
}

// 单色颗粒采样组合版：一次调用完成纹理采样 + 颗粒叠加
// 把屏幕纹理与 UV 接入即可，intensity / size / seed 含义同 FilmGrain
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ApplyFilmGrain</sg:ProviderKey>
///     <sg:DisplayName>Apply Film Grain</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/FilmGrain</sg:SearchCategory>
///     <sg:SearchName>ApplyFilmGrain</sg:SearchName>
///     <sg:SearchTerms>FilmGrain, Grain, Monochrome, Noise, PostEffect</sg:SearchTerms>
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
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "size">
///     <sg:DisplayName>Size</sg:DisplayName>
///     <sg:Default>512</sg:Default>
///</paramhints>
///<paramhints name = "seed">
///     <sg:DisplayName>Seed</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float4 ApplyFilmGrain(
  UnityTexture2D tex,
  UnitySamplerState samplerState,
  float2 uv,
  float time,
  float intensity,
  float size,
  float seed
)
{
  float4 c = SAMPLE_TEXTURE2D(tex, samplerState, uv);
  c.rgb = FilmGrain(c.rgb, uv, time, intensity, size, seed);

  return c;
}

#endif