# Final build verification

Date: 13 October 2026. **Cassette 1.4.0 (10)** exported successfully with `./build --platform=ipod`. Includes playback shadow/material polish, larger seek handle, hold seeking, live folder-rescan counts, persistent Recently Played/history, artwork double-tap and trailing Library/playlist counts.

## iPod export

- Release iphoneos **BUILD SUCCEEDED**; repository/package QA passed for **1.4.0 (10)**.
- App and embedded widget: arm64, IOS platform, minimum iOS 15.0; matching version/build and expected bundle identities/extension point.
- Release notes and project metadata match sources; app icon and widget assets present. No XCTest bundle/test media shipped.
- Both archive integrity checks passed. Every IPA member is byte-identical to the corresponding built app file; the outer ZIP contains exactly the byte-identical versioned IPA.
- Manifest/changelog finalized only after successful packaging and verification. No repeat build/version increment was consumed.
- Unsigned: signing/provisioning, including matching widget App Group entitlements, is required before installation.
- Build log: `/tmp/cassette-ipod-release-2026-10-13.log`.

## Verification context and limits

The expanded feature suite passed 41 native Release Catalyst tests and 18 Python workflow tests during implementation; final count-alignment native render and iPhoneOS compilation also passed. These earlier runs are documented in [Recently Played QA](../recently-played-qa.md) and [testing](../../testing.md). This build invocation ran compilation and repository/package validation, not another complete native test suite or static-analysis run. Physical iPod touch, rendering, signing, transfer and installation remain unverified.

The last Mac export remains **1.3.0 (9)**. No Mac export, upload, sync, push or installation was performed. Its prior receipt is preserved in [1.3.0 build verification](cassette-1.3.0-build.md).

## SHA-256

- `Cassette-unsigned-1.4.0.ipa`: `0c3ab30fd94445ae32e69c95ec0df99b4bf5fc44062f93a983697b084263ea28`
- `Cassette-unsigned-1.4.0.ipa.zip`: `da1631b147462d39e9716091300456983a3941c8c0462315d08a635ceb331bca`
