#ifndef SHADER_LIBRARY_SCREEN
#define SHADER_LIBRARY_SCREEN

#include "ShaderApiReflectionSupport.hlsl"

// 屏幕宽高（像素）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScreenSize</sg:ProviderKey>
///     <sg:DisplayName>Screen Size</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>ScreenSize</sg:SearchName>
///     <sg:SearchTerms>ScreenSize, Resolution, Width, Height</sg:SearchTerms>
///     <sg:ReturnDisplayName>Screen Size (pixels)</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
UNITY_EXPORT_REFLECTION
float2 ScreenSize()
{
  return _ScreenParams.xy;
}

// 屏幕 texel size = (1/width, 1/height)
// 等价于 _ScreenParams.zw - 1.0
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScreenTexelSize</sg:ProviderKey>
///     <sg:DisplayName>Screen Texel Size</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>ScreenTexelSize</sg:SearchName>
///     <sg:SearchTerms>TexelSize, PixelSize, UVPerPixel</sg:SearchTerms>
///     <sg:ReturnDisplayName>Texel Size</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
UNITY_EXPORT_REFLECTION
float2 ScreenTexelSize()
{
  return _ScreenParams.zw - 1.0;
}

// _ScreenParams.zw = (1 + 1/width, 1 + 1/height)
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ScreenParamsZW</sg:ProviderKey>
///     <sg:DisplayName>Screen Params ZW</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>ScreenParamsZW</sg:SearchName>
///     <sg:SearchTerms>ScreenParams, ZW</sg:SearchTerms>
///     <sg:ReturnDisplayName>ScreenParams.zw</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
UNITY_EXPORT_REFLECTION
float2 ScreenParamsZW()
{
  return _ScreenParams.zw;
}

// UV → 像素坐标
// uv 范围 [0,1]，返回 (pixelX, pixelY)
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.UVToPixel</sg:ProviderKey>
///     <sg:DisplayName>UV To Pixel</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>UVToPixel</sg:SearchName>
///     <sg:SearchTerms>UVToPixel, UVToScreen, PixelCoord</sg:SearchTerms>
///     <sg:ReturnDisplayName>Pixel Position</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 UVToPixel(float2 uv)
{
  return uv * _ScreenParams.xy;
}

// 像素坐标 → UV
// pixel 单位是像素，返回 [0,1] UV
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.PixelToUV</sg:ProviderKey>
///     <sg:DisplayName>Pixel To UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>PixelToUV</sg:SearchName>
///     <sg:SearchTerms>PixelToUV, ScreenToUV</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="pixel">
///     <sg:DisplayName>Pixel Position</sg:DisplayName>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 PixelToUV(float2 pixel)
{
  return pixel * (_ScreenParams.zw - 1.0);
}

// NDC xy → UV
// ndc.xy 范围 [-1,1]，返回 [0,1]
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.NdcToUV</sg:ProviderKey>
///     <sg:DisplayName>NDC To UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>NdcToUV</sg:SearchName>
///     <sg:SearchTerms>NdcToUV, ClipToUV, NDCToScreen</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="ndcXY">
///     <sg:DisplayName>NDC XY</sg:DisplayName>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 NdcToUV(float2 ndcXY)
{
  return ndcXY * 0.5 + 0.5;
}

// UV → NDC xy
// uv [0,1] → ndc [-1,1]
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.UVToNdc</sg:ProviderKey>
///     <sg:DisplayName>UV To NDC</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>UVToNdc</sg:SearchName>
///     <sg:SearchTerms>UVToNdc, UVToClip, ScreenToNDC</sg:SearchTerms>
///     <sg:ReturnDisplayName>NDC XY</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 UVToNdc(float2 uv)
{
  return uv * 2.0 - 1.0;
}

// 屏幕空间像素偏移 → UV 偏移
// 如果 velocity 是“每帧移动多少像素”，可以用它转成 UV 位移
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.PixelOffsetToUV</sg:ProviderKey>
///     <sg:DisplayName>Pixel Offset To UV</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>PixelOffsetToUV</sg:SearchName>
///     <sg:SearchTerms>PixelToUV, TexelOffset, UVOffset</sg:SearchTerms>
///     <sg:ReturnDisplayName>UV Offset</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="pixelOffset">
///     <sg:DisplayName>Pixel Offset</sg:DisplayName>
///</paramhints>
UNITY_EXPORT_REFLECTION
float2 PixelOffsetToUV(float2 pixelOffset)
{
  return pixelOffset * (_ScreenParams.zw - 1.0);
}

// 从屏幕 UV + 线性深度重建世界位置
// 需要外部提供 _InvCameraViewProj 和 _WorldSpaceCameraPos
// linearDepth 应为正数，通常来自 Linear01Depth / LinearEyeDepth
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ReconstructWorldFromScreen</sg:ProviderKey>
///     <sg:DisplayName>Reconstruct World From Screen</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/Screen</sg:SearchCategory>
///     <sg:SearchName>ReconstructWorldFromScreen</sg:SearchName>
///     <sg:SearchTerms>ReconstructWorld, DepthToWorld, ScreenToWorld</sg:SearchTerms>
///     <sg:ReturnDisplayName>World Position</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name="uv">
///     <sg:DisplayName>UV</sg:DisplayName>
///     <Default>UV0</Default>
///     <UV/>
///</paramhints>
///<paramhints name="linearDepth">
///     <sg:DisplayName>Linear Depth</sg:DisplayName>
///</paramhints>
// UNITY_EXPORT_REFLECTION
// float3 ReconstructWorldFromScreen(float2 uv, float linearDepth)
// {
//   float ndcX = uv.x * 2.0 - 1.0;
//   float ndcY = uv.y * 2.0 - 1.0;
//
//   float4 clipPos = float4(ndcX, ndcY, 1.0, 1.0);
//   float4 viewPos = mul(_InvCameraViewProj, clipPos);
//   viewPos /= viewPos.w;
//
//   return _WorldSpaceCameraPos + viewPos.xyz * linearDepth;
// }


#endif