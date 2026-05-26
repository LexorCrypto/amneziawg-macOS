# Apple Signing and Entitlements

The default local build is unsigned at the Xcode level and then ad-hoc signed so
the `.app` bundle can be inspected and packaged. That is enough for local build
verification, but it is not enough for a production Packet Tunnel Network
Extension.

## Local Developer Configuration

Create the local signing config:

```sh
cp Sources/WireGuardApp/Config/Developer.xcconfig.template \
  Sources/WireGuardApp/Config/Developer.xcconfig
```

Set:

```xcconfig
DEVELOPMENT_TEAM = ABCDE12345
APP_ID_IOS = com.example.amneziawg.ios
APP_ID_MACOS = com.example.amneziawg.macos
```

`Developer.xcconfig` is intentionally ignored by git because it contains local
team and bundle identifier choices.

## Bundle Identifiers

The macOS targets derive identifiers from `APP_ID_MACOS`:

```text
macOS app:          $(APP_ID_MACOS)
Network Extension: $(APP_ID_MACOS).network-extension
Login helper:      $(APP_ID_MACOS).login-item-helper
```

Use identifiers that are registered in the Apple Developer portal and have
matching provisioning profiles.

## App Group

The app and Network Extension share this App Group:

```text
$(DEVELOPMENT_TEAM).group.$(APP_ID_MACOS)
```

Register the App Group in the Apple Developer portal and enable it for both the
macOS app identifier and the Network Extension identifier.

## Required Capabilities

For the macOS app:

- App Sandbox
- App Groups
- Network Extensions with Packet Tunnel Provider
- User Selected File read/write access

For the macOS Network Extension:

- App Sandbox
- App Groups
- Network Extensions with Packet Tunnel Provider
- Network client access
- Network server access

The checked-in entitlement files are:

```text
Sources/WireGuardApp/UI/macOS/WireGuard.entitlements
Sources/WireGuardNetworkExtension/WireGuardNetworkExtension_macOS.entitlements
```

## Signed Build Commands

Build a signed app:

```sh
scripts/build-macos.sh --signed
```

Build a signed DMG:

```sh
scripts/build-macos-dmg.sh --signed
```

Allow Xcode to create or update provisioning profiles:

```sh
ALLOW_PROVISIONING_UPDATES=1 scripts/build-macos.sh --signed
```

You can also override values from the environment:

```sh
DEVELOPMENT_TEAM=ABCDE12345 \
APP_ID_MACOS=com.example.amneziawg.macos \
ALLOW_PROVISIONING_UPDATES=1 \
scripts/build-macos.sh --signed
```

## Verification

The build scripts run:

```sh
codesign --verify --deep --strict --verbose=2 <WireGuard.app>
```

For release work, also inspect the final entitlements:

```sh
codesign -d --entitlements :- <WireGuard.app>
codesign -d --entitlements :- <WireGuard.app>/Contents/PlugIns/WireGuardNetworkExtension.appex
```

The Network Extension will only work as intended when the app, extension,
profiles, team, App Group, and Packet Tunnel entitlement all match.
