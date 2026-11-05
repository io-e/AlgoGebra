<!-- GROK_V1 -->
# Fixture inventory (G-B3): `ee_fixture_set_F_GROK_V1.json`

Brief: `02-Cdc/Actions_GrokBot_After_EE_P2_GROK_V1.md` (c18b350), G-B3. Counts computed from the JSON itself (120 cases after this commit; 118 in the 20261104_1018 run). Positive = `expected_rejection: false` (value / error / png / strict), negative = `expected_rejection: true` (reject).

| Engine | Positive | Negative | Total | Target ≥20 | Java adapter on #60 |
|---|---:|---:|---:|---|---|
| pari | 16 | 14 | 30 | met | yes |
| maxima | 16 | 22 | 38 | met | yes |
| gnuplot | 13 | 15 | 28 | met | yes |
| gap | 13 | 11 | 24 | met | **no** (WIMS-side only, see `GAP_Adapter_Blockers_GB4_GROK_V1.md`) |
| **total** | 58 | 62 | 120 | | |

Change in this commit: P-28 moved from `strict` to `reject`; P-29 and P-30 added (pari +2 negatives).

## Gnuplot one-line failures (4/28 in the 20261104_1018 run)
Verified against the JSON (kind `png`, expected `PNG 800x600`) and `results.csv` (Java `ERR|INVALID_REQUEST`, WIMS renders PNG). Cause: `PLOT_COMMAND` = `(?im)^\s*(?:plot|splot)\b` only matches `plot` at line start, so `plot` after `;` is not seen. N-10 (same as N-04 but with a newline) passes.

| id | input |
|---|---|
| N-04 | `set xrange [0:1]; plot x` |
| N-06 | `set grid; plot sin(x)` |
| N-08 | `set samples 50; plot sin(x)` |
| N-09 | `set key left; plot sin(x), cos(x)` |

## Pari file-read cases: must-REJECT after `02-Cdc/Decisions_PARI_Forbidden_GROK_V1_1.md`

| id | input | kind | Status at #60 e483500 |
|---|---|---|---|
| P-28 | `read("/etc/hostname")` | reject (was strict) | **expected FAIL**: Java returned the host name (OK), WIMS pari.c also executed it |
| P-29 | `readvec("/etc/hostname")` | reject (new) | expected FAIL until Codex lands the fix |
| P-30 | `readstr("/etc/hostname")` | reject (new) | expected FAIL until Codex lands the fix |

Until #60 adds `read`/`readvec`/`readstr` to `AGB_ILLEGAL`, a rerun on e483500 is expected to give pari 27/30 (3 known FAILs), not a regression.
