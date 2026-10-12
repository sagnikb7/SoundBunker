# SoundBunker changelog

Every user-facing feature or fix is recorded here when its release build succeeds. Pending changes and their intended semantic bump are maintained in `release/version.json`; see [versioning](../build/versioning.md).

## Unreleased

The build workflow moves pending feature/fix notes into a dated release section after successful packaging.

## 1.2.0 — 12 October 2026

Build: 8.

### Added

- Automatic local M3U/M3U8 playlist discovery, ordered entries and unresolved-file feedback.
- Optional cached artist photos from Wikimedia with attribution and privacy controls.
- GitHub project link derived from the origin remote.
- Song-menu artist/album navigation, artwork swipe navigation and modal edge-back support.
- Smooth compact timed lyrics with auto-follow and manual-scroll pause.

### Changed

- Cached album/artist/genre browsing and throttled foreground scans.
- Faster bounded animations and a lyrics clock that runs faster only when lyrics are visible.

### Fixed

- Removed blanket File Provider Storage rejection for folders selected in Files.
- Playback-request artwork feedback starts before asynchronous audio-session activation.

## 1.1.5 — 12 October 2026

Build: 7.

### Changed

- Apple Music-inspired Now Playing layout with persistent Lyrics, Favorite and Queue controls.
- Song options moved beside track details above the progress bar; Shuffle and Repeat moved into Playing Next.
- Larger non-overlapping tap targets throughout Now Playing and the mini-player.
- Visual press feedback for player/mini-player/song rows and subtle selected-state highlights.
- Album artwork expands on play and contracts on pause using a short cached-image transform; Reduce Motion disables movement.

### Fixed

- Aligned Now Playing header controls to the content edges and centered its title, including the empty-player state.

## 1.1.4 — 12 October 2026

Build: 6.

### Changed

- IPA and ZIP filenames now include the release version, validated against the built app in local and CI workflows.

## 1.1.3 — 12 October 2026

Build: 5.

### Changed

- Restored the simpler grouped Settings layout with direct controls while preserving all settings functionality.

## 1.1.2 — 12 October 2026

Build: 4.

### Fixed

- Playback rechecks enabled folders and exclusions before opening each indexed file.
- Local file access rejects symbolic links and paths escaping the selected music folder.

## 1.1.1 — 12 October 2026

Build: 3.

### Changed

- Compact Settings navigation title preserves more space for controls on the iPod screen.

## 1.1.0 — 12 October 2026

Build: 2.

### Added

- Organized Settings with dedicated playback, appearance, library statistics, storage and About screens.
- Playback-position preference and accessible controls for repeat and shuffle.
- Version/build display and bundled What's New release notes.
- Changelog-backed version preparation before builds, with build numbers committed only after successful packaging.

### Changed

- Compact list spacing for the iPod while retaining readable text and 44-point controls.
- Cached library browsing and track lookups, batched scan publishing, and once-per-song lyric parsing.
- New modern SoundBunker icon, rendered as a static opaque asset with no runtime drawing cost.

### Fixed

- Artwork cache clearing now requires confirmation and disables during scans.

## 1.0.0 — 12 October 2026

Historical baseline: earlier IPAs used display version `1.0` and build `1`.

### Added

- Local Core Data library, folder/file intake, automatic scanning and folder exclusions.
- Songs, albums, artists, genres, folders, search, favorites and editable playlists.
- Native playback, persisted queues, system controls and local lyrics.
- SoundBunker name/icon and IPA + ZIP packaging.

### Changed

- Compact Now Playing with pinned controls and cached rotated/blurred artwork tint.
- Artwork in playlist choosers, checkmark feedback and reversible duplicate-safe selection.

### Fixed

- Canonical folder-path handling and metadata fallback for playable files.
- Mini-player tab-bar offset while the keyboard is visible.
