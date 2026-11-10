#ifndef SHADER_LIBRARY_COLOR_GRADING
#define SHADER_LIBRARY_COLOR_GRADING

#include "ShaderApiReflectionSupport.hlsl"
#include "Packages/ShaderLibrary/Library/Color/Common.hlsl"

// 程序化参数调色（Procedural / Parametric Color Grading）
// 不依赖 LUT 纹理，直接在 Shader 里调整色彩属性，通常作为 LUT 的前置步骤或轻量级替代
// 覆盖：色温/色调白平衡、对比度与饱和度、阴影/中间调/高光分区、RGB/HSL 曲线、通道混合器

// 色温 / 色调（白平衡偏移）
// temperature > 0 偏暖（加红减蓝），< 0 偏冷；
// tint > 0 偏洋红，< 0 偏绿；
// 两者取 [-1,1]，模拟 Kelvin / Tint 白平衡，不改变整体亮度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.WhiteBalance</sg:ProviderKey>
///     <sg:DisplayName>White Balance</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>WhiteBalance</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, WhiteBalance, Temperature, Tint, Kelvin, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "temperature">
///     <sg:DisplayName>Temperature</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 WhiteBalance(float3 color, float temperature, float tint)
{
  float t = clamp(temperature, -1.0, 1.0);
  float g = clamp(tint, -1.0, 1.0);
  float3 wb = float3(1.0 + t * 0.3 - g * 0.1, 1.0 + g * 0.2, 1.0 - t * 0.3 - g * 0.1);

  return max(color * wb, 0.0);
}

// 饱和度：以 Rec.709 亮度为轴缩放色度
// saturation = -1 灰度、0 原图、1 两倍饱和度
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Saturation</sg:ProviderKey>
///     <sg:DisplayName>Saturation</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>Saturation</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, Saturation, Vibrance, Color, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "saturation">
///     <sg:DisplayName>Saturation</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 Saturation(float3 color, float saturation)
{
  float l = ColorLumaInternal(color);
  return lerp(float3(l, l, l), color, max(1.0 + saturation, 0.0));
}

// 对比度：以pivot为中心的线性对比度拉伸函数
// contrast = 0 原图；
// pivot 默认 0.5（SDR），线性 HDR 场景可设 0.18
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.Contrast</sg:ProviderKey>
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>Contrast</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, Contrast, Pivot, Color, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "contrast">
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "pivot">
///     <sg:DisplayName>Pivot</sg:DisplayName>
///     <sg:Default>0.5</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 Contrast(float3 color, float contrast, float pivot)
{
  return max((color - pivot) * (1.0 + contrast) + pivot, 0.0);
}

// 组合参数调色（URP Color Adjustments 的程序化等效）
// 依次执行曝光 → 白平衡 → 对比度 → 饱和度；可作为 Internal LUT 的前置步骤
// exposure 单位为 EV，contrast / saturation / temperature / tint 均为增量
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ColorAdjustments</sg:ProviderKey>
///     <sg:DisplayName>Color Adjustments</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>ColorAdjustments</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ColorAdjustments, Exposure, Contrast, Saturation, WhiteBalance, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "exposure">
///     <sg:DisplayName>Exposure</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "contrast">
///     <sg:DisplayName>Contrast</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "saturation">
///     <sg:DisplayName>Saturation</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "temperature">
///     <sg:DisplayName>Temperature</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "tint">
///     <sg:DisplayName>Tint</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ColorAdjustments(
  float3 color,
  float exposure,
  float contrast,
  float saturation,
  float temperature,
  float tint
)
{
  float3 c = max(color, 0.0) * exp2(exposure);
  c = WhiteBalance(c, temperature, tint);
  c = Contrast(c, contrast, 0.5);
  return Saturation(c, saturation);
}

// Lift / Gamma / Gain：阴影、中间调、高光分区独立控制
// lift 抬暗部，gamma 控制中间调，gain 缩放高光；各分量为 RGB 增益
// 默认值 lift (0,0,0)、gamma (1,1,1)、gain (1,1,1) 即不改变画面
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.LiftGammaGain</sg:ProviderKey>
///     <sg:DisplayName>Lift Gamma Gain</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>LiftGammaGain</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, Lift, Gamma, Gain, Shadows, Midtones, Highlights, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "lift">
///     <sg:DisplayName>Lift</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "gamma">
///     <sg:DisplayName>Gamma</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "gain">
///     <sg:DisplayName>Gain</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 LiftGammaGain(float3 color, float3 lift, float3 gamma, float3 gain)
{
  float3 c = max(color, 0.0);
  c = pow(c, 1.0 / max(gamma, float3(1e-3, 1e-3, 1e-3)));
  c = c * gain + lift * (1.0 - c);

  return max(c, 0.0);
}

