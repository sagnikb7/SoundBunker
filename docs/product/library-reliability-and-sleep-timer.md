# Library reliability and sleep timer

## Findings and plan — 13 October 2026

The original scan starts on first RootView appearance and on every active scene transition after 120 seconds. Import, add/reconnect, enable, exclusions and explicit rescan also trigger it. All enabled roots are recursively enumerated. Size/mtime and lyric fingerprints reuse metadata, but every file publishes UI progress and each 25-file batch rebuilds merge indices even when unchanged. Core Data merges run on the main actor. Artwork decoding expands full embedded images before resizing.

Implement in order:
1. Keep cached browsing immediate. Scan once per process launch; never scan just because the screen unlocks. Imports scan the owned source; source changes scan affected sources. Manual rescan remains available for Finder/Files changes during a session. Cancel enumeration when backgrounded. Do not mark tracks missing after incomplete enumeration or file access errors.
2. Coalesce progress to at most four updates/second, send only changed records, keep bounded merge batches. Downsample embedded artwork directly with ImageIO instead of expanding original pixels.
3. Explicit after-first-unlock protection for owned audio and the database; preserve external provider permissions. Coordinate decoder opening, translate permission errors into recovery steps, guard stale session deactivation, recover safely from media-services resets. Background audio entitlement and playback category already exist. These are hardening changes, not proof of the reported crash cause.
4. Keep GitHub/version in About and Remember Position in Playback Preferences. Keep contextual folder rescans because their scope differs from Rescan Library.
5. Add sleep timer from Now Playing's header. Presets 5/10/15/20/30/45/60 minutes, End of Song and End of Queue. Finite queues reject presets exceeding known remaining playable duration (including elapsed position). Unknown durations allow end-based choices only. Repeat permits timed presets; End of Queue overrides repeat at the final entry, End of Song overrides repeat-one. Timer uses a monotonic elapsed deadline, including pauses; it is checked before resume and track transitions. Queue replacement cancels the timer; adding songs does not extend timed deadlines. No timer survives process restart. Natural queue exhaustion cancels it. No audio fade in this release.

## Acceptance and validation

- A 500-file unchanged scan emits bounded progress, no track batches, and preserves identity/favorites/playlists. Cancellation/incomplete access never marks unseen songs deleted.
- Unlock/resume does not automatically start scanning. Explicit scans remain available; import discovers only the owned source.
- Timer rejects overlong or invalid values, expires while paused before resume, stops repeat at the requested boundary, and cancels on queue replacement.
- Run native Release regressions, workflow tests, repository checks and unsigned iphoneos compilation.
- Physical iPod gate: 500 actual songs, scrolling while scanning, lock during playback for 10+ minutes through multiple track boundaries, repeat/timer expiry while locked, headphone disconnect and interruption. Capture crash/JetsamEvent logs and Instruments memory/main-thread traces if termination recurs. Desktop tests cannot certify these outcomes.

## Error -54

Treat NSOSStatusErrorDomain -54 as permission/access failure, not evidence of a codec issue or proof of the crash cause. Recovery copy is specific to file access and retains the domain/code for diagnosis. Never silently delete or replace music.

## Subsequent startup optimization — 13 October 2026

The earlier once-per-launch full scan is superseded by persistent directory checkpoints. Unchanged owned folders need directory metadata checks only; changed/missing checkpoints defer scanning until playback stops and the app is foregrounded. Providers and in-place metadata/lyric edits use explicit rescan. Checkpoints survive restart and are not advanced by cancellation or incomplete scans. The first upgrade to checkpoints requires one successful local scan. See [architecture](../engineering/architecture.md) and README's media sync table for current triggers.
