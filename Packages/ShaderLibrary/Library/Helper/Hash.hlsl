#ifndef SHADER_LIBRARY_HASH
#define SHADER_LIBRARY_HASH

#include "ShaderApiReflectionSupport.hlsl"

// float → float
// 适合对一维索引、时间步长、粒子 ID 做散列
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Hash11</sg:ProviderKey>
///     <sg:DisplayName>Hash 11</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Hash</sg:SearchCategory>
///     <sg:SearchName>Hash11</sg:SearchName>
///     <sg:SearchTerms>Hash, Hash11</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "p">
///     <sg:DisplayName>In</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float Hash11(float p)
{
  p = frac(p * 0.1031);
  p *= p + 33.33;
  p *= p + p;
  return frac(p);
}

// float2 → float
// 适合把 UV、网格坐标、TileID 映射成伪随机值
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Hash21</sg:ProviderKey>
///     <sg:DisplayName>Hash 21</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Hash</sg:SearchCategory>
///     <sg:SearchName>Hash21</sg:SearchName>
///     <sg:SearchTerms>Hash, Hash21</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "p">
///     <sg:DisplayName>In</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float Hash21(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

// float3 → float
// 适合世界坐标、三维网格、体积噪声
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Hash31</sg:ProviderKey>
///     <sg:DisplayName>Hash 31</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Hash</sg:SearchCategory>
///     <sg:SearchName>Hash31</sg:SearchName>
///     <sg:SearchTerms>Hash, Hash31</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "p">
///     <sg:DisplayName>In</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float Hash31(float3 p)
{
  p = frac(p * 0.1031);
  p += dot(p, p.zyx + 31.32);
  return frac((p.x + p.y) * p.z);
}

// float2 → float2
// 适合生成随机方向、随机偏移、随机颜色扰动
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Hash22</sg:ProviderKey>
///     <sg:DisplayName>Hash 22</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Hash</sg:SearchCategory>
///     <sg:SearchName>Hash22</sg:SearchName>
///     <sg:SearchTerms>Hash, Hash22</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "p">
///     <sg:DisplayName>In</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 Hash22(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

// 通过Hash生成Seed扰动
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.HashScramble</sg:ProviderKey>
///     <sg:DisplayName>Hash Scramble</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Hash</sg:SearchCategory>
///     <sg:SearchName>HashScramble</sg:SearchName>
///     <sg:SearchTerms>Hash, HashScramble</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "p">
///     <sg:DisplayName>In</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float HashScramble(float p)
{
  return Hash11(p) * 19.19;
}

// TODO
// 基于 sin 的 Hash 在移动端 half 精度下容易出现条带或精度问题，整数版本更稳。
//
// uint p_hash1u(uint x)
// {
//   x ^= x >> 17u;
//   x *= 0xbf324c81u;
//   x ^= x >> 11u;
//   x *= 0x9c7f5779u;
//   x ^= x >> 16u;
//   return x;
// }
//
// float p_hashInt21(float2 p)
// {
//   uint2 ip = (uint2)(p * 1000.0 + 0.5);
//   uint h = p_hash1u(ip.x + p_hash1u(ip.y));
//   return (float)h / 4294967295.0;
// }


#endif