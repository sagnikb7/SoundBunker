# Native UI QA

Date: 12 October 2026. Target: the actual SoundBunker Mac Catalyst app compiled from shared SwiftUI sources, not the HTML prototype.

## Verified desktop states

- App window title is SoundBunker.
- Empty Library offers Add Music Folder and Import Audio Files, with native tab navigation and no test-tone controls.
- Settings shows automatic-scan guidance, Music Folders, import/rescan, actual library counts, appearance, cache and branded About content.
- Music Folders contains the app-owned SoundBunker source and Add Music Folder.
- Source detail shows Scan this folder, Rescan Folder and Exclude a Folder.
- Toggling scanning off updates the switch and disables Rescan; toggling back on restores enabled scanning.
- A screenshot of the native source-detail screen was inspected. Semantic grouped rows and text appear correctly at the desktop preview size.

## Scope limits

This is a limited desktop UI smoke pass, not a 1:1 screenshot reproduction or a completed physical accessibility audit. The supplied HTML was inspected as inspiration; its 320×568 canvas and invented content are not embedded in the native app. iPod-size rendering, populated library/player/provider-picker journeys and background controls require device QA. Automated tests exercise real indexing/exclusions, Core Data, queues, lyrics and native WAV decoding independently of UI capture.

No sample audio or fabricated music catalog is shipped. See [testing](../testing/testing.md) for runtime results and [prototype mapping](prototype-mapping.md) for adaptations.

## Compact player polish

The native player was rendered through UIHostingController at 320×548 on the Catalyst runtime and visually inspected. Shuffle, Repeat and Lyrics sit within the bottom dock, below transport/seek, and remain visible. The central content yields height instead of the whole screen scrolling. [Compact render](../testing/verification/player-compact.png).

Artwork tint is derived from the user's cover, not a supplied decorative asset: a ≤64-pixel rotated/blurred image cached off the main actor. Playlist choosers show checkmarks for existing entries; the same idempotent mutation serves the Now Playing options menu. The keyboard padding fix responds to system keyboard-frame events. Actual iPod keyboard transitions and color contrast across real covers still need physical confirmation.

## Compact Settings and new icon

Settings groups music library, preferences, storage/library and About. Rows retain 44-point minimum controls; compact inline navigation leaves space on the iPod. Native 320×548 render: [Settings](../testing/verification/settings-compact.png). The opaque navy/cyan/warm-accent headphone/equalizer icon is generated offline; UIKit renders a static app asset. No animation or runtime effects are used for the icon.

Inspect playback, cache confirmation, larger Dynamic Type and scrolling on the physical device before claiming device UX/performance verification.

## Settings visual rollback — 1.1.3

Restored the earlier simple inset-grouped list with Music Library, Playback, Storage and About sections and the standard Settings title. Removed the branding card and colored icon tiles; restored direct playback-position, appearance and cache controls. Music-folder/import/rescan/statistics, shuffle/repeat preferences, cache confirmation/size/limit, installed version, What's New and About remain accessible. The cache section shares the existing utility task and safe-clear behavior with its dedicated screen.

Current native 320×548 render: [Settings](../testing/verification/settings-restored.png). This render is desktop UIKit evidence; actual iPod layout remains a device QA item.

Verification: all 16 Catalyst regression tests passed after the layout/cache-refresh changes; the final compact-label render test also passed. Packaged as 1.1.3 (5); this entry records the checks at that release.

## Earlier header alignment review (superseded by the control layout below)

Dismiss and options glyphs now align with the shared 24-point content margins while retaining 44×44-point hit targets. The centered caption/album uses an independent layer with reserved side space, preventing controls from shifting or overlapping it. Empty album text is omitted so an idle player's caption stays vertically centered. No animation, timer or rendering effect was added.

Native 320×548 renders: [empty player](../testing/verification/player-header-empty.png) and [restored populated player](../testing/verification/player-header-populated.png). Physical iPod confirmation remains pending.

Verification: targeted native player-render test passed. Empty and restored populated renders were reviewed; title, header glyphs and pinned secondary controls fit at 320×548. No IPA was built for this change.

## Now Playing control layout — 1.1.5

The layout follows the user’s requested [Apple Music player pattern](https://support.apple.com/guide/iphone/use-the-music-player-controls-iph676daac9b/ios), adapted to offline iOS 15 playback. The header retains dismiss and centered context. Song options now share the title/artist row immediately above progress. Lyrics, Favorite and Playing Next use three evenly spaced permanent bottom controls; Queue remains visible in artwork, queue and lyrics modes.

Shuffle and Repeat sit in a fixed Playing Next header above the scrollable queue. Header/options/queue controls use 52×52-point targets, footer actions fill equal-width columns at 56 points tall, and transport fills the same columns at 72 points tall. Mini-player icons and queue/lyric rows have 52-point minimum targets. Content is clipped to its allotted region so it cannot cover the fixed dock; the existing artwork cache and lyrics parsing behavior remain unchanged.

Native 320×548 renders: [artwork](../testing/verification/player-controls-artwork.png), [queue](../testing/verification/player-controls-queue.png), [lyrics](../testing/verification/player-controls-lyrics.png). These verify desktop UIKit rendering, not touch interaction on the physical iPod.

Verification: all 16 native Catalyst tests passed. Artwork, Playing Next and lyrics renders were visually reviewed at 320×548 with a long title and an upcoming queue. The persistent control row stays visible in all three modes. No IPA was built or pushed for this change.

## Visual micro-interactions — 1.1.5

Playback artwork uses a 280 ms ease-in/out transform between 90% paused and 100% playing, within a fixed frame. An empty player keeps its placeholder full size. Press feedback fades briefly and contracts to 96% over 120 ms; selected player actions use a 160 ms highlight change. Artwork and blur are reused, with no new timers or idle animation. `VisualFeedback.swift` owns the reusable press style and playback-artwork wrapper.

Reduce Motion keeps artwork at full size, removes press scaling/animated transitions and leaves immediate opacity, icon and selected-state feedback. Existing action handlers and hit-target layout remain intact.

Native renders: [playing](../testing/verification/player-motion-playing.png), [paused](../testing/verification/player-motion-paused.png), [Reduce Motion artwork](../testing/verification/player-motion-reduced.png). Physical iPod fluidity and touch feedback remain device checks.

Verification: all 16 Catalyst tests passed. The render test starts/pauses the local fixture for full-player snapshots, and separately verifies pixel-identical artwork for paused/playing Reduce Motion inputs. These native renders were reviewed; on-device frame-rate and button-touch measurements remain pending. No IPA was built for this change.

The control layout and visual feedback were packaged together in 1.1.5 (7). See the archived player-motion build receipt for that release.

## 1.2.0 feature checks

The album transform is 180 ms and follows requested playback while session activation runs away from the main actor. The fixed control layout stays unchanged. Artwork swipes use horizontal intent and reserve the first 32 screen points for back navigation; native navigation pop is preserved and supported modal roots can dismiss from the left edge. Touch gestures remain physical iPod QA items.

Lyrics use compact 44-point minimum rows with 2-point spacing, a smooth active-line fade and binary-search timing. Initial follow is deferred until anchors are laid out; manual drag pauses following and a Follow button resumes it. The [attached-host capture](../testing/verification/lyrics-following.png) shows the current ninth line immediately after opening at eight seconds.

The actual Catalyst Settings/About screens expose the artist-photo switch/disclosure and repository link. The link opened the correct project in the default browser. Artist rows have cached circular thumbnails and a Photo Credit menu; tests exercise the image client and attribution. See [feature QA](../testing/verification/feature-expansion-qa.md).
