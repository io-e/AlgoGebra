# Windows EE-P1 Follow-up — Gnuplot and PARI Filters

**Run date:** 2026-11-04  
**OS:** Windows 11 x64 (build 26100), host `SHADOW-TB64BO9R`  
**Java:** Temurin 21.0.12.1+1 LTS  
**Code under test:** `2b46d7c8600a411a99687e7a43e59c2e35375459` (includes `77a151c`, Gnuplot semicolon fix)  
**PR:** #60, open; no merge performed.

## Changes verified

- Gnuplot now accepts setup commands followed by `plot`/`splot` on the same line, e.g. `set grid; plot sin(x)`. Host-forced `pngcairo` output and PNG validation remain enabled.
- PARI `AGB_ILLEGAL` now includes `read`, `readvec`, and `readstr`, as required by `Decisions_PARI_Forbidden_GROK_V1_1.md`. Whole-word, case-insensitive filtering remains an AlgoGebra-only deviation from WIMS. This does not claim to sandbox PARI.
- Added sandbox fixtures SBX-20..SBX-23 for the three read APIs and `read("/etc/hostname")`.

## Windows results

| Check | Result |
|---|---:|
| Standalone Java `EngineAcceptanceTest` | **22 PASS**, exit 0 |
| Latest PR #61 fixture set F — Java value/PNG/error subset | **43/43 PASS**: PARI 16/16, Maxima 14/14, Gnuplot 13/13 |
| PR #61 PARI reject rows P-17..P-30 | **14/14 rejected** |
| Additional PARI read variants | **4/4 rejected**: mixed-case `READ*` and `alias(r,read)` |
| Gnuplot rows N-04/N-06/N-08/N-09 | **4/4** rendered valid 800×600 PNGs; artifacts deleted after result close |

The read-filter probes returned `COMMAND_REJECTED`; no read command was allowed to reach GP. The acceptance build compiled 16 Java sources directly and excluded OSGi `Activator.java`, because this clean worktree does not contain generated host/bundle artifacts. Therefore this is not a rerun of `test-engines.ps1`, the full sandbox PowerShell suite, or an RCP product build.

## Fixture scope and parity limits

The latest fixture JSON was taken from PR #61 head `7b2f3c64d86f6de40cd39e2249be18afa2ef53f5` (blob `2295077f772746f48adaaadf6e2774799c43b3b5`). It contains **120 cases**: PARI 30, Maxima 38, Gnuplot 28, GAP 24. Each engine meets the ≥20 target. GAP remains WIMS-reference-only because no Java adapter exists.

The 43 Windows value/PNG/error checks compare Java results with the expected values or captured WIMS outputs from the 118-case Debian run included as `EE-P2_PR61_118case_Debian_results.csv`. The latest three PARI read* rows were added after that WIMS run; those three were checked on Windows for Java rejection only. No WIMS C interface was run on Windows, so this is a Windows Java-side twin, not a fresh two-sided WIMS parity run.

## Reproduction

The external binaries were added to `PATH` for the test PowerShell process only:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:PATH = 'C:\Program Files (x86)\Pari64-2-19-0;C:\maxima-5.49.0\bin;C:\maxima-5.49.0\gnuplot\bin;' + $env:PATH
```

Compile API, runtime, engine, and test Java sources (excluding `Activator.java`), then run:

```powershell
java -cp <compiled-classes> org.geogebra.plus.engine.tests.EngineAcceptanceTest
```

Logs: `EngineAcceptanceTest.log`, `FixtureSetF_Windows_SafeSubset.log`, `PariFixtureF_Rejections.log`, and `GnuplotSemicolonFixtures.log`. `Source_SHA256SUMS.txt` records the source and fixture hashes; `SHA256SUMS` covers the evidence files.
