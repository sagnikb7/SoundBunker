# Final build verification

Date: 13 October 2026. **Cassette 1.4.1 (11)** exported with `./build --platform=ipod` after the branding/documentation cleanup. Includes Cassette icon/widgets, player/folder improvements, persistent Recently Played/history, artwork double-tap and right-aligned list counts. README now uses the production Cassette logo, badges, screenshots and current release information; historical evidence is clearly separated.

## Release and pre-push gates

- Native Release Catalyst: **41 tests, 0 failures, TEST SUCCEEDED** (`/tmp/cassette-branding-native-tests.log`).
- Python workflow suite: **18 tests, 0 failures** (`/tmp/cassette-branding-workflow.log`).
- Release iPhoneOS build: **BUILD SUCCEEDED**; iPhoneOS static analysis: **ANALYZE SUCCEEDED** (`/tmp/cassette-branding-ipod-release.log`, `/tmp/cassette-branding-analysis.log`).
- Generated Xcode project is byte-identical after regeneration. README local image/link targets and production-logo parity passed. Repository/Markdown links and whitespace checks passed.
- App/widget: arm64, IOS platform, minimum iOS 15.0; matching **1.4.1 (11)** version/build, expected identities/extension point, app icon/widget assets and matching bundled notes/project metadata.
- IPA and ZIP integrity passed. Every IPA file is byte-identical to the built bundle; ZIP contains exactly the identical versioned IPA. Test media/XCTest bundles are absent.
- Release manifest/changelog finalized after successful packaging. Both outputs are unsigned; signing/provisioning and matching widget App Group entitlements are required before installation.

## Artifacts and limits

- `dist/Cassette-unsigned-1.4.1.ipa`
- `dist/Cassette-unsigned-1.4.1.ipa.zip`

Last Mac export remains **1.3.0 (9)**; no new Mac export was requested. Earlier receipts: [1.4.0 iPod export](archive/cassette-1.4.0-build.md), [1.3.0 platform exports](archive/cassette-1.3.0-build.md).

Native desktop tests, renders and successful compilation do not certify physical iPod interaction, installation, provider permissions, codecs, background playback or A10 performance. No package upload, sync, transfer or installation was performed. This receipt records local verification; GitHub-hosted CI is a separate run.

## SHA-256

- `Cassette-unsigned-1.4.1.ipa`: `391096ae081797d82af27d76b9ec81ebb4d2a05b996a0d58abd511e4d87aa13c`
- `Cassette-unsigned-1.4.1.ipa.zip`: `f98c04186c59f4a67ba639c02bc75362527d9bcc7eb2d46c0d3f4ba063f96308`
