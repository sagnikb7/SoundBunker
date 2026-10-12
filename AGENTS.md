# Project instructions

## User build preference (saved 12 October 2026)

When the user says **"create build"**, **"build"** in a delivery context, or asks to create an IPA:

1. Build the current Release **iphoneos arm64** app, retaining iOS 15.0 minimum deployment.
2. Use `scripts/create_build.sh` to produce **both** `dist/SoundBunker-unsigned.ipa` and `dist/SoundBunker-unsigned.ipa.zip` (ZIP contains the IPA).
3. Verify both archives, device architecture, minimum OS and bundled resources. Do not ship test media.
4. Return links to both artifacts. Explain that an unsigned IPA needs signing/provisioning before installation; never claim transfer or installation without evidence.

Keep README.md as the entry point; store product, architecture, build, test and design documentation under `docs/` using descriptive lowercase names. Keep original user design references intact. Do not publish, upload, sync or install artifacts unless the user requests it.

During sustained work, provide progress updates describing completed work, current work and remaining work. Respect the user's request for an update at least every five minutes.

## Release tracking

Record every shipped feature/fix in `release/version.json` pending notes before building. Significant features use a minor version bump; fixes and polish use patch. `scripts/create_build.sh` prepares the version before compilation and writes `docs/product/changelog.md` only after successful IPA/ZIP packaging. Retries must not consume versions. Keep bundle identity and persistence paths stable. See [versioning](docs/build/versioning.md).

## Documentation map

- Entry point and project layout: [README.md](README.md).
- Original requirements: [docs/product/offline-music-player-spec.md](docs/product/offline-music-player-spec.md).
- Release history: [docs/product/changelog.md](docs/product/changelog.md).
- GitHub CI and artifact downloads: [docs/build/continuous-integration.md](docs/build/continuous-integration.md).
- Pre-push audit: [docs/testing/repository-audit.md](docs/testing/repository-audit.md).
- Version/build rules: [docs/build/versioning.md](docs/build/versioning.md).
- Product decisions and filesystem policy: [docs/product/product-decisions.md](docs/product/product-decisions.md).
- Future optional enrichment: [docs/product/roadmap.md](docs/product/roadmap.md).
- Implementation status and remaining work: [docs/engineering/implementation-plan.md](docs/engineering/implementation-plan.md).
- Components, persistence, access and playback: [docs/engineering/architecture.md](docs/engineering/architecture.md).
- Visual reference mapping: [docs/design/prototype-mapping.md](docs/design/prototype-mapping.md).
- Native UI verification: [docs/design/native-ui-qa.md](docs/design/native-ui-qa.md).
- Test commands, results and physical QA: [docs/testing/testing.md](docs/testing/testing.md).
- Actual codec evidence: [docs/testing/codec-support.md](docs/testing/codec-support.md).
- Final build receipt: [docs/testing/verification/final-build.md](docs/testing/verification/final-build.md).
- Executed test receipts: `docs/testing/verification/final-tests.txt`; historical receipts: `docs/testing/verification/archive/`.
- Physical iPod connection/signing/install: [docs/build/ipod-installation.md](docs/build/ipod-installation.md).
- IPA + ZIP production and verification: [docs/build/build-artifacts.md](docs/build/build-artifacts.md).

Update the relevant documents when behavior or verification changes. Keep README links synchronized with this map. Test fixtures belong only to the test target. Never mistake a compiler success or desktop test result for physical iPod verification.

Before pushing, run release tests, repository checks, native tests and device build/packaging validation. Generated logs, personal Xcode settings, credentials and signing profiles stay out of Git. CI must not bump releases or commit generated files.
