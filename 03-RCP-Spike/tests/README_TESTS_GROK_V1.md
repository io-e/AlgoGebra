<!-- GROK_V1 -->
# AlgoGebra external engines + RCP image — test pack (GROK_V1)

**Author / version:** Grok Bot, GROK_V1 — 2026-10-29. **Audience:** Codex (Windows) and Grok Bot (Debian).
Modelled on Claude's WIMS4win pack (`tests-win_ALF/*_CLAUDE_V1.ps1`, `lib/TestFramework_CLAUDE_V1.ps1`,
`Run_All_Tests_CLAUDE_V1.ps1`, `tests-win/run_equiv_pc.ps1`), the WA-OEF2IPYNB Maxima tier and `test_unicode_E2.ps1`.

## Layout
- **Single runner: PowerShell 7 (`pwsh`) on Windows and Linux.** `NN_Test_<Area>_GROK_V1.ps1` suites 01-13 are cross-platform (`$IsWindows`/`$IsLinux`).
- `lib/TestFramework_GROK_V1.ps1` — framework, engine driver, WIMS-style direct references (OS-aware paths, `Get-JavaTool`, natives).
- `lib/UiDriver_GROK_V1.ps1` — UI driver for 08-10. Linux: Xvfb + xdotool + python3-PIL screenshots. Windows: user32 SetCursorPos/mouse_event, WinForms SendKeys/Clipboard, System.Drawing CopyFromScreen (Windows UI path syntax-checked only, NOT RUN).
- The former bash twins of suites 01-08 (`*.sh`, `lib/tf_GROK_V1.sh`, `Run_All_GROK_V1.sh`) moved to `03-RCP-Spike/linux-tests/`, next to the project scripts (`build.sh`, `launch.sh`, `test-engines.sh` stay in `03-RCP-Spike/` beside their `.ps1` twins). They are kept for reference/cross-check only; `tests/` holds only `.ps1`, tools and fixtures. No new suites are written in bash.
- `tools/EngineCli_GROK_V1.java` (drives an engine bundle), `tools/GiacCli_GROK_V1.java` (javagiac JNI from the image).
- `fixtures/*.tsv` — UTF-8, tab-separated, shared. Expected values were produced by real CLI runs (never invented).
- `results/` — **git-ignored** local output. Run_All writes `results/<yyyyMMdd_HHmmss>-<host>/`; single suites write `results/` (or `RESULTS_DIR`).
- `../evidence/<date>-<os>-<who>-<runid>/` — versioned, immutable evidence of reviewed runs with `MANIFEST_GROK_V1.tsv` (sha256). Export with `-ExportEvidence <name>`. Archive routine full logs as CI artifacts or keep them locally by run ID.

## Scenario pack (spec section 5)
`scenarios/S_<ID>_<Short>_GROK_V1.ps1` (33 scripts) + `scenarios/lib/Scenario_GROK_V1.ps1` + `scenarios/fixtures/`. One script per spec scenario of the desktop client and shared core; D-02..D-05 map to suites 08/11/09/10; W-01..W-08 are listed only (deferred: web phase). `Run_All_GROK_V1.ps1 -Scenarios | -Gate A..E | -Only <ids>`. Full list, statuses, blockers and evidence: **`SCENARIOS_TRACKING_GROK_V1.md`**. Product-side test hook: `-Dggbplus.scenario=<file>` only (off by default).

