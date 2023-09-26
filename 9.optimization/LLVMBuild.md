# LLVM 编译选项

基于LLVM 16

    cmake -Hllvm -B../build-llvm -DLLVM_TARGETS_TO_BUILD="AArch64;X86;ARM" -DLLVM_INCLUDE_TESTS=OFF