#!/bin/sh
set -ex

version=release_90
prefix=/build/llvm
src=$prefix/src
cpu=4

# stage 0: build only clang
stage0() {
    mkdir -p $src/stage0
    cd $src/stage0
    cmake .. -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$prefix/stage0 \
        -DLLVM_BINUTILS_INCDIR=/usr/include \
        -DLLVM_BUILD_DOCS=NO \
        -DLLVM_BUILD_EXAMPLES=NO \
        -DLLVM_BUILD_RUNTIME:BOOL=OFF \
        -DLLVM_BUILD_TESTS=NO \
        -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_ENABLE_ASSERTIONS=NO \
        -DLLVM_ENABLE_CXX1Y=YES \
        -DLLVM_ENABLE_FFI=NO \
        -DLLVM_ENABLE_LIBCXX=NO \
        -DLLVM_ENABLE_PIC=YES \
        -DLLVM_ENABLE_RTTI=YES \
        -DLLVM_ENABLE_SPHINX=NO \
        -DLLVM_ENABLE_TERMINFO=YES \
        -DLLVM_ENABLE_ZLIB=YES \
        -DLLVM_HOST_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_INCLUDE_EXAMPLES=NO
    ninja clang -j $cpu
    ninja install-clang
    cmake -P tools/clang/lib/Headers/cmake_install.cmake
}

# compile libc++, libc++abi and libunwind with clang from stage0

# TODO: Technically, there will be no runtime dependency to gcc and libstdc++
#       in these libraries, however we used at least libstdc++ to compile
#       libc++.
# TODO: compiler-rt is compiled, but not installed.
stage1() {
    mkdir -p $src/stage1
    cd $src/stage1
    cmake .. -GNinja \
        -DCMAKE_C_COMPILER=$prefix/stage0/bin/clang \
        -DCMAKE_CXX_COMPILER=$prefix/stage0/bin/clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DLLVM_BINUTILS_INCDIR=/usr/include \
        -DLLVM_BUILD_DOCS=NO \
        -DLLVM_BUILD_EXAMPLES=NO \
        -DLLVM_BUILD_RUNTIME:BOOL=ON \
        -DLLVM_BUILD_TESTS=NO \
        -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_ENABLE_ASSERTIONS=NO \
        -DLLVM_ENABLE_CXX1Y=YES \
        -DLLVM_ENABLE_FFI=NO \
        -DLLVM_ENABLE_LIBCXX=NO \
        -DLLVM_ENABLE_PIC=YES \
        -DLLVM_ENABLE_RTTI=YES \
        -DLLVM_ENABLE_SPHINX=NO \
        -DLLVM_ENABLE_TERMINFO=YES \
        -DLLVM_ENABLE_ZLIB=YES \
        -DLLVM_HOST_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_INCLUDE_EXAMPLES=NO \
        \
        -DLIBCXX_HAS_MUSL_LIBC:BOOL=ON \
        -DLIBCXX_HAS_GCC_S_LIB:BOOL=OFF \
        -DLIBCXXABI_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        -DLIBCXXABI_USE_COMPILER_RT:BOOL=ON \
        -DLIBCXXABI_USE_LLVM_UNWINDER:BOOL=ON \
        \
        -DLIBUNWIND_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        \
        -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        -DCOMPILER_RT_BUILD_BUILTINS=ON \
        -DCOMPILER_RT_BUILD_SANITIZERS=ON
    # fix build for libc++.so
    # https://github.com/tpimh/ngtc/issues/3
    # add -lgcc to the first link with libunwind.so.1.0, which is the build of libc++.so
    sed -i -e 's/\(LINK_LIBRARIES = .*\)\(-lm -lrt lib\/libunwind.so.1.0\)/\1-lgcc \2/' build.ninja
    ninja cxx -j $cpu
    ninja install-libcxx install-libcxxabi
    cmake -P projects/libunwind/cmake_install.cmake
}

# compile clang with clang from stage0, and libc++, libc++abi and libunwind
# from stage1
stage2() {
    mkdir -p $src/stage2
    cd $src/stage2
    cmake .. -GNinja \
        -DCMAKE_C_COMPILER=$prefix/stage0/bin/clang \
        -DCMAKE_CXX_COMPILER=$prefix/stage0/bin/clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DLLVM_BINUTILS_INCDIR=/usr/include \
        -DLLVM_BUILD_DOCS=NO \
        -DLLVM_BUILD_EXAMPLES=NO \
        -DLLVM_BUILD_RUNTIME:BOOL=OFF \
        -DLLVM_BUILD_TESTS=NO \
        -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_ENABLE_ASSERTIONS=NO \
        -DLLVM_ENABLE_CXX1Y=YES \
        -DLLVM_ENABLE_FFI=NO \
        -DLLVM_ENABLE_LIBCXX=YES \
        -DLLVM_ENABLE_LIBCXXABI=YES \
        -DLLVM_ENABLE_PIC=YES \
        -DLLVM_ENABLE_RTTI=YES \
        -DLLVM_ENABLE_SPHINX=NO \
        -DLLVM_ENABLE_TERMINFO=YES \
        -DLLVM_ENABLE_ZLIB=YES \
        -DLLVM_HOST_TRIPLE=x86_64-alpine-linux-musl \
        -DLLVM_INCLUDE_EXAMPLES=NO \
        \
        -DCLANG_DEFAULT_CXX_STDLIB=libc++
    ninja clang -j $cpu
    ninja bin/clang-format -j $cpu
    ninja install-clang
    cmake -P tools/clang/lib/Headers/cmake_install.cmake
}


if [[ "$1" == "stage0" ]]; then
stage0
fi
if [[ "$1" == "stage1" ]]; then
stage1
fi
if [[ "$1" == "stage2" ]]; then
stage2
fi
