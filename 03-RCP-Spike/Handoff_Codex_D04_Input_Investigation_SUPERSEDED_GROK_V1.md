<!-- GROK_V1 -->
# Supersession — D-04 Input Investigation Handoff

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_D04_Input_Investigation_SUPERSEDED_GROK_V1.md` |
| Date | 2026-11-04 |
| Supersedes | `03-RCP-Spike/Handoff_Codex_D04_Input_Investigation_CLAUDE_V1.md` |
| Status | **Do not execute the Claude V1 investigation plan as written** |

---

## Why the Claude handoff is stale

The Claude V1 handoff treats `"Please check your input"` on valid `C=5` + Enter as the open D-04 blocker and proposes SWT Traverse / KeyListener instrumentation (hypotheses H1–H3).

That symptom was already root-caused and closed:

| Fact | Evidence |
|---|---|
| Root cause | `Log.logger` null in embedded `GeoGebraPanel`; `Log.read()` NPE from `ScreenReaderAdapterD.readText` after object creation → false “Please check your input” |
| Fix | `GeoGebraLoggerBootstrap` / `initializeGeoGebraLogger()` in host (PR #45, merge `2f24a7e`, issue #28) |
| Suite 09 after fix | **19/1/0** — sole residual is `D04-FOCUS-01` (issue **#33**) |
| Governing residual plan | `02-Cdc/Plan_D04_Residual_Focus_Issue33_GROK_V1.md` |

## Current residual (not the Claude plan)

| Id | Symptom | Owner status |
|---|---|---|
| **#33** / PR **#48** | First keystrokes lost after switching 2D↔3D algebra bars (window focus) | **Paused** — no push/merge until deliberate design resume |

Do **not** re-open BUG-010 / logger / “Please check your input” instrumentation.

## Parallel work that is unblocked

| Lane | Status |
|---|---|
| Engine subprocess EE-P1 | Started on `feat/engine-subprocess-p1` @ `53b807a` — see `evidence/Engine_Subprocess_P1_Report_GROK_V1.md` |

---

*End of `Handoff_Codex_D04_Input_Investigation_SUPERSEDED_GROK_V1.md`.*
