# Offline Music Player — Final Product & Engineering Specification

**Version:** 1.0  
**Status:** Ready for Codex implementation  
**Primary target:** iPod touch (7th generation), iOS 15  
**Minimum deployment target:** iOS 15.0  
**Product type:** Native, fully offline, local-folder music player

## 1. Product vision

Build a fast, dependable native iOS music player that feels like an Apple product. Users select one or more **on-device folders** containing music; the app recursively indexes supported audio files, reads their existing metadata and embedded artwork, and organizes them into a browsable, searchable library. Users play music from the original files without a server, account, cloud service, or internet connection.

**Central rule:** Music files are the source of truth. The app stores an on-device **index**, preferences, queues, playlists, and thumbnail caches—not a duplicated media catalog in the cloud.

### Product principles

1. **100% offline in v1:** no authentication, backend, cloud sync, streaming, API requests, analytics, or tracking.
2. **Native Apple experience:** SwiftUI, system typography/colors, SF Symbols, native navigation, lists, sheets, menus and accessibility.
3. **Non-destructive:** never rename, move, tag, rewrite, or delete original audio files automatically.
4. **Folder-first:** users explicitly register and manage multiple library sources.
5. **Playback reliability first:** background audio, system controls, stable queue and resilient file handling.
6. **Low overhead:** design and measure performance for the A10-powered 4-inch iPod touch.
7. **No speculative infrastructure:** online metadata, art and lyrics enrichment belong only in the roadmap.

## 2. Scope and non-goals

### Included in v1

| Category | Requirements |
|---|---|
| Sources | Add multiple local directories; recursive scan; rescan/remove/reconnect sources; progress/cancellation |
| Library | Songs, Albums, Artists, Genres, Folders, Recently Added, Favorites, Playlists |
| Metadata | Title, artist, album artist, album, year, genre, disc/track number, duration, embedded artwork |
| Playback | Play/pause, next/previous, seek, queue, shuffle, repeat off/one/all, continue to next track |
| Formats | Validate native MP3, AAC/M4A, ALAC, WAV, AIFF; evaluate FLAC, Ogg Vorbis, Opus with real decoder tests |
| Lyrics | Embedded unsynchronized lyrics; external `.lrc`; embedded synchronized lyrics when supported and verified |
| Playlists | Import M3U/M3U8; local create, rename, edit, reorder and delete playlists |
| iOS integration | Background playback, lock screen, Control Center, remote commands, wired/Bluetooth output |
| Persistence | Local library database, bookmarks, queues, favorites, user playlists, playback state |
| Settings | Folder management, rescan, library stats, cache clearing, appearance preference where helpful |

### Explicitly excluded from v1

- Login, account management, user profiles, authorization services.
- Backend servers, cloud databases, synchronization, remote APIs or streaming.
- Downloading or enriching metadata, artwork or lyrics from the internet.
- Fetching cloud-only files presented by document providers.
- Network playlist/URL playback.
- Equalizer, crossfade, ReplayGain, smart playlists, social features.
- Editing or rewriting music tags/files.

**Future roadmap only:** optional user-triggered online metadata matching, missing-cover lookup and lyric lookup/download. Put ideas in `ROADMAP.md` without implementing network layers or dependencies now.

## 3. Target devices and UI

- Minimum OS: **iOS 15.0**. Primary QA device: **iPod touch 7th generation** (A10 Fusion, 4-inch 1136 × 640 display).
- Portrait-first, compact and comfortable at 320-point logical width. Respect safe areas, Dynamic Type and accessible touch targets.
- Use **SwiftUI** with **UIKit bridges only where necessary** (such as a folder document picker).
- Use iOS 15-compatible navigation (`NavigationView` where applicable), system `TabView`, `List`, native search, sheets, context menus, SF Symbols, semantic colors and San Francisco typography.
- No web views, third-party design systems, custom glass effects or animation-heavy UI.
- Automatic light/dark mode; artwork-forward but restrained Now Playing presentation.

### Information architecture

**Library:** Songs, Albums, Artists, Genres, Folders, Recently Added.  
**Playlists:** Imported playlists, user playlists, Favorites.  
**Search:** Local indexed search across songs, artists, albums and playlists.  
**Settings:** Sources, scans, cache, playback settings, diagnostics/about.

Choose native navigation that remains uncluttered on a 4-inch screen; four tabs are an initial preference, not a mandate.

