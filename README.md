# SoundBunker

**Your music. Your pocket.** A native, offline music player for iPod touch (7th generation), targeting iOS 15.0. Built with SwiftUI, Core Data and AVFoundation; no accounts, streaming or app analytics. Music stays local; optional artist photos use Wikimedia and are cached offline.

## Use the app

1. Open SoundBunker. It automatically scans audio in its own Files folder and any enabled folders you've previously added.
2. Tap **Add Music Folder**, choose **Browse → On My iPod**, and select a local folder. iOS grants access to that folder; SoundBunker remembers it and scans recursively.
3. Or tap **Import Audio Files** to explicitly copy selected local audio into SoundBunker. Imported files and Finder transfers are found automatically on the next scan.
4. Browse Songs, Albums, Artists, Genres or Folders. Tap a song to play; tap the mini-player to open Now Playing. Create playlists, mark favorites, search, queue songs or view local lyrics.
5. In **Settings → Music Folders**, open a source to disable it or exclude specific subfolders. Exclusions persist and apply to future automatic scans. Files are never deleted by source removal or exclusion.

**No `Documents/Music` setup is required.** The actual device location is **Files → On My iPod → SoundBunker**, created by the app. The whole app Documents directory is scanned, including nested folders. “On My iPod” is a Files browser location, not a globally accessible filesystem directory: other apps' folders must be selected once with the system picker. Cloud-only iCloud files are skipped. Selected local/provider folders are supported without a blanket path restriction; download provider audio in Files first.

The app contains **no test tone or demo music**. Album artwork and song metadata come from your files; missing artwork uses a music-note placeholder. Embedded plain lyrics and matching adjacent UTF-8 `.lrc` files are read locally. Decoder compatibility and background controls still need actual iPod verification.

## Build and install

- [Connect, sign and install on your iPod](docs/build/ipod-installation.md)
- [Create an IPA and ZIP](docs/build/build-artifacts.md)
- [Versioning and release notes](docs/build/versioning.md) · [Changelog](docs/product/changelog.md)
- [GitHub CI and artifact downloads](docs/build/continuous-integration.md)
- [Run tests and review verification limits](docs/testing/testing.md)

From the repository root, run these commands (macOS with full Xcode installed):

```sh
# Verify release tooling and repository consistency
python3 -m unittest discover -s scripts/tests -v
python3 scripts/verify_repository.py

# Run native Release regression tests on this Mac
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -configuration Release -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath /tmp/SoundBunkerTests \
  ENABLE_TESTABILITY=YES ENABLE_HARDENED_RUNTIME=NO CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual test

# Build the device app and package both versioned artifacts
./scripts/create_build.sh
```

The build script prepares the release version, compiles Release iphoneos arm64 with an iOS 15.0 minimum, creates the IPA and ZIP, then finalizes the changelog after successful packaging. Validate the resulting packages using the version printed by the script:

```sh
python3 scripts/verify_repository.py \
  --app /tmp/PocketMusicRelease/Build/Products/Release-iphoneos/OfflineMusicPlayer.app \
  --ipa dist/SoundBunker-unsigned-1.2.0.ipa
```

The IPA is unsigned: sign/provision it before installing on an iPod. Extract the ZIP if your signing tool expects an IPA. Generated packages stay outside Git. See the linked installation guide for device setup and signing options.

Open `OfflineMusicPlayer.xcodeproj` and select the **OfflineMusicPlayer** scheme. The internal target name remains stable; the installed app name and icon are **SoundBunker**. The Mac Catalyst target previews the same SwiftUI and library code on the desktop.

Whenever you request **“create build”**, the project workflow produces both `dist/SoundBunker-unsigned-<version>.ipa` and `dist/SoundBunker-unsigned-<version>.ipa.zip`. This preference is saved in [AGENTS.md](AGENTS.md).

## Project layout

