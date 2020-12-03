UE4 View & State
===

* FSceneView 包含Family,ViewState,ViewUniformBuffer
    * FViewInfo
* FSceneViewFamily 包含Views,Scene,RenderTarget
* FSceneViewStateInterface
    * FSceneViewState 存储渲染相关的**跨帧**资源（TAA历史信息、遮挡剔除信息、HLOD可见性、阴影等）
* FSceneInterface
    * FScene 场景管理接口，物件和光源，特效以及阴影资源，绘制列表，光线追踪资源（场景加速结构）
* FSceneRenderer 渲染器实例（**每帧都会销毁重建**，同时绘制多个View）

常见的用法
```cpp
	auto RT = NewObject<UTextureRenderTarget2D>();
	RT->AddToRoot();
	RT->ClearColor = FLinearColor::Transparent;
	RT->TargetGamma = TargetGamma;
	RT->InitCustomFormat(TargetSize.X, TargetSize.Y, PF_FloatRGBA, false);
	FTextureRTResource* RTResource = RT->GameThread_GetRTResource();
	FSceneViewFamilyContext ViewFamily(
		FSceneViewFamily::ConstructionValues(RTResource, Scene, FEngineShowFlags(ESFIM_Game))
			.SetWorldTimes(FApp::GetCurrentTime() - GStartTime, FApp::GetDeltaTime(), FApp::GetCurrentTime() - GStartTime)
		);

	// To enable visualization mode
	ViewFamily.EngineShowFlags.SetPostProcessing(true);
	ViewFamily.EngineShowFlags.SetVisualizeBuffer(true);
	ViewFamily.EngineShowFlags.SetTonemapper(false);
	ViewFamily.EngineShowFlags.SetScreenPercentage(false);

	FSceneViewInitOptions ViewInitOptions;
	ViewInitOptions.SetViewRectangle(FIntRect(0, 0, TargetSize.X, TargetSize.Y));
	ViewInitOptions.ViewFamily = &ViewFamily;
	ViewInitOptions.HiddenPrimitives = HiddenPrimitives;
	ViewInitOptions.ViewOrigin = ViewOrigin;
	ViewInitOptions.ViewRotationMatrix = ViewRotationMatrix;
	ViewInitOptions.ProjectionMatrix = ProjectionMatrix;
		
	FSceneView* NewView = new FSceneView(ViewInitOptions);
	NewView->CurrentBufferVisualizationMode = VisualizationMode;
	ViewFamily.Views.Add(NewView);

	ViewFamily.SetScreenPercentageInterface(new FLegacyScreenPercentageDriver(
		ViewFamily, /* GlobalResolutionFraction = */ 1.0f, /* AllowPostProcessSettingsScreenPercentage = */ false));

	FCanvas Canvas(RTResource, NULL, FApp::GetCurrentTime() - GStartTime, FApp::GetDeltaTime(), FApp::GetCurrentTime() - GStartTime, Scene->GetFeatureLevel());
	Canvas.Clear(FLinearColor::Transparent);
	GetRendererModule().BeginRenderingViewFamily(&Canvas, &ViewFamily);

	// Copy the contents of the remote texture to system memory
	OutSamples.SetNumUninitialized(TargetSize.X*TargetSize.Y);
	FReadSurfaceDataFlags ReadSurfaceDataFlags;
	ReadSurfaceDataFlags.SetLinearToGamma(false);
	RTResource->ReadPixelsPtr(OutSamples.GetData(), ReadSurfaceDataFlags, FIntRect(0, 0, TargetSize.X, TargetSize.Y));
	FlushRenderingCommands();
					
	RT->RemoveFromRoot();
	RT = nullptr;
```