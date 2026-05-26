#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/build-macos-dmg.sh [options]

Build the macOS app with scripts/build-macos.sh, then package it into a DMG
with a /Applications symlink.

Options:
  --configuration NAME   Xcode configuration to build (default: Debug)
  --signed               Use normal Apple code signing from Developer.xcconfig
  --unsigned             Disable Apple signing and apply local ad-hoc signing (default)
  --run-swiftlint        Run SwiftLint build phases
  --skip-swiftlint       Skip SwiftLint build phases (default)
  --no-clean             Reuse the temp source copy and DerivedData
  --skip-build           Package the existing temp app without running xcodebuild
  --volume-name NAME     DMG volume name (default: AmneziaWG macOS)
  -h, --help             Show this help

Environment overrides:
  AWG_BUILD_TMP_ROOT     Temp build root (default: /private/tmp/awg-apple-build)
  AWG_BUILD_OUTPUT_ROOT  Output root for artifacts (default: <repo>/build)
  AWG_BUILD_STAMP        Artifact timestamp override
  AWG_DMG_VOLUME_NAME    DMG volume name override
USAGE
}

die() {
    echo "error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

configuration="${CONFIGURATION:-Debug}"
signing_mode="unsigned"
skip_build=0
volume_name="${AWG_DMG_VOLUME_NAME:-AmneziaWG macOS}"
build_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --configuration)
            [[ $# -ge 2 ]] || die "--configuration requires a value"
            configuration="$2"
            build_args+=("--configuration" "$2")
            shift 2
            ;;
        --signed)
            signing_mode="signed"
            build_args+=("--signed")
            shift
            ;;
        --unsigned)
            signing_mode="unsigned"
            build_args+=("--unsigned")
            shift
            ;;
        --run-swiftlint|--skip-swiftlint|--no-clean)
            build_args+=("$1")
            shift
            ;;
        --skip-build)
            skip_build=1
            shift
            ;;
        --volume-name)
            [[ $# -ge 2 ]] || die "--volume-name requires a value"
            volume_name="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(cd "$script_dir/.." && pwd -P)"
tmp_root="${AWG_BUILD_TMP_ROOT:-/private/tmp/awg-apple-build}"
derived_data="$tmp_root/DerivedData"
output_root="${AWG_BUILD_OUTPUT_ROOT:-$project_root/build}"
staging_dir="$tmp_root/dmg-staging"
build_script="$script_dir/build-macos.sh"

require_command hdiutil
require_command ditto
require_command codesign

if [[ "$skip_build" -eq 0 ]]; then
    if ((${#build_args[@]})); then
        "$build_script" --no-archive "${build_args[@]}"
    else
        "$build_script" --no-archive
    fi
fi

app_path="$derived_data/Build/Products/$configuration/WireGuard.app"
[[ -d "$app_path" ]] || die "expected app not found: $app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"

stamp="${AWG_BUILD_STAMP:-$(date +%Y%m%d-%H%M)}"
configuration_slug="$(printf '%s' "$configuration" | tr '[:upper:]' '[:lower:]')"
signing_slug="$signing_mode"
[[ "$signing_mode" == "unsigned" ]] && signing_slug="ad-hoc"
output_dir="$output_root/macos-$configuration_slug-$stamp"
dmg_path="$output_dir/WireGuard-macos-$configuration_slug-$signing_slug-$stamp.dmg"

rm -rf "$staging_dir"
mkdir -p "$staging_dir" "$output_dir"
ditto "$app_path" "$staging_dir/WireGuard.app"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
    -volname "$volume_name" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDZO \
    "$dmg_path"

hdiutil verify "$dmg_path"

echo "DMG: $dmg_path"
echo "App: $app_path"
