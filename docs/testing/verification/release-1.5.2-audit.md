# Release 1.5.2 discrepancy audit

13 October 2026. User reports GitHub remains in both Settings root and About on installed **1.5.2 (14)**, installed using Sideloadly. Treat this device report as unresolved; do not assume the user installed an older version.

## Evidence checked

Current Settings source declares only What's New and About Cassette in its About section. The sole project Link is inside AboutView. A new full-height native Catalyst render covers the entire Settings list, unlike the prior compact capture that omitted its bottom. Inspected [Settings](release-1.5.2-settings.png) and [About](release-1.5.2-about.png): no GitHub at root; one in About, displaying 1.5.2 (14). These are desktop render evidence, not screenshots of the user's iPod.

Extracted the actual executable bytes directly from each exported IPA and checked the two literal labels:

| IPA version (build) | Old root label present | About label present |
|---|---|---|
| 1.4.1 (11) | True | True |
| 1.5.0 (12) | False | True |
| 1.5.1 (13) | False | True |
| 1.5.2 (14) | False | True |

Literal checks are supplemental evidence, not a substitute for executing the installed device UI. No new production code or replacement release was generated during this audit: the exported binary and current source already lack the reported root link. The installed/re-signed executable has not been retrieved or compared.

## Claims audit

| Request | Verified locally | Still unverified |
|---|---|---|
| Scan frequency/performance | No foreground rescan call; changed-record batching; 500-file reuse/progress regression | Real 500-song A10 responsiveness and Instruments traces |
| Screen-lock termination | File protection/session hardening implemented; background audio configured | Root cause and physical crash resolution |
| Error −54 | Permission error recovery copy and test | Original device failure reproduction |
| Settings duplicates | Full root/About renders and exported binary label comparison | Conflicting installed-device report |
| Sleep timer | Queue limits, repeat boundaries, pause expiry and replacement cancellation tests | Timer expiry while physically locked |
| Black widgets | Snapshot/refresh/artwork regressions and rendered fallback cards | Sideloadly-installed extension launch, App Groups and black-widget resolution |
| Designer logo | Original preserved, asset parity, widget renders and packaged resources | Installed icon/cache refresh |
| Documentation/media sync | README and engineering guides updated; repository checks | None for the documentation edits |

The earlier final summaries should not be interpreted as certification of device crash/widget fixes. Passing native tests does not establish the cause of these physical-device reports. Next evidence needed for the duplicate-link discrepancy: an iPod screenshot of the Settings root showing the row, then installed executable/signing comparison if device tooling permits. Do not delete app data or reinstall merely to suppress the report.

Focused native render test passed. Log: `/tmp/cassette-settings-audit.log` (outside Git).
