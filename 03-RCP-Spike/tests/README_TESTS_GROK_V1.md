<!-- GROK_V1 -->
# AlgoGebra external engines + RCP image — test pack (GROK_V1)

**Author / version:** Grok Bot, GROK_V1 — 2026-10-29. **Audience:** Codex (Windows) and Grok Bot (Debian).
Modelled on Claude's WIMS4win pack (`tests-win_ALF/*_CLAUDE_V1.ps1`, `lib/TestFramework_CLAUDE_V1.ps1`,
`Run_All_Tests_CLAUDE_V1.ps1`, `tests-win/run_equiv_pc.ps1`), the WA-OEF2IPYNB Maxima tier and `test_unicode_E2.ps1`.

## Layout
- `NN_Test_<Area>_GROK_V1.sh` (Debian) and `NN_Test_<Area>_GROK_V1.ps1` (Windows, PowerShell 7) — same IDs, same fixtures.
- `lib/tf_GROK_V1.sh`, `lib/TestFramework_GROK_V1.ps1` — framework + engine driver + WIMS-style direct references.
- `tools/EngineCli_GROK_V1.java` (drives an engine bundle), `tools/GiacCli_GROK_V1.java` (javagiac JNI from the image).
- `fixtures/*.tsv` — UTF-8, tab-separated, shared. Expected values were produced by real CLI runs (never invented).
- `results/` — per-suite CSV + logs, `Run_All_<ts>_GROK_V1.csv/.md`.

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
| Env vars | `JAVA_HOME`, `IMAGE`, optional `RESULTS_DIR`. Debian also: `ALGOGEBRA_BASE` (default `/workspace/AlgoGebra`). |

D-ENG-02: do not download/install engines without the user's approval. A missing binary gives `BAIL OUT` + exit 2 (clean SKIP), never a crash.

## Run
```powershell
cd 03-RCP-Spike\tests
pwsh -File 01_Test_Engine_Discovery_GROK_V1.ps1      # one suite
pwsh -File Run_All_GROK_V1.ps1 [-SkipRcp]            # all suites -> results\Run_All_<ts>_GROK_V1.csv
```
Debian: `./Run_All_GROK_V1.sh [--skip-rcp]`, `./08_Test_RCP_Image_GROK_V1.sh` needs `xvfb-run` and the Linux image from `../build.sh`.

## Suites and expected status
| # | Suite | Covers | Expected |
|---|---|---|---|
| 01 | Engine_Discovery | binaries on PATH, versions, Java 21, each engine spawns | PASS (exit 2 if a binary is missing) |
| 02 | PARI | WIMS-style direct gp vs engine; `factor(2^64-1)` etc. | PASS since BUG-001 fix (093b302) |
| 03 | Maxima | diff / integrate (incl. `logabs:true` → `log(abs(x))`) / ratsimp / factor / expand | PASS since BUG-002 fix |
| 04 | Gnuplot | PNG 800x600, artefact deleted after close | PASS |
| 05 | Sandbox | WIMS deny lists, `:lisp`, no file written, 3 s timeout + process-tree kill | PASS (BUG-006 open: PARI `system()` relies on gp secure mode) |
| 06 | Encoding | é à ü € in/out, accented gnuplot title, accented temp dir (sh) | PASS |
| 07 | CAS_Equivalence | GIAC JNI vs PARI vs Maxima | PASS, 3 SKIP (no PARI equivalent) |
| 08 | RCP_Image | D-02 50/50 resolved, 3 engines available, GIAC `Expand[(x+1)^2]`, 3D view | PASS on Debian; on Windows image engines are available only if binaries are on PATH |

## Result format
TAP lines `ok N - [P0|P1] ID :: detail`, `not ok …`, `ok N - … # SKIP reason`; last line `PASS: n FAIL: n SKIP: n`.
Exit codes: 0 all pass, 1 any FAIL, 2 BAIL OUT (environment missing), 124 timeout. Run_All prints `GATE: MET|NOT MET`.

## Evidence rule (AGENTS.md)
A scenario counts as RUN only with: date, commit, OS, Java, fixture hash (`sha256sum fixtures/*.tsv` / `Get-FileHash`), command,
expected vs actual, log path (`results/…`). A Gradle/javac build success is not evidence. Anything not executed is reported **NOT RUN**.

## Debian results (2026-10-29, Debian 13.7, Temurin 21.0.13/25.0.5, gp 2.17.2, Maxima 5.47.0, gnuplot 6.0.2)
| Run | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | Total |
|---|---|---|---|---|---|---|---|---|---|
| 14:21 before fix (83887ca+pack) | 10/0/0 | 5/5/0 | 7/7/0 | 8/0/0 | 16/0/0 | 7/4/0 | 6/9/3 | 7/0/0 | 66/25/3 |
| 14:31 after fix (merge of 093b302) | 10/0/0 | 10/0/0 | 14/0/0 | 8/0/0 | 16/0/0 | 11/0/0 | 15/0/3 | 7/0/0 | **91/0/3 GATE MET** |
