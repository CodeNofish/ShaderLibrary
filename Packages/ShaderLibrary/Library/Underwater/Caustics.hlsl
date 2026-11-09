#ifndef SHADER_LIBRARY_CAUSTICS
#define SHADER_LIBRARY_CAUSTICS

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Underwater/WaterCommon.hlsl"

// Caustics（焦散）：光线经水面折射后在水底汇聚形成的光斑
// 四类实现：程序化噪声（Voronoi / RotateMin / TriTwist）、预烘焙贴图投影、波动模拟频段、
//           光子映射 / 光线追踪（此处仅提供 7 色采样的色散近似）
// 所有灰度焦散函数只输出单通道 float：HDRP 的 EvaluateSimulationCaustics 等节点仅输出 R 通道，
// 必须分离 R 再参与光照计算，直接连 Base Color 会导致画面偏红（有意为之的性能优化设计）
// 执行顺序：先完成水下扭曲，再把焦散作为光照贡献叠加，避免焦散图案本身被扭曲而失真

// 程序化 Voronoi 焦散
// 细胞状光斑，用 pow(contrast) 增强对比；零纹理带宽、纯 ALU，适合移动端与风格化水体
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.VoronoiCaustics</sg:ProviderKey>
///     <sg:DisplayName>Voronoi Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>VoronoiCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, Voronoi, Procedural, Noise, Grayscale, Mobile</sg:SearchTerms>
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
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "contrast">
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float VoronoiCaustics(float2 uv, float time, float scale, float contrast, float speed)
{
  float pattern = WaterVoronoi(uv * max(scale, 1e-4), time * speed);
  return WaterCausticsContrast(pattern, contrast);
}

// 程序化 RotateMin 焦散
// 矩阵变换 + 分形最小值合并，形成网状光纹；同样为零纹理带宽的纯 ALU 算法
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.RotateMinCaustics</sg:ProviderKey>
///     <sg:DisplayName>Rotate Min Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>RotateMinCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, RotateMin, Fractal, Procedural, Grayscale</sg:SearchTerms>
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
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "contrast">
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float RotateMinCaustics(float2 uv, float time, float scale, float contrast, float speed)
{
  float pattern = WaterRotateMin(uv * max(scale, 1e-4), time * speed);
  return WaterCausticsContrast(pattern, contrast);
}

// 程序化 TriTwist 焦散
// 三角形扭曲算法，输出锐利的几何光斑，风格化水体常用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.TriTwistCaustics</sg:ProviderKey>
///     <sg:DisplayName>Tri Twist Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>TriTwistCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, TriTwist, Triangle, Geometric, Procedural</sg:SearchTerms>
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
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "contrast">
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:Default>4</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float TriTwistCaustics(float2 uv, float time, float scale, float contrast, float speed)
{
  float pattern = WaterTriTwist(uv * max(scale, 1e-4), time * speed);
  return WaterCausticsContrast(pattern, contrast);
}

// 波动模拟焦散（Wave Simulation Band，HDRP EvaluateSimulationCaustics 的轻量近似）
// 基于波动频段实时计算光线汇聚强度，输出单通道灰度
// band = 0 高频涟漪（Ripples）、1 低频涌浪（Swell）；可与水面动画联动
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.WaveSimulationCaustics</sg:ProviderKey>
///     <sg:DisplayName>Wave Simulation Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>WaveSimulationCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, WaveSimulation, Ripples, Swell, HDRP, Grayscale</sg:SearchTerms>
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
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "band">
///     <sg:DisplayName>Band</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float WaveSimulationCaustics(float2 uv, float time, float2 direction, float band, float speed)
{
  return WaterWaveBand(uv, time * speed, direction, band);
}

// 光谱色散焦散（光子映射 / RT 焦散的 ALU 近似）
// 文档中的"波长聚类 + 7 色采样近似连续光谱"：对 7 个波长分别偏移采样 Voronoi 图案并按光谱权重合成
// 真正的分布式光子映射、LHPC、硬件光追需要光子图/光追管线，超出 ShaderGraph 函数库能力
// dispersion 控制不同波长的偏移差，输出为带色散的 HDR 焦散颜色
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SpectralCaustics</sg:ProviderKey>
///     <sg:DisplayName>Spectral Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>SpectralCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, Spectral, Dispersion, PhotonMapping, 7Samples, RayTracing</sg:SearchTerms>
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
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "dispersion">
///     <sg:DisplayName>Dispersion</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SpectralCaustics(float2 uv, float time, float scale, float dispersion, float speed)
{
  float3 sum = 0.0;

  for (int i = 0; i < 7; i++)
  {
    float t = (float)i / 6.0;
    float2 shifted = uv + float2((t - 0.5) * dispersion, 0.0);
    float c = WaterVoronoi(shifted * max(scale, 1e-4), time * speed);

    float3 spectral = saturate(float3(
      1.5 - abs(4.0 * t - 1.0),
      1.5 - abs(4.0 * t - 2.0),
      1.5 - abs(4.0 * t - 3.0)
    ));

    sum += WaterCausticsContrast(c, 4.0) * spectral;
  }

  return sum / 7.0;
}