## Prerequisites (Windows)
| Item | Requirement / hint |
|---|---|
| PowerShell | 7+ (`pwsh`) — Run_All launches each suite with `pwsh -NoProfile`. |
| JDK 21 | Temurin 21 (compile + EngineCli). `JAVA_HOME` or default `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot`. |
| Java 25 | Only for suite 08 — bundled in the installed image (`jre\`). |
| Engine bundles | Run `03-RCP-Spike\build.ps1` first (needs the GeoGebra source pin); suites bail out (exit 2) if `host\build\org.geogebra.plus.engine.*_0.1.0.jar` is missing. |
| PARI/GP | `gp.exe` on PATH (installer from pari.math.u-bordeaux.fr, "GP for Windows"). |
| Maxima | `maxima.bat` on PATH (e.g. `C:\maxima-5.49.0\bin`, sourceforge installer). |
| Gnuplot | `gnuplot.exe` on PATH (gnuplot.info Windows installer, pngcairo terminal). |
| RCP image | `IMAGE` = installed image, default `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8`. **r8 predates the BUG-001/002 fix**: rebuild with build.ps1 + install-product.ps1 (r9+) before expecting engine results from the image. |
| Env vars | `JAVA_HOME`, `IMAGE`, optional `RESULTS_DIR`; suite 11: `GGB_SOURCE`, `BND_JAR`, `REF_BUNDLES`, `GGB_ASSEMBLE=1`; suite 13: `GGB_SOURCE`, `GGB_RERUN_TASKS=1` to force fresh Gradle execution, `GGB_SKIP_GRADLE=1` to count existing XML only; UI: `UI_DISPLAY` (Linux). |
| Linux | pwsh 7.6.9 (Microsoft tarball, `/usr/local/bin/pwsh`), Temurin 21, Xvfb, xdotool, python3-PIL; optional xclip (clipboard read-back). |

### Windows PATH example (Codex run of 689d4b4, 2026-10-29)
```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:PATH = 'C:\Program Files (x86)\Pari64-2-19-0;C:\maxima-5.49.0\bin;C:\maxima-5.49.0\gnuplot\bin;' + $env:PATH   # session only
$env:IMAGE = 'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r9'   # after the r9 rebuild (BUG-008)
pwsh -File 03-RCP-Spike\tests\Run_All_GROK_V1.ps1 -SkipRcp -SkipUi
```

D-ENG-02: do not download/install engines without the user's approval. A missing binary gives `BAIL OUT` + exit 2 (clean SKIP), never a crash.

## Run
```powershell
cd 03-RCP-Spike\tests
pwsh -File 01_Test_Engine_Discovery_GROK_V1.ps1      # one suite
pwsh -File Run_All_GROK_V1.ps1 [-SkipRcp] [-SkipUi] [-WithBuild] [-WithBaseline] [-ExportEvidence <name>]   # -> results\<runid>\
pwsh -File Run_All_GROK_V1.ps1 -Scenarios | -Gate A | -Only P-02,D-06   # scenario scripts
```
Same command on Debian (`pwsh -File Run_All_GROK_V1.ps1 -WithBuild -WithBaseline`). Run_All refuses an empty suite list (exit 2), counts a suite
without summary as FAIL, and reports BAIL separately (Codex 689d4b4). 09/10 drive the desktop: on Windows run them only in an attended session.

## Foreground-window guard (BUG-019, branch `feat/ui-foreground-guard`)
Every UI driver action (click, keystroke, paste, screenshot, pixel read) calls `Assert-GgbForeground` (lib/UiDriver_GROK_V1.ps1):
the foreground window must belong to the GeoGebraPlus java/javaw process (`ggbplus.runId`) and have a GeoGebra title. One
activation attempt is made; otherwise **no input is sent** and the check (and all later checks of that suite) are recorded as
`BLOCKED` (CSV status BLOCKED, TAP `# SKIP BLOCKED foreground guard: <title/pid>`, counted in SKIP; Run_All shows `guard-BLOCKED=n`).
Screenshots are cropped to the GeoGebraPlus window rect, never the full desktop.
- Real desktop (Windows): input-driven UI (suites 09/10, P-01 screenshot) only with `pwsh Run_All_GROK_V1.ps1 -AllowForegroundInput ...`
  (sets `GGB_UI_ALLOW_FOREGROUND=1`). Without it those checks are BLOCKED. Close browsers/editors with unsaved work first and do not use the PC during the run.
- Linux: the private Xvfb started by the suites counts as opt-in.
- Guard self-test: `14_Test_UiGuard_GROK_V1.ps1` (safe anywhere; negative cases must be BLOCKED with 0 inputs).

## Suites and expected status
| # | Suite | Covers | Expected |
|---|---|---|---|
| 01 | Engine_Discovery | binaries on PATH, versions, Java 21, each engine spawns | PASS (exit 2 if a binary is missing) |
| 02 | PARI | WIMS-style direct gp vs engine; `factor(2^64-1)` etc. | PASS since BUG-001 fix (093b302) |
| 03 | Maxima | diff / integrate (incl. `logabs:true` → `log(abs(x))`) / ratsimp / factor / expand | PASS since BUG-002 fix |
| 04 | Gnuplot | PNG 800x600, artefact deleted after close | PASS |
| 05 | Sandbox | WIMS deny lists, `:lisp`, no file written, 3 s timeout + process-tree kill | PASS (BUG-006 FIXED: PARI system/extern/externstr/fileextern/install/eval rejected before gp; SBX-14..19) |
| 06 | Encoding | é à ü € in/out, accented gnuplot title, accented temp dir (sh) | PASS |
| 07 | CAS_Equivalence | GIAC JNI vs PARI vs Maxima | PASS, 3 SKIP (no PARI equivalent) |
| 08 | RCP_Image | D-02 50/50 resolved, 3 engines available, GIAC `Expand[(x+1)^2]`, 3D view | PASS on Debian; on Windows image engines are available only if binaries are on PATH |
| 09 | D04_UI | D-04: input bar keystrokes (`fixtures/d04_inputs_GROK_V1.tsv`), error dialog, lost keystrokes, 2D<->3D focus, clipboard, ctrl+a NPE, ReTeX fonts, HiDPI; screenshots `results/screenshots/09_*.png` | FAIL expected (BUG-004, BUG-009..012) |
| 10 | D05_Strict3D | strict (no boot delegation) 3D: init, no JOGL link errors, non-blank canvas pixels, redraw after `A=(1,2,3)` | PASS on Debian (Mesa llvmpipe) |
| 11 | Bundle_Build (opt-in `-WithBuild`) | bnd 7.1.0 rebuild of the 02-Cdc recipes, BSN/version/exports/imports/class list vs r8, Equinox resolution with r8 externals | PASS on Debian |
| 12 | Engine_Robustness | 8 parallel calls PARI/Maxima, long outputs, timeout/crash recovery, no orphan processes, fake-marker payloads | PASS |
| 13 | GeoGebra_Baseline (opt-in `-WithBaseline`) | upstream Gradle `:common-jre:test`, `:desktop:test` at the pin, JUnit XML counts | PASS on Debian |

## Result format
TAP lines `ok N - [P0|P1] ID :: detail`, `not ok …`, `ok N - … # SKIP reason`; last line `PASS: n FAIL: n SKIP: n`.
Exit codes: 0 all pass, 1 any FAIL, 2 BAIL OUT (environment missing), 124 timeout. Run_All prints `GATE: MET|NOT MET`.

## Evidence rule (AGENTS.md)
A scenario counts as RUN only with: date, commit, OS, Java, fixture hash (`sha256sum fixtures/*.tsv` / `Get-FileHash`), command,
expected vs actual, log path (`../evidence/<run>/…` for reviewed runs). A Gradle/javac build success is not evidence. Anything not executed is reported **NOT RUN**.

## Debian results (2026-10-29, Debian 13.7, Temurin 21.0.13/25.0.5, gp 2.17.2, Maxima 5.47.0, gnuplot 6.0.2)
| Run | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | Total |
|---|---|---|---|---|---|---|---|---|---|
| 14:21 before fix (83887ca+pack) | 10/0/0 | 5/5/0 | 7/7/0 | 8/0/0 | 16/0/0 | 7/4/0 | 6/9/3 | 7/0/0 | 66/25/3 |
| 14:31 after fix (merge of 093b302) | 10/0/0 | 10/0/0 | 14/0/0 | 8/0/0 | 16/0/0 | 11/0/0 | 15/0/3 | 7/0/0 | **91/0/3 GATE MET** |

## PowerShell pack results (2026-10-29)
| Run | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Windows, Codex e3e8a82 (r9, temporary PATH) | 7/0/0 | 10/0/0 | 14/0/0 | 6/0/0 | 14/0/0 | 9/0/0 | 15/0/3 | 7/0/0 | NOT RUN (attended UI) | NOT RUN (attended UI) | NOT RUN (Bnd CLI absent) | 13/0/0 | 3/2/0 (known desktop locale failure) |
| Debian, pwsh 7.6.9, 15:03-15:45 | 7/0/0 | 10/0/0 | 14/0/0 | 6/0/0 | 14/0/0 | 9/0/0 | 15/0/3 | 7/0/0 | 7/17/0 (D-04) | 5/0/0 | 62/0/2 | 13/0/0 | 5/0/0 |

Windows evidence (2026-10-29): R9 was rebuilt and installed at `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r9`. `Run_All_GROK_V1.ps1 -SkipUi` returned **95 PASS, 0 FAIL, 3 SKIP** for suites 01-08 and 12; suite 08 confirmed 50/50 resolution, all three engines available, GIAC CAS, and JOGL 3D initialization. `test-engines.ps1` also passed the PARI factorization, Maxima derivative, and Gnuplot PNG checks. Suite 13 was run separately: common-jre had 6,526 existing test results (6,514 pass, 12 skipped; Gradle task `UP-TO-DATE`), while desktop executed 1,090 tests and failed only the known locale-sensitive `CallJavaScriptTest.testEval` (1,088 pass, 1 fail, 1 skipped). Suites 09/10 were not run because they drive the attended desktop; suite 11 was not run because no Bnd CLI JAR is installed. Run summary: `results/Run_All_20261029_153650_GROK_V1.csv`; suite 13 summary: `results/13_GeoGebra_Baseline_GROK_V1.csv`.

ps1 vs former sh (14:31, 0 FAIL both): 01 7 vs 10 (no version checks), 04 6 vs 8, 05 14 vs 16, 06 9 vs 11; 02, 03, 07, 08 equal.

## After BUG-006 fix (2026-10-29 16:09, Debian, pwsh 7.6.9)
`Run_All_GROK_V1.ps1 -SkipUi -ExportEvidence debian-grokbot-bug006`: 01 7, 02 10, 03 14, 04 6, **05 20** (SBX-02 + SBX-14..19 REJECT), 06 9, 07 15/0/3, 08 7, 12 13 → **101/0/3 GATE MET**.
Evidence: `03-RCP-Spike/evidence/20261029-linux-debian-grokbot-bug006-20261029_160937-grok-bot-vm-419969949/`. Earlier runs: see `03-RCP-Spike/evidence/README.md`.
