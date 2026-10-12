# Final build verification

Date: 12 October 2026. SoundBunker **1.1.5 (7)** includes the reorganized Now Playing dock, persistent Lyrics/Favorite/Queue controls, song options beside metadata, Shuffle/Repeat in Playing Next, larger hit targets and bounded visual micro-interactions.

- Release iphoneos: **BUILD SUCCEEDED**, arm64, IOS, minimum 15.0, SDK 27.0.
- Native Catalyst suite: **16 tests, zero failures**, after the UI/motion changes. Final artwork-render refinement: one test, zero failures.
- Packaging/release tests: **eight tests, zero failures**, rerun before this build.
- Repository/device-package validation: PASS. Version/build/release notes match finalized manifest/changelog; bundle identity remains `com.local.offlinemusicplayer`.
- IPA/ZIP integrity: PASS. ZIP contains exactly the byte-identical `SoundBunker-unsigned-1.1.5.ipa`.
- Icon bundled; test media and XCTest resources absent.
- Native 320×548 player layouts and playing/paused states reviewed. Reduce Motion artwork images match in both states. See [visual QA](../../../design/native-ui-qa.md).
- No signing/provisioning or device installation performed. Physical iPod fluidity, touch interaction, codec and background behavior remain device QA items. Static analysis was not repeated for this release.

## Checksums

- `SoundBunker-unsigned-1.1.5.ipa`: `c19037ac3ebe6eac598b189ff17eab620eca060c5f6c56ffdfb39b15cef69b07`
- `SoundBunker-unsigned-1.1.5.ipa.zip`: `6f1d1f2e2603734642e4d930c8773d9635eb2ec1cc9e68e7375bb8f402613259`
