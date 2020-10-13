# UE4实现Bindless资源支持

``` cpp
RHICommandList.SetBindlessUAVs(ShaderRHI, UAVIndex, 
    UAVCount, UAVs);

RHICommandList.SetBindlessSRVs(ShaderRHI, SRVIndex, 
    SRVCount, SRVs);
```

Shader Model 5.1+

```
static constexpr uint32 ENABLE_UNBOUNDED_DESCRIPTOR_TABLES = (1 << 20);

D3DCompiler_47
```

Each bindless resource is bounded to individual RootSignature Parameter (unbound resource residents in the last range within a descriptor table).

DescriptorHeap and RootParameters

``` 

```