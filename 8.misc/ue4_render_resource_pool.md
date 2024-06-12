# UE的GPU Resource Pool 

* TResourcePool
    * Tick
        * Called by TickRenderingTickables
            * FRenderingThreadTickHeartbeat::Run
            * FEngineLoop::Tick
* TRenderResourcePool
    * CreatePooledResource(ArraySize)
    * ReleasePooledResource
    * PooledSizeForCreationArguments(ArraySize)

## 使用示例

* FGlobalDynamicMeshIndexPool
    * TGlobalResource\<FGlobalDynamicMeshIndexPool\> GDynamicMeshIndexPool
    * Used by `FPooledDynamicMeshBufferAllocator`
* FGlobalDynamicMeshVertexPool
* FBoneBufferPool
* FClothBufferPool