### Important screens and states

- First launch: straightforward **Add Music Folder** empty state.
- Library lists: efficient scrolling, artwork thumbnail, title and secondary metadata; sensible sort options.
- Persistent mini-player above the tab bar with artwork, title, play/pause and route to Now Playing.
- Now Playing: album art, title/artist, seek slider, elapsed/remaining time, previous/play-next, queue, shuffle, repeat, lyrics entry.
- Lyrics: ordinary readable text or highlighted timestamped LRC with tap-to-seek.
- Native loading, empty, unavailable, scan-error, unsupported-format and permission-reconnect states.

## 4. Folder sources, Files access and indexing

### Source model

A `MusicSource` represents a user-registered folder or the app-managed local Music folder. The UI must permit adding multiple sources across sessions, removing a source from the **library only**, scanning an individual source, or rescanning all sources.

Use `UIDocumentPickerViewController` for user selection, with folder content types supported by the deployed APIs. Security-scoped URLs/bookmarks must be handled safely: start/stop access correctly, persist bookmarks, detect stale bookmarks, and request user reconnection if access fails. Use file coordination where document providers require it.

**iOS limitation:** Do not imply unrestricted Android-like filesystem access. Do not recursively crawl locations that were not granted to the app.

### Offline source policy

- Prefer files physically available on the device or in the app's own Documents container.
- The Files picker may expose remote-backed providers. Do **not** initiate cloud-only file downloads; report inaccessible/non-local entries clearly. Where reliable identification is impossible, fail conservatively rather than promising offline access.
- Do not attempt to bypass sandboxing or provider permissions.

### App-owned folder

- Maintain `Documents/Music` for user-transferred files.
- Configure file-sharing/opening-in-place keys as appropriate for Files and supported desktop transfer workflows.
- Register this folder automatically as a local source; do not copy already accessible files without an explicit import choice.

### Scanner requirements

1. Enumerate relevant files recursively with cancellation and scan progress.
2. Ignore hidden/system entries and unrelated formats; prevent recursive traversal cycles.
3. Parse metadata and artwork on background tasks with **bounded concurrency**.
4. Write indexed data to Core Data in batches and publish incremental results.
5. Detect additions and modifications using available file identity, size, timestamps and path information.
6. Deduplicate the **same underlying file** indexed through overlapping sources, but **not** separate copies merely sharing title/artist.
7. Keep temporarily inaccessible files in the index with an unavailable state; do not silently erase playlists or favorites.
8. Avoid reparsing an unchanged library on each launch; allow full manual rescan.
9. Handle source removal without deleting original files or removing tracks still referenced by another registered source.

Do not rely on always-on folder watching/background indexing on iOS. Scan when user requests it and during appropriate foreground opportunities. Never claim arbitrary background directory access.

## 5. Library data and metadata

Store locally with **Core Data**. Suggested conceptual entities: `MusicSource`, `Track`, `Album`, `Artist`, `Playlist`, `PlaylistEntry`, `PlaybackState`. Normalize only where useful; avoid unnecessary persistence complexity.

Capture available title, artist, album artist, album, genre, date/year, track/disc number, duration, artwork and embedded lyrics. Use applicable ID3, MP4 and other tag parsers; do not assume AVFoundation exposes every tag uniformly. Preserve Unicode and set readable fallbacks: filename / Unknown Artist / Unknown Album / placeholder artwork.

- Sort album tracks by disc and track number.
- Group compilations appropriately using album artist when available.
- Store stable IDs and source relationships apart from display metadata.
- Store artwork thumbnails in a bounded local disk/memory cache, not full image blobs in Core Data.
- Treat library database schema migrations and preservation of favorites/playlists as first-class concerns.
- Make local search efficient for several thousand tracks using appropriate fetch requests and indexing.

## 6. Audio format strategy

**Native first, evidence-based compatibility.** Build a stable `AudioEngine` interface and use AVFoundation for actually supported media. Validate files **by successful decoder playback**, not solely extension recognition.

Target matrix:

| Format | v1 approach |
|---|---|
| MP3 | Native backend; test on target OS/device |
| AAC / M4A | Native backend; test |
| ALAC | Native backend; test |
| WAV / AIFF | Native backend; test |
| FLAC | Verify native support on the exact OS/container; otherwise evaluate decoder |
| Ogg Vorbis / Opus | Evaluate compatible third-party decoding backend only if needed |

