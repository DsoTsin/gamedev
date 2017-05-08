# 使用Clang构建C++反射框架

## Clang简介

---

Clang是LLVM构建工具链的类C语言（ObjC、C、C++）的编译前端，它可以完成代码到抽象语法树的转换（AST）。
由于Clang以及LLVM代码设计得比较模块化，接口定义清晰，所以被广大开发者进行二次开发，包括语法的扩展、新语言设计、
AST分析处理、静态代码分析等。

本文讲述如何使用**LibClang**开发C++的反射框架。

---

## 反射器（Reflector）的设计

---

### LibClang的接口以及暴露的能力

### AST遍历

### 注解解析

### 反射代码生成

### 编译流程

---

## 参考

---

- [C++ Reflection](http://austinbrunkhorst.com/blog/category/reflection)
- [Kaleido3D/CppReflector](https://github.com/TsinStudio/kaleido3d/tree/master/Source/Tools/CppReflector)