# Product decisions

## SoundBunker

Name selected by the user on 12 October 2026. The basic logo is an original white sound-bar mark sheltered by a bunker arch on a blue field. The prior Pocket Music working name is removed from visible UI. Internal Xcode target/bundle identifiers and existing database/cache locations remain stable so renaming does not reset users' data.

## Usable local-first library

The supplied prototype informs navigation, spacing and system styling; its catalog/artwork/statistics are illustrative and are never shipped. The test tone was moved entirely to test fixtures. The app starts with actions to add folders/import actual audio rather than playback diagnostics.

## Automatic discovery and restrictions

Scan the app-owned Documents directory and enabled previously granted source roots on opening, and on foreground only after a two-minute full-scan interval. Explicit user rescan/source/import actions bypass the foreground throttle. Skip unchanged metadata by fingerprint; use bounded background work and incremental results. No always-on/background directory watcher is promised.

The On My iPod location is a Files UI grouping, not an unrestricted root. Access to other apps' local folders requires explicit directory selection through Apple's picker. Source switches and excluded subfolder paths allow users to restrict scans. Excluded tracks remain indexed for data preservation but are hidden from library browsing; independent permitted source memberships still work. Reconnection retains restrictions.

Cloud-only iCloud audio is skipped; explicitly selected downloaded provider folders are allowed. The earlier blanket File Provider Storage path refusal was removed at the user’s request. Third-party providers control their own file availability. File import is an explicit copy action, unlike folder registration, which indexes originals in place. Neither source removal nor playlist deletion removes audio files.

## Build preferences

Every create build request returns an unsigned Release IPA plus a ZIP containing it. This preference is saved in repository instructions and implemented by the build script. Signing and physical installation are separate actions requiring a working installer/account setup.

## Artist-image exception to the original offline specification

On 12 October 2026 the user explicitly requested a free trusted artist-image API. Music, album art and lyrics remain local; artist photos may use public Wikimedia endpoints. Photos are enabled by default, fetched on demand for artist rows and cached with creator/license/source attribution. Artist names and normal network information are sent; audio and local paths are not uploaded. The switch stops new lookups but allows cached photos. Exact-name musical matches must be unique; ambiguous/missing/network-failed results use placeholders. This request supersedes the original spec’s prohibition on network enrichment for artist photos only.
