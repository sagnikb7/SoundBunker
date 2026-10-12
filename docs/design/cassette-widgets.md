# Cassette branding and widgets

Date: 12 October 2026. Packaged release **1.3.0 (9)**. Both iPod IPA/ZIP and local Mac .app/ZIP passed validation. No push or installation was performed. See [build receipt](../testing/verification/final-build.md).

## Selected design

The user chose the second displayed concept: [compact artwork/track layout](assets/widget-selected-concept.png). This pre-rebrand concept is a historical reference. The implemented widgets use the new Cassette icon instead of the previous mark, real local cover art, and a music-note fallback when artwork is absent. Concept songs/art are not bundled as app media.

- Square: artwork upper left, small Cassette mark upper right, last-played label, title and artist.
- Horizontal: larger artwork left, track/artist right, and an Open player navigation affordance.
- Empty: Cassette/Open library. Tap opens Library instead of an empty player.

Native renders: [square](../testing/verification/cassette-widget-square.png), [horizontal](../testing/verification/cassette-widget-horizontal.png), [empty](../testing/verification/cassette-widget-empty.png). These use isolated mock text and the genuine no-artwork fallback for verification, not shipped demo music. WidgetKit supplies its own rounded mask; the app preview applies the same corner treatment.

## iOS 15 behavior

The extension supports `systemSmall` and `systemMedium`, targeting iOS 15. `widgetURL` opens `cassette://player` or `cassette://library`. It does not autoplay, read arbitrary paths or accept URL parameters. iOS 15 widgets cannot execute in-place playback controls; [Apple’s interactive-widget guidance](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities) introduces those buttons for iOS 17+. Existing app/system media controls continue handling playback.

Settings → Playback → Widgets previews both native card layouts and explains installation. After a signed installation, touch and hold the Home Screen → + → Cassette → select size → Add Widget.

## Snapshot and performance

`WidgetSnapshotStore` writes only title, artist and a generated cover filename to the App Group `group.com.local.offlinemusicplayer`. No audio, bookmarks, favorites, playlists or private database is copied. Covers reuse the app’s already-downsampled local JPEG, at most 2 MB; only the latest and one preceding image are retained. JSON reads are limited to 64 KB, unsafe paths/symlinks are rejected, and unchanged snapshot writes are suppressed.

The provider has a single-entry `.never` timeline. Changed metadata triggers `reloadTimelines(ofKind:)`; system timing remains controlled by WidgetKit. Updates happen when the track changes or indexed metadata changes (debounced), never from progress ticks or Play/Pause. Superseded publication tasks cancel before writing. No widget network calls, timers, scanning, audio decoding or continuous blur. See [Apple’s timeline guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Signing and App Groups

The iPhoneOS app embeds `CassetteWidget.appex`. Its identifier is `com.local.offlinemusicplayer.widget`; the app remains `com.local.offlinemusicplayer`. Both targets use the same App Group entitlement. Catalyst excludes the extension and does not request the iOS group; native desktop tests inject temporary directories.

On a compatible Xcode/device setup:

1. Select the same signing Team for OfflineMusicPlayer and CassetteWidget.
2. Register an App Group supported by that Team. Configure the same group in both target entitlements and `CassetteWidgetConfiguration.appGroup` if the registered name differs.
3. Add App Groups in Signing & Capabilities for both targets; confirm the provisioning profiles include the group and the widget profile matches the app’s identifier prefix.
4. Install the containing app and extension together, launch Cassette, play a local song, then add both widget sizes.
5. Confirm artwork/title update after changing songs, cached display offline, and taps open player/library without starting playback.

An unsigned IPA or a signing tool that strips App Groups does not establish shared access. Re-signing must preserve/provision the extension and matching group; otherwise the widget safely stays empty. This host cannot verify iPod signing/installation. See [App Group setup](https://developer.apple.com/documentation/xcode/configuring-app-groups) and [device installation](../build/ipod-installation.md).

## Branding and assets

The display name is **Cassette**. The user’s exact GitHub repository spelling is [sagnikb7/casette](https://github.com/sagnikb7/casette). Origin and bundled project metadata follow that URL. Bundle identifier, Documents/database/private-cache paths stay stable; owned-source IDs persist while their display name updates. Previously generated pre-rebrand packages/receipts remain historical. New builds use `Cassette-unsigned-<version>.ipa` and `.ipa.zip`.

App icon: `OfflineMusicPlayer/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, opaque 1024×1024. Widget mark: a 64px version in both app/widget asset catalogs. Existing artwork/icon references are preserved under `docs/design/assets/`; original HTML references remain untouched.

Built-in ImageGen prompt used for the installed icon:

> Create the final production iOS app icon for an offline music player newly named Cassette. Single square 1024x1024 icon image, fully opaque edge-to-edge background, absolutely no transparent pixels, no external margins, no rounded outer-square mask (iOS supplies its own), no text or lettering, no watermark, no phone or mockup. Main mark: a clean modern minimalist audio cassette tape, immediately recognizable even at 40px. Horizontal rectangular cassette with softly rounded internal corners, warm ivory body, two bold dark circular reels with clear centers and a short dark tape-window connector between them, a simple inset trapezoid lower tape area. Balanced generous silhouette occupies about70% ofwidth centered slightlyabove middle. A narrow coral-orange label stripe across upper portion and restrained muted teal details reference the app's existing warmth. Background: deep midnight navy with very subtle smooth teal illumination behind tape, no busytexture. Modern Apple-quality icon craft, geometric near-flat construction with extremely restrained soft depth on the object only, crisp boldedges and sufficient contrast. More modern than literal retro photography, tactile and sophisticated without tiny screws or dense details. Reels and dark tape shape should read clearly, no headphones, no bunker arch, no music note. The cassette tape shape is the entire brand; avoid extra decoration. Native iOS icon for a compact iPod touch screen. Currentdate12October2026 irrelevant toimage, no datevisible.

The generated original was converted with `sips -z 1024 1024` for the app icon and `sips -z 64 64` for the widget mark. No runtime rendering/animation is used for the icon.

## Executed QA

- Native Release Catalyst: **36 tests, zero failures; TEST SUCCEEDED**, including the 32 existing app/folder/player tests.
- Python workflow tests: **18 tests, zero failures**, including platform commands and Mac packaging.
- iPhoneOS app plus embedded extension Release build/static analysis: **ANALYZE SUCCEEDED**; no analyzer findings.
- Read-only validation checks both arm64 binaries, iOS 15 minimum, app/extension versions, widget extension point/identity, matching source entitlements and bundled assets. App icon is 1024px/opaque. No test tone or XCTest resource is present in the device app.
- Regression coverage: persisted snapshots, duplicate-write suppression, missing-group fallback, bounded image retention/oversized covers, invalid/oversized JSON, unsafe artwork paths, known-only deep links, and native square/horizontal/empty renders.

Actual iPod Home Screen rendering, group provisioning, timeline scheduling, device taps, VoiceOver and battery use remain physical-device checks. Desktop card renders and successful extension compilation do not prove widget installation or OS timeline behavior.
