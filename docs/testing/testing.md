# Testing and verification

## Environment

Recorded 12 October 2026: macOS 27.0.1, Xcode 27.0 (27A266a), Swift 6.4 in Swift 5 language mode, iOS SDK 27.0. No iOS simulator runtime is installed. The connected iPod touch 7 (`iPod9,1`) reports unsupported pairing in Xcode 27 and is not a Run destination. The shared native code is testable through Mac Catalyst on this host.

## Run automated tests

```sh
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath /tmp/PocketMusicCatalyst \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual test
```

Local ad-hoc signing permits Catalyst testing without an Apple development team. XCTest fixtures reside in `OfflineMusicPlayerTests/Fixtures` and are copied into the **test bundle only**. They are never application resources. `scripts/generate_fixture.py` reproduces the original, unrestricted low-volume PCM WAV.

Coverage:

- LRC offsets, multiple timestamps, malformed input and plain lyrics.
- Source exclusion boundary matching and decoding older source records with default restrictions.
- Recursive fixture indexing and filename/artist fallbacks.
- Favorites, playlist duplicate order, non-destructive exclusion and source/playlist removal.
- Same-file identities across overlapping roots, distinct copies and cancellation.
- Core Data record round trips, deletion and real SQLite reopening.
- Native WAV decode/playback advancement, pause, seek bounds and natural completion callback.
- Queue transitions, repeat-one, silent state restoration and unavailable-file recovery.
- Rejection of remote playback URLs.

Tests use temporary fixture folders and isolated databases/caches. Native WAV playback is executed on the Mac runtime; this is not an iPod codec certification. The initial runs caught metadata-reader and canonical-path errors, which were repaired before the final run. **Final native result: 16 tests executed, 0 failures, TEST SUCCEEDED.** Final receipts are in `verification/`.

## Device build and packaging

```sh
./scripts/create_build.sh
```

Outputs are an unsigned Release iphoneos IPA plus a ZIP containing it. Verify iPhoneOS/arm64, MinimumOSVersion 15.0, SoundBunker display name/icon, and no test tone/XCTest bundles. See [build artifacts](../build/build-artifacts.md).

Simulator compilation, if needed, does not execute tests:

```sh
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SoundBunkerSimulator CODE_SIGNING_ALLOWED=NO build-for-testing
```

Xcode 27 XCTest support targets newer iOS runtimes, so actual iOS 15 test execution needs a compatible Xcode/macOS/device setup. Do not treat later-runtime compilation as iOS 15 execution evidence.

## Native UI checks

The actual SoundBunker Catalyst app was opened. Verified the empty-library folder/import actions, Settings navigation, Music Folders/source detail, enabled/disabled scan switch, disabled Rescan control while a source is excluded, and restoration of enabled scanning. The app is branded SoundBunker and has no sample-playback button. See [native UI QA](../design/native-ui-qa.md).

Folder selection/provider access, populated 320-point iPod layouts, system background controls and device performance are not proven by these desktop checks. No claim of physical installation, lock-screen behavior or battery measurements is made.

## Physical iPod checklist — pending

- Install a properly signed build; confirm iOS version, app name/icon and first-launch silence.
- Add multiple actual local folders through Files → On My iPod; relaunch and verify persisted access.
- Copy audio into SoundBunker's Files folder; opening must discover it without a Music subfolder.
- Toggle source scanning and exclude/include nested folders; ensure no original files are removed.
- Rescan additions/removals, revoke/reconnect permissions and cancel a long scan.
- Check song rows, albums, artist/genre/folder details, search and editable playlists on 320-point width with VoiceOver/large text.
- Test real MP3/AAC/ALAC/WAV/AIFF and assess other formats by actual decoder playback.
- Seek and rapidly switch songs; exercise queue ends, shuffle/repeat, unavailable entries and relaunch without autoplay.
- Lock screen, Control Center, wired headphones and Bluetooth; check interruption/unplug behavior.
- Check embedded lyrics and adjacent LRC offsets, highlighted lines and tap-to-seek.
- Turn Wi-Fi off; verify fully offline playback and safe handling of cloud-only/provider entries.
- Observe large-library responsiveness, memory and battery on the A10 device.

## Remaining coverage

Actual revoked/stale provider bookmarks, third-party provider coordination, iOS lifecycle/UI journeys and large-library performance require further device tests. M3U import and per-codec metadata parsing are remaining implementation work, not tested features. Historical foundation receipts are archived under `verification/archive/`.

## Player-polish regression run

Passed **12 tests, 0 failures** on the native Catalyst target, plus an unsigned iphoneos Release build. New tests verify idempotent additions to multiple playlists and stored records, tiny artwork backgrounds and object reuse from the cache, and generate the compact native player render inspected in [verification/player-compact.png](verification/player-compact.png). The fixed dock keeps all three secondary controls visible in that render. Physical iPod software-keyboard placement and A10 performance are still pending.

## Playlist selection follow-up

12 tests passed after adding reversible membership selection and cached artwork rows. The playlist regression now exercises repeated add protection, toggle off/on, persisted removal, isolation between playlists and complete removal of legacy duplicates. Device visual confirmation of the new rows is pending.

## Settings, performance and versioning verification

The latest native suite runs 16 tests. Added coverage verifies playback-position preference without autoplay, repeat persistence with an empty queue, unchanged scans producing no track-array publications, and cache clearing preserving favorites/playlists. Native Settings and Now Playing are rendered at 320×548 for visual review; this is desktop UIKit evidence, not physical iPod interaction.

Five isolated Python release-workflow tests pass (`python3 -m unittest discover -s scripts/tests -v`). They cover semantic bumps, failed-build retries, notes required after shipping changes, mutations during build and a mismatched built version. Successful packaging writes the versioned Markdown changelog.

The modern app icon is an opaque 1024×1024 static asset. Sorting/ID lookup caches, batched index publication and once-per-song lyric parsing reduce repeated work. Actual A10 fluidity, memory and battery still require device measurements.

## Pre-push audit

The 1.1.2 audit run passes all 16 native tests and six Python release tests. New path-policy coverage checks traversal/absolute-path rejection and indexed files replaced by symlinks. Device static analysis succeeds without analyzer findings. See [repository audit](repository-audit.md) and [CI workflow](../build/continuous-integration.md).
