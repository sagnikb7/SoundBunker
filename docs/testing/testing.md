# Testing and verification

## Environment

Recorded 12 October 2026: macOS 27.0.1, Xcode 27.0 (27A266a), Swift 6.4 in Swift 5 language mode, iOS SDK 27.0. No iOS simulator runtime is installed. The connected iPod touch 7 (`iPod9,1`) reports unsupported pairing in Xcode 27 and is not a Run destination. The shared native code is testable through Mac Catalyst on this host.

## Run automated tests

```sh
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -configuration Release -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath /tmp/CassetteCatalyst \
  ENABLE_TESTABILITY=YES ENABLE_HARDENED_RUNTIME=NO CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual test
```

Local ad-hoc signing permits Catalyst testing without an Apple development team. The Release test invocation enables testability and disables Catalyst hardened-runtime library validation so the ad-hoc XCTest bundle can load. These flags apply only to this desktop test invocation; device packaging uses its normal Release settings. XCTest fixtures reside in `OfflineMusicPlayerTests/Fixtures` and are copied into the **test bundle only**. They are never application resources. `scripts/generate_fixture.py` reproduces the original, unrestricted low-volume PCM WAV.

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

Tests use temporary fixture folders and isolated databases/caches. Native WAV playback is executed on the Mac runtime; this is not an iPod codec certification. The initial runs caught metadata-reader and canonical-path errors, which were repaired before the final run. **Latest native result: 53 tests executed, 0 failures, TEST SUCCEEDED (Release Catalyst, 13 October 2026).** Final receipts are in `verification/`.

## Device build and packaging

```sh
./scripts/create_build.sh
```

Outputs are an unsigned Release iphoneos IPA plus a ZIP containing it. Verify iPhoneOS/arm64, MinimumOSVersion 15.0, Cassette display name/icon, and no test tone/XCTest bundles. See [build artifacts](../build/build-artifacts.md).

Simulator compilation, if needed, does not execute tests:

```sh
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/CassetteSimulator CODE_SIGNING_ALLOWED=NO build-for-testing
```

Xcode 27 XCTest support targets newer iOS runtimes, so actual iOS 15 test execution needs a compatible Xcode/macOS/device setup. Do not treat later-runtime compilation as iOS 15 execution evidence.

## Native UI checks

An earlier pre-rebrand Catalyst build was opened for the initial smoke pass. Verified the empty-library folder/import actions, Settings navigation, Music Folders/source detail, enabled/disabled scan switch, disabled Rescan control while a source is excluded, and restoration of enabled scanning. Those historical checks preceded the Cassette rename. Current compact renders and branding are documented in native UI QA. See [native UI QA](../design/native-ui-qa.md).

Folder selection/provider access, populated 320-point iPod layouts, system background controls and device performance are not proven by these desktop checks. No claim of physical installation, lock-screen behavior or battery measurements is made.

## Physical iPod checklist — pending

- Install a properly signed build; confirm iOS version, app name/icon and first-launch silence.
- Add multiple actual local folders through Files → On My iPod; relaunch and verify persisted access.
- Copy audio into Cassette’s Files folder; opening must discover it without a Music subfolder.
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

Actual revoked/stale provider bookmarks, third-party provider coordination, iOS lifecycle/UI journeys and large-library performance require further device tests. M3U import is implemented and regression-tested; deeper per-codec metadata parsing remains implementation work. Historical foundation receipts are archived under `verification/archive/`.

## Player-polish regression run

Passed **12 tests, 0 failures** on the native Catalyst target, plus an unsigned iphoneos Release build. New tests verify idempotent additions to multiple playlists and stored records, tiny artwork backgrounds and object reuse from the cache, and generate the compact native player render inspected in [verification/player-compact.png](verification/player-compact.png). The fixed dock keeps all three secondary controls visible in that render. Physical iPod software-keyboard placement and A10 performance are still pending.

## Playlist selection follow-up

12 tests passed after adding reversible membership selection and cached artwork rows. The playlist regression now exercises repeated add protection, toggle off/on, persisted removal, isolation between playlists and complete removal of legacy duplicates. Device visual confirmation of the new rows is pending.

## Settings, performance and versioning verification

