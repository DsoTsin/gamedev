GVDB源码分析
===

关键代码位于 **gvdb_volume_gvdb.cpp**

下面这些代码能够基本定义GVDB体素的构建、更新、以及邻近查找

```c
Line: 286

// Topology
LoadFunction ( FUNC_FIND_ACTIV_BRICKS,	"gvdbFindActivBricks",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_BITONIC_SORT,		"gvdbBitonicSort",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_CALC_BRICK_ID,		"gvdbCalcBrickId",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_RADIX_SUM,			"RadixSum",						MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_RADIX_PREFIXSUM,	"RadixPrefixSum",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_RADIX_SHUFFLE,		"RadixAddOffsetsAndShuffle",	MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_FIND_UNIQUE,		"gvdbFindUnique",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_COMPACT_UNIQUE,		"gvdbCompactUnique",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_LINK_BRICKS,		"gvdbLinkBricks",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );

// Incremental Topology
LoadFunction ( FUNC_CALC_EXTRA_BRICK_ID,"gvdbCalcExtraBrickId",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	

LoadFunction ( FUNC_CALC_INCRE_BRICK_ID,"gvdbCalcIncreBrickId",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_CALC_INCRE_EXTRA_BRICK_ID,"gvdbCalcIncreExtraBrickId",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	

LoadFunction ( FUNC_DELINK_LEAF_BRICKS,	"gvdbDelinkLeafBricks",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_DELINK_BRICKS,		"gvdbDelinkBricks",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_MARK_LEAF_NODE,		"gvdbMarkLeafNode",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );

// Gathering
LoadFunction ( FUNC_COUNT_SUBCELL,		"gvdbCountSubcell",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_INSERT_SUBCELL,		"gvdbInsertSubcell",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_INSERT_SUBCELL_FP16,"gvdbInsertSubcell_fp16",		MODL_PRIMARY, "cuda_gvdb_module.ptx");
LoadFunction ( FUNC_GATHER_DENSITY,		"gvdbGatherDensity",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_GATHER_LEVELSET,	"gvdbGatherLevelSet",			MODL_PRIMARY, "cuda_gvdb_module.ptx");
LoadFunction ( FUNC_GATHER_LEVELSET_FP16, "gvdbGatherLevelSet_fp16", MODL_PRIMARY, "cuda_gvdb_module.ptx");

LoadFunction ( FUNC_CALC_SUBCELL_POS,	"gvdbCalcSubcellPos",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_MAP_EXTRA_GVDB,		"gvdbMapExtraGVDB",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_SPLIT_POS,			"gvdbSplitPos",					MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_SET_FLAG_SUBCELL,	"gvdbSetFlagSubcell",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );	

LoadFunction ( FUNC_READ_GRID_VEL,		"gvdbReadGridVel",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );	
LoadFunction ( FUNC_CHECK_VAL,			"gvdbCheckVal",					MODL_PRIMARY, "cuda_gvdb_module.ptx" );	

// Apron Updates
LoadFunction ( FUNC_UPDATEAPRON_F,		"gvdbUpdateApronF",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_UPDATEAPRON_F4,		"gvdbUpdateApronF4",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_UPDATEAPRON_C,		"gvdbUpdateApronC",				MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_UPDATEAPRON_C4,		"gvdbUpdateApronC4",			MODL_PRIMARY, "cuda_gvdb_module.ptx" );
LoadFunction ( FUNC_UPDATEAPRONFACES_F, "gvdbUpdateApronFacesF",		MODL_PRIMARY, "cuda_gvdb_module.ptx" );

```

# GVDB的构建

![](images/gvdb_build.png)

从`RebuildTopology`函数开始，它也提供了CPU的实现用于数据验证

最多可以构建**5**层
![](images/gvdb_build_topo.png)

GPU的构建逻辑：

* ActivateBricksGPU
    * CUDA::FUNC_CALC_BRICK_ID, 计算Brick的ID
    * Voxel点云排序
    * CUDA::FUNC_FIND_UNIQUE
    * CUDA::AUX_UNIQUE_CNT
    * CUDA::FUNC_COMPACT_UNIQUE
    ![](images/gvdb_activate_bricks.png)
    ![](images/gvdb_build_alloc_resources.png)
    * CUDA::FUNC_LINK_BRICKS
      对每一层的Brick链接
    ![](images/gvdb_build_link_bricks.png)
        ```cuda
        // link node
        extern "C" __global__ void gvdbLinkBricks ( VDBInfo* gvdb, int lev)
        {
            int i = blockIdx.x * blockDim.x + threadIdx.x;
            if ( i >= gvdb->nodecnt[ lev ] ) return;

            VDBNode* node = getNode ( gvdb, lev, i);

            if (!node->mFlags) return;
            uint64 pnodeId = getParent( gvdb, lev+1, node->mPos);
            if (pnodeId == ID_UNDEFL) return;

            VDBNode* pnode = getNode ( gvdb, lev+1, pnodeId);

            int res = gvdb->res[lev+1];
            int3 range = gvdb->noderange[lev+1];

            int3 posInNode = node->mPos - pnode->mPos;
            posInNode *= res;
            posInNode.x /= range.x;
            posInNode.y /= range.y;
            posInNode.z /= range.z;
            int bitMaskPos = (posInNode.z*res + posInNode.y)*res+ posInNode.x;
            
            if (posInNode.x > res || posInNode.x < 0 || posInNode.y > res || posInNode.y < 0 || posInNode.z > res || posInNode.z < 0) return;

            // set mParent in node
            node->mParent = ((pnodeId << 16) | ((lev+1) << 8));	// set parent of child

            uint64 listid = pnode->mChildList;
            uint64 cndx = listid >> 16;
            if (cndx >= gvdb->nodecnt[ lev+1 ]) return;
            uint64* clist = (uint64*) (gvdb->childlist[lev+1] + cndx*gvdb->childwid[lev+1]);

            *(clist + bitMaskPos) = ((uint64(i) << 16) | (uint64(lev) << 8));

        }
        ```

* 核心CUDA代码位于 `gvdb_library/src/cuda_gvdb_nodes.cuh`