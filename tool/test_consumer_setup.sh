#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/packages/leak_sniffer"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$TMP_DIR/pubspec.yaml" <<EOF
name: leak_sniffer_consumer_smoke
publish_to: "none"

environment:
  sdk: ^3.11.3

dev_dependencies:
  leak_sniffer:
    path: $PACKAGE_DIR
EOF

mkdir -p "$TMP_DIR/lib"
cat >"$TMP_DIR/lib/poller.dart" <<'EOF'
import 'dart:async';

class Poller {
  final Timer _timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) {},
  );
}
EOF

(
  cd "$TMP_DIR"
  dart pub get >/dev/null

  local_output="$(dart run leak_sniffer --check 2>&1 || true)"
  printf '%s\n' "$local_output"

  if [[ ! -f "$TMP_DIR/analysis_options.yaml" ]]; then
    echo
    echo "Expected leak_sniffer to create analysis_options.yaml automatically."
    exit 1
  fi

  if ! rg -n "^  custom_lint: \\^0\\.8\\.1$" "$TMP_DIR/pubspec.yaml" >/dev/null; then
    echo
    echo "Expected leak_sniffer to add custom_lint as a direct dev dependency for IDE diagnostics."
    exit 1
  fi

  if ! rg -n "custom_lint" "$TMP_DIR/analysis_options.yaml" >/dev/null; then
    echo
    echo "Expected leak_sniffer to enable the custom_lint analyzer plugin in analysis_options.yaml."
    exit 1
  fi

  if [[ "$local_output" != *"Configured leak_sniffer successfully."* ]]; then
    echo
    echo "Expected leak_sniffer to configure the consumer project automatically."
    exit 1
  fi

  if [[ "$local_output" != *"avoid_uncancelled_timer"* ]]; then
    echo
    echo "Expected leak_sniffer to lint the consumer project through the configured custom_lint setup."
    exit 1
  fi
)
