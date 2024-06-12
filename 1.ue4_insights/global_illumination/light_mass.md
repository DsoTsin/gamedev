Lightmass
===

支持 `Mac` 和 `Windows`

# 数据流

* UE4Editor
    * Export scene, static meshes, lights to file
    * Start **Swarm**, prepare job depend files
    * OpenChannel, start job
* SwarmAgent
    * Launch UnrealLightmass
* UnrealLightmass
    * Finish
    * UE4Editor import build data

## 基础组件

* DotNet实现
    * SwarmCommonUtils
    * SwarmCoodinatorInterface
    * SwarmInterface

### Swarm 协议格式

### Lightmass代码拆解

#### Editor 导出部分


#### Lightmass 烘焙部分

原理见[Lightmass的算法解析](light_mass_photon_mapping.md)


#### Editor 导入部分 BuiltData

## 可加速计算部分

CUDA加速部分

ISPC AVX512加速部分

## 可分布式计算部分

## IncrediBuild 集成统一调度