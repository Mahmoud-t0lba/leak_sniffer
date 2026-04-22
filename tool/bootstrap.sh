#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/packages/leak_sniffer"
APP_DIR="$ROOT_DIR/apps/leak_sniffer_example"

echo "Bootstrapping leak_sniffer workspace..."

echo "Resolving package dependencies..."
(
  cd "$PACKAGE_DIR"
  dart pub get
)

echo "Resolving example app dependencies..."
(
  cd "$APP_DIR"
  flutter pub get
)

echo
echo "Workspace ready."
echo "Run ./tool/watch.sh to start custom_lint watch mode."
