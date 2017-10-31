# UE4 代码多版本兼容指南

在升级一些旧有UE4代码时，通常会遇到方法变更等问题。

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

在预编译头文件加入 "Runtime/Launch/Resources/Version.h" 版本信息头文件，使用引擎版本宏区分代码

``` cpp
#include "Runtime/Launch/Resources/Version.h"


#if ENGINE_MINOR_VERSION <= 15
...
#else
...
#endif

```

项目文件uproject依赖的编译插件需要显式声明

``` json
	,
	"Plugins": [
		{
			"Name": "LuaPlugin",
			"Enabled": true
		}
	]
```

插件以赖的插件也需要显式声明

4.17 插件Shader声明，材质参数头文件路径变更
