# Final build verification

Date: 12 October 2026. **Cassette 1.3.0 (9)** was exported successfully using both platform commands. Includes the Cassette icon/name, square/horizontal iOS widgets, player/folder refinements and platform-specific build tooling.

## iPod export

- `./build --platform=ipod`: **BUILD SUCCEEDED** and repository/package QA passed.
- Release iphoneos arm64; minimum iOS 15.0. Widget extension is embedded with matching 1.3.0 (9), native arm64/iOS 15 and the expected extension point/identity.
- IPA and ZIP integrity passed; outer ZIP contains the byte-identical versioned IPA. Icon, notes and project link bundled; no test media/XCTest resources.
- Unsigned; signing/provisioning and matching widget App Group are required before installation.

## Mac export

- `./build --platform=mac`: **BUILD SUCCEEDED** and native bundle/signature/ZIP validation passed.
- Versioned .app plus .app.zip, universal arm64/x86_64, MACCATALYST, macOS 12 minimum. Copied bundle’s strict/deep signature verification passes; ad-hoc local signature, no public notarization.
- Both exports reuse **1.3.0 (9)**; finalized manifest records `platform_builds` for mac and ipod.
- ZIP contains byte-matching bundle files; native copying preserves executable permissions/links. A real extracted ZIP bundle also passed native platform/resource/signature validation. No iOS widget or test bundle/media in the Mac app.

## Regression evidence and limits

- Native Release Catalyst suite: **36 tests, zero failures**.
- Python command/release/packaging/project-metadata suite: **18 tests, zero failures**.
- App/iOS widget static analysis passed on this shipping source before packaging. Both platform builds/package checks passed afterward.
- Command tests cover invalid flags and build lock rejection; release tests cover cross-platform version reuse, retries and wrong-platform finalization. Mac archive tests cover native copying/extraction, executable bits/symlinks, filename rejection and preservation of earlier artifacts on packaging failure.
- Shell syntax, CI YAML, Markdown links and whitespace checks passed. Hosted CI has not been verified for these unpushed changes.
- Native renders and device limits: [widgets](../../../design/cassette-widgets.md), [player/folder QA](../player-folder-qa.md), [Mac parity](../../../build/mac-export.md).
- No physical iPod installation, transfer, group provisioning, device timeline behavior, Mac notarization or upload/push performed.

## SHA-256

- `Cassette-unsigned-1.3.0.ipa`: `c2321981e3e5406ccc31a550fe7d856e3ab4d7aaca5664c75a05278e4b07d55f`
- `Cassette-unsigned-1.3.0.ipa.zip`: `f4fc2ce439a697d14f00ef2e54e8cec90fcc11f84fe774ea0b129263cb2ea52d`
- `Cassette-1.3.0-mac.app.zip`: `756050e8c54e8ecd55bf34743f4e71dc1b61a3636794d178ffbc734fef3ecb97`
