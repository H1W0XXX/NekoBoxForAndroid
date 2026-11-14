#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
GO_ROOT=$(cd "$ROOT_DIR/.." && pwd)
LIBCORE_DIR="$ROOT_DIR/libcore"
SING_BOX_DIR="$GO_ROOT/sing-box"
LIBNEKO_DIR="$GO_ROOT/libneko"
ENV_FILE="$ROOT_DIR/buildScript/lib/core/get_source_env.sh"

if [ ! -f "$ENV_FILE" ]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

ensure_repo() {
  local dir="$1"
  local repo="$2"
  local ref="$3"

  if [ ! -d "$dir/.git" ]; then
    echo ">> cloning $repo -> $dir"
    git clone "$repo" "$dir"
  fi

  echo ">> preparing $(basename "$dir") @ $ref"
  git -C "$dir" fetch --all --tags --prune
  git -C "$dir" checkout "$ref"
}

ensure_repo "$SING_BOX_DIR" "${SING_BOX_REPO:-https://github.com/MatsuriDayo/sing-box.git}" "$COMMIT_SING_BOX"
ensure_repo "$LIBNEKO_DIR" "https://github.com/MatsuriDayo/libneko.git" "$COMMIT_LIBNEKO"

cd "$LIBCORE_DIR"

echo ">> go version"
go version

echo ">> go env GOMOD GOPATH"
go env GOMOD GOPATH

echo ">> go list ./..."
go list ./...

echo ">> go build ./..."
go build ./...

echo ">> local Go-only libcore diagnostics completed"
