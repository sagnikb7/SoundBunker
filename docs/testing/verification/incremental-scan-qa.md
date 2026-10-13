# Persistent directory check verification

13 October 2026. Replaces the prior once-per-launch full scan policy.

## Executed evidence

The native Release Catalyst suite passed **53 tests, zero failures**. Python release workflow suite passed **18 tests**. Log files: `/tmp/cassette-incremental-scan-tests.log` and `/tmp/cassette-incremental-workflow-tests.log` (outside Git).

- 500 actual fixture files indexed into a disk database; reopen and startup discovery caused **zero scans** and zero checked-audio publications while preserving all 500 records.
- A new file in an already indexed nested album directory caused exactly one source scan and produced 501 records. Calling discovery again in the same session did not rescan.
- Pending automatic discovery did not start during playback or while backgrounded; becoming idle/foreground permitted it. Explicit cancellation cleared pending work.
- Cancelled manual scanning did not advance the checkpoint. A true in-place lyric edit left directory timestamps unchanged and was refreshed through explicit rescan.
- Changed external-source files did not cause startup probing. An explicit per-source rescan discovered them.
- Existing incomplete-scan, library organization, playback, sleep timer and widget regressions passed.

One initial test simulated an in-place edit by writing and restoring a folder timestamp. That restoration changed timestamp precision, legitimately triggering a scan. The fixture was corrected to truncate/write through FileHandle, retaining the real directory timestamp; the final test verifies that timestamp and passes.

## Boundaries

Directory stamps are not a complete filesystem journal. Existing file content/tag/lyric edits may not change a parent directory. Files/Finder transfers during the current session and provider changes need explicit refresh. Startup does not traverse provider roots. The first launch without a checkpoint requires a successful initial local scan. Directory additions/deletions/renames are detected through a known ancestor; changed sources still enumerate entries to reconcile their content. Checkpoints commit only after complete reliable enumeration.

This verifies behavior on Mac Catalyst with test WAVs. It does not establish A10 timings, battery consumption, physical iPod responsiveness or resolution of the previously reported crash/widget failures.

The latest retro rainbow PNG is preserved unmodified; current app/README icons and both widget marks match their expected derived assets. Native widget captures show the replacement logo.
