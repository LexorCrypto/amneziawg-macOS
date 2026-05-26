# AmneziaWG 2.0 Integration Notes

This fork tracks the AmneziaWG 2.0 Go backend for the macOS app and Network
Extension path.

## Backend Module

The Go bridge is declared in:

```text
Sources/WireGuardKitGo/go.mod
```

Current backend:

```text
github.com/amnezia-vpn/amneziawg-go v0.2.18
go 1.24.4
```

The Apple bridge imports the backend through:

```text
Sources/WireGuardKitGo/api-apple.go
```

The Makefile extracts the AmneziaWG backend version and writes it into the
bridge build metadata:

```text
Sources/WireGuardKitGo/Makefile
```

## Supported Parameters

The macOS configuration path preserves these AmneziaWG parameters:

```text
Jc, Jmin, Jmax
S1, S2, S3, S4
H1, H2, H3, H4
I1, I2, I3, I4, I5
```

`S1`-`S4` and `I1`-`I5` are treated as integer values. `H1`-`H4` are stored as
strings so the app can preserve range-style values used by AmneziaWG configs.

## Swift Configuration Path

The main AmneziaWG fields flow through:

```text
Sources/WireGuardKit/InterfaceConfiguration.swift
Sources/Shared/Model/TunnelConfiguration+WgQuickConfig.swift
Sources/WireGuardKit/PacketTunnelSettingsGenerator.swift
```

The responsibilities are:

- parse AmneziaWG interface keys from wg-quick text
- keep the values in the app tunnel model
- export the values back to wg-quick text
- send the values to the Network Extension through UAPI settings

## Parser Error Handling

Invalid custom AmneziaWG interface parameters are surfaced through the macOS app
error mapping in:

```text
Sources/WireGuardApp/UI/macOS/ParseError+WireGuardAppError.swift
```

## Validation Performed

The current repository state has been validated with:

- direct Go bridge build for macOS arm64
- full local `scripts/build-macos.sh --no-archive --no-clean`
- ad-hoc code signature verification
- `scripts/build-macos-dmg.sh --skip-build`
- DMG verification through `hdiutil verify`

Unsigned/ad-hoc validation proves the local build and packaging path. A
production Network Extension still requires Apple Developer signing and matching
profiles, as described in [Apple signing and entitlements](macos-signing.md).
