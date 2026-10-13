# Player and folder refinement QA

> Historical verification recorded before the Cassette rebrand. For the current release, see the [latest build receipt](final-build.md).

Date: 12 October 2026. Prepared source candidate: **1.2.1 (9)**. Release notes are pending; the last packaged IPA remains 1.2.0 (8). No new IPA, push, signing or installation was requested/performed for this refinement.

## Executed verification

- Native Release Catalyst XCTest: **32 tests, zero failures, TEST SUCCEEDED**. Testability is enabled and hardened runtime disabled only for the ad-hoc desktop test invocation.
- Python release/packaging/project-link tests: **ten tests, zero failures**.
- Final Release iPhoneOS compilation/static analysis: **ANALYZE SUCCEEDED**, no analyzer findings.
- Source/device validation: arm64, iOS 15.0 minimum, stable bundle identity, prepared version/notes/source fingerprint, icon and project metadata. Files/Finder sharing flags are true in source and compiled Info.plist. Test media and XCTest bundles are absent from the device app.
- Generated project stays synchronized; Markdown links and whitespace checks pass.

## Regression evidence

- Adding a provider-style folder during another scan cancels/serializes work, retains picker access, persists a resolvable bookmark and does not duplicate the source on repeated selection.
- Removing an external source during a scan cannot restore it from that scan’s snapshot. Saved source/location records are removed; audio, favorite identity and playlist references remain. Re-adding the folder restores the same song identity/favorite.
- Reconnection keeps source identity and scanning preference; a missing folder reports an error without adding a broken source.
- The transfer guide is created in Documents and ignored by audio indexing. Private database paths and bundle identity remain unchanged.
- A real native WAV fixture reports WAV/PCM and the exact 352800 bits/sec encoded rate (22.05 kHz, mono, 16-bit). Legacy Track JSON lacking the optional format/bitrate fields still decodes; unknown rates are displayed as unavailable.
- Scrubber range/accessibility, duplicate-begin/finish event handling, accessibility-style non-touch seeking and a 44-point hit surface pass native checks. iOS uses a cached 10-point thumb; Catalyst’s NSSlider ignores UIKit thumb images and uses its own knob. Device thumb appearance/touch still requires iPod confirmation.

## Visual review

Compact 320×548 [player](player-folder-artwork.png) and [queue](player-folder-queue.png) renders were inspected: white options, aligned metadata/seek, audio-quality footer, permanent secondary controls, denser 44-point queue rows and trailing shuffle/repeat. The [timed lyrics](player-folder-lyrics.png) capture shows tighter 32-point minimum rows and the active ninth line followed after initial layout. No Follow button or persistent manual-follow state remains. Larger text wraps intrinsically.

Menu source inspection confirms the full-player menu contains Artist, Album and Add to Playlist; all shared song rows add Artist/Album destinations while preserving their queue/favorite actions. Original user design references remain intact.

## Physical checks remaining

- Install/sign on the actual iPod; select a real Files/provider folder, relaunch and reconnect after revocation. Desktop provider-style paths do not prove iOS permission behavior.
- Connect/trust the iPod in Finder, locate Files → Cassette, drag audio, then reopen/rescan. File-sharing flags cannot prove pairing or a transfer occurred.
- Drag the small seek thumb, cancel a scrub, exercise VoiceOver seeking, open menus/destinations, and check large text in player/queue/lyrics.
- Verify auto-follow while songs advance, after manual scrolling and backward seeking; measure A10 frame rate/battery using real music.

Xcode 27’s XCTest libraries target newer runtimes than iOS 15; desktop test execution does not certify iOS 15. AppIntents metadata extraction is skipped because the app has no AppIntents dependency. Desktop UI-host/accessibility diagnostic warnings are not device evidence.

## Polish pass checks (pending device verification)

- Drag Now Playing artwork left/right: next/previous fires, short drags return; edge-back gesture still dismisses.
- Scroll any song list to the end with a track loaded: the last row sits fully above the mini player.
- Open a song list with a long artist name: the title scrolls with faded edges and the count stays visible.
