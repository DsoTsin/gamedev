# UE4 代码多版本兼容指南

在升级一些旧有UE4代码时，通常会遇到引擎接口变更等问题，为了减少升级维护成本，可以通过以下方法实现游戏项目无缝升级。

项目Build.cs中使用宏WITH_FORWARDED_MODULE_RULES_CTOR来兼容4.16前后版本

``` csharp
#if WITH_FORWARDED_MODULE_RULES_CTOR
    public SolarGame(ReadOnlyTargetRules Target) : base(Target)
#else
    public SolarGame(TargetInfo Target)
#endif
    {
    	...
    }
```

C++ 代码部分

在预编译头文件加入 "Runtime/Launch/Resources/Version.h" 版本信息头文件，使用引擎版本宏区分代码：

``` cpp
#include "Runtime/Launch/Resources/Version.h"


#if ENGINE_MINOR_VERSION <= 15
...
#else
...
#endif

```

项目文件uproject依赖的编译插件需要显式声明（LuaPlugin是我们项目使用的Lua桥接代码生成插件）：

``` json
	,
	"Plugins": [
		{
			"Name": "LuaPlugin",
			"Enabled": true
		}
	]
```

插件依赖的插件也需要显式声明，如下（Apollo依赖引擎插件OnlineSubsystem）

``` json
  "Modules": [
    {
      "Name": "OnlineSubsystemApollo",
      "Type": "Runtime",
      "LoadingPhase": "Default",
      "WhitelistPlatforms": [ "Win32", "Win64", "Android", "IOS", "Mac", "PS4", "XBOXONE", "HTML5" ],
      "BlacklistPlatforms": [ "Linux" ]
    }
  ],
  "Plugins": [
    {
      "Name": "OnlineAdapter",
      "Enabled": true
    },
    {
      "Name": "OnlineSubsystemUtils",
      "Enabled": true
    },
    {
      "Name": "OnlineSubsystem",
      "Enabled": true
    }
  ]
```


4.17 插件Shader声明，材质参数头文件路径变更

``` hlsl
// 4.17以后的版本支持自定义渲染插件，shader的参数头文件路径使用如下头文件
#include "/Engine/Public/Platform.ush"
#include "/Engine/Generated/GeneratedUniformBuffers.ush" 
```