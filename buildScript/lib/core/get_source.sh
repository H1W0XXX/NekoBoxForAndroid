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
TLS_DIRECT_PATCH="$ROOT_DIR/buildScript/lib/core/patches/ss-tls-direct.patch"
if git apply --reverse --check "$TLS_DIRECT_PATCH" >/dev/null 2>&1; then
  echo "ss tls direct patch already applied"
else
  git apply "$TLS_DIRECT_PATCH"
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
