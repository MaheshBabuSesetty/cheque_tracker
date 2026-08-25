#!/usr/bin/env bash
# Builds a release artifact with Dart symbol obfuscation enabled.
#
# `--obfuscate` has no static config-file equivalent in Flutter — it's a
# build-command flag — so it's easy to lose track of and ship an
# unobfuscated release by just running `flutter build ...` directly.
# Use this script instead so the flag can't be forgotten.
#
# Usage: scripts/build_release.sh apk|appbundle|ios

set -euo pipefail

target="${1:-apk}"
symbols_dir="build/symbols/$(date +%Y%m%d%H%M%S)"
mkdir -p "$symbols_dir"

case "$target" in
  apk)
    flutter build apk --release --obfuscate --split-debug-info="$symbols_dir"
    ;;
  appbundle)
    flutter build appbundle --release --obfuscate --split-debug-info="$symbols_dir"
    ;;
  ios)
    flutter build ios --release --obfuscate --split-debug-info="$symbols_dir"
    ;;
  *)
    echo "Unknown target '$target' — expected apk, appbundle, or ios." >&2
    exit 1
    ;;
esac

echo "Debug symbols for this build are in $symbols_dir — keep them (privately) to symbolicate future crash reports."
