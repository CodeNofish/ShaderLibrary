#ifndef SHADER_LIBRARY_VERTEX_DISPLACEMENT
#define SHADER_LIBRARY_VERTEX_DISPLACEMENT

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Underwater/WaterCommon.hlsl"

// 顶点位移扭曲：直接在顶点着色器中对水面 Mesh 施加 Gerstner / 正弦波位移
// 几何级真实度最高，可正确模拟波浪轮廓对折射的影响，但性能消耗大
// 通常仅用于近景水面或高质量过场；返回值可直接加到 Vertex Position
// position 建议传世界坐标（Object Space 需先变换，否则波会随物体移动）

// 单个 Gerstner 波
// 深水波速 c = sqrt(g/k)，同时产生水平与垂直位移，形成尖锐波峰、平缓波谷
// steepness 建议 0~1，wavelength 为波长（世界单位），speed 为时间倍率
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GerstnerWave</sg:ProviderKey>
///     <sg:DisplayName>Gerstner Wave</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>GerstnerWave</sg:SearchName>
///     <sg:SearchTerms>Underwater, Vertex, Gerstner, Wave, Displacement, Water</sg:SearchTerms>
///     <sg:ReturnDisplayName>Displacement</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "steepness">
///     <sg:DisplayName>Steepness</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "wavelength">
///     <sg:DisplayName>Wavelength</sg:DisplayName>
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 GerstnerWave(float3 position, float time, float2 direction, float steepness, float wavelength, float speed)
{
  return WaterGerstner(position, time, direction, steepness, wavelength, speed);
}

// 多个 Gerstner 波叠加
// 各波方向按黄金角依次旋转、波长递增、权重递减，避免单方向波的机械重复
// waveCount 建议 1~6；值越大波形越自然，顶点开销也越高
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.GerstnerWaveSum</sg:ProviderKey>
///     <sg:DisplayName>Gerstner Wave Sum</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>GerstnerWaveSum</sg:SearchName>
///     <sg:SearchTerms>Underwater, Vertex, Gerstner, Wave, Displacement, Ocean</sg:SearchTerms>
///     <sg:ReturnDisplayName>Displacement</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "steepness">
///     <sg:DisplayName>Steepness</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "wavelength">
///     <sg:DisplayName>Wavelength</sg:DisplayName>
///     <sg:Default>10</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "waveCount">
///     <sg:DisplayName>Wave Count</sg:DisplayName>
///     <sg:Default>3</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 GerstnerWaveSum(
  float3 position,
  float time,
  float2 direction,
  float steepness,
  float wavelength,
  float speed,
  int waveCount
)
{
  float2 base = normalize(direction + float2(1e-5, 0.0));
  float3 offset = 0.0;
  float weight = 1.0;
  float total = 0.0;

  for (int i = 0; i < waveCount; i++)
  {
    float angle = (float)i * 2.39996;
    float s = sin(angle);
    float c = cos(angle);
    float2 d = float2(base.x * c - base.y * s, base.x * s + base.y * c);
    float w = wavelength * (1.0 + (float)i * 0.37);

    offset += WaterGerstner(position, time, d, steepness, w, speed) * weight;
    total += weight;
    weight *= 0.65;
  }

  return offset / max(total, 1e-4);
}

// 正弦波顶点位移（仅 Y 方向）
// 最轻量的水面起伏，适合风格化水体与移动端；frequency 为空间角频率
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SineWaveDisplacement</sg:ProviderKey>
///     <sg:DisplayName>Sine Wave Displacement</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>SineWaveDisplacement</sg:SearchName>
///     <sg:SearchTerms>Underwater, Vertex, Sine, Wave, Displacement, Mobile</sg:SearchTerms>
///     <sg:ReturnDisplayName>Displacement</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "position">
///     <sg:DisplayName>Position</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "time">
///     <sg:DisplayName>Time</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "direction">
///     <sg:DisplayName>Direction</sg:DisplayName>
///     <sg:Default>1,0</sg:Default>
///</paramhints>
///<paramhints name = "amplitude">
///     <sg:DisplayName>Amplitude</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "frequency">
///     <sg:DisplayName>Frequency</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
///<paramhints name = "speed">
///     <sg:DisplayName>Speed</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SineWaveDisplacement(float3 position, float time, float2 direction, float amplitude, float frequency, float speed)
{
  float2 d = normalize(direction + float2(1e-5, 0.0));
  float phase = dot(d, position.xz) * frequency - time * speed;

  return float3(0.0, sin(phase) * amplitude, 0.0);
}

// 折射方向：配合波面法线与折射率计算光线偏折方向
// eta 为两侧折射率之比 n1/n2（空气→水约 0.75），incident 指向表面
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.WaterRefract</sg:ProviderKey>
///     <sg:DisplayName>Water Refract</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Underwater</sg:SearchCategory>
///     <sg:SearchName>WaterRefract</sg:SearchName>
///     <sg:SearchTerms>Underwater, Refract, IOR, Snell, Vertex, Water</sg:SearchTerms>
///     <sg:ReturnDisplayName>Direction</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "incident">
///     <sg:DisplayName>Incident</sg:DisplayName>
///     <sg:Default>0,-1,0</sg:Default>
///</paramhints>
///<paramhints name = "normal">
///     <sg:DisplayName>Normal</sg:DisplayName>
///     <sg:Default>0,1,0</sg:Default>
///</paramhints>
///<paramhints name = "eta">
///     <sg:DisplayName>Eta</sg:DisplayName>
///     <sg:Default>0.75</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 WaterRefract(float3 incident, float3 normal, float eta)
{
  return refract(normalize(incident), normalize(normal), max(eta, 1e-4));
}

#endif