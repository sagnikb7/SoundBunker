# Recently Played verification

Date: 12 October 2026. Implementation tasks are recorded in [implementation status](../../engineering/implementation-plan.md). The feature is included in pending minor-release notes; no new version or packaged export has been finalized.

## Results

- Native Release Mac Catalyst: **41 tests, 0 failures, TEST SUCCEEDED**. Log: `/tmp/cassette-history-tests.log`.
- Final focused Library/history render test: **1 test, 0 failures, TEST SUCCEEDED**. Log: `/tmp/cassette-history-render-tests.log`.
- Python release/build workflow: **18 tests, 0 failures**. Log: `/tmp/cassette-history-workflow.log`.
- Unsigned Release iPhoneOS app/widget compilation: **BUILD SUCCEEDED**. Log: `/tmp/cassette-history-device.log`.
- `git diff --check`: passed.

History tests use isolated fixture folders and an isolated SQLite store. They verify successful playback starts, natural queue advancement/repeat-one, pause/resume deduplication, silent restoration, cancelled activation, failed playback, newest-ten entries with unique event identities, retained full history beyond ten events, real SQLite reopening and source exclusion/re-enable without losing history. The repeat-one test awaits the asynchronous history event rather than the already-playing state.

## Visual evidence

The [Library render](recently-played-library.png) was inspected at 320-point width with a taller 820-point capture to expose the below-the-fold section. Recently Played retains the horizontal 112-point artwork tiles, 12-point spacing, title/artist typography and shows a trailing chevron on its navigable header. The [history render](recently-played-history.png) was inspected at 320×548: artwork, song titles, artists, timestamps and song options fit. Test tracks use the normal missing-art fallback; real album art uses the existing cached artwork view.

## Limits

This is native desktop UIKit/Catalyst and iPhoneOS compilation evidence. Physical iPod scrolling, navigation, tap behavior and relaunch/provider-folder history remain device QA. History begins empty on upgrade and records future successful plays; earlier playback cannot be reconstructed from import dates. No IPA was exported or installed.
