# SoundBunker

**Your music. Your pocket.** A native, offline music player for iPod touch (7th generation), targeting iOS 15.0. Built with SwiftUI, Core Data and AVFoundation; no accounts, streaming, analytics or network dependencies inside the app.

## Use the app

1. Open SoundBunker. It automatically scans audio in its own Files folder and any enabled folders you've previously added.
2. Tap **Add Music Folder**, choose **Browse → On My iPod**, and select a local folder. iOS grants access to that folder; SoundBunker remembers it and scans recursively.
3. Or tap **Import Audio Files** to explicitly copy selected local audio into SoundBunker. Imported files and Finder transfers are found automatically on the next scan.
4. Browse Songs, Albums, Artists, Genres or Folders. Tap a song to play; tap the mini-player to open Now Playing. Create playlists, mark favorites, search, queue songs or view local lyrics.
5. In **Settings → Music Folders**, open a source to disable it or exclude specific subfolders. Exclusions persist and apply to future automatic scans. Files are never deleted by source removal or exclusion.

**No `Documents/Music` setup is required.** The actual device location is **Files → On My iPod → SoundBunker**, created by the app. The whole app Documents directory is scanned, including nested folders. “On My iPod” is a Files browser location, not a globally accessible filesystem directory: other apps' folders must be selected once with the system picker. Cloud-only files are skipped; unverifiable external File Provider storage is conservatively refused.

The app contains **no test tone or demo music**. Artwork and metadata come from your files; missing artwork uses a music-note placeholder. Embedded plain lyrics and matching adjacent UTF-8 `.lrc` files are read locally. Decoder compatibility and background controls still need actual iPod verification.

## Build and install

- [Connect, sign and install on your iPod](docs/build/ipod-installation.md)
- [Create an IPA and ZIP](docs/build/build-artifacts.md)
- [Versioning and release notes](docs/build/versioning.md) · [Changelog](docs/product/changelog.md)
- [GitHub CI and artifact downloads](docs/build/continuous-integration.md)
- [Run tests and review verification limits](docs/testing/testing.md)

Open `OfflineMusicPlayer.xcodeproj` and select the **OfflineMusicPlayer** scheme. The internal target name remains stable; the installed app name and icon are **SoundBunker**. The Mac Catalyst target previews the same SwiftUI and library code on the desktop.

Whenever you request **“create build”**, the project workflow produces both `dist/SoundBunker-unsigned.ipa` and `dist/SoundBunker-unsigned.ipa.zip`. This preference is saved in [AGENTS.md](AGENTS.md).

## Project layout

```text
OfflineMusicPlayer.xcodeproj/       Native Xcode project and shared scheme
OfflineMusicPlayer/
  Assets.xcassets/                  App icon
  Library/                         Models, Core Data store, scanner, folder policy
  Playback/                        Native engine and playback coordinator
  Views/                           SwiftUI screens and system document picker
  Resources/                       Offline release notes
OfflineMusicPlayerTests/
  Fixtures/                        Test media; never shipped in the app
scripts/                           Build, packaging, release tests, icon and fixture utilities
release/                           Version manifest and pending release notes
docs/
  product/                         Product spec, decisions and roadmap
  engineering/                     Architecture and implementation status
  design/                          Prototype mapping and visual QA
  testing/                         Test instructions, results and evidence
  build/                           Installation and artifact instructions
offline-music-player-prototype/     Original user-supplied visual references
dist/                              Generated IPA and ZIP outputs (ignored by Git)
```

## Scope and remaining work

This version implements local folder/file intake, automatic incremental metadata scans, source exclusions, a persisted library, favorites/user playlists, local search, queues/shuffle/repeat, playback restoration without autoplay, and local lyrics. M3U/M3U8 import, deeper codec-specific metadata parsing, queue reordering and physical iPod performance/format certification remain tracked in [the implementation plan](docs/engineering/implementation-plan.md). Final validation: **16 Catalyst tests passed**, Release iphoneos build and IPA/ZIP checks passed. See [build receipt](docs/testing/verification/final-build.md). Physical iPod execution is still pending.

See [codec evidence](docs/testing/codec-support.md); candidate extensions are not a verified support guarantee.

The original [product specification](docs/product/offline-music-player-spec.md) and [design mapping](docs/design/prototype-mapping.md) explain the intended final v1 behavior.

## Player polish

Now Playing keeps seek, transport, Shuffle, Repeat and Lyrics in a fixed dock; artwork/metadata/queue/lyrics use the remaining space. Its options menu adds the current song to playlists. Manual additions are duplicate-safe, and existing entries show checkmarks in the song chooser and playlist picker.

The surface tint uses album artwork rotated 180 degrees and heavily blurred from a thumbnail of at most 64 pixels. Rendering runs off the main actor and is cached (16 images); there is no continuous blur or extra playback timer. Reduce Transparency uses the plain system background. The mini-player drops its tab-bar offset while the keyboard is visible.

Playlist selection rows show cached album thumbnails, song title/artist and a +/checkmark. Tap again to undo membership; this applies to Add Songs and the Now Playing playlist chooser. Existing duplicate records are fully removed when deselected.

## Settings and responsiveness

Settings groups music sources, playback, appearance, library statistics, artwork storage and About. Cache clearing asks for confirmation and keeps music, favorites and playlists. Version/build and offline What's New are available inside the app. The release workflow tracks changes in the Markdown changelog before delivery.

Song lists use compact spacing with 44-point controls. Browsing and playback use cached sorting and track lookups; scans publish changed tracks in batches and skip unchanged records. Lyrics parse once when the song changes. Cache deletion runs off the main actor. The new opaque app icon is a static asset. Physical iPod frame-rate, memory and battery measurements remain pending.
