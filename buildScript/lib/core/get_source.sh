#!/bin/bash
set -e

source "buildScript/init/env.sh"
ENV_NB4A=1
source "buildScript/lib/core/get_source_env.sh"
ROOT_DIR="$(pwd)"
pushd ..

####

DEFAULT_SING_BOX_REPO="https://github.com/MatsuriDayo/sing-box.git"
SING_BOX_REPO="${SING_BOX_REPO:-$DEFAULT_SING_BOX_REPO}"
if [ ! -d "sing-box" ]; then
  git clone --no-checkout "$SING_BOX_REPO" sing-box
fi
pushd sing-box
git checkout "$COMMIT_SING_BOX"
if [ -z "${SING_BOX_APPLY_PATCH:-}" ]; then
  if [ "$SING_BOX_REPO" = "$DEFAULT_SING_BOX_REPO" ]; then
    SING_BOX_APPLY_PATCH=1
  else
    SING_BOX_APPLY_PATCH=0
  fi
fi
if [ "$SING_BOX_APPLY_PATCH" = "1" ]; then
  git restore --source "$COMMIT_SING_BOX" -- option/shadowsocks.go outbound/shadowsocks.go
  rm -f outbound/shadowsocks_tls_direct.go
  TLS_DIRECT_PATCH="$ROOT_DIR/buildScript/lib/core/patches/ss-tls-direct.patch"
  git apply --check "$TLS_DIRECT_PATCH" || exit 1
  git apply "$TLS_DIRECT_PATCH" || exit 1
fi
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
