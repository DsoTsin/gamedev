# SIMD Library

* C#
    * **Right** Multiplication

* C++
    * `Runtime/Math/Simd`
        * `vec-math.h`
    * `Matrix Math`
        * `Matrix4x4Simd.h`
            * MultiplyMatrices4x4 **Right** Multiplication
        * `vec-matrix.h`
            * float4x4 `mul`(float4x4, ...) **Left** Multiplication
        * `Matrix4x4.h` (under Runtime/Math)
            * `Vector4f Matrix4x4f::MultiplyVector4` **Left** Multiplication

```cpp
v * m = mad(x.m0, v.x, x.m1 * v.y) + mad(x.m2, v.z, x.m3 * v.w);
```

# Intel's Masked Occlusion Culling Libray

* **Left** Multiplication [Can be modified to Right Mul, check function `TransformVertices`]