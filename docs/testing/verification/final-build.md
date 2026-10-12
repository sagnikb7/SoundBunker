# Final build verification

Date: 12 October 2026. SoundBunker **1.1.2 (4)** includes the modern opaque icon, organized Settings, playback-position preference, version/What's New screens, compact rows/navigation and reduced repeated library/lyrics work, alongside the previous player/playlist polish. Audit fixes recheck folder policy and reject symbolic links/path escapes before playback.

- Native Catalyst XCTest: **16 tests, 0 failures; TEST SUCCEEDED**.
- Python release workflow: **6 tests, 0 failures**.
- Xcode device static analysis: **ANALYZE SUCCEEDED**, no analyzer findings reported.
- Release iphoneos build: **BUILD SUCCEEDED**; arm64, IOS, minimum 15.0, SDK 27.0.
- Bundle identifier `com.local.offlinemusicplayer` retained; database paths/schema unchanged.
- Installed version/build and bundled release notes match manifest; changelog finalized and source fingerprint matches.
- Modern icon bundled. TestTone and XCTest bundles absent.
- IPA/ZIP integrity: PASS; outer ZIP contains exactly the byte-identical IPA.
- Native 320×548 renders reviewed: [Now Playing](player-compact.png), [Settings](settings-compact.png).
- Regression tests cover cached tiny artwork, reversible playlist selection, playback preferences, unchanged scan publication and user organization retained after cache clearing.
- Signing/provisioning not included. Physical iPod keyboard layout, provider access, A10 frame rate/memory/battery and real codec behavior remain pending.

## Checksums

- `SoundBunker-unsigned.ipa`: `3a32ad47b3f58a364e875da9f14e3412eeaba7a9640695d6e833fc3faeffbd2e`
- `SoundBunker-unsigned.ipa.zip`: `c03abce386e749939ed9cf24f38d1c3e2991ceb2e9a48a3f157fd3705494e131`
