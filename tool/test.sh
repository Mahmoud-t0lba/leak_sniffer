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
  lint_output="$(dart run leak_sniffer --check 2>&1 || true)"
  printf '%s\n' "$lint_output"

  if [[ "$lint_output" != *"avoid_unclosed_stream_controller"* ]]; then
    echo
    echo "Expected the example app to surface its intentional stream controller demo lint."
    exit 1
  fi

  if [[ "$lint_output" != *"lib/main.dart"* ]]; then
    echo
    echo "Expected the intentional example-app lint to point at lib/main.dart."
    exit 1
  fi

  if [[ "$lint_output" != *"1 issue found."* ]]; then
    echo
    echo "Expected exactly one intentional lint from the example app."
    exit 1
  fi
)

echo
echo "Verifying one-install consumer setup..."
"$ROOT_DIR/tool/test_consumer_setup.sh"
