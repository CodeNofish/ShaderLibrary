#ifndef SHADER_LIBRARY_SILHOUETTE_COMMON
#define SHADER_LIBRARY_SILHOUETTE_COMMON

// 剪影 / 透视公共算法（内部使用，不带 UNITY_EXPORT_REFLECTION，不会生成 ShaderGraph 节点）
// 内联实现以保证各效果文件自包含，命名统一加 Silhouette 前缀避免与其它分类冲突
// 注意：ZTest / Stencil / Queue / RenderFeature 属于 Pass 状态与管线配置，无法由函数完成，
//       本库只实现其中的深度比较、遮罩逻辑与着色算法，具体配置见各文件注释

static float SilhouetteHash21(float2 p)
{
  p = frac(p * float2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return frac((p.x + p.y) * p.x);
}

// 深度遮挡判定：当前片元比场景背景"更远"即被遮挡
// Reverse-Z 缓冲（Unity URP / DX11+ 常见）下比较方向需反转，否则判定完全相反
// bias 抵消深度精度误差，softness 软化边界，返回 [0,1] 的遮挡遮罩
static float SilhouetteOcclusion(float fragmentDepth, float sceneDepth, float bias, float softness, float reverseZ)
{
  float diff = lerp(fragmentDepth - sceneDepth, sceneDepth - fragmentDepth, step(0.5, reverseZ));
  return smoothstep(bias, bias + max(softness, 1e-4), diff);
}

// 周期脉冲：sin(time * speed) 映射到 [0,1]，noise 用于轻微扰动相位产生"呼吸感"
static float SilhouettePulse(float time, float speed, float noise)
{
  float phase = time * speed + noise * 0.9424778;
  return sin(phase) * 0.5 + 0.5;
}

#endif