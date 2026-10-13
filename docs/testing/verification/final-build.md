# Final build verification

13 October 2026: **Cassette 1.5.3 (15)** exported with `./build --platform=ipod`. Includes persistent directory checkpoints for cached-first startup and the latest user-supplied Retro Rainbow Cassette Icon.

## Executed checks

- Native Release Catalyst: **53 tests, zero failures**, including 500-song disk-backed restart with zero audio scans, nested additions, deferred playback/background discovery, explicit cancellation, retained checkpoints, manual lyric edits and provider refresh. See [scan evidence](incremental-scan-qa.md).
- Release tooling: **18 tests, zero failures**.
- Supplied retro PNG preserved byte-for-byte. App/README icons are identical opaque 1024px assets; app/widget marks are identical opaque 64px assets. Current square/medium widget captures inspected with the new logo.
- Release iPhoneOS build and repository/package QA passed. App and widget are arm64, IOS, minimum iOS 15.0, matching 1.5.3 (15); expected identities, embedded resources and no test media/XCTest bundles.
- Both IPA and ZIP pass archive checks. All IPA payload bytes match the built app. Outer ZIP contains the identical IPA.
- Source release notes staged before compilation and finalized after packaging. README, architecture, product decisions, media discovery policy and test documents reflect the new triggers.

## Artifacts and limits

`dist/Cassette-unsigned-1.5.3.ipa` and `dist/Cassette-unsigned-1.5.3.ipa.zip` are unsigned. Signing/provisioning, including matching widget App Groups, is required before installation. No upload, transfer or installation occurred. Last Mac export remains 1.3.0 (9); the shared source is updated for the next Mac build.

Initial upgrade requires one successful owned-source scan to establish checkpoints. Afterwards unchanged launches check known directory metadata without enumerating songs. Providers, in-place tag/lyric edits and Files/Finder changes during the same session require explicit rescan. Physical iPod/A10 performance, the reported lock-screen termination and black-widget behavior remain unverified. Desktop tests are not device certification. The [1.5.2 installed Settings discrepancy](release-1.5.2-audit.md) also remains an open device report.

Logs outside Git: `/tmp/cassette-incremental-scan-tests.log`, `/tmp/cassette-incremental-workflow-tests.log`, `/tmp/cassette-incremental-ipod-build.log`. Prior receipt: [1.5.2](archive/cassette-1.5.2-build.md).

## SHA-256

- IPA: `607e400f0eb385bab2ac218ee45add52dd1cdeece85dcc93f308db4e271c0d03`
- ZIP: `7302742bec85867c8c6a72559e41d0c121ea53c19945d9350aba9417844f2982`
