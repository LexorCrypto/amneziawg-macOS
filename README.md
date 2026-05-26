# AmneziaWG for macOS

This repository is a Lexor-maintained macOS-focused fork of
[`amnezia-vpn/awg-apple`](https://github.com/amnezia-vpn/awg-apple).

The supported product target in this fork is the macOS app with its Packet
Tunnel Network Extension. The upstream iOS targets and shared Apple sources are
still present because the original project shares code between platforms, but
this repository is not maintained as an iOS distribution.

## Current Status

- macOS app version: `1.0.15 (26)`
- Go backend: `github.com/amnezia-vpn/amneziawg-go v0.2.18`
- Required Go toolchain: Go `1.24` or newer
- Local packaging: reproducible ad-hoc `Debug` app archives and DMG packages
- Production readiness: Apple Developer signing, provisioning profiles, and
  Network Extension entitlements must be configured before shipping or using the
  Packet Tunnel extension as a production-signed build

AmneziaWG 2.0 parameters are supported by the macOS parser, exporter, and
Network Extension UAPI generator:

`Jc`, `Jmin`, `Jmax`, `S1`-`S4`, `H1`-`H4`, `I1`-`I5`.

## Quick Start

Install Xcode command line tools, SwiftLint, and Go:

```sh
brew install swiftlint go
```

Build a local unsigned/ad-hoc macOS app:

```sh
scripts/build-macos.sh
```

Create a DMG package:

```sh
scripts/build-macos-dmg.sh
```

Build artifacts are written to:

```text
build/macos-<configuration>-<timestamp>/
```

The build wrappers copy the source tree to `/private/tmp/awg-apple-build/source`
before running Xcode. This avoids the Go bridge Makefile issues caused by
checkout paths that contain spaces, such as `VS code`.

## Documentation

- [macOS build guide](docs/macos-build.md)
- [Apple signing and entitlements](docs/macos-signing.md)
- [AmneziaWG 2.0 integration notes](docs/amneziawg-2.md)

## Manual Xcode Build

For signed Xcode builds, create a local developer configuration:

```sh
cp Sources/WireGuardApp/Config/Developer.xcconfig.template \
  Sources/WireGuardApp/Config/Developer.xcconfig
```

Then set your Apple Developer Team ID and bundle identifiers in
`Sources/WireGuardApp/Config/Developer.xcconfig`.

Open the project:

```sh
open WireGuard.xcodeproj
```

The reproducible scripts are preferred for local macOS work because they set the
Go caches, temp source copy, SwiftLint behavior, and signing mode consistently.

## WireGuardKit Integration

The upstream WireGuardKit integration notes remain relevant for consumers who
embed `WireGuardKit` separately. They may mention iOS because they come from the
original Apple project. For this fork, macOS remains the maintained application
target.

1. Add the Swift package:

   ```text
   https://git.zx2c4.com/wireguard-apple
   ```

2. `WireGuardKit` links against the `wireguard-go-bridge` library, but Swift
   Package Manager cannot build it automatically. Create an External Build
   System target named `WireGuardGoBridge<PLATFORM>`, using `/usr/bin/make` as
   the build tool.

3. Point the External Build System directory to:

   ```text
   ${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo
   ```

4. Set `SDKROOT` to `macosx` for macOS consumers.

5. Add `WireGuardGoBridge<PLATFORM>` as a dependency of the Network Extension
   target and link `WireGuardKit` into both the extension and host app.

## License

This project keeps the upstream MIT license. See [COPYING](COPYING).