// 分离调色 Split Toning：按亮度给阴影与高光分别染色
// balance 移动分区边界（> 0 更多像素落入高光），默认两种 tint 均为白色即不改变画面
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.SplitToning</sg:ProviderKey>
///     <sg:DisplayName>Split Toning</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>SplitToning</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, SplitToning, Shadows, Highlights, ColorBalance, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "shadowTint">
///     <sg:DisplayName>Shadow Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "highlightTint">
///     <sg:DisplayName>Highlight Tint</sg:DisplayName>
///     <sg:Default>1,1,1</sg:Default>
///</paramhints>
///<paramhints name = "balance">
///     <sg:DisplayName>Balance</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 SplitToning(float3 color, float3 shadowTint, float3 highlightTint, float balance)
{
  float l = ColorLumaInternal(saturate(color));
  float w = smoothstep(0.0, 1.0, saturate(l * 2.0 + balance));
  float3 tint = lerp(shadowTint, highlightTint, w);

  return max(color * tint, 0.0);
}

// 通道混合器 Channel Mixer
// 三个参数分别是输出 R/G/B 由输入 RGB 组成的权重；默认即为单位矩阵
// 可模拟胶片感光层串扰，或做创意色彩偏移（例如红通道混入部分绿）
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.ChannelMixer</sg:ProviderKey>
///     <sg:DisplayName>Channel Mixer</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>ChannelMixer</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, ChannelMixer, RGBCurve, Channel, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "redChannel">
///     <sg:DisplayName>Red Channel</sg:DisplayName>
///     <sg:Default>1,0,0</sg:Default>
///</paramhints>
///<paramhints name = "greenChannel">
///     <sg:DisplayName>Green Channel</sg:DisplayName>
///     <sg:Default>0,1,0</sg:Default>
///</paramhints>
///<paramhints name = "blueChannel">
///     <sg:DisplayName>Blue Channel</sg:DisplayName>
///     <sg:Default>0,0,1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 ChannelMixer(float3 color, float3 redChannel, float3 greenChannel, float3 blueChannel)
{
  return float3(dot(color, redChannel), dot(color, greenChannel), dot(color, blueChannel));
}

// HSL 曲线维度：色相偏移 / 饱和度 / 明度
// 用 YIQ 旋转做色相偏移，避免 RGB↔HSV 转换带来的色阶断层
// hueShift 为色相圈数 [-0.5,0.5]，saturation 为增量，value 为亮度倍数
///<funchints>
///     <sg:ProviderKey>ShaderLibrary.HueSaturationValue</sg:ProviderKey>
///     <sg:DisplayName>Hue Saturation Value</sg:DisplayName>
///     <sg:SearchCategory>ShaderLibrary/ColorGrading</sg:SearchCategory>
///     <sg:SearchName>HueSaturationValue</sg:SearchName>
///     <sg:SearchTerms>ColorGrading, HSL, HSV, HueShift, Saturation, Value, Curve, PostEffect</sg:SearchTerms>
///     <sg:ReturnDisplayName>Out</sg:ReturnDisplayName>
///     <sg:Version>1.0</sg:Version>
///     <sg:DynamicPrecision/>
///</funchints>
///<paramhints name = "color">
///     <sg:DisplayName>Color</sg:DisplayName>
///     <sg:Default>0,0,0</sg:Default>
///</paramhints>
///<paramhints name = "hueShift">
///     <sg:DisplayName>Hue Shift</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "saturation">
///     <sg:DisplayName>Saturation</sg:DisplayName>
///     <sg:Default>0</sg:Default>
///</paramhints>
///<paramhints name = "value">
///     <sg:DisplayName>Value</sg:DisplayName>
///     <sg:Default>1</sg:Default>
///</paramhints>
UNITY_EXPORT_REFLECTION
float3 HueSaturationValue(float3 color, float hueShift, float saturation, float value)
{
  float3 yiq = mul(float3x3(
    0.299,  0.587,  0.114,
    0.596, -0.274, -0.322,
    0.211, -0.523,  0.312
  ), color);

  float hue = atan2(yiq.z, yiq.y) + hueShift * 6.2831853;
  float chroma = sqrt(yiq.y * yiq.y + yiq.z * yiq.z) * max(1.0 + saturation, 0.0);
  yiq.y = cos(hue) * chroma;
  yiq.z = sin(hue) * chroma;

  float3 rgb = mul(float3x3(
    1.0,  0.956,  0.621,
    1.0, -0.272, -0.647,
    1.0, -1.106,  1.703
  ), yiq);

  return max(rgb * max(value, 0.0), 0.0);
}

#endif