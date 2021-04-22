# UE4（面向PC&主机平台）场景渲染的缺陷和挑战

> 仅讨论**静态场景**渲染，不包括地形

## 当前场景制作挑战

---

随着最近几年生产技术的迭代推进，逐渐出现以下的需求和挑战：

* 小范围高密度静态场景
* 较低可复用度场景（大部分物件不可重用，MegaScan素材）
* 过程化生成场景（实例化渲染物件）
* 可破坏场景（主要由刚体构成）

## UE4原生引擎不足

---

* MaterialInstance方式对**uber material**的支持力度不够
* **数据驱动**的渲染支持不够（材质描述方式对数据驱动的改造不友好，虽然有PrimitiveCustomData支持）
* StaticMesh数量过多的场景渲染对CPU负担较大，面数复杂度高的StaticMesh对GPU负担大
    * 虽然UE5**一部分**解决了该问题
        * 虚拟几何体
        * 层次化管理和表达复杂模型
        * 混合光栅化
* HISM针对性的优化力度不够，还需要针对性地管理内存，剔除和渲染：
    * 建筑（HISM批次合并不彻底）
    * 草（运行时的生成，实例化的渲染还有很大优化空间）
    * 树木（树木本身的mesh复杂也是瓶颈），需要增加层次化的表达

## 国外AAA引擎的设计

---

* 数据驱动方式的渲染
    * **全游戏场景物件**统一的层次化的数据结构CPU&GPU管理和剔除
        * 每个场景节点标记了物件类型
        * 不同类型的节点可以针对性选择子节点的管理和剔除方式
            * 有的引擎对复杂的树木也进行层次化的剔除和渲染
    * **尽可能**使用**shader固化**材质模板，xml描述材质，达成更方便的合批
    * 同样实现了CPU（用于遮挡剔除）和**GPU**的软件光栅化
        * 利用更小的compute调度单位（wavefront/warp）实现软件光栅化([Emulating a fake retro GPU in Vulkan compute][1])
        * UE5的混合光栅化方案
    * 复杂物件（建筑，扫描场景）层次化表示和运行时剔除（GPU Driven Rendering, Dunia Engine）
    * 运行时利用GPU的过程化数据生成（Horizon：Decima Engine）


[1]:https://themaister.net/blog/2019/10/12/emulating-a-fake-retro-gpu-in-vulkan-compute/