ASTC
===

目前主流的ASTC压缩工具库包含以下：

* [NVIDIA Texture Tools 3][1]
* [ISPC TexComp][2]
* [ARM astcenc][3]

当然还有仍保持自研引擎厂商开发的In-house GPU加速的ASTC压缩裤

---

## 对比

||NVTT3|ISPCTexComp|astcenc|
|:-:|:-:|:-:|:-:|
|压缩方式| CUDA GPU加速 | CPU SIMD加速 | 手写SIMD加速 |
|支持格式|LDR|LDR|LDR+HDR|
|支持尺寸|全部尺寸|最大到8x8|全部尺寸|
|引擎支持|暂无|Unreal|Unity|
|算法原理|||PCA|


[1]:https://developer.nvidia.com/gpu-accelerated-texture-compression
[2]:https://github.com/GameTechDev/ISPCTextureCompressor
[3]:https://github.com/ARM-software/astc-encoder