Shader 里常用的噪声大致可以分成：**白噪声 / 基础随机噪声、晶格梯度噪声、值噪声、点基细胞噪声、分形组合噪声，以及 Curl、Wavelet、Domain Warping 等高级变体**。

### 常见噪声算法

| 噪声类型 | 核心特点 | 典型用途 |
|---|---|---|
| **White Noise** | 纯随机，不连续，像素间无相关性 | 随机种子、抖动、故障效果 |
| **Value Noise** | 在网格顶点放随机标量，再做平滑插值 | 简单纹理、低开销扰动 |
| **Perlin Noise** | 基于晶格梯度向量插值，连续平滑 | 地形、云、水波、材质扰动 |
| **Simplex Noise** | Perlin 改进版，单纯形网格，高维更高效 | 3D/4D 噪声、体积云、动态特效 |
| **Worley / Voronoi Noise** | 基于点到特征点的最近距离 | 细胞纹、石面、水渍、气泡 |
| **FBM / Fractal Noise** | 多层噪声叠加，频率递增、振幅递减 | 山脉、云团、火焰、湍流 |
| **Turbulence Noise** | 对噪声取绝对值后再叠加 | 粗糙纹理、火焰、烟雾 |
| **Curl Noise** | 用噪声构造无散度向量场 | 流体扰动、烟雾卷曲 |
| **Wavelet Noise** | 频带更可控的晶格噪声 | 细节纹理、抗混叠合成 |
| **OpenSimplex Noise** | 避开 Simplex 专利的替代方案 | 高质量程序化纹理 |
| **Domain Warping** | 用噪声再次扰动采样坐标 | 大理石、熔岩、云团扭曲 |



### 在 Shader 里怎么选

- **要自然连续纹理**：优先 **Perlin / Simplex**。
- **性能敏感或移动端**：可用 **Value Noise**，或把噪声预烘焙到纹理里。
- **要细胞、裂纹、皮肤、石面**：用 **Worley / Voronoi**。
- **要丰富细节**：把任意基础噪声叠成 **FBM**。
- **要做流体、烟雾卷曲**：用 **Curl Noise** 或 **Domain Warping**。
- **Unity 里快速验证**：可以直接用 **Shader Graph 的 Noise 节点**，里面通常包含 Simplex、Perlin 等实现； 需要自定义算法时，再放进 **Custom Function / HLSL include** 里。

另外，Shader 里真正的 `rand()` 很少直接用，通常用 **hash 函数 + 平滑插值** 来构造稳定、可重复的噪声。

---
需要我为你提供 Perlin、Simplex 或 Worley 噪声的 HLSL 代码模板吗？
