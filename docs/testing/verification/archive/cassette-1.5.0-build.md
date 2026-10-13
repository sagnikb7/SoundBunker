# Final build verification

13 October 2026: **Cassette 1.5.0 (12)** exported using `./build --platform=ipod`.

- Native Release Catalyst: **46 tests, zero failures**. Includes 500-file unchanged scan, incomplete enumeration retention, sleep limits/boundaries/expiry, permission recovery and compact timer rendering.
- Python release workflow: **18 tests, zero failures**.
- Release iPhoneOS compilation and repository/package verification passed.
- App and embedded widget: arm64, IOS, minimum iOS 15.0; matching 1.5.0 (12) versions, stable bundle identities, compiled artwork assets and matching bundled resources.
- IPA and outer ZIP integrity passed. All IPA payload files match the verified built app. ZIP contains the identical IPA. Test media and XCTest bundles are absent.
- Release notes were recorded before building and finalized only after packaging succeeded.

Artifacts: `dist/Cassette-unsigned-1.5.0.ipa` and `dist/Cassette-unsigned-1.5.0.ipa.zip`. Signing/provisioning, including matching widget App Groups, is required before installation. No upload, transfer or installation was performed. Last Mac export remains 1.3.0 (9).

Logs outside Git: `/tmp/cassette-reliability-tests.log`, `/tmp/cassette-workflow-tests.log`, `/tmp/cassette-reliability-ipod-build.log`.

## Device limits

The user's screen-lock termination has not been reproduced or certified fixed. Background file protection and session handling are hardened, but physical iPod playback through lock, queue transitions and sleep expiry remains required. The 500-file automated regression uses small test WAV copies on the Mac; it is not an A10 performance benchmark. See [plan and device acceptance](../../../product/library-reliability-and-sleep-timer.md).

Previous receipt: [1.4.1](cassette-1.4.1-build.md).

## SHA-256

- IPA: `f4131af28525e8f45f17f029a962364b0b668b67268337858d8545eaa9669750`
- ZIP: `e3ae0e46a52e1c4af1a6f75cb61c42efafdc2b43cd3e301c03482101af8a5a3a`
