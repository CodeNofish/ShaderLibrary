针对你正在开发的独立 URP Shader 库，建议按“**基础函数 → 布尔/域操作 → 烘焙与生成 → 渲染/应用 → 变体与发布**”五层来设计，避免把 SDF 做成一堆散文件。

### 必做模块

| 模块 | 建议实现 | 用途 |
|---|---|---|
| `SDFPrimitives.hlsl` | `sdSphere / sdBox / sdRoundedBox / sdPlane / sdCylinder / sdCapsule / sdTorus / sdCone` | 程序化形状、UI、VFX 遮罩 |
| `SDFCombiners.hlsl` | `opUnion / opIntersect / opSubtract` + `opSmoothUnion / opSmoothIntersect / opSmoothSubtract` | 组合形状、有机体、溶解/融合 |
| `SDFDomains.hlsl` | `opTranslate / opRotate / opScale / opRepeat / opMirror / opTwist / opBend` | 平铺、变形、程序化纹理/模型 |
| `SDFUtils.hlsl` | `sdfNormal / sdfSmoothStep / sdfDither / sdfAA / sdfGradient` | 法线、抗锯齿、边缘光、描边 |
| `SDFRayMarching.hlsl` | 屏幕/局部 Ray Marching、最大步数、步长缩放、深度提前退出 | 体积形状、后处理、特效 |
| `SDFBake.compute` | Mesh→Texture3D、AABB 包围盒、距离截断、RWTexture3D 输出 | 烘焙 SDF 体积纹理 |
| `SDFMeshBaker.cs` | 编辑器烘焙、预览切片、导出 `.asset` | 库内资源生产管线 |
| `SDFSoftShadow.hlsl` | SDF 软阴影、遮挡累积、接触硬化 | 后处理/体积阴影 |
| `SDFAO.hlsl` | 基于 SDF 的环境光遮蔽近似 | 体积/隐式物体 AO |
| `SDFCollision.hlsl` | 粒子/角色与 SDF 碰撞、穿透深度、表面法线 | VFX、角色特效 |

### 关键算法取舍

- **平滑布尔**：优先用 IQ 版 `smoothMin`，`k` 必须按世界单位解释，不要做成无量纲“平滑度”。
- **法线**：统一用中心差分梯度 `normalize(grad(SDF))`，并在接近表面时才采样，避免 NaN。
- **Ray Marching**：提供“屏幕空间”和“局部包围盒”两套入口；移动端建议限制步数、使用 `half` 精度、提前退出。
- **Mesh→SDF**：Compute Shader 里做三角形-点距离 + AABB 剔除；输出 `R16_SFloat` 或 `R32_SFloat`。
- **2D SDF**：如果库要覆盖 UI/VFX 遮罩，补一个 `Jump Flooding / 8SSEDT` 生成器，从黑白遮罩快速生成距离场。

### 发布结构建议

```
Editor/
  SDFMeshBaker.cs
  SDFMeshBakerWindow.cs
Runtime/
  SDFLibrary.asmdef
  Shaders/SDFPrimitives.hlsl
  Shaders/SDFCombiners.hlsl
  Shaders/SDFDomains.hlsl
  Shaders/SDFUtils.hlsl
  Shaders/SDFRayMarching.hlsl
  Shaders/SDFSoftShadow.hlsl
  Shaders/SDFAO.hlsl
  Shaders/SDFCollision.hlsl
ComputeShaders/
  SDFBake.compute
Samples~/
  URP_SDF_Showcase/
```

几个工程约束：

- **URP 兼容**：所有示例 Shader 走 `HLSLPROGRAM / ENDHLSL`，引用 `Core.hlsl`，属性放在 `UnityPerMaterial` CBUFFER。
- **变体控制**：Ray Marching、软阴影、AO 用 `shader_feature_local` 开关，避免全局关键字污染。
- **平台降级**：提供 `SDF_FEATURE_RAYMARCHING`、`SDF_FEATURE_SOFT_SHADOW`、`SDF_PRECISION_HALF` 等宏，移动端默认关闭高步数路径。
- **示例优先**：至少给 3 个样例——SDF UI 圆角/描边、体积 Ray Marching 形状、Mesh SDF 烘焙 + 粒子碰撞。

如果只先做最小可用版本，建议先上：`Primitives + Combiners + Domains + Utils + MeshBake`。这套已经能覆盖你库里的程序化形状、融合效果、体积渲染和烘焙管线，后面再补 Ray Marching、软阴影和 AO。

---
需要我为你生成 `SDFPrimitives.hlsl` 或 `SDFCombiners.hlsl` 的核心代码框架吗？
