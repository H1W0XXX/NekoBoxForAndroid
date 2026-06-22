#!/bin/bash

chmod -R 777 .build 2>/dev/null
rm -rf .build 2>/dev/null

if [ -z "$GOPATH" ]; then
    GOPATH=$(go env GOPATH)
fi

# Install gomobile and gobind from the selected fork revision.
# Do not run `gomobile init` here because Matsuri's gomobile still forces
# `gobind@latest`, which upgrades beyond the pinned Go toolchain in CI.
if [ ! -f "$GOPATH/bin/gomobile-matsuri" ] || [ ! -f "$GOPATH/bin/gobind" ]; then
    rm -rf gomobile
    git clone https://github.com/MatsuriDayo/gomobile.git
    pushd gomobile
    git checkout "${GOMOBILE_REF:-origin/master}"
    pushd cmd
    pushd gomobile
    go install -v
    popd
    pushd gobind
    go install -v
    popd
    popd
    rm -rf gomobile
    cp -f "$GOPATH/bin/gomobile" "$GOPATH/bin/gomobile-matsuri"
    cp -f "$GOPATH/bin/gobind" "$GOPATH/bin/gobind-matsuri"
fi