The earlier settings/performance suite ran 16 tests; the current expanded suite runs 27. Added coverage verifies playback-position preference without autoplay, repeat persistence with an empty queue, unchanged scans producing no track-array publications, and cache clearing preserving favorites/playlists. Native Settings and Now Playing are rendered at 320×548 for visual review; this is desktop UIKit evidence, not physical iPod interaction.

The initial five isolated Python release-workflow tests passed (`python3 -m unittest discover -s scripts/tests -v`). They cover semantic bumps, failed-build retries, notes required after shipping changes, mutations during build and a mismatched built version. Successful packaging writes the versioned Markdown changelog.

The modern app icon is an opaque 1024×1024 static asset. Sorting/ID lookup caches, batched index publication and once-per-song lyric parsing reduce repeated work. Actual A10 fluidity, memory and battery still require device measurements.

## Pre-push audit

The 1.1.2 audit run passes all 16 native tests and six Python release tests. New path-policy coverage checks traversal/absolute-path rejection and indexed files replaced by symlinks. Device static analysis succeeds without analyzer findings. See [repository audit](repository-audit.md) and [CI workflow](../build/continuous-integration.md).

## Versioned packaging

The 1.1.4 build passes eight Python packaging/release tests. Added packaging checks ensure IPA/ZIP names include the built version, the ZIP contains the identical versioned IPA and mismatched names fail before output. The unsigned device build and archive/architecture/resource checks pass; see the latest build receipt.

## Persistent player controls

All 16 native regression tests passed after relocating song options and favorites, adding persistent Queue access and moving Shuffle/Repeat to Playing Next. The existing player-render test now captures populated artwork, queue and lyrics states with long track text at 320×548, without autoplay. Native touch behavior and enlarged control comfort remain physical iPod QA items.

## Visual motion verification

All 16 native tests passed after adding bounded artwork/press transforms and selection highlights. The player-render test captures playing/paused UI and checks that the artwork wrapper produces identical images for both Reduce Motion playback states. The wrapper receives the actual SwiftUI accessibility setting in the app; the test supplies its value directly because the system environment is read-only. Device animation fluidity and touch handling are not certified by these captures.

## Feature expansion verification

The packaged 1.2.0 (8) release passes 27 native and ten Python workflow tests, plus Release iPhoneOS compilation/static analysis. Added tests cover M3U ordering/missing references/refresh, selected provider-style folders/bookmarks, scan throttling, LRC updates, rapid activation cancellation, isolated clock publication and Wikimedia matching/cache/offline/opt-out behavior. The initial-follow lyric render uses a real attached native host. Full receipts and physical-device limits are recorded in [feature QA](verification/feature-expansion-qa.md).

## Player/folder refinement verification

The prepared 1.2.1 (9) candidate passes 32 native Release tests, ten workflow tests and final iPhoneOS Release static analysis. New regressions cover folder add/removal during active scans, reconnect/repeated selection, persistent bookmark resolution, non-destructive data retention, legacy format metadata decoding, exact WAV bitrate, transfer-guide exclusion and scrubber hit area/accessibility. See [full QA receipt](verification/player-folder-qa.md). Last packaged artifacts remain 1.2.0 until the next build request.

## Cassette/widget verification

The packaged 1.3.0 (9) release passes 36 native Release tests, 18 Python workflow tests and iPhoneOS app/extension static analysis. Native card renders and shared-storage/deep-link regressions are recorded in [Cassette widgets](../design/cassette-widgets.md). Player/folder refinements are included in this minor release. Home Screen installation and matching App Group provisioning remain device checks; both platform exports passed packaging validation.

## Player/library polish verification — 12 October 2026

See [player/library polish receipt](verification/player-library-polish-qa.md) for native hold-seeking, small-folder scan progress, cumulative counts, scrubber checks and device compilation. Physical iPod translucency and gesture comfort remain unverified.

## Recently Played verification — 12 October 2026

The expanded native Release Catalyst suite passes 41 tests. History coverage verifies successful starts, natural transitions/repeat-one, no pause/resume duplicates, no silent-restore/cancelled/failed entries, newest-ten event identities, complete history, actual SQLite reopening, and exclusion/re-enable retention. See [Recently Played QA](verification/recently-played-qa.md).

## Album-art double-tap verification — 12 October 2026

