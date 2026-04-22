#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/packages/leak_sniffer"
APP_DIR="$ROOT_DIR/apps/leak_sniffer_example"

"$ROOT_DIR/tool/bootstrap.sh"

echo
echo "Analyzing leak_sniffer package..."
(
  cd "$PACKAGE_DIR"
  dart analyze
)

echo
echo "Running leak_sniffer package tests..."
(
  cd "$PACKAGE_DIR"
  dart test
)

echo
echo "Analyzing example app..."
(
  cd "$APP_DIR"
  flutter analyze
)

echo
echo "Running example app widget tests..."
(
  cd "$APP_DIR"
  flutter test
)

echo
echo "Running custom_lint against the example app..."
(
  cd "$APP_DIR"
  dart run custom_lint
)
