# Product decisions

## SoundBunker

Name selected by the user on 12 October 2026. The basic logo is an original white sound-bar mark sheltered by a bunker arch on a blue field. The prior Pocket Music working name is removed from visible UI. Internal Xcode target/bundle identifiers and existing database/cache locations remain stable so renaming does not reset users' data.

## Usable local-first library

The supplied prototype informs navigation, spacing and system styling; its catalog/artwork/statistics are illustrative and are never shipped. The test tone was moved entirely to test fixtures. The app starts with actions to add folders/import actual audio rather than playback diagnostics.

## Automatic discovery and restrictions

Scan the app-owned Documents directory and enabled previously granted source roots on opening/foreground. Skip unchanged metadata by fingerprint; use bounded background work and incremental results. No always-on/background directory watcher is promised.

The On My iPod location is a Files UI grouping, not an unrestricted root. Access to other apps' local folders requires explicit directory selection through Apple's picker. Source switches and excluded subfolder paths allow users to restrict scans. Excluded tracks remain indexed for data preservation but are hidden from library browsing; independent permitted source memberships still work. Reconnection retains restrictions.

External unknown File Provider storage and cloud-only iCloud files are refused conservatively. File import is an explicit copy action, unlike folder registration, which indexes originals in place. Neither source removal nor playlist deletion removes audio files.

## Build preferences

Every create build request returns an unsigned Release IPA plus a ZIP containing it. This preference is saved in repository instructions and implemented by the build script. Signing and physical installation are separate actions requiring a working installer/account setup.
