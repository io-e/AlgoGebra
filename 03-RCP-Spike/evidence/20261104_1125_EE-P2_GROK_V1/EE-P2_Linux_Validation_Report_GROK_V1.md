<!-- GROK_V1 -->
# EE-P2 Linux validation: G-B1 rerun on #60 `f464660`

Run: `20261104_1125_EE-P2_GROK_V1` (2026-11-04 ~11:25-11:40 Europe/Paris), Debian 13 x86-64, Temurin 21.0.13+9. Supersedes `20261104_1018_EE-P2_GROK_V1` (114/118 on `e483500`, kept for history).

Code under test: #60 head **`f46466083f18dedb1f8a5fefdd29a2d95f23dad9`** (includes `77a151c` Gnuplot semicolon fix and `2b46d7c` Pari read* block), merged into `grok/ee-p2-linux-validation` with a normal merge commit. Fixture: `ee_fixture_set_F_GROK_V1.json`, 120 cases. Comparison: D-WIMS-T01 soft parity.

## Results: 120/120

| Engine | Positive (value/error/png/strict) | Negative (reject) | Total |
|---|---|---|---|
| pari | 16/16 | 14/14 | **30/30** |
| maxima | 16/16 | 22/22 | **38/38** |
| gnuplot | 13/13 | 15/15 | **28/28** |
| gap (WIMS reference only, no Java adapter) | 13/13 | 11/11 | **24/24** REF-PASS |

- **Gnuplot soft-parity slice:** 28/28. N-04 `set xrange [0:1]; plot x`, N-06 `set grid; plot sin(x)`, N-08 `set samples 50; plot sin(x)` and N-09 `set key left; plot sin(x), cos(x)` now render 800x600 PNGs on Java (previously `INVALID_REQUEST`). All 15 Gnuplot rejects are still rejected.
- **Pari attack slice:** 14/14 rejected by Java. P-28 `read`, P-29 `readvec` and P-30 `readstr` on `/etc/hostname` return `ERR|COMMAND_REJECTED`. WIMS `pari.c` still executes them and prints the host name. The harness labels these "WIMS neutralised / no effect", which is inaccurate for these 3 rows: WIMS is less strict here, per the BUG-006 V1_1 owner decision.
- **Regressions:** none. Every case that passed on `e483500` still passes.
- **Codex `test-engines.sh` / `EngineAcceptanceTest` on Linux:** 22 PASS, 0 FAIL, exit 0 (`codex_acceptance_linux.log`).

Codex Windows evidence at this head: `03-RCP-Spike/evidence/20261104-windows-ee-p1-gnuplot-semicolon-codex/` records code under test `2b46d7c`, with EngineAcceptanceTest 22 PASS, 43/43 value/PNG/error rows, P-17..P-30 14/14 rejected and N-04/06/08/09 4/4 PNG. `f464660` itself only adds that evidence.

Harness note: the first two attempts were invalid because of my setup (wrong WIMS interface path, then `gap.sh` missing from PATH). They are not recorded as results. The final run uses `-WimsInterfaces /workspace/grok-g1/ee_wims/src/Interfaces -ExtraPath /workspace/scratch_ee_p2/bin`.

## Files
`results.json`, `results.csv`, `scenario_run.log`, `codex_acceptance_linux.log`, `versions.txt`, `SHA256SUMS`. No production Java, states.yaml or Run_All changed.
