<!-- GROK_V1 -->
# AlgoGebra external engines + RCP image — test pack (GROK_V1)

**Author / version:** Grok Bot, GROK_V1 — 2026-10-29. Modelled on Claude's WIMS4win pack (`tests-win_ALF/*_CLAUDE_V1.ps1`,
`lib/TestFramework_CLAUDE_V1.ps1`, `Run_All_Tests_CLAUDE_V1.ps1`, `tests-win/run_equiv_pc.ps1`), the WA-OEF2IPYNB Maxima tier and
`test_unicode_E2.ps1`.

## Conventions taken from Claude's pack
- Numbered suites `NN_Test_<Area>_GROK_V1.{sh,ps1}`, shared framework in `lib/`, one aggregator `Run_All_GROK_V1.*`.
- TAP lines `ok N - [P0|P1] ID :: detail` / `not ok …` / `# SKIP reason`; P0 = blocking, P1 = important.
- Final line `PASS: n FAIL: n SKIP: n` parsed by Run_All; per-suite CSV in `results/`; Run_All writes `Run_All_<ts>_GROK_V1.csv` + `.md`, prints GATE MET/NOT MET.
- Exit codes: 0 all pass, 1 any FAIL, 2 BAIL OUT (missing environment), 124 = timeout (child process).
- Each suite runs as a child process (exit-code isolation), timeouts enforced, process tree killed.
- Expected values are **never invented**: they come from a direct CLI reference that reproduces WIMS `src/Interfaces/common.c`
  (header, `Start line …` marker, command, `End line …` marker; keep only the text after the last start marker), cross-checked by GIAC.

## Suites
| # | Suite | What |
|---|---|---|
| 01 | Engine_Discovery | gp/maxima/gnuplot on PATH, versions, Java 21, each engine spawns |
| 02 | PARI | direct reference vs engine, incl. `factor(2^64-1)` (BUG-001) |
| 03 | Maxima | diff / integrate / ratsimp / factor / expand, direct vs engine (BUG-002) |
| 04 | Gnuplot | PNG 800x600 direct + engine, artefact deleted after close |
| 05 | Sandbox | WIMS illegal/illpart lists (write, plot, system, load, with_stdout, gnuplot system/!/set output), `:lisp` escape, no file written, 3 s timeout + kill |
| 06 | Encoding | UTF-8 accents/€ in/out (PARI, Maxima), accented gnuplot title, accented temp dir |
| 07 | CAS_Equivalence | GIAC (javagiac JNI from the image) vs PARI vs Maxima on `fixtures/equiv_GROK_V1.tsv` |
| 08 | RCP_Image | Xvfb: D-02 50/50 resolved, 3 engines available=true, GIAC `Expand[(x+1)^2]`, 3D view |

Fixtures (`fixtures/*.tsv`, UTF-8, tab-separated) are shared by .sh and .ps1.

## Run
Debian: `./Run_All_GROK_V1.sh [--skip-rcp]` (env: `JAVA_HOME`, `IMAGE`, `ALGOGEBRA_BASE`). Windows: `pwsh -File Run_All_GROK_V1.ps1 [-SkipRcp]` (env `IMAGE` = installed win image).

## Debian results 2026-10-29 14:21 Europe/Paris (commit of this pack, Debian 13.7, Temurin 21.0.13 / 25.0.5, gp 2.17.2, Maxima 5.47.0, gnuplot 6.0.2)
| Suite | Pass | Fail | Skip | rc | Status |
|---|---|---|---|---|---|
| 01_Test_Engine_Discovery | 10 | 0 | 0 | 0 | PASS |
| 02_Test_PARI | 5 | 5 | 0 | 1 | FAIL |
| 03_Test_Maxima | 7 | 7 | 0 | 1 | FAIL |
| 04_Test_Gnuplot | 8 | 0 | 0 | 0 | PASS |
| 05_Test_Sandbox | 16 | 0 | 0 | 0 | PASS |
| 06_Test_Encoding | 7 | 4 | 0 | 1 | FAIL |
| 07_Test_CAS_Equivalence | 6 | 9 | 3 | 1 | FAIL |
| 08_Test_RCP_Image | 7 | 0 | 0 | 0 | PASS |

**TOTAL: 66 pass, 25 fail, 3 skip — GATE: NOT MET**

All 25 FAIL are the engine output-parser defects BUG-001 (PARI header values leak) and BUG-002 (Maxima header values leak);
every corresponding direct-reference check PASSES with the same expected value. Windows .ps1 twins: **NOT RUN** (written, not executed).
