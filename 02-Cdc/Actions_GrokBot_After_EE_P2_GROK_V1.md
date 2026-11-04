<!-- GROK_V1 -->
# Grok Bot — next actions after EE-P2 / GV residual (`Actions_GrokBot_After_EE_P2_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_GrokBot_After_EE_P2_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Audience | **Grok Bot** (Debian) |
| Prior wave | P0/P1 in `Actions_Codex_GrokBot_After_WIMS_Q17_GROK_V1.md` — **done** (G-A1..G-A7) |
| Constraints | **No merge**, no force-push, no `common` edits, #48/#33 stay paused |
| Tip docs | `feat/grok-sprint3-plan-v1-1` @ `d40684f` (D-WIMS-* + BUG-006 V1_1 on GitHub) |

---

## Why a new queue

The previous brief left GBot with only **G-A8** (owner-gated) and idle WAR/focus work. Codex now owns Gnuplot one-line + Pari `read*` on **#60**. GBot can stay productive on Debian evidence and readiness.

---

## P0 — do now (parallel with Codex)

| ID | Action | Done when |
|---|---|---|
| **G-B1** | **Watch #60** for Codex landing of (a) Gnuplot multi-statement `plot` fix and (b) `AGB_ILLEGAL` + `read`/`readvec`/`readstr`. When either lands, re-run the **Pari attack slice** + **Gnuplot soft-parity slice** of `ee_fixture_set_F_GROK_V1.json` on Debian against that commit. Post counts as a comment on **#61** (or refresh #61 evidence). **Do not merge.** | Comment with PASS/FAIL counts + commit SHA under test |
| **G-B2** | Open a **PR** for the GV residual branch `grok/gv-residual-gb-r2-r5` → `feat/grok-sprint3-plan-v1-1` (or `feat/external-engines` if that is the agreed base). Title: evidence-only GB-R2..R5. Body links #34 status. **Review-only, no merge.** | PR URL posted |
| **G-B3** | Add to #61 (or residual report): a one-page **fixture inventory** — per-engine case counts vs ≥20 target, list of the 4 Gnuplot one-line failures (exact strings), and the `read("/etc/hostname")` case marked **must-REJECT after V1_1**. | Section in PR #61 or residual MD |

### P1 — useful while waiting on Codex

| ID | Action | Done when |
|---|---|---|
| **G-B4** | Grow **GAP** Java side readiness note: #60 has no Java GAP adapter yet (24/24 WIMS-only). Document minimum GAP fixture subset for when Codex adds the adapter; keep fixtures in `ee_fixture_set_F_GROK_V1.json`. | Short “GAP adapter blockers” note on #61 |
| **G-B5** | **GB-R1 optional twin**: one Debian HTTP GV-1 style probe (`cmd=new`/`reply` already done in G-A6). Add `module=adm/raw&job=getinfoserver` JSON spot-check on your `127.0.0.1:18431` if still easy to start. Evidence only. | Addendum on residual branch / PR from G-B2 |
| **G-B6** | Suite **15** web probe refresh if WAR from prior Debian build still available (you rebuilt GeoGebra web for suite 23). Confirm suite 15 still green; if WAR missing, document rebuild command only — **do not** block on full GWT from scratch unless cheap. | TAP or SKIP+reason |
| **G-B7** | Rebase-check **#49** against current `feat/external-engines` tip again after any tip move; leave mergeable status on #34 or #49. **No merge.** | One-line status |

### P2 — only when owner asks

| ID | Action |
|---|---|
| **G-A8** | Mock CGI rebase for #40–#42 → D-WIMS-G01 (`cmd=new`/`reply` + JSON hook). Design note / draft only until OK. |
| **G-B8** | After Claude lands `geogebra-cas` rename: spot-check Debian CAS `Derivative(...)` help example (old GB-R6). |
| **G-B9** | #48 / #33 Debian Xvfb re-verify — **only** after owner un-pause + Windows suite 09+10 gate. |

### Still idle / blocked

| Item | Wait for |
|---|---|
| G-T2 / Playwright W-09 full | Codex WAR + owner |
| G-T4 D-11 product | CourseTreePanel image |
| Merge #40–#42, #60, #61, #49 | Owner |

---

## Paste brief — Grok Bot

> **P0:** (1) Watch #60 — when Codex lands Gnuplot one-line fix and/or Pari `read*` block, re-run those fixture slices on Debian and comment on #61. (2) Open a **review-only PR** for `grok/gv-residual-gb-r2-r5`. (3) Publish fixture inventory + must-REJECT `read` case on #61. **P1:** GAP adapter blockers note, optional `adm/raw` getinfoserver spot-check, suite 15 if WAR handy, #49 mergeability ping. **Skip G-A8** until asked. **No merges.** Specs now on tip: `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`, `Decisions_PARI_Forbidden_GROK_V1_1.md`.

---

## Codex dependency (for awareness)

| Codex on #60 | Then GBot |
|---|---|
| Gnuplot line-start filter fix | G-B1 Gnuplot re-run |
| `read`/`readvec`/`readstr` in `AGB_ILLEGAL` | G-B1 Pari attack re-run (expect REJECT) |
| Optional Java GAP adapter | G-B4 fixtures become runnable on Java |

---

*End of `Actions_GrokBot_After_EE_P2_GROK_V1.md`.*
