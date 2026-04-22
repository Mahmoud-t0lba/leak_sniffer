#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/leak_sniffer_example"

if [[ ! -f "$APP_DIR/.dart_tool/package_config.json" ]]; then
  "$ROOT_DIR/tool/bootstrap.sh"
fi

cd "$APP_DIR"
dart run leak_sniffer --watch
