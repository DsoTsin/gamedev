# REDEngine的GI

相关源码文件

* giProbeBakingUtility.cpp **[backendPipeline]**
    * GI::RenderProbes
    * ProbeBakeGeneratorState::ProcessProbeData
        * 烘焙GI Surfel
        * 一个启发是近距离的Surfel数据可以通过多帧GBuffer来生成，而不是通过Voxelization，这样能更高保真度的保存数据，这个Surfel数据的保存可以通过Spatial Hash Grid保存，类似的实现在AMD BrixelGI里有所提及；HSGI[TX]则将Voxelization生成的world space surfel数据作为GI场景表达的一个补充，当然也可以考虑多帧GBuffer生成surfel voxel修正漏光
    * ScheduleGIGenerate
        * "Detect Empty Sectors ( Only Terrain and Roads )"
        * "Create Proxies for the scene"
        * "Create Scene and Add Proxies"
        * "GI Probes placement"
            * Max probes per sector
        * "Initial tetrahedralization of probes"
        * "Render GI Probes"
        * "Clean After GI Probes"
        * "Merge TetStructures"
        * "Process GI Bricks"
        * "Generate DepthMap"
        * "RayTrace Surfel-Probe"
            * Collect surfels
        * "Generate Save Data.. Save header"
        * "Generate Save Data.. Processing Surfels"
            * Using HilbertID/Morton Code
                ```C
                Uint32 HilbertID( Uint32 x, Uint32 y, Uint32 z )
                {
                #define SPLIT_BITS(b)					\
                    b = (b | (b << 16)) & 0x030000FF;	\
                    b = (b | (b << 8)) & 0x0300F00F;	\
                    b = (b | (b << 4)) & 0x030C30C3;	\
                    b = (b | (b << 2)) & 0x09249249;	
                    SPLIT_BITS( x );
                    SPLIT_BITS( y );
                    SPLIT_BITS( z );
                #undef SPLIT_BITS
                    return x | (y<<1) | (z<<2);
                }
                ```
        * "Generate Save Data.. Post RayCast"
        * "Save Resources"
        * "Clean up"
        * UE里去实现这个过程利用GPU Lightmass会比较合适
            * GPULightmass有完整的GPU Scene、材质信息
* giProbeDistributionGenerator.cpp **[backendPipeline]**
    * ProbeDistribuitionGenerator::Generate `"Distribute probes"`
        * runtimeSystemGI.cpp **[backendPrecomputedLight]**
            * GI::CProbeSpawner::PopulateProbeData
                * 先生成SDF数据
                * 然后根据摆放的GIVolume在Volume内的Mesh按密度控制沿着表面布置Probe
* giProbeSectorsGenerator.cpp
    * ProbeSectorsGenerator


