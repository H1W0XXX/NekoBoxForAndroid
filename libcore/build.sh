#!/bin/bash

set -euo pipefail

source ./env_java.sh || true
source ../buildScript/init/env_ndk.sh

BUILD=".build"

rm -rf $BUILD/android \
  $BUILD/java \
  $BUILD/javac-output \
  $BUILD/src

if [ -z "$GOPATH" ]; then
  GOPATH=$(go env GOPATH)
fi

: "${LIBCORE_GOMOBILE_TARGET:=android}"

if [ "$LIBCORE_GOMOBILE_TARGET" = "android/arm64" ]; then
  : "${LIBCORE_GOARM64:=v9.2,crypto}"
  : "${LIBCORE_CGO_CFLAGS:=-O3 -march=armv9-a+crypto}"
  : "${LIBCORE_CGO_CXXFLAGS:=$LIBCORE_CGO_CFLAGS}"
fi

if [ -n "${LIBCORE_GOARM64:-}" ]; then
  export GOARM64="$LIBCORE_GOARM64"
fi

if [ -n "${LIBCORE_CGO_CFLAGS:-}" ]; then
  export CGO_CFLAGS="${CGO_CFLAGS:+$CGO_CFLAGS }$LIBCORE_CGO_CFLAGS"
fi

if [ -n "${LIBCORE_CGO_CXXFLAGS:-}" ]; then
  export CGO_CXXFLAGS="${CGO_CXXFLAGS:+$CGO_CXXFLAGS }$LIBCORE_CGO_CXXFLAGS"
fi

echo ">> gomobile target: $LIBCORE_GOMOBILE_TARGET"
echo ">> GOARM64: ${GOARM64:-default}"
echo ">> CGO_CFLAGS: ${CGO_CFLAGS:-default}"
echo ">> CGO_CXXFLAGS: ${CGO_CXXFLAGS:-default}"

export GOBIND=gobind-matsuri
"$GOPATH"/bin/gomobile-matsuri bind -v -target "$LIBCORE_GOMOBILE_TARGET" -androidapi 21 -cache "$(realpath $BUILD)" -trimpath -ldflags='-s -w' -tags='with_conntrack,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api' .
rm -r libcore-sources.jar

proj=../app/libs
mkdir -p $proj
cp -f libcore.aar $proj
echo ">> install $(realpath $proj)/libcore.aar"
