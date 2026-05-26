# macOS Build Guide

This fork is built and packaged as a macOS app with a Packet Tunnel Network
Extension. The maintained build path is the wrapper script in `scripts/`, not a
hand-patched temporary checkout.

## Prerequisites

- macOS with Xcode installed
- Xcode command line tools available to `xcodebuild`
- Go `1.24` or newer
- SwiftLint, unless you explicitly keep the default skipped lint phase

Install the common Homebrew dependencies:

```sh
brew install swiftlint go
```

The AmneziaWG 2.0 bridge currently uses `github.com/amnezia-vpn/amneziawg-go
v0.2.18` and the module declares `go 1.24.4`.

## Local App Build

Run:

```sh
scripts/build-macos.sh
```

By default the script:

- builds the `WireGuardmacOS` scheme in `Debug`
- targets `platform=macOS,arch=arm64`
- copies the repository to `/private/tmp/awg-apple-build/source`
- stores DerivedData under `/private/tmp/awg-apple-build/DerivedData`
- stores Go caches under `/private/tmp/awg-apple-build`
- skips legacy SwiftLint build phases with `SKIP_SWIFTLINT=1`
- disables Apple signing and applies a local ad-hoc signature
- creates a zip archive under `build/macos-debug-<timestamp>/`

The temp source copy is intentional. The Go bridge Makefile is sensitive to
source paths that contain spaces, and the common local path `VS code` breaks
that build if Xcode runs directly from the checkout.

## DMG Package

Run:

```sh
scripts/build-macos-dmg.sh
```

The DMG wrapper builds the app with `scripts/build-macos.sh --no-archive`, then
creates a mountable DMG containing:

- `WireGuard.app`
- an `/Applications` symlink

The output path is:

```text
build/macos-<configuration>-<timestamp>/WireGuard-macos-<configuration>-<signing>-<timestamp>.dmg
```

To package the existing app from the temp DerivedData without rebuilding:

```sh
scripts/build-macos-dmg.sh --skip-build
```

## Signed Builds

Unsigned/ad-hoc builds are only for local development. For a signed build:

```sh
scripts/build-macos.sh --signed
```

For a signed DMG:

```sh
scripts/build-macos-dmg.sh --signed
```

If you want Xcode to manage provisioning profiles during the build:

```sh
ALLOW_PROVISIONING_UPDATES=1 scripts/build-macos.sh --signed
```

See [Apple signing and entitlements](macos-signing.md) before relying on a
signed Network Extension build.

## Useful Options

`scripts/build-macos.sh` supports:

- `--configuration NAME`
- `--signed`
- `--unsigned`
- `--run-swiftlint`
- `--skip-swiftlint`
- `--no-archive`
- `--no-clean`

`scripts/build-macos-dmg.sh` supports:

- `--configuration NAME`
- `--signed`
- `--unsigned`
- `--run-swiftlint`
- `--skip-swiftlint`
- `--no-clean`
- `--skip-build`
- `--volume-name NAME`

## Environment Overrides

Common overrides:

```sh
AWG_GO_BIN_DIR=/opt/homebrew/bin
AWG_BUILD_TMP_ROOT=/private/tmp/awg-apple-build
AWG_BUILD_OUTPUT_ROOT="$PWD/build"
AWG_BUILD_STAMP=20260526-2011
```

Signed build overrides:

```sh
DEVELOPMENT_TEAM=ABCDE12345
APP_ID_MACOS=com.example.amneziawg.macos
APP_ID_IOS=com.example.amneziawg.ios
ALLOW_PROVISIONING_UPDATES=1
```

DMG-specific override:

```sh
AWG_DMG_VOLUME_NAME="AmneziaWG macOS"
```

## Troubleshooting

If the Go bridge fails with a path containing spaces, use the wrapper scripts.
They build from `/private/tmp/awg-apple-build/source`.

If Go is too old, install a newer toolchain and point the script at it:

```sh
AWG_GO_BIN_DIR=/opt/homebrew/bin scripts/build-macos.sh
```

If the bridge keeps using a stale copied Go root, run a clean build without
`--no-clean`. The Makefile also tracks the Go toolchain version and rebuilds its
cache when it changes.

If SwiftLint fails on legacy upstream violations, keep the default
`--skip-swiftlint`. Use `--run-swiftlint` only when you intentionally want to
clean lint debt.

If signing fails, first verify `Developer.xcconfig`, bundle identifiers,
profiles, and Network Extension capabilities. Unsigned builds cannot act as
production-signed Network Extension releases.
