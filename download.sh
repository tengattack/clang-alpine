#!/bin/sh
set -ex

version=release_90
prefix=/build/llvm
src=$prefix/src

install_tools() {
    apt-get install -y --no-install-recommends build-essential git cmake ninja-build python2 linux-headers-amd64
}

hp() {
    http_proxy=$proxy https_proxy=$proxy no_proxy=localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,224.0.0.0/4,240.0.0.0/4,hub.maoer.co $@;
}

download() {
    mkdir -p $src

    url=https://github.com/llvm-mirror
    hp git clone --depth 1 --branch $version --single-branch $url/llvm.git $src

    #( cd $src/tools && git clone --depth 1 --branch $version $url/clang.git )
    ( cd $src/tools && hp git clone --depth 1 --branch ${version}_objc https://github.com/tengattack/clang.git )
    ( cd $src/projects && hp git clone --depth 1 --branch $version $url/compiler-rt )
    ( cd $src/projects && hp git clone --depth 1 --branch $version $url/libcxx )
    ( cd $src/projects && hp git clone --depth 1 --branch $version $url/libcxxabi )
    ( cd $src/projects && hp git clone --depth 1 --branch $version $url/libunwind )
}

install_tools
download
