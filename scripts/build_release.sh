#!/usr/bin/env bash
# Builds a release artifact with Dart symbol obfuscation enabled.
#
# `--obfuscate` has no static config-file equivalent in Flutter — it's a
# build-command flag — so it's easy to lose track of and ship an
# unobfuscated release by just running `flutter build ...` directly.
# Use this script instead so the flag can't be forgotten.
#
# Usage: scripts/build_release.sh apk|appbundle|ios dev|uat|prod
#
# The env argument is required (no default) — AppEnvironment.name silently
# falls back to 'dev' when --dart-define=APP_ENV isn't passed, so an omitted
# arg here would ship a "release" build wired to the dev API/Azure AD app
# instead of the intended one.

set -euo pipefail

target="${1:-apk}"
env="${2:-}"
symbols_dir="build/symbols/$(date +%Y%m%d%H%M%S)"

case "$env" in
  dev|uat|prod) ;;
  *)
    echo "Missing or unknown environment '$env' — expected dev, uat, or prod as the second argument." >&2
    echo "Usage: scripts/build_release.sh apk|appbundle|ios dev|uat|prod" >&2
    exit 1
    ;;
esac

mkdir -p "$symbols_dir"
dart_defines=(--dart-define-from-file=.env --dart-define="APP_ENV=$env")

case "$target" in
  apk)
    flutter build apk --release --obfuscate --split-debug-info="$symbols_dir" "${dart_defines[@]}"
    ;;
  appbundle)
    flutter build appbundle --release --obfuscate --split-debug-info="$symbols_dir" "${dart_defines[@]}"
    ;;
  ios)
    flutter build ios --release --obfuscate --split-debug-info="$symbols_dir" "${dart_defines[@]}"
    ;;
  *)
    echo "Unknown target '$target' — expected apk, appbundle, or ios." >&2
    exit 1
    ;;
esac

echo "Debug symbols for this build are in $symbols_dir — keep them (privately) to symbolicate future crash reports."
