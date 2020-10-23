# UE4自定义结构体序列化

> 疑问：像TMap这样的复杂结构是如何序列化的呢

先看看TStructOpsTypeTraitsBase2这个类

----

## TStructOpsTypeTraitsBase2

```cpp
USTRUCT()
struct FXXX
{

bool Serialize(FArchive& Ar);
};


template<>
struct TStructOpsTypeTraits<FXXX> : public TStructOpsTypeTraitsBase2<FXXX>
{
	enum
	{
		WithSerializer = true
	};
};
```

再看看更基础的**FVector**，序列化的代码位于***UObject/Property.cpp***

> 使用StructOpsTypeTraits的代码位于***UObject/Class.h***

UScriptStruct （代理类） 记录 T 反射信息 ICppStructOps