```text
OfflineMusicPlayer.xcodeproj/       Native Xcode project and shared scheme
OfflineMusicPlayer/
  Assets.xcassets/                  App icon
  Library/                         Models, Core Data store, scanner, folder policy
  Metadata/                        Optional artist-photo lookup and attribution cache
  Playback/                        Native engine, playback clock and coordinator
  Views/                           SwiftUI screens and system document picker
  Resources/                       Release notes and public project metadata
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

This source version implements M3U/M3U8 discovery, optional artist photos, local folder/file intake, automatic incremental metadata scans, source exclusions, a persisted library, favorites/user playlists, local search, queues/shuffle/repeat, playback restoration without autoplay, and local lyrics. Deeper codec-specific metadata parsing and queue reordering and physical iPod performance/format certification remain tracked in [the implementation plan](docs/engineering/implementation-plan.md). Latest feature validation: **27 Catalyst tests and ten workflow tests passed**; see [feature QA](docs/testing/verification/feature-expansion-qa.md). The latest packaged release is **1.2.0 (8)**, with verified versioned IPA and ZIP artifacts. See [build receipt](docs/testing/verification/final-build.md). Physical iPod execution is still pending.

See [codec evidence](docs/testing/codec-support.md); candidate extensions are not a verified support guarantee.

The original [product specification](docs/product/offline-music-player-spec.md) and [design mapping](docs/design/prototype-mapping.md) explain the intended final v1 behavior.

## Player polish

Now Playing keeps track details/options, seek, transport and a Lyrics/Favorite/Queue row in a fixed dock. Artwork, queue and lyrics use the remaining space. Playing Next contains Shuffle and Repeat above its scrollable song list. The song options menu sits beside the title/artist above the seek bar and adds the current song to playlists. Manual additions are duplicate-safe, and existing entries show checkmarks in the song chooser and playlist picker.

The surface tint uses album artwork rotated 180 degrees and heavily blurred from a thumbnail of at most 64 pixels. Rendering runs off the main actor and is cached (16 images); there is no continuous blur or extra playback timer. Reduce Transparency uses the plain system background. The mini-player drops its tab-bar offset while the keyboard is visible.

Playlist selection rows show cached album thumbnails, song title/artist and a +/checkmark. Tap again to undo membership; this applies to Add Songs and the Now Playing playlist chooser. Existing duplicate records are fully removed when deselected.

## Settings and responsiveness

Settings uses the earlier simple grouped layout with Music Library, Playback, Storage and About, retaining direct playback-position, appearance and safe cache-clear controls alongside statistics and playback preferences. Cache clearing asks for confirmation and keeps music, favorites and playlists. Version/build and offline What's New are available inside the app. The release workflow tracks changes in the Markdown changelog before delivery.

Song lists use compact spacing with 44-point controls. Browsing and playback use cached sorting and track lookups; scans publish changed tracks in batches and skip unchanged records. Lyrics parse once when the song changes. Cache deletion runs off the main actor. The new opaque app icon is a static asset. Physical iPod frame-rate, memory and battery measurements remain pending.

## Visual feedback

Now Playing gently expands artwork to full size on Play and contracts it to 90% on Pause. The frame stays fixed, preserving control alignment. Player, mini-player and song-row buttons provide brief press feedback; Lyrics, Queue and Favorite show subtle selected-state highlights. Reduce Motion disables scaling and animated transitions while retaining immediate visual state changes. No haptics or continuous animation loops are used. The playback request starts artwork feedback before audio-session activation, and the artwork transition lasts 180 ms.

## Playlists, lyrics, navigation and artist images

M3U/M3U8 files inside enabled music folders become playlists automatically during scanning. Paths are resolved relative to the playlist, in order, including intentional duplicate entries. Missing/excluded entries stay listed as unresolved; remote URLs and references outside that granted root are skipped. Rescanning updates imported lists from their files without creating another playlist. For a portable import, add the folder containing both playlist and music, or copy both into SoundBunker while keeping the relative structure.

Timed lyrics use closer line spacing, a smooth active-line transition and automatic following. Drag to browse older lines; tap **Follow** to resume. Adding/changing an adjacent LRC is detected on a scan. The song menu opens Artist/Album pages; swipe artwork left for next, right for previous. The far-left edge is reserved for navigation back or modal dismissal where a previous destination exists.

Artist photos are optional and enabled by default. On-demand Wikipedia/Wikimedia lookups send artist names and normal connection information, never audio files. Only a unique matching musical artist and free licensed image are used. Long-press an artist row for **Photo Credit**. Disable **Settings → Online Artist Photos** to stop new lookups; cached photos stay available. See [metadata and playlist policy](docs/engineering/metadata-and-playlists.md).

Foreground scans are throttled to one full scan per two minutes; explicit rescans/imports/source changes still work immediately. Browsing is cached, clock updates no longer invalidate library views, and polling runs at 5 Hz only for visible timed lyrics, 2 Hz for the visible player and 0.5 Hz when the player is closed. No polling runs while paused.
