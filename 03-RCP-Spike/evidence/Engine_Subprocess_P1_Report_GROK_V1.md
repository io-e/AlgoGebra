<!-- GROK_V1 -->
# Engine Subprocess P1 Report (EE-P1)

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/evidence/Engine_Subprocess_P1_Report_GROK_V1.md` |
| Date | 2026-11-04 |
| Branch | `feat/engine-subprocess-p1` (from `origin/feat/external-engines` @ `4e13b83`) |
| OS / Java | Windows x86_64 / Temurin JDK 21.0.12 |
| Command | `pwsh -File 03-RCP-Spike/test-engines.ps1` with PATH = Pari64-2-19-0 + maxima-5.49.0 + gnuplot |

---

## Resume context

Codex session `G1_Geogebra_Migration_CODEX_v1` ended on CDC validation. That review was already applied on `feat/grok-sprint3-plan-v1-1` (`Cdc_External_Engines…V1_2`). The Claude D-04 “Please check your input” investigation handoff is **stale** (BUG-010 closed via logger bootstrap); residual D-04 is **#33** and remains **owner-paused**. This lane implements the unblocked EE-P1 hardening.

## Gap analysis vs handoff / CDC V1_2

| Item | Before this branch | After |
|---|---|---|
| PARI AGB_ILLEGAL (+ eval) | Already present | Unchanged (verified by tests) |
| Maxima WIMS illegal/illpart | Already present | Added explicit load/save/batch negative tests |
| Gnuplot PNG magic + host output path | Already present | Unchanged |
| Gnuplot `pngcairo` header | Used `png` | **Switched to `pngcairo`** |
| Gnuplot `call` / backticks | Missing | **Blocked** |
| Empty text after success (BUG-015) | OPEN — `factor((` → OK empty | **INVALID_OUTPUT** in Pari + Maxima |
| Timeout / `destroyForcibly` | Already present | Unchanged (PASS) |

## Test matrix results

| Test ID | Result | Notes |
|---|---|---|
| T-BASE PATH discovery | **PASS** | |
| T-BASE timeout / process-tree kill | **PASS** | |
| T-BASE WIMS marker extraction | **PASS** | |
| T-PARI-01 `factor(2^64-1)` | **PASS** | `3,1;5,1;17,1;257,1;641,1;65537,1;6700417,1` |
| T-PARI BUG-006 filters | **PASS** | system/extern/install/eval (pre-process) |
| T-PARI BUG-015 `factor((` | **PASS** | `INVALID_OUTPUT` |
| T-MAX-01 `diff(sin(x^2), x)` | **PASS** | `2*x*cos(x^2)` |
| T-MAX filters | **PASS** | system/plot/load/save/batch |
| T-GNU-01 `plot sin(x)` | **PASS** | 800×600 PNG, signature OK |
| T-GNU filters | **PASS** | `!`, system, set output/print, call, load, backticks |

No SKIP rows: gp, maxima, and gnuplot were all on PATH for this run.

## Code touched

- `engines/pari/.../PariGPEngine.java` — blank payload → `INVALID_OUTPUT`
- `engines/maxima/.../MaximaEngine.java` — blank payload → `INVALID_OUTPUT`
- `engines/gnuplot/.../GnuplotEngine.java` — pngcairo; block `call` + backticks
- Matching unit/acceptance tests under `engines/*/test/`
- `states.yaml` — BUG-015 → `FIXED_PENDING_REVIEW`

## Not in this PR

- Connected WIMS mode / S-01 / S-02
- OSGi production factory wiring beyond existing activators
- GAP engine
- Issue #33 / PR #48 focus work (still paused)
- Full scenario pack re-run of `S_X-06_*.ps1` against an installed RCP image (unit harness covers the engine layer)

## Next

1. Owner/Grok review of BUG-015 status.
2. Optional: rebuild product image and re-run scenario `X-06` for ledger closure.
3. When owner un-pauses #33: deliberate frame-before-input design per `Plan_D04_Residual_Focus_Issue33_GROK_V1.md`.

---

*End of `Engine_Subprocess_P1_Report_GROK_V1.md`.*
