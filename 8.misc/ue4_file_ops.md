UE4 IO & Package介绍
===

* UPackage & FLinker & FArchive
* BulkData
* PlatformFile
* NetworkFileSystem

## 基础IO文件操作
---

- FileHelper (最简单的文件操作方式)

``` cpp
#include "Misc/FileHelper.h"
FFileHelper::BufferToString( FString& Result, const uint8* Buffer, int32 Size )
FFileHelper::LoadFileToArray(TArray<uint8>& Result, const TCHAR* Filename, uint32 Flags = 0);
FFileHelper::LoadFileToString( FString& Result, const TCHAR* Filename, EHashOptions VerifyFlags = EHashOptions::None, uint32 ReadFlags = 0 );
```

- PlatformFile
- IFileManager

``` cpp
#include "HAL/FileManager.h"
class IFileManager
{
public:
    static IFileManager& Get();
    FArchive* CreateFileReader( const TCHAR* Filename, uint32 ReadFlags=0 );
    FArchive* CreateFileWriter( const TCHAR* Filename, uint32 WriteFlags=0 );
    bool DirectoryExists( const TCHAR* InDirectory );
    FDateTime GetAccessTimeStamp( const TCHAR* Filename );
};
```

- FPlatformFileManager 最复杂的文件读取方式

``` cpp
#include "HAL/PlatformFileManager.h"
class FPlatformFileManager {
public:
    static FPlatformFileManager& Get();
    // 创建
    IPlatformFile* GetPlatformFile( const TCHAR* Name );
    IPlatformFile& GetPlatformFile();
};
// 平台文件抽象类
class IPlatformFile {
public:
void InitializeNewAsyncIO();
IFileHandle* OpenRead(const TCHAR* Filename, bool bAllowWrite = false);
IFileHandle* OpenReadNoBuffering(const TCHAR* Filename, bool bAllowWrite = false);
IFileHandle* OpenWrite(const TCHAR* Filename, bool bAppend = false, bool bAllowRead = false);
IAsyncReadFileHandle* OpenAsyncRead(const TCHAR* Filename);
// 内存映射文件
IMappedFileHandle* OpenMapped(const TCHAR* Filename);
IMappedFileHandle* AllocateMapped(const TCHAR* Filename, int64 Size);
bool CopyDirectoryTree(const TCHAR* DestinationDirectory, const TCHAR* Source, bool bOverwriteAllExisting);
};
```

- BulkData 读取
``` cpp
// BulkData (Size > 16K)
class IAsyncReadRequest;
typedef TFunction<void(bool bWasCancelled, IAsyncReadRequest*)> FAsyncFileCallBack;
class FByteBulkData
{
public:

GetFileName();

FBulkDataIORequest* 
    CreateStreamingRequest(
        EAsyncIOPriorityAndFlags Priority, 
        FAsyncFileCallBack* CompleteCallback, 
        uint8* UserSuppliedMemory) const;

FBulkDataIORequest* 
    CreateStreamingRequest(
        int64 OffsetInBulkData, int64 BytesToRead, 
        EAsyncIOPriorityAndFlags Priority, 
        FAsyncFileCallBack* CompleteCallback, 
        uint8* UserSuppliedMemory) const;
};

// 异步文件读取
IAsyncReadFileHandle* IORequestHandle = FPlatformFileManager::Get().GetPlatformFile().OpenAsyncRead(*Filename);
check(IORequestHandle); // this generally cannot fail because it is async
if (IORequestHandle == nullptr)
{
    return nullptr;
}
const int64 OffsetInFile = GetBulkDataOffsetInFile() + OffsetInBulkData;
IAsyncReadRequest* ReadRequest = IORequestHandle->ReadRequest(OffsetInFile, BytesToRead, Priority, CompleteCallback, UserSuppliedMemory);
if (ReadRequest != nullptr)
{
    return new FBulkDataIORequest(IORequestHandle, ReadRequest, BytesToRead);
}
else
{
    delete IORequestHandle;
    return nullptr;
}

bool FBulkDataIORequest::PollCompletion() const
{
	return ReadRequest->PollCompletion();
}
bool FBulkDataIORequest::WaitCompletion(float TimeLimitSeconds) const
{
	return ReadRequest->WaitCompletion(TimeLimitSeconds);
}
uint8* FBulkDataIORequest::GetReadResults() const
{
	return ReadRequest->GetReadResults();
}
```

- MemoryMapping File（内存映射文件）

```cpp
check(!FPlatformProperties::GetMemoryMappingAlignment() || IsAligned(BulkDataOffsetInFile, FPlatformProperties::GetMemoryMappingAlignment()));
bWasMapped = BulkData.MapFile(*Filename, BulkDataOffsetInFile, GetBulkDataSize());
    
bool FUntypedBulkData::FAllocatedPtr::MapFile(const TCHAR *InFilename, int64 Offset, int64 Size)
{
	check(!MappedHandle && !MappedRegion); // It doesn't make sense to do this twice, but if need be, not hard to do

	MappedHandle = FPlatformFileManager::Get().GetPlatformFile().OpenMapped(InFilename);

	if (!MappedHandle)
	{
		return false;
	}
	MappedRegion = MappedHandle->MapRegion(Offset, Size, true); //@todo we really don't want to hit the disk here to bring it into memory
	if (!MappedRegion)
	{
		delete MappedHandle;
		MappedHandle = nullptr;
		return false;
	}

	check(Size == MappedRegion->GetMappedSize());
	Ptr = (void*)(MappedRegion->GetMappedPtr()); //@todo mapped files should probably be const-correct
	check(IsAligned(Ptr, FPlatformProperties::GetMemoryMappingAlignment()));
	bAllocated = true;
	return true;
}

void FUntypedBulkData::FAllocatedPtr::UnmapFile()
{
	if (MappedRegion || MappedHandle)
	{
		delete MappedRegion;
		delete MappedHandle;
		MappedRegion = nullptr;
		MappedHandle = nullptr;
		Ptr = nullptr; // make sure we don't try to free this pointer
	}
}
```

- FArchive

```cpp
class FArchive {
public:
FString GetArchiveName() const;
FLinker* GetLinker();

int64 TotalSize();
bool AtEnd();
void Seek(int64 InPos);
int64 Tell();
void Flush();

void Serialize(void* V, int64 Length);
FArchive& ByteOrderSerialize(void* V, int32 Length);

bool SetCompressionMap(TArray<struct FCompressedChunk>* CompressedChunks, ECompressionFlags CompressionFlags);
void SerializeCompressed(void* V, int64 Length, FName CompressionFormat, ECompressionFlags Flags=COMPRESS_NoFlags, bool bTreatBufferAsFileReader=false);

void AttachBulkData(UObject* Owner, FUntypedBulkData* BulkData);
void DetachBulkData(FUntypedBulkData* BulkData, bool bEnsureBulkDataIsLoaded);

//版本管理
int32 UE4Ver() const;
FEngineVersionBase EngineVer() const;
int32 CustomVer(const struct FGuid& Key) const;
void UsingCustomVersion(const struct FGuid& Guid);

private:
// 自定义版本
mutable FCustomVersionContainer* CustomVersionContainer = nullptr;
};
```

---

## UPackage结构

## DirectStorage

- Queue IO Request

``` cpp
QueueReuest(DestMemoryAddress, FileName)
QueueSignal(Fence)
```