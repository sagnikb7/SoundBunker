# Final build verification

Date: 12 October 2026. SoundBunker **1.1.4 (6)** includes the restored Settings layout; local and CI packaging now append the release version to both IPA and ZIP filenames.

- Release iphoneos: **BUILD SUCCEEDED**, arm64, IOS, minimum 15.0, SDK 27.0.
- Packaging/release tests: **eight tests, zero failures**, including rejection of filenames with the wrong version and byte-identical IPA content inside the versioned ZIP.
- Read-only repository and built-package validation: PASS. Bundle identity stays `com.local.offlinemusicplayer`; version/build/notes match finalized manifest/changelog.
- Icon bundled; no test media or XCTest resources included.
- IPA and outer ZIP integrity: PASS; the ZIP contains exactly `SoundBunker-unsigned-1.1.4.ipa`.
- Workflow YAML parsed and shell syntax checked. Updated CI configuration has not been pushed or run on GitHub.
- App Swift code is unchanged from the tested Settings rollback: 16 native regression tests plus the final compact-label render test passed previously. Native tests/static analysis were not repeated for filename-only workflow changes.
- Signing/provisioning and physical iPod QA remain pending.

## Checksums

- `SoundBunker-unsigned-1.1.4.ipa`: `4e721e6170eb961f27a1b29894448f912cbac7eea2518ae35dfda5e99bd38b73`
- `SoundBunker-unsigned-1.1.4.ipa.zip`: `9dc58e5f0a435408c3464994213fdf5061efc32f4b42ea730d4a41fa38247187`
