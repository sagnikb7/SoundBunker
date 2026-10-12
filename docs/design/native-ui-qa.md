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
