# Pre-push audit and QA

Date: 12 October 2026. Scope: SoundBunker 1.2.0 (8), native source, persistence, folder restrictions, M3U playlists, artist metadata, playback, release/package scripts, project contents and CI configuration.

## Findings resolved

- Playback opened indexed locations without explicitly rechecking the source's enabled/excluded policy. Preparation now checks source policy before opening each location.
- An indexed song replaced with a symbolic link could point outside its granted music root. Playback now checks canonical containment and local file policy rejects symbolic links, including adjacent lyrics/import inputs. Regression coverage exercises local files, traversal, absolute paths and replaced links.
- The project lacked Git/CI configuration. Added main-branch/PR/manual native QA, device static analysis, packaging verification and read-only release/document checks. Official actions are pinned to immutable commits; monthly Dependabot updates them.
- The release fingerprint included untracked Finder metadata, causing clean-clone QA to fail. It now excludes `.DS_Store`/AppleDouble files; a regression test confirms the fingerprint stays portable. The existing manifest fingerprint was normalized without changing app version or packaged content.
- Raw local compiler logs and device/signing files are excluded from version control. Original prototype references, app icon, test fixture and concise verification evidence remain tracked.

## Verification

- Native Release Catalyst: 27 XCTest tests, zero failures, TEST SUCCEEDED. The documented test invocation enables testability and disables hardened runtime for ad-hoc XCTest loading; device Release packaging settings are unchanged.
- Python release/packaging/project-metadata workflow: ten tests, zero failures.
- Workflow and Dependabot YAML parsed successfully.
- Release iphoneos package and static analysis results are recorded in [final build receipt](verification/final-build.md).
- Read-only repository QA checks manifest/source fingerprint, bundle identity/build/notes, finalized changelog and local Markdown links; device validation checks arm64/iOS 15/icon/notes/no test resources and both archive layers.
- Push uses the configured origin on main without force; generated packages, logs and signing files remain ignored.
- Pattern scan found no embedded private keys, common token formats or hard-coded credentials in source/configuration. This is a heuristic check, not a guarantee against all secret formats.

## Remaining limitations

Physical iPod provider/bookmark flows, software keyboard placement, Control Center/background playback, real codecs, VoiceOver/larger text and A10 memory/battery/frame rate remain device QA items. M3U import is delivered and regression-tested; deeper codec metadata parsing and queue reordering remain roadmap items. The audit does not certify complete implementation of the original specification.

GitHub-hosted CI execution is separate from local checks. The pushed commit's result must be checked in Actions; branch protection/signing/publishing are not configured.
