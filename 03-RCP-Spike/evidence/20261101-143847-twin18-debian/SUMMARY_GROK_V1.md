# Twin suite 18 — Windows (PR #11, launch.ps1) vs Debian (PR #9, launch.sh) (GROK_V1)

Filename collision: **both PR #9 and PR #11 add `03-RCP-Spike/tests/18_Test_LaunchCourse_GROK_V1.ps1`** (git add/add conflict confirmed by a scratch merge). Diff: `suite18_PR9_vs_PR11.diff`.

## Runs on Debian
| Run | PASS | FAIL | SKIP | Note |
|---|---|---|---|---|
| PR #9 suite vs launch.sh (r8 image) | 17 | 0 | 2 | LC-18/19 skip (no course package) |
| PR #9 suite vs launch.sh (PR #11 image built on Debian) | 18 | 0 | 1 | LC-18 real Xvfb launch PASS, see p0b evidence on PR #9 |
| PR #11 suite vs launch.sh (via `shim_launchsh_GROK_V1.ps1`) | 15 | 1 | 0 | only fail = test uses Windows-relative `tests\fixtures\...` |
| PR #11 suite vs launch.ps1 on Debian | 8 | 8 | 0 | launch.ps1 hard-codes `D:` EclipseHome (line 156) — Windows-only, expected; all 8 error-code cases pass, all 8 success cases fail |
| Windows (Codex, PR #11 evidence) | 16 | 0 | 0 | |

## Case mapping
| LC (PR #9) | PR #11 (Windows) case | Win | Debian launch.sh | Exit code aligned |
|---|---|---|---|---|
| LC-01 no flag | no course keeps property absent | PASS | PASS | 0 |
| LC-02 relative | relative -Course → absolute | PASS | PASS (LC); #11 case FAIL on Linux: backslash path in test | 0 |
| LC-03 `--course=` | --course= alias | PASS | PASS | 0 |
| LC-04 spaces | path with spaces | PASS | PASS | 0 |
| LC-05 missing value | missing -Course value | PASS | PASS | 64 = 64 |
| LC-06 repeated | repeated -Course | PASS | PASS | 64 = 64 |
| LC-07 missing file | missing course | PASS | PASS | 66 = 66 |
| LC-08 directory | directory course path (`directory.json`) | PASS | PASS | 66 = 66 |
| LC-09 extension | non-JSON `.txt` | PASS | PASS (+ `.ggb`) | 65 = 65 |
| LC-10 > 1 MiB | above 1 MiB | PASS | PASS | 65 = 65 |
| LC-11 URL | remote URL | PASS | PASS | 64 = 64 |
| LC-12 symlink → realpath | — | gap | PASS | — |
| LC-13 root escape (abs, `..`, symlink) + inside accepted | outside root 77 / inside accepted | PASS (abs only) | PASS | 77 = 77 |
| LC-14 env fallback + flag wins | env fallback / flag precedence (env points to **missing** file) | PASS | PASS (env valid) | 0 |
| LC-15 flag order | Headless and Course either order | PASS | PASS | 0 |
| LC-16 shell metachars literal | — | gap | PASS | — |
| LC-17 course error before Java / no JDK = 4 | — | gap | PASS | 4 (PR #4) — no Windows twin |
| LC-18 Xvfb real launch | — (attended SWT stays Windows) | gap | PASS on PR #11 image | — |
| LC-19 T-27 layering | — | gap | SKIP | — |

**Exit codes 64/65/66/77 are fully aligned.** Gaps on Windows: symlink/junction resolution (LC-12, LC-13 via `..`/link), metachar literal (LC-16), course-before-Java ordering / no-JDK code (LC-17). Gap on Debian: PR #11's stronger "env points to missing file but flag wins" variant — add to LC-14.

## Proposed resolution of the collision
1. One cross-platform file `18_Test_LaunchCourse_GROK_V1.ps1` keeping the LC-01..19 IDs and TAP/CSV framework (PR #9 version), with a launcher adapter: `$IsWindows` → `pwsh launch.ps1 -NoBuild …`, else `bash launch.sh …`; dry-run argv parsed from `ARG ` lines (launch.sh) or the `-D` line (launch.ps1). Add PR #11's env-missing+flag case to LC-14 and use `Join-Path` for the relative path.
2. Merge order: #4 → #9 (or #9 alone) → #11 with its suite-18 file dropped/renamed (e.g. `18b_Test_LaunchCourse_Windows_CODEX_V1.ps1` until unified). Codex or Grok does the unification as a new commit, no force-push.
