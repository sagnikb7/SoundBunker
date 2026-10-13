# Final build verification

13 October 2026: current local iPod and Mac exports are **1.5.3 (18)**, verified before pushing the no-ZIP packaging change. Application source fingerprint is unchanged. Output names are `dist/Cassette-unsigned-1.5.3.ipa` and `dist/Cassette.app`.

- 18 release/workflow tests and 53 native Release Catalyst tests passed. Native log: `/tmp/cassette-packaging-prepush-tests.log`.
- Both platform repository/package validators passed, including Mac signature/universal architectures and iPod embedded widget/platform/version/resources.
- Fresh packaging of the real iPod build in a temporary directory generated only the IPA; all payload file bytes matched the built app.
- Shell syntax and diff whitespace checks passed. Review found no blocking packaging issue.
- Documentation and CI now use the no-ZIP policy. CI validates Mac without uploading its bundle; GitHub artifact downloads still have GitHub's own transport wrapper.

These are local checks, not a claim of hosted CI success or physical iPod verification. Historical build 16 hashes below refer only to the prior exports.

# Build 16 historical verification

13 October 2026: **Cassette 1.5.3 (16)** exported sequentially with `./build --platform=ipod` and `./build --platform=mac`. Includes persistent directory checkpoints for cached-first startup and the latest user-supplied Retro Rainbow Cassette Icon.

## Executed checks

- Native Release Catalyst: **53 tests, zero failures**, including 500-song disk-backed restart with zero audio scans, nested additions, deferred playback/background discovery, explicit cancellation, retained checkpoints, manual lyric edits and provider refresh. See [scan evidence](incremental-scan-qa.md).
- Release tooling: **18 tests, zero failures**.
- Supplied retro PNG preserved byte-for-byte. App/README icons are identical opaque 1024px assets; app/widget marks are identical opaque 64px assets. Current square/medium widget captures inspected with the new logo.
- Release iPhoneOS build and repository/package QA passed. App and widget are arm64, IOS, minimum iOS 15.0, matching 1.5.3 (16); expected identities, embedded resources and no test media/XCTest bundles.
- Both IPA and ZIP pass archive checks. All IPA payload bytes match the built app. Outer ZIP contains the identical IPA.
- Source release notes staged before compilation and finalized after packaging. README, architecture, product decisions, media discovery policy and test documents reflect the new triggers.

## Artifacts and limits

`dist/Cassette-unsigned-1.5.3.ipa` and `dist/Cassette-unsigned-1.5.3.ipa.zip` are unsigned. Signing/provisioning, including matching widget App Groups, is required before installation. No upload, transfer or installation occurred. Mac export is `dist/Cassette-1.5.3-mac.app` and `.app.zip`, matching 1.5.3 (16). Universal arm64/x86_64 Catalyst, macOS 12+, strict/deep ad-hoc signature, resource parity and ZIP validation passed. Desktop widgets are absent. This local signature is not notarized public distribution.

Initial upgrade requires one successful owned-source scan to establish checkpoints. Afterwards unchanged launches check known directory metadata without enumerating songs. Providers, in-place tag/lyric edits and Files/Finder changes during the same session require explicit rescan. Physical iPod/A10 performance, the reported lock-screen termination and black-widget behavior remain unverified. Desktop tests are not device certification. The [1.5.2 installed Settings discrepancy](release-1.5.2-audit.md) also remains an open device report.

Logs outside Git: `/tmp/cassette-incremental-scan-tests.log`, `/tmp/cassette-incremental-workflow-tests.log`, `/tmp/cassette-incremental-ipod-build.log`. Prior receipt: [1.5.2](archive/cassette-1.5.2-build.md).

## SHA-256

- IPA: `5b18fd54bd5f5ba6a0342d4e28df09d2f8ff36f943c2eb88e194ccad95a910d7`
- ZIP: `86a02d6a2ea328245683723d72cebb683d9c00a2d660b0f8ca9ff7fa1529c5b4`

- Mac ZIP: `1283fafbea6d473df6b8dd5aa195d241881f8095d3686fb28f2a4b221a2db129`

Rebuild logs: `/tmp/cassette-rebuild-ipod.log`, `/tmp/cassette-rebuild-mac.log`. Production source hash is unchanged from the tested build 15; repeated iPod export advanced the build number once, and Mac reused build 16.
