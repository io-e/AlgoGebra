<!-- GROK_V1 -->
# Planning — next actions (GBot + Codex)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1 |
| Supersedes | `Planning_GBot_Next_Actions_GROK_V1.md` P0/P1 (GB-W1…W8 / GB-E1 closed) |
| Tip product | `origin/feat/external-engines` @ `9d67b57` |
| Tip docs | `feat/grok-sprint3-plan-v1-1` (this commit wave) |
| Debian evidence | **PR [#64](https://github.com/io-e/AlgoGebra/pull/64)** — GB-W1…W8 done; **do not merge** unless owner wants archive on tip |
| Reports | `Report_GBot_P1_GB_W5_W8_GROK_V1.md` (GROK_V1_1), `Report_GBot_AlgoGebra_JSON_Debian_GROK_V1.md` (#64) |

---

## 0. Just closed — do not reopen

| Item | Result |
|---|---|
| GB-W1…W4 Debian JSON hook smoke | PASS (#64) |
| GB-W5 installer / `build-runtime-tree` | Draft on wims4win `4ae4d86`; Debian parity OK |
| GB-W7 live suites 21–23 | **DONE** — 21: 14/0/0; 22: 19/9/0; 23: 4/2/0; Codex gaps G1–G10 |
| GB-W8 accented answer | **VERIFIED** — cp1252 `été` grade 1; UTF-8 submit wrong |
| GB-E1 #57/#58 | Behind tip; rebase before merge |
| GBot session | Nothing pending on GBot side for W5–W8 |

---

## 1. Codex — ordered plan (primary now)

### P0 — WA-9 grade client (blocks connected WIMS)

Rebase product client off D-S01 mock onto real hook contract. Source of truth: **#64 Addendum A.3** (also copied in P1 report V1_1).

| ID | Action | Done when |
|---|---|---|
| **CX-W1** | Implement `cmd=new` → parse `session` → `cmd=reply&special_parm=algogebra_json&replyN=…` | Unit/integration against recorded Debian HTML fixtures from #64 |
| **CX-W2** | Extract `<!-- ALGOGEBRA_JSON_BEGIN…END -->`; accept `{grade,seed,answers[],feedback}` | Parses #64 `json/*.json` |
| **CX-W3** | 3-way HTML handling (no new status field unless owner approves): JSON / `answer_analysis` / sure-retry UI | Matches owner rules |
| **CX-W4** | Encode `replyN` as **windows-1252** percent-encoding (not UTF-8) | Accent fixture: `été` → grade 1 |
| **CX-W5** | Accept JSON **number** grades `0` and `1` (int OK; no require `0.0`) | Fixture assert |
| **CX-W6** | UI: do not show `answers[].given` as exact student keystrokes | Copy / a11y note |
| **CX-W7** | Update suites **22** (+ **23** asserts): live path green for happy path; keep 413/500/timeout **mock-only** (G8) | TAP: live happy path PASS; mock edge PASS |
| **CX-W8** | Reword suite **21** WT-06/WT-13 away from D-S01 `job=getresult` | 21 still 14/0/0 with new contract text |

**Out of CX scope:** merging #40–#42 as-is; inventing `adm/raw` grade; editing `common`.

### P1 — RCP product (parallel if owner keeps them unblocked)

| ID | Action | Notes |
|---|---|---|
| **CX-R1** | Finish **#48 / #33** 3D focus | Owner already launched Codex lane |
| **CX-R2** | Land **#63** D-06 after `-Headless -D06` re-smoke | Includes `CoreBundleCatalog` `1e48358` |
| **CX-R3** | Optional: engine regression tests for `e7f1ad4` (backtick / eval / `read*`) | If not already covered |

### Codex — do not

- Merge #64 / #40–#42 / #57–#58 without owner  
- Assume UTF-8 form bodies to WIMS  
- Treat “HTML response” as a single error class  

---

## 2. Grok Bot — ordered plan (after Codex or idle-support)

### P0 — support Codex WA-9 (on request)

| ID | Action | Done when |
|---|---|---|
| **GB-N1** | Publish **fixture pack** from #64 for CI: wrong/right 00006/00076 + `gbw8acc` HTML/JSON (+ SHA256) under `03-RCP-Spike/tests/fixtures/wims-live/` on a **draft** PR | Files + README; no merge |
| **GB-N2** | Keep Debian WIMS+hook up for Codex smoke; **wimslogd stay stopped** unless owner asks | URL note in PR comment |
| **GB-N3** | After CX-W7 push: re-run suites 22/23 live; attach TAP | Evidence folder |

### P1 — hygiene / evidence PRs

| ID | Action |
|---|---|
| **GB-N4** | Rebase **#57**, **#58** onto `9d67b57+`; refresh if needed; still no merge |
| **GB-N5** | Optional: close-loop comment on **#64** that P1 report V1_1 cites it for GB-W7/W8 |
| **GB-N6** | If owner merges #63: Debian N/A note or skip |

### P2 — later (owner ask)

| ID | Action |
|---|---|
| **GB-N7** | GB-W9 track-E demo script (student path) |
| **GB-N8** | GB-W10 more `\choice` coverage |
| **GB-N9** | Resume #48 Debian watch only after Codex new head |
| **GB-N10** | Full `Run_All` after next product merge wave |

### GBot — do not

- Compete with Codex on WA-9 product JS  
- Restart wimslogd  
- Merge evidence PRs  
- Redesign hook / add JSON `status` without approval  

---

## 3. Claude (spec) — one-liner ask

Update `Spec_WIMS_Message_Integration` / CDC: reply field encoding = **windows-1252**; document integer `grade` 0/1; point at #64 A.4. Fold G1–G10 into WI-22 if still D-S01-shaped.

---

## 4. Critical path

```
#64 evidence (done)
        │
        ▼
Codex CX-W1…W8  (WA-9 client + suites)  ══parallel══  Codex CX-R1/R2 (#48, #63)
        │
        ▼
GBot GB-N3 live re-smoke 22/23
        │
        ▼
Owner: merge client PR; park or rewrite #40–#42; decide #64 archive merge
```

---

## 5. Paste briefs

### GBot

> P0 closed (W1–W8). Next: on request, fixture pack from #64 for Codex (GB-N1); keep hook server up, wimslogd stopped; after Codex WA-9 push, re-smoke suites 22/23 live (GB-N3). Rebase #57/#58 when free. No merges.

### Codex

> Primary: WA-9 rebase using #64 gaps G1–G10 — `cmd=new`/`reply` + `special_parm`, HTML comment JSON, cp1252 encode, int grades, 3-way HTML classify. Update suites 21–23. Parallel: finish #48 and #63 re-smoke. Do not merge #40–#42 unchanged.

---

*End of `Planning_GBot_Codex_Next_GROK_V1.md`.*
