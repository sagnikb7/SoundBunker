# Final build verification

Date: 12 October 2026. SoundBunker **1.2.0 (8)** includes M3U/M3U8 playlists, selected provider-folder access, optional attributed artist photos, the project link, followed timed lyrics, player navigation/gestures and playback performance improvements.

- Release iphoneos: **BUILD SUCCEEDED**, arm64, minimum iOS 15.0.
- Native Catalyst suite: **27 tests, zero failures**; the pre-push Release-optimized run also passed all 27.
- Python packaging/release/project-link suite: **ten tests, zero failures**.
- Release device static analysis: **ANALYZE SUCCEEDED**, no analyzer findings.
- Repository/device-package validation: PASS. Sources, bundled version/build/resources and finalized manifest/changelog match. Bundle identity remains `com.local.offlinemusicplayer`.
- IPA/ZIP integrity: PASS. ZIP contains exactly the byte-identical `SoundBunker-unsigned-1.2.0.ipa`.
- Icon and metadata resources bundled; test media and XCTest resources absent.
- Native UI and regression evidence: [feature QA](../feature-expansion-qa.md), [visual QA](../../../design/native-ui-qa.md).
- No signing, provisioning, upload, push or device installation performed. Physical iPod interaction, provider permissions and performance remain device QA items.

## Checksums

- `SoundBunker-unsigned-1.2.0.ipa`: `4bd6e51ed0efe290bcf194a6b3bff6fa3509400cd7ab647a7771c6d960ec05f0`
- `SoundBunker-unsigned-1.2.0.ipa.zip`: `2092ce1cf23d9a734ae7fd14e68bad52b37bdf7a569aa06e913948febf3def68`
