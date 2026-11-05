# EE-P2a..d Linux validation — soft parity (D-WIMS-T01) on PR #60 head (GROK_V1)

Run: `20261104_1018_EE-P2_GROK_V1` (2026-11-04 10:18 Europe/Paris), Debian 13 x86-64. Supersedes the byte-identical run `20261104_0742_EE-P2_GROK_V1` (27/27 on `dd8ba96`, kept for history).

**Code under test:** PR #60 `feat/engine-subprocess-p1` code commit `60fc43e`. Branch head is now `e41eda7`, whose two extra commits (`fdff5c8`, `e41eda7`) add Windows evidence files only (no code). Both are merged into this branch with normal merge commits.
**Windows checks for #60:** GitHub has **no CI check runs / statuses** on `60fc43e` or `e41eda7` (0 check runs, combined status pending/0). Windows evidence exists only as committed files: `03-RCP-Spike/evidence/20261104-windows-ee-p1-codex-60fc43e/` (Codex, Windows 11, 21 PASS / 0 FAIL / 0 SKIP).

## Comparison rule
**D-WIMS-T01 soft parity.** The decision text is not on GitHub yet (owner brief `Actions_Codex_GrokBot_After_WIMS_Q17_GROK_V1.md` is local only), so this run uses the definition relayed on 2026-11-04: *compare values and rejection strictness, i.e. same normalized value, and Java rejects at least as strictly as WIMS. Byte-identical output is not required.*
CDC External Engines V1_2 (`origin/feat/grok-sprint3-plan-v1-1`, `02-Cdc/02-01_Wims_Integration/`) EE-P2d still says *"Byte-identical output on fixture set F (≥20 cases per engine)"*. This run applies the **≥20 cases per engine** part and replaces "byte-identical" with D-WIMS-T01. The V1_2 row should be updated to match.

Fixture set F: `03-RCP-Spike/tests/fixtures/ee_fixture_set_F_GROK_V1.json`. It is engine-agnostic (fields: id, engine, input, kind, expected.value, expected.normalization, expected_rejection, sentinel) and shared with Codex for C-A2.
Kinds: `value` (same normalized value on both sides, and equal to expected.value when set); `error` (Java returns an error); `png` (Java gives a valid PNG, checked by magic bytes, at 800x600); `reject` (Java rejects, with no side effect or sentinel file); `strict` (Java must reject whenever WIMS blocks).

## Case counts
| Engine | Cases | value/png | error | reject | strict | Result |
|---|---|---|---|---|---|---|
| Pari | 28 | 14 | 2 | 11 | 1 | 28/28 PASS |
| Maxima | 38 | 13 | 1 | 22 | 2 | 38/38 PASS |
| Gnuplot | 28 | 13 png | 0 | 15 | 0 | 24/28 (4 FAIL) |
| GAP | 24 | 12 | 1 | 11 | 0 | 24/24 REF-PASS (WIMS side only, no Java adapter) |
| **Total** | **118** | | | | | **114 PASS / 4 FAIL** |

## EE-P2 verdicts (V1_2 criteria + D-WIMS-T01)
| Step | V1_2 criterion | Verdict |
|---|---|---|
| EE-P2a | binaries on PATH, versions recorded | **PASS**. See `versions.txt`: PARI/GP 2.17.2, Maxima 5.47.0, Gnuplot 6.0p2 (apt), GAP 4.14.0 (source build), Temurin 21.0.13 |
| EE-P2b | WIMS C interfaces, provenance recorded | **PASS**. Stock WIMS 4.31b `src/Interfaces` pari/maxima/gap, rebuilt from `/workspace/wims-full`. Gnuplot has no WIMS interface, so raw gnuplot (as WIMS exec.c runs it) is the reference |
| EE-P2c | Java SubprocessEngine on Linux, Java 21 | **PASS** for Pari, Maxima and Gnuplot. Codex's `EngineAcceptanceTest` gives 21/21 PASS on Linux (`codex_acceptance_linux.log`). GAP: **N/A**, there is still no Java adapter on #60 |
| EE-P2d | compare on F, ≥20 per engine | **PARTIAL**. Pari and Maxima PASS. Gnuplot has 4 FAILs (below). GAP is WIMS-reference only |

## Findings
1. **Gnuplot: Java over-rejects valid one-line scripts (4 FAIL, N-04/N-06/N-08/N-09).** `set xrange [0:1]; plot x`, `set grid; plot sin(x)`, `set samples 50; plot sin(x)` and `set key left; plot sin(x), cos(x)` return `INVALID_REQUEST`, while WIMS-side gnuplot renders an 800x600 PNG. The cause is that `PLOT_COMMAND` is `(?im)^\s*(?:plot|splot)\b`, so `plot` must start a line. The same scripts written with newlines pass (N-10..N-13). Java isn't less strict here; it's a functional gap. Fix for Codex: accept `plot` after `;`.
2. **No real value mismatches.** Only text-level differences remain. P-14 `polroots(x^2-2)` gives `+0.0*I` on WIMS and `+0.E-38*I` on Java. The values are numerically equal, so it passes under the `numeric` normalization. The gp binary is the same on both sides, so this is a header or output post-processing difference to note, not a calculation difference.
3. **No case where Java is less strict than WIMS.** Of 48 reject cases run on both sides: 15 are blocked on both sides. In 6, WIMS-side gnuplot actually ran the command (`plot system("id")`, `system "id"`, `set output`, `save`, `set print`, `print system("id")`), so Java is stricter. In the other 27, WIMS neutralised the command (Maxima/Pari mangle the token) or it had no observable effect, and Java rejects.
4. **Shared gap: Pari `read("/etc/hostname")` (P-28) is allowed by both WIMS and Java** and returns the file contents. This is soft-parity PASS (Java is as strict as WIMS), but it is an arbitrary file read. Suggest adding `read`/`readvec`/`readstr` to `AGB_ILLEGAL` (owner decision, like BUG-006).
5. **Maxima `:lisp` and `?system` (M-37/M-38)** are rejected by Java (`INVALID_OUTPUT` / `COMMAND_REJECTED`), and the sentinel shows no shell execution on either side.
6. **GAP (WIMS side only):** all 12 values are correct, and all 11 security negatives (Exec, Process, Reread, SaveWorkspace, Filename, PrintTo, AppendTo, Read, InputTextFile, DirectoriesSystemPrograms, IO_fork) are blocked by gap.c's illegal[]/illpart[] mangling. Harness note: gap.c sets HOME=/nodir, so a `.gap_hist` PrintTo error line is filtered out as noise.
7. **Harness change:** pwsh 7.4 wraps empty stderr lines as `RemoteException`, so these are now filtered on both sides. This would have broken a byte-identical comparison.

## Files
`results.json`, `results.csv`, `scenario_run.log`, `codex_acceptance_linux.log`, `versions.txt`, `SHA256SUMS`. Scenario: `tests/scenarios/S_EE-P2_Linux_Compare_GROK_V1.ps1` (v2, fixture-driven). Driver: `tests/tools/EeP2Driver_GROK_V1.java` (unchanged). No production Java, states.yaml or Run_All changed.