// 预烘焙贴图投影焦散（Caustics Texture Overlay）
// 以世界坐标 XZ 平面投影到水底表面，避免焦散"漂浮"在水面；可配合 CausticsMask 限定作用区域
// scrollSpeed 让静态贴图产生缓慢流动，弥补预烘焙缺乏动态变化的缺点；仅取 R 通道（单通道优化）
// Unity 为 Y-up 使用 worldPos.xz；UE 为 Z-up 时请将 worldPos.xy 组合传入
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CausticsTextureProjection</sg:ProviderKey>
///     <sg:DisplayName>Caustics Texture Projection</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>CausticsTextureProjection</sg:SearchName>
///     <sg:SearchTerms>Caustics, Texture, Projection, WorldXZ, Baked, Grayscale</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "causticsTex">
///     <sg:DisplayName>Caustics Texture</sg:DisplayName>
///</paramhints>
///<paramhints name = "samplerState">
///     <sg:DisplayName>Sampler State</sg:DisplayName>
///</paramhints>
///<paramhints name = "worldPos">
///     <sg:DisplayName>World Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "scrollSpeed">
///     <sg:DisplayName>Scroll Speed</sg:DisplayName>
///     <sg:Default>0.02,0.01</sg:Default>
///</paramhints>
///<paramhints name = "scale">
///     <sg:DisplayName>Scale</sg:DisplayName>
///     <sg:Default>0.1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float CausticsTextureProjection(
  UnityTexture2D causticsTex,
  UnitySamplerState samplerState,
  float3 worldPos,
  float time,
  float2 scrollSpeed,
  float scale
)
{
  float2 uv = worldPos.xz * max(scale, 1e-4) + time * scrollSpeed;
  return SAMPLE_TEXTURE2D(causticsTex, samplerState, uv).r;
}

// 焦散 HDR 着色：与水体折射色匹配
// 程序化焦散直接相加容易色调不协调；hdrColor 可大于 1 表示 HDR 光强，refrColor 与折射节点保持一致
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.CausticsTint</sg:ProviderKey>
///     <sg:DisplayName>Caustics Tint</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>CausticsTint</sg:SearchName>
///     <sg:SearchTerms>Caustics, Tint, HDR, RefrColor, ColorConsistency</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "caustics">
///     <sg:DisplayName>Caustics</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "hdrColor">
///     <sg:DisplayName>HDR Color</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "refrColor">
///     <sg:DisplayName>Refraction Color</sg:DisplayName>
///     <sg:Default>0.6,0.85,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 CausticsTint(float caustics, float3 hdrColor, float3 refrColor)
{
  return caustics * hdrColor * refrColor;
}

// 叠加焦散（组合）
// caustics 为单通道灰度（只接 R 通道），mask 接 CombineCausticsMasks 的结果
// 作为光照贡献相加，intensity 可驱动强度动画；请在水下扭曲之后调用
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ApplyCaustics</sg:ProviderKey>
///     <sg:DisplayName>Apply Caustics</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Caustics</sg:SearchCategory>
///     <sg:SearchName>ApplyCaustics</sg:SearchName>
///     <sg:SearchTerms>Caustics, Apply, Lighting, Mask, HDR, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "caustics">
///     <sg:DisplayName>Caustics</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "hdrColor">
///     <sg:DisplayName>HDR Color</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "refrColor">
///     <sg:DisplayName>Refraction Color</sg:DisplayName>
///     <sg:Default>0.6,0.85,1</sg:Default>
///</paramhints>
///<paramhints name = "intensity">
///     <sg:DisplayName>Intensity</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "mask">
///     <sg:DisplayName>Mask</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ApplyCaustics(float3 color, float caustics, float3 hdrColor, float3 refrColor, float intensity, float mask)
{
  return color + CausticsTint(caustics, hdrColor, refrColor) * saturate(intensity) * saturate(mask);
}

#endif