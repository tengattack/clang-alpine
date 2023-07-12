#!/bin/sh
set -e

apt-get install -y --no-install-recommends build-essential git make cmake ninja-build python2

ln -s /usr/bin/python2 /usr/bin/python

cd /build

git clone https://github.com/oclint/oclint.git

cd oclint

git checkout v0.15

cd /build/llvm/src/stage0

ninja clangTooling

cp -r ../tools/clang/include/clang ../include
cp -r ../tools/clang/include/clang-c ../include
cp -r tools/clang/include/clang include

cd /build/oclint/oclint-scripts

./makeWithSystemLLVM /build/llvm/src/stage0

cd ../build/oclint-release

tar czf oclint-0.15.tar.gz bin lib
