# Build outputs

Saved preference: iPod builds produce only `dist/Cassette-unsigned-<version>.ipa`; Mac builds produce only `dist/Cassette.app`. No ZIP companions are generated.

Use `./build --platform=ipod` or `./build --platform=mac`. A plain build defaults to iPod. Builds run sequentially under a lock, prepare version metadata before compilation, verify outputs, then finalize the release. See [versioning](versioning.md).

The iPod export is Release arm64, minimum iOS 15, unsigned and requires signing/provisioning before installation. The IPA itself is an archive with a validated Payload; no outer ZIP is needed. Verify app/widget identity, resources, matching version, platform and absence of test media.

The Mac export is universal Release Catalyst for macOS 12+. Packaging preserves executable permissions, symlinks and the verified ad-hoc signature. Quit Cassette, drag `Cassette.app` into Applications and choose Replace. Older version-named installations require a one-time removal of the old app bundle to avoid duplicates. Bundle identity and data paths stay stable. The internal version/build remains available in About. Desktop widgets are absent; local signing is not notarized public distribution.

Failed Mac copying/validation preserves the previous export. Existing historical packages are not deleted automatically. Build logs and exports remain outside Git. Never infer installation or physical device success from packaging validation.
