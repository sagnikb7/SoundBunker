# Final build verification

13 October 2026: **Cassette 1.5.2 (14)** exported using `./build --platform=ipod`. Includes the 1.5.0 library/playback/sleep-timer work, 1.5.1 widget recovery, and the new designer-provided frosted rainbow logo.

## Passed checks

- Native Release Catalyst regression suite after widget changes: **48 tests, zero failures**.
- Widget suite rebuilt after logo replacement: **6 tests, zero failures**, with square and medium renders visually inspected. Updated current widget screenshots show the supplied mark.
- Python release workflow suite: **18 tests, zero failures**.
- Designer original preserved byte-for-byte; 1024px opaque app/README icons match; 64px opaque app/extension marks match.
- Release iPhoneOS compilation and repository/package verification passed.
- App and embedded widget: arm64, IOS, minimum iOS 15.0; matching 1.5.2 (14) versions, stable identities, compiled icon/mark resources and matching bundled release/project metadata.
- IPA and outer ZIP integrity passed. All IPA payload files match the verified built app. ZIP contains the identical IPA. Test music and XCTest bundles are absent.
- Release notes recorded before builds and finalized only after successful packaging.

## Artifacts and limits

`dist/Cassette-unsigned-1.5.2.ipa` and `dist/Cassette-unsigned-1.5.2.ipa.zip` require signing/provisioning, including matching widget App Groups. No upload, transfer or installation was performed. Last Mac export remains 1.3.0 (9); shared source assets include the new logo for the next Mac build.

The user reports both widgets remain black with a Sideloadly installation. The installed extension signature/profiles and physical WidgetKit execution have not been inspected. Code now repairs shared snapshots, requests refreshes/retries and bounds image decoding, but the reported Home Screen failure is not certified resolved. Use Settings → Widgets → Refresh Widgets after installing, inspect shared-storage status, and remove/re-add stale widgets. See [widget acceptance](../widget-recovery-qa.md).

The screen-lock app termination likewise remains a physical-device acceptance gate. Desktop regressions and 500 small WAV fixtures are not A10 performance or locked-playback certification. See [reliability plan](../../../product/library-reliability-and-sleep-timer.md). Previous receipt: [1.5.0](cassette-1.5.0-build.md).

Logs remain outside Git: `/tmp/cassette-widget-recovery-tests.log`, `/tmp/cassette-widget-workflow-tests.log`, `/tmp/cassette-designer-logo-tests.log`, `/tmp/cassette-designer-logo-ipod-build.log`.

## SHA-256

- IPA: `c4c2404ac5a0f1904936227fe7752c4f3692f2f8b359f3c21f7b55e377bea59d`
- ZIP: `2708df17337b9b8af03bc7f7ce0767cf481ff717118db1c433c998a00a9afbb4`
