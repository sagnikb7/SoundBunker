# Feature expansion QA

Date: 12 October 2026. Packaged release: **1.2.0 (8)**. Release IPA and ZIP passed integrity/device-resource validation; release notes are finalized in the manifest and changelog. See [build receipt](final-build.md).

## Executed checks

- Native Mac Catalyst XCTest: **27 tests, zero failures; TEST SUCCEEDED**. The pre-push run also passed all 27 under Release optimization, with testability enabled and hardened runtime disabled only for the ad-hoc desktop test invocation.
- Python release/packaging/project-link tests: **ten tests, zero failures**.
- Final Release iPhoneOS build plus static analysis: command completed successfully, **ANALYZE SUCCEEDED**. Built app is arm64, IOS, minimum 15.0; project metadata and release notes are bundled, test media/bundles absent.
- Read-only candidate checks verify finalized fingerprint matches shipping sources, manifest/version/notes, bundle identity, Markdown links and device resources.
- No analyzer findings. Xcode's AppIntents metadata-extraction warning remains because this app does not use AppIntents.

## New regression evidence

- M3U preserves ordered/duplicate local entries, normalizes separators/BOM, skips remote/escaping references and retains missing entries.
- A selected local folder with a File Provider Storage pathname is indexed; minimal bookmark resolution and imported playlist persistence/refresh keep their identities.
- A repeat scan creates no extra playlist; changed manifests update the same record. Foreground throttle avoids an immediate rescan while explicit scans remain available.
- Added/modified/removed LRC sidecars refresh the indexed song without changing its identity.
- Rapid Play/Pause cancels pending audio activation. Artwork-swipe Previous selects the prior track even beyond three seconds, rather than just restarting the current track.
- Clock events publish through PlaybackClock without general player object changes, avoiding library-consumer invalidation. No device FPS/battery claim is inferred.
- Artist matching rejects unrelated/ambiguous pages and supports musical bands/duos. Mocked HTTPS responses exercise the production client, image downsampling, creator/license/source caching, unknown provider fields, offline backoff and opt-out without losing cached photos.
- Live public Wikimedia search/ImageInfo queries for a generic artist returned free image metadata and attribution; the current thumb.wikimedia.org CDN is supported. Automated tests do not depend on Internet access.

## Native UI checks

Settings and About were opened in the actual Catalyst app. Verified the online-photo toggle/disclosure, installed candidate version and the GitHub link derived from origin. Clicking the About link opened `github.com/sagnikb7/SoundBunker` in the default browser (Helium).

[Timed lyric capture](lyrics-following.png) uses an attached native host and shows the active ninth line after opening at position eight seconds, proving the initial follow command occurs after layout. Spacing/highlight were visually reviewed. Player artwork/queue/lyrics render checks and Reduce Motion geometry checks continue to pass.

## Physical iPod checks remaining

- Select actual Files/provider folders, relaunch, revoke/reconnect grants and test offline cached audio.
- Exercise album swipes and far-left native back/modal dismissal, including nested navigation and conflicts with scrolling.
- Check lyrics follow, manual-scroll pause/Follow and tap-to-seek with real timed files and large text.
- Compare Play/Pause animation feel, rapid interactions, A10 memory/frame rate/battery and background/remote-command behavior.
- Confirm Wikimedia images/credit menu/lookup switch on the device. Missing/ambiguous photos remain placeholders.

The source implementation and desktop/device compilation are verified. Actual iPod touch behavior and performance are not certified by these checks. IPA and ZIP were packaged successfully. No upload, push or installation was performed.
