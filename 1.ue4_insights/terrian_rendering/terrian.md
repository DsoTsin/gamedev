# Unreal Insight: Landscape 模块分析

## 地形支持的材质表达式

![](images/t_mat_classes.png)

## 地形渲染

### Weight Map

LandscapeComponent

* SectionBaseX
* SectionBaseY
* WeightMapTextures
* XYOffsetmapTexture
* WeightmapSubsectionOffset
* HeightmapScaleBias
* HeightmapTexture
* GIBakedBaseColorTexture

* RenderGrassMap()

### Grass Map

![](images/t_grass_map_usage.png)

### Render GrassMap

![](images/t_grass_map_rendering.png)

## 草的裁减

![](images/t_grass_culling.png)

### Landscape Grass

![](images/t_grass_culling_params.png)

![](images/t_grass_hcomp_culling.png)

### 材质

* LandscapeMaterial
* LandscapeHoleMaterial

### 光照

* LightMassSetting
* StaticLightingResolution
* bCastShadowAsTwoSided
* LightChannels

### 层次混合

### LOD

* NumSubsections
* SubsectionSizeQuads
* LandscapeSectionOffset
* LODDistanceFactor
* StreamingDistanceMultiplier
* LODFalloff
* MaxLODLevel

## 高度场碰撞体

相关参数控制：

* CollisionThickness

![](images/t_height_collision.png)