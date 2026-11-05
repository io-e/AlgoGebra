<!-- GROK_V1_1 -->
# Planning — next actions (GBot + Codex)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1_1 |
| Supersedes | `Planning_GBot_Next_Actions_GROK_V1.md` P0/P1 (GB-W1…W8 / GB-E1 closed) |
| Tip product | `origin/feat/external-engines` @ `9d67b57` |
| Tip docs | `feat/grok-sprint3-plan-v1-1` |
| WA-9 client | **`codex/wims-wa9-client` @ `9177a5a`** (pushed; **no PR yet**) — fixture suites green; live SKIP until GBot |
| Debian evidence | **PR [#64](https://github.com/io-e/AlgoGebra/pull/64)** — GB-W1…W8 done |
| Live re-smoke brief | `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md` |
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

## 1. Codex — status after `9177a5a`

| ID | Status |
|---|---|
| **CX-W1…W8** | **DONE** on `codex/wims-wa9-client` @ `9177a5a` (fixture/replay green; no PR opened) |
| Live proof | **Pending GBot GB-N3** (suite 23 skip until `GGB_WIMS_LIVE_ENDPOINT`) |

### P1 — still open for Codex

| ID | Action | Notes |
|---|---|---|
| **CX-R1** | Finish **#48 / #33** 3D focus | Separate lane |
| **CX-R2** | Land **#63** D-06 after `-Headless -D06` re-smoke | Includes `CoreBundleCatalog` |
| **CX-R3** | Optional: engine regression tests for `e7f1ad4` | If not already covered |
| **CX-W9** | After GBot live PASS: open PR for WA-9 (or stack on owner base); do not merge alone | Owner review |

### Codex — do not

- Merge #64 / #40–#42 / #57–#58 / WA-9 without owner  
- Claim live-server PASS from fixture replay alone  

---

## 2. Grok Bot — ordered plan (**GB-N3 is now P0**)

### P0 — live re-smoke WA-9

| ID | Action | Done when |
|---|---|---|
| **GB-N3** | Follow `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md`: checkout `9177a5a`, live `test-wims-live.ps1` + suite 23 with `GGB_WIMS_LIVE_ENDPOINT` | Evidence folder + short report; W4-live **not** SKIP |
| **GB-N2** | Keep Debian WIMS+hook up for that run; tear down CGI (+ auto wimslogd) after | URL in report |

### P1 — after live green / hygiene

| ID | Action | Done when |
|---|---|---|
| **GB-N1** | Optional: note that Codex already vendored sanitized fixtures under `tests/fixtures/wims-live/` — only add extras if live finds gaps | Skip if nothing new |
| **GB-N4** | Rebase **#57**, **#58** onto tip when free | Comments; no merge |
| **GB-N5** | Comment on **#64** / WA-9 that live re-smoke used `9177a5a` | Link evidence |

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
#64 evidence (done)  →  Codex WA-9 @ 9177a5a (fixture green, done)
                              │
                              ▼
                    GBot GB-N3 live re-smoke  ◄── P0 now
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   evidence report      Codex CX-W9 PR      Codex CX-R1/R2 (#48,#63)
          │
          ▼
Owner: merge WA-9 after live PASS; park #40–#42; archive #64
```

---

## 5. Paste briefs

### GBot

> **P0 = GB-N3.** Checkout `codex/wims-wa9-client` @ `9177a5a`. Read `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md`. With WIMS+hook on `:18431`, run `test-wims-live.ps1` (00006 right/wrong) and suite 23 with `GGB_WIMS_LIVE_ENDPOINT` set. Optional `gbw8acc`/`été`. Evidence folder; no merges. wimslogd: don’t start manually.

### Codex

> WA-9 fixture work done @ `9177a5a`. Wait for GBot live PASS, then open PR (CX-W9). Parallel: #48 / #63. Do not claim live-server evidence from fixture replay.

---

*End of `Planning_GBot_Codex_Next_GROK_V1.md`.*
