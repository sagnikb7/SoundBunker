# Project instructions

## User build preference (saved 12 October 2026)

Recognize explicit commands **`build --platform=ipod`** and **`build --platform=mac`**. Use the root `./build` launcher or `scripts/create_build.sh` with the same flag.

- **iPod:** `./build --platform=ipod` builds Release iphoneos arm64, minimum iOS 15.0, and exports both `dist/Cassette-unsigned-<version>.ipa` and `.ipa.zip`. Verify both archives, the embedded widget/version/resources, architecture and minimum OS. Return both links and explain that signing/provisioning is needed before installation.
- **Mac:** `./build --platform=mac` builds universal Release Mac Catalyst (arm64/x86_64, macOS 12+) and exports `dist/Cassette-<version>-mac.app` plus `.app.zip`. Verify the app signature, architectures/platform/minimum, resource/version parity and ZIP. Return the app/ZIP links. Explain local ad-hoc signing is not notarized public distribution and that desktop widgets are absent.
- Plain **“build”**, **“create build”** or an IPA request defaults to **iPod**, retaining the saved IPA+ZIP preference. The script also defaults to iPod for compatibility.
- Run platform builds sequentially under the script’s lock. Successful export of the second platform reuses the same version/build for unchanged sources; failed retries do not consume versions. A repeat export of an already-built platform increments the build number. Do not ship test media or claim transfer/installation without evidence.

Keep README.md as the entry point; store product, architecture, build, test and design documentation under `docs/` using descriptive lowercase names. Keep original user design references intact. Do not publish, upload, sync or install artifacts unless the user requests it.

During sustained work, provide progress updates describing completed work, current work and remaining work. Respect the user's request for an update at least every five minutes.

## Release tracking

Record every shipped feature/fix in `release/version.json` pending notes before building. Significant features use a minor version bump; fixes and polish use patch. `scripts/create_build.sh` prepares the version before compilation and writes `docs/product/changelog.md` only after successful platform packaging/verification. Retries must not consume versions. Keep bundle identity and persistence paths stable. See [versioning](docs/build/versioning.md).

## Documentation map

- Entry point and project layout: [README.md](README.md).
- Reliability and sleep timer: [plan and acceptance](docs/product/library-reliability-and-sleep-timer.md).
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
- Incremental scanning: [verification and limits](docs/testing/verification/incremental-scan-qa.md).
- Widget recovery: [verification and device checks](docs/testing/verification/widget-recovery-qa.md).
- Cassette widgets/signing/branding: [docs/design/cassette-widgets.md](docs/design/cassette-widgets.md).
- Native UI verification: [docs/design/native-ui-qa.md](docs/design/native-ui-qa.md).
- Test commands, results and physical QA: [docs/testing/testing.md](docs/testing/testing.md).
- Metadata, M3U and directory policy: [docs/engineering/metadata-and-playlists.md](docs/engineering/metadata-and-playlists.md).
- Player/folder refinement verification: [docs/testing/verification/player-folder-qa.md](docs/testing/verification/player-folder-qa.md).
- Feature expansion verification: [docs/testing/verification/feature-expansion-qa.md](docs/testing/verification/feature-expansion-qa.md).
- Actual codec evidence: [docs/testing/codec-support.md](docs/testing/codec-support.md).
- Final build receipt: [docs/testing/verification/final-build.md](docs/testing/verification/final-build.md).
- Executed test receipts: `docs/testing/verification/final-tests.txt`; historical receipts: `docs/testing/verification/archive/`.
- Native Mac export/parity: [docs/build/mac-export.md](docs/build/mac-export.md).
- Physical iPod connection/signing/install: [docs/build/ipod-installation.md](docs/build/ipod-installation.md).
- IPA + ZIP production and verification: [docs/build/build-artifacts.md](docs/build/build-artifacts.md).

Update the relevant documents when behavior or verification changes. Keep README links synchronized with this map. Test fixtures belong only to the test target. Never mistake a compiler success or desktop test result for physical iPod verification.

Before pushing, run release tests, repository checks, native tests and device build/packaging validation. Generated logs, personal Xcode settings, credentials and signing profiles stay out of Git. CI must not bump releases or commit generated files.
