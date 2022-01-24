# MetalLib翻译到SPIRV

Apple Metal使用的LLVM IR是表达能力非常**完备**的中间表示语言。

```cpp
#import <metal_stdlib>

using namespace metal;

// Calculates a slice of a depth pyramid from a higher resolution slice
//  Handles downsampling from odd sized depth textures.
kernel void depthPyramid(depth2d<float, access::sample> inDepth        [[texture(0)]],
                         texture2d<float, access::write> outDepth      [[texture(1)]],
                         constant uint4& inputRect                     [[buffer(2)]],
                         uint2 tid                                     [[thread_position_in_grid]])
{
    constexpr sampler sam (min_filter::nearest, mag_filter::nearest, coord::pixel);
    uint source_width   = inputRect.x;
    uint source_height  = inputRect.y;
    float2 src          = float2(tid * 2 + inputRect.zw);

    float minval        = inDepth.sample(sam, src);
    minval              = max(minval, inDepth.sample(sam, src + float2(0, 1)));
    minval              = max(minval, inDepth.sample(sam, src + float2(1, 0)));
    minval              = max(minval, inDepth.sample(sam, src + float2(1, 1)));
    bool edge_x         = (tid.x * 2 == source_width - 3);
    bool edge_y         = (tid.y * 2 == source_height - 3);

    if (edge_x)
    {
        minval = max(minval, inDepth.sample(sam, src + float2(2, 0)));
        minval = max(minval, inDepth.sample(sam, src + float2(2, 1)));
    }
    if (edge_y)
    {
        minval = max(minval, inDepth.sample(sam, src + float2(0, 2)));
        minval = max(minval, inDepth.sample(sam, src + float2(1, 2)));
    }
    if (edge_x && edge_y) minval = max(minval, inDepth.sample(sam, src + float2(2, 2)));

    outDepth.write(float4(minval), tid);
}
```

