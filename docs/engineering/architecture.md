# Architecture

## Ownership and data flow

The SwiftUI App owns one `LibraryStore` and one `PlaybackCoordinator`. Views read observable state and request actions; they never create independent players. The library loads first, then the player restores its stable-ID queue without starting audio. The root scans on first appearance and throttles foreground full scans to a two-minute interval; concurrent scans are suppressed.

`LibraryScanner` is an actor with one metadata worker, bounding resource use. It recursively enumerates regular audio candidates, skips hidden files/packages/symlinks, and applies source exclusions before reading metadata. File resource and volume identities deduplicate overlapping roots; separate copies keep separate identities. Size/mtime fingerprints avoid reparsing unchanged files. Results reach the main actor in batches of 25.

`LibraryStore` publishes batch results, saves to Core Data and marks missed files unavailable after a completed scan. Cancelling retains existing state plus already published additions. A failed source retains indexed identities and user data, marks locations unavailable and exposes reconnection. Removing a source only removes its locations; favorites and playlist references remain, and other source memberships continue to work.

## Persistence

`LibraryDatabase` uses a versioned programmatic Core Data model with keyed `LibraryRecord` entities: source, track, playlist and playback records. JSON payloads retain stable identities, source memberships and version-tolerant source defaults. Unique record keys support updates; automatic lightweight model migration is enabled. Display albums/artists are derived from tracks, including album-artist grouping and disc/track sorting.

Search currently filters the loaded local index. Larger-library indexed SQL search and measured fetch/scroll performance remain work items. Tests isolate their stores and fixtures from production data. Disk persistence is verified separately from in-memory serialization tests.

## File access and offline policy

The app scans its entire Documents directory automatically; it appears as SoundBunker under On My iPod. No Music subfolder is required. External roots are explicitly selected through UIDocumentPickerViewController, saved as bookmarks and resolved on subsequent opens. Security scope is balanced during scanning and held for the active track until replacement. Readable stale bookmark locations remain usable; unavailable locations request reconnection. Resolved roots are cached and invalidated on reconnection/removal.

Reading/copying provider audio uses NSFileCoordinator. Explicitly selected provider folders are allowed; the previous pathname-based rejection is removed. Cloud-only ubiquitous audio and symbolic links are refused before decoding. Directory placeholders may be enumerated to discover downloaded children. Third-party providers retain control over file availability; download audio in Files first. Arbitrary device-wide access and remote audio streaming are not implemented.

Source enable flags and excluded relative paths persist. Path-boundary matching excludes `Podcasts/…` without excluding `Podcasts Plus/…`. Excluded songs disappear from library browsing while their stored identities/favorites/playlist entries remain. No original media is rewritten or removed.

## Playback

`NativeAudioEngine` wraps AVAudioPlayer, refuses non-file URLs, clamps seeks and ignores callbacks from replaced player instances. The main-actor coordinator resolves a track through its allowed source memberships, skips unavailable queue entries with a bounded traversal, handles natural advance/repeat, remote commands, interruption and headphone removal. It persists on pause, seek, background and at ten-second intervals during playback. No sound starts automatically on relaunch.

Views use a persistent mini-player above the iOS tab bar and a full-screen Now Playing presentation. Native session/Control Center integration is implemented; real-device behavior is not yet certified. Shuffle-off currently sorts the remaining queue by title rather than restoring its pre-shuffle order; this is documented for further refinement.

## Artwork and lyrics

Embedded artwork is reduced to 320×320 JPEGs off the main UI flow. Disk cache is trimmed to 50 MB off the main actor when new thumbnails are produced; thumbnail memory cache is capped at 12 MB. Cache clearing removes generated thumbnails only. A missing/evicted thumbnail falls back to a semantic note symbol.

Embedded plain lyrics and matching adjacent UTF-8 LRC are retained in the index. LRC supports offsets and multiple timestamps, highlights by playback time and permits tap-to-seek/manual scroll. No synchronized timestamps are invented for plain text. Binary synchronized tags and codec-specific numeric/tag parsing remain incomplete.

## Compact player and playlist polish

Now Playing reserves a fixed dock outside its scroll regions for seek/transport and the three secondary controls. The artwork shrinks to the remaining height; metadata remains in the dock above progress without pushing the secondary row below the fold. A native 320×548 render was inspected. The root removes the mini-player's 49-point tab-bar padding when keyboard frame notifications report a visible keyboard; keyboard safe-area avoidance supplies its vertical position.

`ArtworkSurfaceCache` is an actor that decodes artwork directly to at most 64 pixels, rotates 180 degrees, applies a cropped/clamped Gaussian blur and stores up to 16 results. A static CIContext and NSCache avoid per-tick rendering and repeated setup. The foreground uses a strong semantic surface overlay for text contrast; Reduce Transparency suppresses the tint. Device CPU/memory/battery profiling remains pending.

`LibraryStore.addTrack(_:to:)` is the shared, idempotent manual-add mutation used by song menus, the playlist song chooser and Now Playing's playlist picker. It reads the latest stored playlist, refuses repeats/missing identities and publishes a checkmark only after a successful database commit. Legacy duplicate entries are preserved; reorder/delete behavior remains unchanged.

Playlist selection uses `LibraryStore.toggleTrack(_:in:)`: an unselected song uses the idempotent add path; a selected song removes all matching IDs, commits, then publishes the updated state. Song menus retain add-only semantics. Both chooser screens reuse the bounded thumbnail cache and expose the current selection/removal action to accessibility.

## Responsiveness and release identity

LibraryStore caches visible/title-sorted tracks and an ID lookup, invalidating when tracks or source policy change. Scan batches save changed records and publish once per batch; unchanged scans avoid track publication. Restriction/removal/failure handling similarly publishes one array update. Lyrics parse on song changes; artwork tint uses the existing tiny cached background. Cache clearing removes generated files on a utility task and resets index metadata in yielding batches without deleting source audio.

Settings reads installed version/build and bundled ReleaseNotes.json. The release manifest and scripts maintain semantic versions, build numbers and the Markdown changelog; branding assets do not change bundle identity, Core Data schema or database paths.

## Feature expansion

M3U discovery shares the scan pass and caches manifest parsing by file fingerprint. Imported origins and unresolved paths are optional JSON fields, preserving old playlist decoding and the existing Core Data schema. Import refresh saves/publishes only changed playlists. LRC sidecar fingerprints refresh changed lyrics.

BrowseIndex caches albums, artists, genres and recent lists. PlaybackClock alone publishes elapsed time, so library consumers do not redraw for progress ticks. PlaybackSession serializes blocking activation away from the UI; a generation token prevents a canceled request from starting audio later. Artwork responds to requested playback, using a bounded 180 ms transform. Only visible timed lyrics use the faster clock and binary-search line lookup.

The metadata layer, network boundaries, attribution, cache/backoff and project link derivation are documented in [metadata and playlists](metadata-and-playlists.md).
