# IPA and ZIP build workflow

User preference: every **create build** request produces both an IPA and a ZIP containing the IPA. Saved in [AGENTS.md](../../AGENTS.md).

```sh
./scripts/create_build.sh
```

Outputs:

- `dist/SoundBunker-unsigned.ipa`
- `dist/SoundBunker-unsigned.ipa.zip`

The script prepares version/build and bundled release notes before compilation, then records the successful release in the [changelog](../product/changelog.md). See [versioning rules](versioning.md).

The script compiles **Release, iphoneos, arm64**, with iOS 15 minimum and signing disabled. `package_ipa.py` checks the platform/executable, rejects test bundles, packages `Payload/OfflineMusicPlayer.app`, validates ZIP integrity and creates an outer ZIP containing the IPA. A custom derived-data directory can be supplied with `POCKET_MUSIC_DERIVED_DATA`; the legacy variable/target names stay stable internally.

This is an **unsigned/unprovisioned device package for re-signing**, not an App Store export, simulator app or Mac Catalyst app. Sideloadly or a valid Apple provisioning workflow must sign it before installation. ZIP is only a convenient transport container: extract it to obtain the IPA.

Before delivery, verify the app's MinimumOSVersion and Mach-O platform/minimum, arm64 architecture, SoundBunker display name, bundled icon and absence of TestTone/sample audio/XCTest bundles. Record checksums and test results in `docs/testing/verification/`. Never claim installation or device playback from packaging success.

The original generated project script is a maintenance utility; rerunning it replaces manual project settings. Tests and test fixtures remain exclusively in the test target.