An optional decoder (possibly MobileVLCKit or another maintained library) must pass checks for iOS 15 compatibility, A10/arm64 compatibility, binary size, performance, licensing, distribution and playback-state coordination. Do **not** introduce a heavyweight dependency before native playback works. If a desired format remains unsupported, show an honest error and record it in `CODEC_SUPPORT.md`.

Keep one coherent public playback interface regardless of backend. Avoid loading full audio into memory when streaming is supported.

## 7. Playback and operating-system integration

Provide a single, long-lived `PlaybackCoordinator` owning the active engine, playback state, queue and system integration. Views subscribe to state; they do not instantiate independent audio engines.

Required: play/pause, seek/scrub, next/previous, queue order, play-next/add-to-queue, shuffle, repeat off/one/all, album/playlist playback, natural end-of-track advance and deterministic handling of rapid input. Persist last track, playback position, queue and repeat/shuffle state; on launch restore without unexpectedly auto-playing sound.

Configure `AVAudioSession` for media playback and the legitimate background audio mode. Integrate `MPRemoteCommandCenter` and `MPNowPlayingInfoCenter` with correct title, artist, artwork, duration, elapsed time and playback rate. Handle phone/system interruptions, headphone unplug, output route changes, unavailable files and decoder errors. Do not use silent-audio/background-execution hacks.

## 8. Lyrics — local files only

Support:

- Embedded **plain lyrics** from supported metadata fields.
- External UTF-8 `.lrc` adjacent to the audio file, matched conservatively by basename; optional encoding fallback.
- Embedded timestamped/synchronized lyrics **only when the selected metadata parser supports them and tests verify them**.

LRC parser must accept `[mm:ss.xx]` timestamps, multiple timestamps per line, common header fields and offset metadata; handle empty/malformed lines gracefully. Synchronize highlighting to **audio playback time**, including seeks and pauses. Allow manual scroll and tap-to-seek on timed lines. Never invent sync data for ordinary plain lyrics. Do not search or download lyrics online.

## 9. M3U / M3U8 and native playlists

Import local `.m3u` and `.m3u8` files. Handle extended M3U metadata, LF/CRLF, BOM where relevant, Unicode, relative paths, imported absolute paths and unresolved paths. Resolve relative paths against playlist location; use registered source roots for unambiguous fallback resolution. Preserve entry order and intentional duplicates. Keep missing tracks visible as unavailable rather than silently replacing them with guessed matches. Remote playlist URLs are out of scope.

Create/rename/edit/reorder/delete **app-local** playlists; support Play All and shuffle. Persist playlist entries against stable track identities. Deleting an in-app playlist must not delete any music files. Do not modify source M3U files without a separate deliberate export feature.

## 10. Architecture and engineering constraints

Recommended stack:

| Layer | Choice |
|---|---|
| App/UI | Swift, SwiftUI, selective UIKit integration |
| State organization | MVVM + focused observable models |
| Playback | AVFoundation; optional verified codec adapter |
| System media | AVAudioSession, MediaPlayer |
| File access | FileManager, UIDocumentPickerViewController, bookmarks |
| Metadata | Native extraction + targeted parser when needed |
| Persistence | Core Data |
| Async work | Swift concurrency compatible with iOS 15 |
| Dependency management | Swift Package Manager where feasible |
| Testing | XCTest, XCUITest, manual device QA |

Suggested service responsibilities: `LibraryScanner`, `MetadataService`, `ArtworkCache`, `LibraryRepository`, `PlaylistService`, `LyricsService`, `AudioEngine`, `PlaybackCoordinator`.

Keep SwiftUI views presentation-focused, use protocols where they enable meaningful tests and avoid elaborate dependency-injection systems or abstractions for future online features.

## 11. Performance and accessibility

Performance target is a **responsive A10-powered iPod**, not a recent flagship iPhone. Use lazy list rendering, bounded metadata workers, thumbnail caching with eviction, batch writes and background parsing. Minimize idle CPU and timers, especially when paused. Avoid animation-heavy backgrounds, repeated full artwork decoding and scanning on every launch. Measure rather than claim launch time, scrolling FPS, memory or battery performance.

Respect VoiceOver, Dynamic Type where practical, semantic labels, system contrast, safe areas, adequate touch targets and the narrow display. Check landscape only if deliberately supported; portrait-first is sufficient.