Now Playing artwork has a two-tap gesture that calls the existing playback toggle. The gesture is attached to the artwork before its surrounding layout frame; horizontal track swipes retain their simultaneous drag gesture. Unsigned Release iPhoneOS app/widget compilation passed (`/tmp/cassette-artwork-double-tap-device.log`), and `git diff --check` passed. Actual double-tap/swipe arbitration remains physical iPod QA; no new export or installation was performed.

## Trailing list counts — 12 October 2026

Library category counts and playlist song counts now sit on the trailing edge before the chevron. The focused native Library/history render test passed, and the [320×548 Library render](verification/library-trailing-counts.png) was inspected to confirm aligned trailing counts. Unsigned Release iPhoneOS compilation and `git diff --check` passed. Logs: `/tmp/cassette-list-count-render.log`, `/tmp/cassette-list-count-device.log`. Physical iPod QA remains pending.

## Cassette branding pre-push checks — 13 October 2026

The current source passes all **41 native Release Catalyst tests** and **18 Python workflow tests**. README local HTML image/link targets and production-logo byte parity passed; Markdown links pass repository QA. Test scratch/output paths now use Cassette. The Xcode project regenerates byte-identically. Current logo/docs are separated from archived pre-rebrand evidence; bundle IDs and private persistence/cache paths remain unchanged. Logs: `/tmp/cassette-branding-native-tests.log` and `/tmp/cassette-branding-workflow.log`. Build/static-analysis/package results are in the [latest receipt](verification/final-build.md).

## Library reliability and sleep timer — 13 October 2026

Final Release Catalyst suite: **46 tests, zero failures**. Python workflow suite: **18 tests, zero failures**. New regressions cover 500-file unchanged rescans with zero track batches and throttled progress, preservation of missing entries after incomplete enumeration, finite queue timer limits, repeat boundary overrides, pause expiry, replacement cancellation and permission recovery copy. The timer uses continuous monotonic time including device sleep. Compact timer rendering was inspected at 320-point width; boundary options appear before duration presets. The test uses a 12-second WAV; disabled minute presets in the capture are expected.

Logs remain outside Git: `/tmp/cassette-reliability-tests.log`, `/tmp/cassette-workflow-tests.log`. Specification and device gates: [Library reliability and sleep timer](../product/library-reliability-and-sleep-timer.md). No physical lock-screen crash reproduction or A10 profiling has been performed. The reported termination is not certified fixed.

## Widget recovery — 13 October 2026

Release Catalyst: **48 tests, zero failures**; workflow suite: **18 tests, zero failures**. Added empty/corrupt snapshot repair and forced publication, bounded artwork decoding, unsafe/broken cover fallback and content-based cover identity checks. Inspected both square and medium empty-state renders: title, icon and library prompt are visible. Captures and logs remain outside Git (`/tmp/Cassette-widget-empty.png`, `/tmp/Cassette-widget-empty-horizontal.png`, `/tmp/cassette-widget-recovery-tests.log`, `/tmp/cassette-widget-workflow-tests.log`). [Widget recovery QA](verification/widget-recovery-qa.md) records findings and device acceptance. The iOS WidgetKit host and reported black widgets have not been reproduced on the physical iPod.

## Designer logo verification — 13 October 2026

The 1254×1254 supplied PNG is preserved byte-for-byte. App/README production icons match at 1024×1024 with no alpha; app/extension widget marks match at 64×64 with no alpha. The asset change was followed by **six widget tests, zero failures** and visual inspection of the regenerated square/medium renders, which show the new mark. Current widget screenshots were refreshed in verification docs. Log: `/tmp/cassette-designer-logo-tests.log`. No re-generation, crop or recoloring of the designer artwork occurred.

## Installed-build discrepancy audit

The user reports duplicate Settings/About GitHub links on 1.5.2 (14). Full-height native renders and direct exported-IPA label checks do not reproduce it; the installed-device mismatch remains unresolved. See the [claims and evidence audit](verification/release-1.5.2-audit.md).

## Persistent directory discovery and retro logo

The latest suite passes **53 native tests** and **18 workflow tests**, including disk-backed 500-song zero-scan restart, nested additions, playback/background deferral, cancellation, explicit provider refresh and in-place lyric edits. See [incremental scan evidence and limits](verification/incremental-scan-qa.md). Current widget captures use the latest retro rainbow artwork.
