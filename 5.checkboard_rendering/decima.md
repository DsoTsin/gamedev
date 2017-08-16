# Decima引擎在PS4 Pro上的Checkboard Rendering

* 每帧渲染50%的像素
* 每一帧有选择性地采样坐标
* 以下的部分需要以原有的分辨率渲染：
	* 深度缓冲
	* 三角形IndexBuffer
	* AlphaTested Coverage

## 棋盘旋转

We can transform this rotated buffer into what we call a ‘tangram’. We call it a tangram because it’s sort of like that so-called puzzle game.

We can cut the rotated buffer into parts and shuffle them around like so. 
The nice thing about that is that it’s completely lossless, and allows the 2160p checkerboard data to be packed into a compact 2160x2160 texture again. And it also still supports bilinear sampling.
And because of the exact way we placed these parts, we can use the built-in texture-wrap hardware to do the unwrapping for us, without any additional logic or shader instructions during sampling. 

The only thing required during sampling is rotating the native-res UV by 45 degrees, and offsetting this by an offset that’s constant per frame.

```c
struct Vertex 
{
    Vec3 mPos;
    Vec2 mUV;
    Vertex(const Vec3& pos, const Vec2& uv) : mPos(pos), mUV(uv) { }
};
// UV旋转
void GetVerticesForTangramRendering(int native_width, int native_height, bool is_even_frame, Vertex* out_vertices) 
{
    ASSERT(native_width == (native_height * 16) / 9);
    float half_width = 0.5f * (float)native_width;
    float half_height = 0.5f * (float)native_height;

    // Prepare three 45-degree rotated quads, placed to cover each checkerboard pixel exactly once.
    for (int i = 0; i < 3; ++i) 
    {
        float x = (float)native_height * (i == 2 ? 1.0f : 0.0f) + (is_even_frame ? -0.5f : 0.0f);
        float y = (float)native_height * (i == 1 ? -1.0f : 0.0f) + (is_even_frame ?  0.0f : 0.5f);
        out_vertices[4 * i + 0] = Vertex(Vec3(x, y, 1.0f), Vec2(0.0f, 0.0f));
        out_vertices[4 * i + 1] = Vertex(Vec3(half_width + x, half_width + y, 1.0f), Vec2(1.0f, 0.0f));
        out_Vertices[4 * i + 2] = Vertex(Vec3(half_width - half_height + x, half_width + half_height + y, 1.0f), Vec2(1.0f, 1.0f));
        out_vertices[4 * i + 3] = Vertex(Vec3(-half_height + x, half_height + y, 1.0f), Vec2(0.0f, 1.0f));
    }
}
```

## 七巧板拼装和采样

``` c
// Get the uv for the native-res output pixel, repeating the outer most pixels to prevent blending with different tangram parts/the padding areas.
// The border distance was chosen to allow for a bit of safe neighborhood sampling, but this detail is implementation specific.
int2 native_pos = (int2)(uv * float2(native_width, native_height));
native_pos.x = clamp(native_pos.x, 1.0, native_width – 3.0);
native_pos.y = min(native_pos.y, native_height – 3.0);

float is_odd_frame = ... // 1 for odd frames, 0 for even frames

// Get the tangram uv, pointing exactly to halfway the nearest two corner samples in the tangram.
float2 tangram_uv = float2(-1.0 + is_odd_frame + native_pos.x - native_pos.y, 2.0 + is_odd_frame + native_pos.x + native_pos.y) * (0.5 / native_height);

// Do a simple resolve
float4 tangram_color = tex2Dlod(tangram_texture, bilinear_sampler, tangram_uv, 0.0);
```
