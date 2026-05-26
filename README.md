# AmneziaWG for macOS

This repository is a Lexor-maintained macOS-focused fork of
`amnezia-vpn/awg-apple`. The supported product target here is the macOS app and
its Network Extension packaging.

The upstream iOS targets and shared Apple code are still present because the
original project shares sources between iOS and macOS, but this fork is not
maintained as an iOS app distribution. Build, packaging, signing, and release
work in this repository should be treated as macOS-first unless explicitly
stated otherwise.

## Building

- Clone this repo:

```
$ git clone https://github.com/LexorCrypto/amneziawg-macOS.git awg-apple
$ cd awg-apple
```

- Rename and populate developer team ID file:

```
$ cp Sources/WireGuardApp/Config/Developer.xcconfig.template Sources/WireGuardApp/Config/Developer.xcconfig
$ vim Sources/WireGuardApp/Config/Developer.xcconfig
```

- Install SwiftLint and Go. For the Lexor macOS build wrapper below, use
  Homebrew Go 1.21:

```
$ brew install swiftlint go@1.21
```

### Lexor macOS local build

For local macOS builds of this AmneziaWG fork, use the reproducible build
wrapper:

```
$ scripts/build-macos.sh
```

The script builds from `/private/tmp/awg-apple-build/source` so the Go bridge
Makefile never sees spaces in the checkout path. It also uses Homebrew Go 1.21
from `/opt/homebrew/opt/go@1.21/bin`, stores Go caches under `/private/tmp`, and
skips the legacy SwiftLint phases by passing `SKIP_SWIFTLINT=1`.

By default this creates a local ad-hoc Debug build and writes a zip to
`build/macos-debug-<timestamp>/`. To attempt an Apple-signed build, populate
`Sources/WireGuardApp/Config/Developer.xcconfig` with a real `DEVELOPMENT_TEAM`
and bundle IDs/profiles that have Packet Tunnel Provider and App Groups enabled,
then run:

```
$ scripts/build-macos.sh --signed
```

To create a mountable DMG with the app and an Applications shortcut, run:

```
$ scripts/build-macos-dmg.sh
```

The DMG wrapper reuses the same temp-copy build path and signing mode as
`scripts/build-macos.sh`.

- Open project in Xcode:

```
$ open WireGuard.xcodeproj
```

- Flip switches, press buttons, and make whirling noises until Xcode builds it.

## WireGuardKit integration

The notes below are inherited from upstream and may mention iOS. For this fork,
macOS remains the supported application target.

1. Open your Xcode project and add the Swift package with the following URL:
   
   ```
   https://git.zx2c4.com/wireguard-apple
   ```
   
2. `WireGuardKit` links against `wireguard-go-bridge` library, but it cannot build it automatically
   due to Swift package manager limitations. So it needs a little help from a developer. 
   Please follow the instructions below to create a build target(s) for `wireguard-go-bridge`.
   
   - In Xcode, click File -> New -> Target. Switch to "Other" tab and choose "External Build 
     System".
   - Type in `WireGuardGoBridge<PLATFORM>` under the "Product name", replacing the `<PLATFORM>` 
     placeholder with the name of the platform. For example, when targeting macOS use `macOS`, or 
     when targeting iOS use `iOS`.
     Make sure the build tool is set to: `/usr/bin/make` (default).
   - In the appeared "Info" tab of a newly created target, type in the "Directory" path under 
     the "External Build Tool Configuration":
     
     ```
     ${BUILD_DIR%Build/*}SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo
     ```
     
   - Switch to "Build Settings" and find `SDKROOT`.
     Type in `macosx` if you target macOS, or type in `iphoneos` if you target iOS.
   
3. Go to Xcode project settings and locate your network extension target and switch to 
   "Build Phases" tab.
   
   - Locate "Dependencies" section and hit "+" to add `WireGuardGoBridge<PLATFORM>` replacing 
     the `<PLATFORM>` placeholder with the name of platform matching the network extension 
     deployment target (i.e macOS or iOS).
     
   - Locate the "Link with binary libraries" section and hit "+" to add `WireGuardKit`.
   
4. In Xcode project settings, locate your main bundle app and switch to "Build Phases" tab. 
   Locate the "Link with binary libraries" section and hit "+" to add `WireGuardKit`.
   
5. iOS only: Locate Bitcode settings under your application target, Build settings -> Enable Bitcode, 
   change the corresponding value to "No".
   
Note that if you ship your app for both iOS and macOS, make sure to repeat the steps 2-4 twice, 
once per platform.

## MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
