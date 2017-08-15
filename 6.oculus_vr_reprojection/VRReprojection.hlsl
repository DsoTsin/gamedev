#include "/Engine/Public/Platform.ush"

struct ProjectionVS
{
    float4 Position : POSITION;
    float2 UV : TEXCOORD0;
};

struct ProjectionVS2PS
{
    float4 Position : SV_POSITION;
    float2 UV : TEXCOORD0;
};

SamplerState DepthSampler;
Texture2D DepthTexture;

SamplerState OtherEyeDepthSampler;
Texture2D OtherEyeDepthTexure;

float4x4 OtherEyeViewProj;
float4x4 InvViewProj;

// xy:DepthBufferSize.xy, zw:1/DepthBufferSize.xy
float4 DepthBufferSize;
float4 ReprojectionMaskColor;

#define DepthThreshold    0.001f

[vertexshader] ProjectionVS2PS CopyDepthVS(ProjectionVS In)
{
    ProjectionVS2PS Out;
	Out.Position = WorldPositionToLocal(In.Position);
	Out.UV = In.UV;
	return Out;
}

[pixelshader] float4 CopyDepthPS(ProjectionVS2PS In) : SV_Target
{
	float z = DepthTexture.Sample(DepthSampler, float4(In.UV, 0, 0));
	return float4(z.xxx, 1);
}

float GetOtherEyeConservativeDepth(float2 otherEyeUV)
{
    float otherEyeDepth = OtherEyeDepthTexure.Sample(OtherEyeDepthSampler, otherEyeUV + float2(0, 2 / DepthBufferSize.y), 0);
    otherEyeDepth = max(otherEyeDepth, OtherEyeDepthTexure.Sample(OtherEyeDepthSampler, otherEyeUV + float2(2 / DepthBufferSize.x, -2 / DepthBufferSize.y), 0));
    otherEyeDepth = max(otherEyeDepth, OtherEyeDepthTexure.Sample(OtherEyeDepthSampler, otherEyeUV + float2(-2 / DepthBufferSize.x, -2 / DepthBufferSize.y), 0));
    return otherEyeDepth;
}

[pixelshader] float4 ReprojectionPassPS(ProjectionVS2PS In) : SV_Target
{
	// read depth and reconstruct world position of pixel
	float depth = DepthTexture.Sample(DepthSampler, In.UV);
    float4 clipSpacePos = float4(In.UV * 2.0 - 1.0, depth, 1);
	float4 worldPos = mul(InvViewProj, clipSpacePos);
	worldPos.xyz /= worldPos.w;

	// transform into other eye's view
	float4 otherClipSpacePos = mul(OtherEyeViewProj, float4(worldPos.xyz, 1));
	otherClipSpacePos.xyz /= otherClipSpacePos.w;

	// read color
	float2 otherEyeUV = otherClipSpacePos.xy*0.5 + 0.5;
	float4 otherEyeColor = OtherEyeDepthTexure.Sample(OtherEyeDepthSampler, otherEyeUV, 0);
	float isReprojectable = otherEyeColor.a;

	// Verify if if it is a valid reprojection by using conservativeFilter
	float otherEyeDepth = GetOtherEyeConservativeDepth(otherEyeUV);
	float diff = otherEyeDepth - depth;
	if (diff > DepthThreshold * isReprojectable)
	{
		discard;            // this will be filled in later
	}
	
	return ReprojectionMaskColor * otherEyeColor;
 }