```c
source_filename = "depthPyramid"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64-apple-ios13.0.0"

%struct._depth_2d_t.191 = type opaque
%struct._texture_2d_t.192 = type opaque
%struct._sampler_t.193 = type opaque

@__air_sampler_state = internal addrspace(2) constant i64 -9188470239253725111, align 8
@llvm.global_ctors = appending global [0 x { i32, void ()*, i8* }] zeroinitializer

; Function Attrs: convergent nounwind
define void @depthPyramid(%struct._depth_2d_t.191 addrspace(1)* %0, %struct._texture_2d_t.192 addrspace(1)* %1, <4 x i32> addrspace(2)* noalias nocapture readonly dereferenceable(16) %2, <2 x i32> %3) local_unnamed_addr #0 {
  %5 = load <4 x i32>, <4 x i32> addrspace(2)* %2, align 16
  %6 = extractelement <4 x i32> %5, i64 0 ; source_width
  %7 = extractelement <4 x i32> %5, i64 1 ; source_height
  %8 = shl <2 x i32> %3, <i32 1, i32 1>   ; tid * 2
  %9 = shufflevector <4 x i32> %5, <4 x i32> undef, <2 x i32> <i32 2, i32 3> ; inputRect.zw
  %10 = add <2 x i32> %9, %8  ; tid * 2 + inputRect.zw
  %11 = tail call fast <2 x float> @air.convert.f.v2f32.u.v2i32(<2 x i32> %10) #2 ; float2 src = float2(tid * 2 + inputRect.zw);
  ; inDepth.sample(sam, src);
  %12 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %11, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  ; float minval = inDepth.sample(sam, src);
  %13 = extractvalue { float, i8 } %12, 0
  ; src + float2(0, 1)
  %14 = fadd fast <2 x float> %11, <float 0.000000e+00, float 1.000000e+00>
  ; inDepth.sample(sam, src + float2(0, 1))
  %15 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %14, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %16 = extractvalue { float, i8 } %15, 0
  %17 = tail call fast float @air.fast_fmax.f32(float %13, float %16) #2
  %18 = fadd fast <2 x float> %11, <float 1.000000e+00, float 0.000000e+00>
  %19 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %18, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %20 = extractvalue { float, i8 } %19, 0
  %21 = tail call fast float @air.fast_fmax.f32(float %17, float %20) #2
  %22 = fadd fast <2 x float> %11, <float 1.000000e+00, float 1.000000e+00>
  %23 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %22, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %24 = extractvalue { float, i8 } %23, 0
  %25 = tail call fast float @air.fast_fmax.f32(float %21, float %24) #2
  %26 = extractelement <2 x i32> %3, i64 0
  %27 = shl i32 %26, 1
  %28 = add i32 %6, -3
  %29 = icmp eq i32 %27, %28
  %30 = extractelement <2 x i32> %3, i64 1
  %31 = shl i32 %30, 1
  %32 = add i32 %7, -3
  %33 = icmp eq i32 %31, %32
  br i1 %29, label %34, label %43

34:                                               ; preds = %4
  %35 = fadd fast <2 x float> %11, <float 2.000000e+00, float 0.000000e+00>
  %36 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %35, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %37 = extractvalue { float, i8 } %36, 0
  %38 = tail call fast float @air.fast_fmax.f32(float %25, float %37) #2
  %39 = fadd fast <2 x float> %11, <float 2.000000e+00, float 1.000000e+00>
  %40 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %39, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %41 = extractvalue { float, i8 } %40, 0
  %42 = tail call fast float @air.fast_fmax.f32(float %38, float %41) #2
  br label %43

43:                                               ; preds = %34, %4
  %44 = phi float [ %42, %34 ], [ %25, %4 ]
  br i1 %33, label %45, label %54

45:                                               ; preds = %43
  %46 = fadd fast <2 x float> %11, <float 0.000000e+00, float 2.000000e+00>
  %47 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %46, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %48 = extractvalue { float, i8 } %47, 0
  %49 = tail call fast float @air.fast_fmax.f32(float %44, float %48) #2
  %50 = fadd fast <2 x float> %11, <float 1.000000e+00, float 2.000000e+00>
  %51 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %50, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %52 = extractvalue { float, i8 } %51, 0
  %53 = tail call fast float @air.fast_fmax.f32(float %49, float %52) #2
  br label %54

54:                                               ; preds = %45, %43
  %55 = phi float [ %53, %45 ], [ %44, %43 ]
  %56 = and i1 %29, %33
  br i1 %56, label %57, label %62

57:                                               ; preds = %54
  %58 = fadd fast <2 x float> %11, <float 2.000000e+00, float 2.000000e+00>
  %59 = tail call { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly %0, %struct._sampler_t.193 addrspace(2)* nocapture readonly bitcast (i64 addrspace(2)* @__air_sampler_state to %struct._sampler_t.193 addrspace(2)*), i32 1, <2 x float> %58, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #3
  %60 = extractvalue { float, i8 } %59, 0
  %61 = tail call fast float @air.fast_fmax.f32(float %55, float %60) #2
  br label %62

62:                                               ; preds = %57, %54
  %63 = phi float [ %61, %57 ], [ %55, %54 ]
  %64 = insertelement <4 x float> undef, float %63, i32 0
  %65 = shufflevector <4 x float> %64, <4 x float> undef, <4 x i32> zeroinitializer
  tail call void @air.write_texture_2d.v4f32(%struct._texture_2d_t.192 addrspace(1)* nocapture %1, <2 x i32> %3, <4 x float> %65, i32 0, i32 2) #1
  ret void
}

; Function Attrs: argmemonly nounwind
declare void @air.write_texture_2d.v4f32(%struct._texture_2d_t.192 addrspace(1)* nocapture, <2 x i32>, <4 x float>, i32, i32) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #2

; Function Attrs: argmemonly convergent nounwind readonly
declare { float, i8 } @air.sample_depth_2d.f32(%struct._depth_2d_t.191 addrspace(1)* nocapture readonly, %struct._sampler_t.193 addrspace(2)* nocapture readonly, i32, <2 x float>, i1, <2 x i32>, i1, float, float, i32) local_unnamed_addr #3

; Function Attrs: nounwind readnone
declare <2 x float> @air.convert.f.v2f32.u.v2i32(<2 x i32>) local_unnamed_addr #2

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind }
attributes #2 = { nounwind readnone }
attributes #3 = { argmemonly convergent nounwind readonly }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}
!air.version = !{!5}
!air.language_version = !{!6}
!air.compile_options = !{!7, !8, !9}
!air.kernel = !{!10}
!air.sampler_states = !{!17}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 0]}
!1 = !{i32 2, !"Dwarf Version", i32 4}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{!"Apple metal version 31001.325 (metalfe-31001.325)"}
!5 = !{i32 2, i32 2, i32 0}
!6 = !{!"Metal", i32 2, i32 2, i32 0}
!7 = !{!"air.compile.denorms_disable"}
!8 = !{!"air.compile.fast_math_enable"}
!9 = !{!"air.compile.framebuffer_fetch_enable"}
!10 = !{void (%struct._depth_2d_t.191 addrspace(1)*, %struct._texture_2d_t.192 addrspace(1)*, <4 x i32> addrspace(2)*, <2 x i32>)* @depthPyramid, !11, !12}
!11 = !{}
!12 = !{!13, !14, !15, !16}
!13 = !{i32 0, !"air.texture", !"air.location_index", i32 0, i32 1, !"air.sample", !"air.arg_type_name", !"depth2d<float, sample>", !"air.arg_name", !"inDepth"}
!14 = !{i32 1, !"air.texture", !"air.location_index", i32 1, i32 1, !"air.write", !"air.arg_type_name", !"texture2d<float, write>", !"air.arg_name", !"outDepth"}
!15 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 16, !"air.location_index", i32 2, i32 1, !"air.read", !"air.arg_type_size", i32 16, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"uint4", !"air.arg_name", !"inputRect"}
!16 = !{i32 3, !"air.thread_position_in_grid", !"air.arg_type_name", !"uint2", !"air.arg_name", !"tid"}
!17 = !{!"air.sampler_state", i64 addrspace(2)* @__air_sampler_state}
```