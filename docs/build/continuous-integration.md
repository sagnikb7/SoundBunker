# GitHub Actions

[Cassette QA](https://github.com/sagnikb7/casette/actions/workflows/ci.yml) runs on pushes to main, pull requests and manual dispatch. It uses the GitHub-hosted macos-15 image and logs its installed Xcode version. Hosted toolchains can differ from the local Xcode 27 environment.

The workflow runs Python release tests, read-only release/Markdown link checks, deterministic project regeneration, native Release Catalyst XCTest with testability enabled and hardened runtime disabled only for the ad-hoc desktop test invocation, an unsigned Release iphoneos build plus static analysis, and a separately built universal local Mac Catalyst app. Packaging validates arm64, minimum iOS 15, bundle identity/version, bundled release notes/icon, absence of test media and IPA integrity. Test reports are retained for seven days; versioned IPA/checksums for fourteen days. The IPA filename includes the version; the Mac export is named Cassette.app.

CI builds the version already recorded in the commit. It does not bump versions, modify the changelog, push commits, publish GitHub releases or install on devices. Use the local release script to finalize a new version before committing. Download unsigned packages from a successful run's Artifacts section and sign before installation.

Actions are pinned to official immutable commits, checkout credentials are not retained, and the workflow token has read-only repository permission. Monthly Dependabot updates propose action upgrades. No signing credentials are required. Repository branch protection is not configured: once the first hosted run passes, the owner can require the `native-qa` status check for pull requests in GitHub settings.

Run the equivalent checks locally:

```sh
python3 -m unittest discover -s scripts/tests -v
python3 scripts/verify_repository.py
python3 scripts/create_project.py
# Then run native XCTest and device build commands in testing.md.
```

The runner's native desktop tests do not certify iPod interaction, A10 performance, battery life or codec behavior on iOS 15.

References: [official macos-15 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md), [checkout](https://github.com/actions/checkout), [upload-artifact](https://github.com/actions/upload-artifact).

The Mac package uses a separate derived-data directory from XCTest so test bundles cannot leak into the exported app. CI calls packaging/validation directly on committed versions, never the release-preparing `./build` commands. The local Mac app preserves executable permissions/signatures; it is an ad-hoc build, not a notarized release.

Current packaging policy: CI validates a versioned IPA and `Cassette.app` without ZIP companions. The IPA remains a downloadable CI artifact (GitHub wraps artifact downloads itself). Mac bundles are validated on the runner but not uploaded through upload-artifact, which does not preserve executable permissions; create the local app with `./build --platform=mac`.
