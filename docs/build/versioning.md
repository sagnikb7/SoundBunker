# Versioning and release notes

`release/version.json` is the release source of truth. Settings shows the installed bundle's version/build; What's New reads bundled release notes offline. Bundle identifier and database location stay stable so an in-place update can retain playlists and favorites.

Before shipping a feature or fix, add a `pending` object containing `bump` and at least one of `added`, `changed`, or `fixed` (arrays of human-readable notes). Use **minor** for significant new features, **patch** for fixes/polish, and **major** for incompatible changes. All shipped changes belong in the Markdown changelog, including smaller fixes.

Run `./scripts/create_build.sh`. It prepares the version before compiling, creates and validates the IPA plus ZIP, then commits the release to `docs/product/changelog.md` and updates the manifest. A failed build keeps the pending release and does not consume another version/build on retry. Rebuilding unchanged app sources increments only the build number. Changed shipping files without pending notes stop the build. Do not manually bump Info.plist or finalize a failed build.

The first tracked release is 1.1.0 (build 2); older packages used version 1.0/build 1. The baseline is recorded as 1.0.0 in the changelog.

Verify workflow behavior with:

```sh
python3 -m unittest discover -s scripts/tests -v
```

Tests cover retries, semantic bumps, unchanged rebuilds, missing notes, source changes during compilation and mismatched built versions. Native app regression tests are separate.
