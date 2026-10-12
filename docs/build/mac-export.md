# Native Mac export verification

Date: 12 October 2026. Candidate: Cassette 1.3.0 (9). An independent agent verified the existing target without changing source, project settings, release version or Git state for Mac support.

## Result

The existing app builds and launches natively through **Mac Catalyst**. It is not an iOS simulator or an iPhone app running through emulation, and it is not a separate AppKit rewrite. [Apple describes Catalyst as UIKit running on macOS](https://developer.apple.com/help/account/capabilities/create-a-mac-version-of-an-ipad-app).

Verified Release app: `/tmp/CassetteMacAudit/Build/Products/Release-maccatalyst/OfflineMusicPlayer.app`. Build log: `/tmp/CassetteMacAudit.log` (local, ignored). Universal Mach-O architectures are arm64/x86_64, platform MACCATALYST. Actual macOS minimum from `LSMinimumSystemVersion` is **12.0**; the binary’s Catalyst `minos 15.0` is its iOS compatibility version. Strict/deep ad-hoc signature verification passed. Host launch ran the exact executable as PID 14762. Intel architecture is included; this does not prove execution on an Intel Mac.

## Local build command

From the repository root:

```sh
./build --platform=mac
# Equivalent: ./scripts/create_build.sh --platform=mac
```

Outputs are `dist/Cassette-<version>-mac.app` and `.app.zip`. The script prepares release metadata, builds Release universal Catalyst, verifies the copied app/signature/resources, creates a metadata-preserving ZIP, then finalizes the release. `CASSETTE_MAC_DERIVED_DATA` overrides its default `/tmp/CassetteMacRelease` output cache. Download/extract the ZIP or open the `.app` locally. The internal executable remains OfflineMusicPlayer to preserve identity.

To build the iPod version instead, use `./build --platform=ipod`. Both exports reuse the same version/build for unchanged sources on the first export to each platform. A Mac-only successful package can finalize release notes; a subsequent iPod export verifies its own embedded widget/resources independently. Ad-hoc signing/hardened-runtime settings here are for local execution, not a public distribution receipt.

## Feature parity

| Feature | Existing Mac behavior/evidence |
|---|---|
| Local playback, seeking, queue, shuffle/repeat | Shared native engine compiles; Catalyst tests exercise actual playback and queue behavior. |
| Library/search, favorites/playlists, M3U, lyrics/artwork | Shared implementation and native tests run on Catalyst; launch alone does not certify every UI journey. |
| Artist photos, attribution, project link | Shared URLSession and link/UI code is desktop-compatible; mocked API coverage is included. |
| Folder picker/import/exclusion/removal | Existing Catalyst-compatible picker and store code; real protected-folder access and persistent grants still require Mac QA. |
| Persistence | Same schema, separate local Mac data. No automatic iPod synchronization. The unsandboxed Mac-owned music folder is `~/Library/Application Support/PocketMusic/Files`. |
| Widgets | In-app previews work. **Desktop widgets are absent unchanged**: extension disables Catalyst, embedding is iOS-only, and the shared widget directory returns nil on Catalyst. Supporting desktop widgets requires project/source work. |
| Finder → iPod / On My iPod | Device-specific transfer flow; Mac uses local folder/import workflows. Some helper text still references iPod. |
| Media keys/Control Center/headphones/Bluetooth | APIs compile, but actual Mac peripheral/system behavior is not yet verified. |
| Desktop polish | Existing Catalyst UI/platform adaptations; no custom Mac toolbar, menu or keyboard-shortcut system. |

The containing app bundles the icon, assets, project link and release notes; no widget extension or test media is embedded. The existing 36 Release Catalyst tests passed in the parent verification. Full all-feature parity is not claimed.

## Distribution

A public Mac release needs a separate archive/signing/package process. Direct distribution normally uses Developer ID signing and notarization; the verified ad-hoc app has no Team ID or hardened runtime and is not that deliverable. Mac App Store distribution needs its signing/sandbox configuration and renewed file-access QA. No certificates, provisioning, notarization, public package or upload were configured here.

See [Apple’s Catalyst distribution instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev033e997ca.html), [notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) and [widget capability limits](../design/cassette-widgets.md).
