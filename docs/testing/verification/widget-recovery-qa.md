# Widget recovery and verification

13 October 2026. User reports both Home Screen widget sizes remain entirely black after unlock and opening Cassette; installation was through Sideloadly. The re-signed extension and installed provisioning have not been inspected.

## Findings and changes

The provider previously used a `.never` timeline and the app requested reloads only when metadata changed. A failed/stale entry therefore had no scheduled recovery opportunity, and relaunch with unchanged metadata could suppress recovery. Missing/corrupt snapshot data was indistinguishable from a valid empty snapshot during publishing. Widget artwork used unrestricted UIImage file decoding; compressed byte limits did not bound decoded pixel memory. Snapshot file protection was implicit, and Settings exposed no refresh/status action.

The provider now requests a timeline after 30 minutes (a system-scheduled opportunity, not a guaranteed deadline). App launch after restoration and manual Refresh Widgets force a snapshot write/reload, even for unchanged data. Missing/corrupt empty snapshots are repaired. Shared directory/data use after-first-unlock protection on iOS. Artwork names hash content, decoder input rejects oversized files/symlinks, and ImageIO limits decoded covers to 320 pixels. Missing/corrupt covers retain title and the visible music-note fallback. Settings reports write failures or missing shared storage without claiming provisioning is verified.

Missing App Groups alone should display the Cassette/Open Library fallback, not an entirely blank card. A black block can also reflect an extension that cannot launch or render, signing/provisioning problems, memory termination, or a stale system render. No device extension log has established which caused this report. The SDK's contentMarginsDisabled implementation has an iOS 17 runtime guard and returns unchanged configuration on iOS 15; it is not an unguarded iOS 17 call.

## Validation

Automated results and package receipt are recorded after execution in [final build](final-build.md). Tests cover valid/missing/corrupt snapshots, forced recovery, unchanged-write suppression, content-based cover identity, bounded decoding, unsafe/broken cover fallback, retention, deep links, and native square/medium empty/populated cards. Native Catalyst card tests do not execute the iOS WidgetKit extension host.

## Physical iPod acceptance

1. Install app and embedded extension signed by the same team with matching App Group provisioning. Verify both signatures/profiles if using a signing tool.
2. Unlock, launch Cassette and play a local song. Settings → Widgets → Refresh Widgets should report shared data ready. This reports successful storage access, not complete signing verification.
3. Remove and re-add both sizes if an old black render persists. With no track, both should show Cassette and Open Library; with a track, title/artist should remain visible even without artwork.
4. Change tracks, lock/unlock, relaunch on the same song and confirm recovery. Test an unavailable cover and a fresh install without shared storage; fallback must remain legible if the extension launches.
5. If still black, collect the CassetteWidget extension crash/JetsamEvent logs and signing/profile evidence. Do not classify desktop screenshots or IPA compilation as a passed Home Screen test.
