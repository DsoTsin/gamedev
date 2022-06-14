# UE4 Slate App 开发

* Slate渲染器无法使用SlateRHIRenderer（由于和编辑器绑定了）
* 只能使用D3D和OpenGL Renderer（Mac，Linux）
* 一些依赖编辑器的模块都不能使用
* 分配动态图像资源只支持RGBA8格式

> 代码位于StandaloneRenderer.cpp


