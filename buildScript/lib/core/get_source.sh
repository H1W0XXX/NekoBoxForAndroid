#!/bin/bash
set -e

source "buildScript/init/env.sh"
ENV_NB4A=1
source "buildScript/lib/core/get_source_env.sh"
ROOT_DIR="$(pwd)"
pushd ..

####

if [ ! -d "sing-box" ]; then
  git clone --no-checkout https://github.com/MatsuriDayo/sing-box.git
fi
pushd sing-box
git checkout "$COMMIT_SING_BOX"
git restore --source "$COMMIT_SING_BOX" -- option/shadowsocks.go protocol/shadowsocks/outbound.go
rm -f protocol/shadowsocks/tls_direct.go
TLS_DIRECT_PATCH="$ROOT_DIR/buildScript/lib/core/patches/ss-tls-direct.patch"
git apply --check "$TLS_DIRECT_PATCH" || exit 1
git apply "$TLS_DIRECT_PATCH" || exit 1
popd

####

if [ ! -d "libneko" ]; then
  git clone --no-checkout https://github.com/MatsuriDayo/libneko.git
fi
pushd libneko
git checkout "$COMMIT_LIBNEKO"
popd

####

popd
