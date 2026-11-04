<!-- GROK_V1 -->
# Actions — Codex + Grok Bot (after owner Q1–Q7 lock)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_Codex_GrokBot_After_WIMS_Q17_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Trigger | Owner locked WIMS CDC open points in `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md` |
| Constraints | **No merge**, no force-push, no `common` edits, #48/#33 stay **paused** until owner un-pauses |
| Claude lane (not these agents) | Fold Q1–Q7 into WIMS CDC + soften EE-P2d wording (F-1, F-2, F-6) |

---

## Context (read once)

| Decision | Effect on agents |
|---|---|
| **D-WIMS-G01** | Grade path = stock `cmd=new`/`reply` + JSON hook — **not** `adm/raw` as primary OEF grade; mocks on #40–#42 will need a later rebase |
| **D-WIMS-E01** | MVP: missing engine = hard error; no WIMS exploration fallback yet |
| **D-WIMS-C01** | Converter frozen variants **N=20** (GAP-6 accepted) |
| **D-WIMS-T01** | EE-P2d bar = **values match + rejections ≥ as strict** (not byte-identical) |
| **D-WIMS-L01** | Engine id `giac` → `geogebra-cas` (schemas/converter — Claude/Grok Build; agents consume after land) |
| **D-WIMS-E02** | yacas/m2/scilab stay non-gradable offline |

Open board (2026-11-04): **#60** EE-P1 (Codex), **#61** EE-P2 (Grok Bot), **#49** hygiene, **#40–#42** WIMS stack parked, **#48** focus paused.

---

## Codex (Windows) — ordered

### P0 — do now

| ID | Action | Done when |
|---|---|---|
| **C-A1** | Keep **PR #60** (EE-P1) reviewable: rebase onto current `feat/external-engines` tip if drifted; refresh Windows `test-engines.ps1` evidence path in PR body | PR mergeable + evidence link current; **do not merge** |
| **C-A2** | Expand **fixture set F** for EE-P2d / D-WIMS-T01 on Windows: grow Maxima, Gnuplot, GAP toward **≥20** cases each (Pari already ~12 → push to 20). Store under `03-RCP-Spike/engines/test/` or agreed fixtures dir | Counts published per engine; illegal inputs included |
| **C-A3** | Align fixture **pass bar** with D-WIMS-T01 in the EE-P1 report / test harness comments: compare **values** + rejection strictness, drop any “byte-identical” claim | Report cites D-WIMS-T01 |

### P1 — small / when free

| ID | Action | Done when |
|---|---|---|
| **C-A4** | Suite 09 **clipboard hygiene** only (owned fixture / skip if contaminated) — test-only PR | New PR, no product focus change |
| **C-A5** | After Claude lands `geogebra-cas` rename: grep Windows course/help fixtures and fix any leftover `"giac"` engine ids | Fixtures match schema |

### Paused / do not touch

| ID | Rule |
|---|---|
| **C-X1** | **#48 / #33** focus — paused; no pushes, no merge |
| **C-X2** | Scanner / BUG-015 product beyond what #60 already contains |
| **C-X3** | WIMS L2-1 adapter / #40–#42 merges |
| **C-X4** | yacas / m2 / scilab wrappers |

### Paste brief — Codex

> **P0:** Keep #60 rebase-clean + evidence fresh (no merge). Expand Maxima/Gnuplot/GAP fixtures toward ≥20 with D-WIMS-T01 soft parity (values + rejection strictness). **P1:** optional suite 09 clipboard hygiene PR. **Do not** touch #48/#33, WIMS merges, or scanner. Decisions: `02-Cdc/02-01_Wims_Integration/Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`.

---

## Grok Bot (Debian) — ordered

### P0 — do now

| ID | Action | Done when |
|---|---|---|
| **G-A1** | Finish / refresh **PR #61** EE-P2a..d evidence using **D-WIMS-T01** (not byte-identical). Call out per-engine fixture counts vs ≥20 target | PR body + evidence folder updated; gaps listed |
| **G-A2** | **GB-R2** from residual handoff: suite **19** on tip + fidelity metrics (value_equals vs object_exists, Hint: flat, engine key presence) | `Validation_GrokBot_WIMS_GV_Residual_…` or evidence under `03-RCP-Spike/evidence/` |
| **G-A3** | **#49** hygiene: confirm still MERGEABLE vs tip; leave for owner review — **no merge** | Status comment on #49 / #34 |

### P1 — next

| ID | Action | Done when |
|---|---|---|
| **G-A4** | **GB-R3** — count OEF corpus files that imply CAS/engine (pari/maxima/gap/…) | Count + 3 example paths |
| **G-A5** | **GB-R4** — rerun suites **21–23** on mock CGI for #40–#42 branches; note tip drift | TAP paths + counts |
| **G-A6** | **GB-R5** — Debian WIMS HTTP URL + start procedure + scoring usable Y/N | One short section in residual report |
| **G-A7** | Expand Debian half of fixture set F (share with Codex C-A2); prioritize Maxima/GAP | Toward ≥20 each |

### P2 — after Claude CDC fold-in (owner asks)

| ID | Action | Done when |
|---|---|---|
| **G-A8** | Rebase / redesign mock CGI for #40–#42 from fake `adm/class/sheet&job=getresult` toward **D-WIMS-G01** (`cmd=new`/`reply` + JSON hook). **Do not merge** | Design note or draft PR comment only until owner OK |
| **G-A9** | Optional Debian twin of GV-1 CGI probe (GB-R1) | Evidence pack if useful |
| **G-A10** | Spot-check `geogebra-cas` / Derivative example on Debian CAS (GB-R6) | Note in residual report |

### Still idle / blocked

| ID | Wait for |
|---|---|
| G-T2 WAR consume / Playwright W-09 browser | Codex WAR artifact + owner |
| G-T4 D-11 product Run_All | CourseTreePanel image |
| #48 focus verify on Xvfb | Owner un-pause + Windows proof first |
| Merge #40–#42 / #60 / #61 | Owner |

### Paste brief — Grok Bot

> **P0:** Refresh #61 EE-P2 with D-WIMS-T01 soft parity; run suite 19 fidelity (GB-R2); confirm #49 still mergeable (no merge). **P1:** GB-R3 corpus engine counts, suites 21–23 mock green, Debian WIMS URL note, grow Maxima/GAP fixtures. **P2 only when asked:** mock rebase to `cmd=new`/`reply`+JSON (D-WIMS-G01). Read `Handoff_GrokBot_WIMS_GV_Residual_GROK_V1.md` + `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`. No merges.

---

## Dependency sketch

```
Claude: fold Q1–Q7 into CDC / schemas (F-1..F-3, F-6)
        │
        ├─ Codex C-A1..A3  (#60 + fixtures Windows)
        │         │
        │         └─ Grok Bot G-A1 / G-A7  (#61 + fixtures Debian)
        │
        └─ Grok Bot G-A2..A6  (GV residual, suites 19/21–23)
                    │
                    └─ [owner ask] G-A8 mock rebase for #40–#42
```

---

## Explicitly not for Codex or Grok Bot this wave

- Pushing local commits `47f6fbc` / `37b9639` (owner / Grok Build session)
- Closing #33 or merging #48
- Implementing L2-1 WIMS adapter
- Course-panel FR chrome i18n (#39 P2 leftover)
- #53 null-panel product fix (evidence-only if owner asks)

---

*End of `Actions_Codex_GrokBot_After_WIMS_Q17_GROK_V1.md`.*
