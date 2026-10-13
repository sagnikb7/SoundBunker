# Cassette native UI verification

Current evidence reviewed on 13 October 2026. Cassette uses the designer-provided retro rainbow cassette icon. The original prototypes and pre-rebrand evidence are retained separately in [historical native UI QA](../testing/verification/archive/native-ui-pre-cassette.md).

## Current compact renders

- [Library](../testing/verification/library-trailing-counts.png): native 320×548 render; category counts align before disclosure chevrons.
- [Recently Played](../testing/verification/recently-played-library.png): horizontal 112-point artwork/song tiles and a navigable title/chevron, captured at 320-point width with extra height to show the section below the fold.
- [Listening History](../testing/verification/recently-played-history.png): unique newest-first songs (latest play wins), artwork, timestamps and song options at 320×548.
- [Now Playing](../testing/verification/player-library-polish-playing.png): artwork/shadow, larger seek handle, fixed transport and secondary controls at 320×548.
- [Widgets](cassette-widgets.md): selected square/horizontal card layout and Cassette brand assets.

The production artwork is [Cassette’s icon](assets/cassette-icon.png), matching the app icon asset. No prototype catalog, album art or sample music is shipped.

## Interaction and verification limits

Now Playing supports a 24-point visible seek thumb with a 44-point touch surface, hold-to-seek transport and double-tap artwork to play/pause. Horizontal artwork swipes retain next/previous navigation. Settings/folder detail display live rescan counts and Cancel. Library/history tiles use cached local artwork, with a music-note fallback.

The images above are native desktop UIKit/Catalyst evidence. The expanded history suite passed 41 tests; focused render and iPhoneOS compilation checks passed after subsequent gesture/alignment edits. See [testing](../testing/testing.md) and the [latest package receipt](../testing/verification/final-build.md).

Physical iPod gesture arbitration, translucency, provider-folder selection, Dynamic Type/VoiceOver journeys, background playback and A10 performance remain to be verified. No screenshot or compiler result is a physical-device installation claim.

## Player and library polish (1.5.4 pending)

- Sleep timer lives in the Now Playing song options menu; the header only holds the dismiss chevron.
- Song title is a single-line marquee with 12-point faded edges (static when it fits; manually scrollable with Reduce Motion).
- Artwork fills the available width (no 240-point cap), uses a 10-point corner radius, and follows horizontal drags: past ~80 points or a fling it skips next/previous; shorter drags spring back.
- Mini player play/pause and next use the same 20-point symbols in 52-point hit areas.
- Song lists (Songs, artist, genre) use a custom large title with the count beside it, an in-list search bar, and a sort icon at the top right; long titles auto-scroll.
- List separators use a quieter 8% tint; lists add a 56-point bottom clearance so the last row clears the mini player.

Status: compiled for the iOS Simulator only; visual match to the native large title, gesture feel and the iOS 15 list inset still need on-device checks.

Artist song pages reuse the opt-in cached Wikimedia photo as a 250-point edge-to-edge hero when one is available. A three-stop adaptive gradient fades the image into `systemBackground`, so the artist name and count remain legible in both light and dark appearances. Pages without a photo retain the standard large-title header.