## 12. Testing and release acceptance

### Automated tests

- Folder enumeration, nested directories, overlapping sources, partial scans, revoked/stale bookmarks, cancellations and source removal.
- Metadata fallbacks, album/disc sorting, cache behavior and library persistence.
- M3U/M3U8 paths, encodings, duplicate entries, Unicode, unresolved/malformed lines.
- LRC timestamps, offsets, multi-timestamps, seeking and malformed content.
- Queue transitions, shuffle/repeat modes, missing-file recovery and playback-state restoration.
- UI smoke tests for first launch, library navigation/search, Now Playing and playlist editing.

Use deterministic local fixtures and mock OS services when genuine automation isn't feasible. Run real-media playback tests separately.

### Real-device manual QA — iPod touch 7th gen

- Launch and navigate on the actual 4-inch screen.
- Import multiple folders and rescan after adding/removing tracks.
- Restore folder access after relaunch and report unavailable provider files.
- Run common-codec sample files and document every format that truly works.
- Lock screen while playing; use Control Center, headphone and Bluetooth controls.
- Seek, rapidly switch tracks, exhaust a queue, shuffle and repeat.
- Verify lyrics synchronization and relative-path playlist import.
- Exercise a library of hundreds/thousands of tracks and observe memory, responsiveness and battery.
- Validate offline behavior with network connectivity disabled.

**Definition of done:** The app builds with minimum deployment target iOS 15.0, reliably indexes local selected folders, retains the indexed library, browses and plays **verified** supported audio files, integrates system background controls, handles M3U/M3U8, displays local lyrics, preserves user playlists and fails safely on missing/revoked files. Any unverified device-level behavior must be explicitly identified.

## 13. Implementation sequence for Codex

**Phase A — Establish a working foundation**  
Inspect existing repository, installed Xcode/SDK/simulator/MCP tools. Create or update the normal Xcode project, confirm iOS 15 deployment settings, build native navigation/empty states and demonstrate real sample-file playback.

**Phase B — Local library**  
Implement source picker/bookmarks, app-owned Music folder, background scanner, metadata extraction, Core Data and indexed library screens. Build and test.

**Phase C — Reliable playback**  
Implement queue, shuffle/repeat, mini-player, Now Playing, background audio, remote commands, interruption handling and restoration. Build and test.

**Phase D — Organization and lyrics**  
Implement playlists, local search, favorites, M3U/M3U8 and local plain/synchronized lyrics. Build tests for parsers. Build and test.

**Phase E — Compatibility and QA**  
Verify the codec matrix, add third-party decoding only if justified, optimize on older hardware, test source failure cases and run available simulator/physical-device QA.

Keep a buildable project after each phase. Fix observed compiler/test failures before progressing. Never present mock screens as working integrations.

### Environment and MCP instructions

Inspect installed Xcode version, iOS SDKs, iOS 15 simulator availability, code-signing prerequisites and discoverable Xcode-related MCP capabilities. Use working MCP integration if available; otherwise use `xcodebuild`, `xcrun simctl` and native tests. **Do not fabricate tools, simulator availability or successful tests.** A later iOS simulator with iOS 15 minimum deployment target does not prove actual iOS 15 runtime compatibility; physical iPod verification remains a separate gate.

## 14. Required repository artifacts

- `README.md` — run/build instructions, setup, file transfer and operational limitations.
- `ARCHITECTURE.md` — key components, source/bookmark lifecycle, playback/data flow.
- `CODEC_SUPPORT.md` — actual decoder/backend, format/containers, tested status and limitations.
- `TESTING.md` — test commands, fixtures, results and physical iPod QA checklist.
- `ROADMAP.md` — only future optional metadata/cover/lyrics online enrichment, without v1 implementation.
- Native Xcode project, Swift sources, executable tests and legally usable test media fixtures.

## 15. Final instructions to Codex

**Implement rather than only proposing architecture.** Inspect the repository and development environment first. Make pragmatic decisions and continue in small, working increments. Favor native UI, offline integrity, stable playback and code maintainability over breadth. Build, run available tests, fix failures and explicitly differentiate verified features from unverified ones. Do not add any login, cloud, backend, networking or future-enrichment scaffolding. Begin with **Phase A** and produce a runnable iOS 15-targeted application.
