# Cassette native UI verification

Current evidence reviewed on 13 October 2026. Cassette uses the designer-provided retro rainbow cassette icon. The original prototypes and pre-rebrand evidence are retained separately in [historical native UI QA](../testing/verification/archive/native-ui-pre-cassette.md).

## Current compact renders

- [Library](../testing/verification/library-trailing-counts.png): native 320×548 render; category counts align before disclosure chevrons.
- [Recently Played](../testing/verification/recently-played-library.png): horizontal 112-point artwork/song tiles and a navigable title/chevron, captured at 320-point width with extra height to show the section below the fold.
- [Listening History](../testing/verification/recently-played-history.png): newest-first songs, artwork, timestamps and song options at 320×548.
- [Now Playing](../testing/verification/player-library-polish-playing.png): artwork/shadow, larger seek handle, fixed transport and secondary controls at 320×548.
- [Widgets](cassette-widgets.md): selected square/horizontal card layout and Cassette brand assets.

The production artwork is [Cassette’s icon](assets/cassette-icon.png), matching the app icon asset. No prototype catalog, album art or sample music is shipped.

## Interaction and verification limits

Now Playing supports a 24-point visible seek thumb with a 44-point touch surface, hold-to-seek transport and double-tap artwork to play/pause. Horizontal artwork swipes retain next/previous navigation. Settings/folder detail display live rescan counts and Cancel. Library/history tiles use cached local artwork, with a music-note fallback.

The images above are native desktop UIKit/Catalyst evidence. The expanded history suite passed 41 tests; focused render and iPhoneOS compilation checks passed after subsequent gesture/alignment edits. See [testing](../testing/testing.md) and the [latest package receipt](../testing/verification/final-build.md).

Physical iPod gesture arbitration, translucency, provider-folder selection, Dynamic Type/VoiceOver journeys, background playback and A10 performance remain to be verified. No screenshot or compiler result is a physical-device installation claim.
