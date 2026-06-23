#!/usr/bin/env bash
# Package each Lambda handler with shared/ utilities and pip dependencies.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
HANDLERS_DIR="$ROOT/handlers"
SHARED_DIR="$ROOT/shared"
REQ="$SHARED_DIR/requirements.txt"

rm -rf "$DIST"
mkdir -p "$DIST"

for handler_file in "$HANDLERS_DIR"/*.py; do
  name="$(basename "$handler_file" .py)"
  if [[ "$name" == __* ]]; then
    continue
  fi

  build_dir="$(mktemp -d)"
  mkdir -p "$build_dir/handlers" "$build_dir/shared"

  cp "$handler_file" "$build_dir/handlers/${name}.py"
  cp "$SHARED_DIR"/*.py "$build_dir/shared/"

  python3 -m pip install -r "$REQ" -t "$build_dir" --quiet --upgrade --disable-pip-version-check

  (cd "$build_dir" && zip -qr "$DIST/${name}.zip" .)
  rm -rf "$build_dir"

  echo "Packaged $name -> dist/${name}.zip"
done
