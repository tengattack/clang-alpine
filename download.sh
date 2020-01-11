#!/bin/sh
set -ex

version=release_90
prefix=/build/llvm
src=$prefix/src

install_tools() {
    apk --no-cache add build-base git cmake ninja python2 linux-headers
}

download() {
    mkdir -p $src

    url=https://github.com/llvm-mirror
    git clone --depth 1 --branch $version --single-branch $url/llvm.git $src

    #( cd $src/tools && git clone --depth 1 --branch $version $url/clang.git )
    ( cd $src/tools && git clone --depth 1 --branch ${version}_objc https://github.com/tengattack/clang.git )
    ( cd $src/projects && git clone --depth 1 --branch $version $url/compiler-rt )
    ( cd $src/projects && git clone --depth 1 --branch $version $url/libcxx )
    ( cd $src/projects && git clone --depth 1 --branch $version $url/libcxxabi )
    ( cd $src/projects && git clone --depth 1 --branch $version $url/libunwind )
}

install_tools
download
