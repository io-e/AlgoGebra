<!-- GROK_V1_3 -->
# Planning — next actions (GBot + Codex)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1_3 |
| Supersedes | GROK_V1_2 (CX-W9 was “open PR”) |
| Tip product | `origin/feat/external-engines` @ `9d67b57` |
| Tip docs | `feat/grok-sprint3-plan-v1-1` |
| WA-9 client PR | **[#67](https://github.com/io-e/AlgoGebra/pull/67)** → `feat/external-engines` (cites #66) — **OPEN, not merged** |
| Live evidence | **[#66](https://github.com/io-e/AlgoGebra/pull/66)** — GB-N3 live PASS @ `9177a5a` |
| Hook evidence | **[#64](https://github.com/io-e/AlgoGebra/pull/64)** — GB-W1…W8 |
| Handoff (historical) | `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md` |

---

## 0. Just closed — do not reopen

| Item | Result |
|---|---|
| GB-W1…W8 Debian hook | PASS (#64) |
| Codex CX-W1…W8 WA-9 client | DONE @ `9177a5a` |
| **GB-N3 live re-smoke** | **PASS** (#66) |
| **CX-W9 open PR** | **DONE** — [#67](https://github.com/io-e/AlgoGebra/pull/67) OPEN / MERGEABLE; **not merged** |
| Planning handoff on origin | Yes |

### GB-N3 live counts (archive)

Suite 23 **30/0/0** (W4-live ran); 00006 right/wrong 3/0/0 each; `été` cp1252 grade 1 (`e9 74 e9`).

---

## 1. Codex — current

| ID | Status | Notes |
|---|---|---|
| **CX-W9** | **PR open** [#67](https://github.com/io-e/AlgoGebra/pull/67) | Awaiting **owner merge**; cites #66 |
| **CX-R1** | **Untouched** — [#48](https://github.com/io-e/AlgoGebra/pull/48) / #33 still open | Resume when owner asks |
| **CX-R2** | **Untouched** — [#63](https://github.com/io-e/AlgoGebra/pull/63) still open | `-Headless -D06` when resumed |
| **CX-R3** | Optional | `e7f1ad4` regressions if needed |

### Codex — do not

- Merge #67 / #66 / #64 / #40–#42 without owner  
- Silent tip commits instead of PR updates  

### Paste brief (Codex)

> CX-W9 done as PR #67 (not merged). Stand by for owner review. #48 and #63 remain open/untouched until assigned. Do not merge #67 yourself.

---

## 2. Grok Bot — standby

| ID | Status |
|---|---|
| **GB-N3** | Closed (#66) |
| Server + auto-`wimslogd` | **Leave running** (GBot standing by) |
| **#57 / #58** | **MERGEABLE**; GBot policy = **merge base into branch** when behind (no force-rebase of pushed branches). No action now |
| **GB-N11** | Tear down CGI/`wimslogd` **only when owner asks** |

### P2 — later (owner ask)

| ID | Action |
|---|---|
| **GB-N7** | Track-E demo script |
| **GB-N8** | More `\choice` coverage |
| **GB-N9** | #48 Debian watch after Codex new head |
| **GB-N10** | Full `Run_All` after product merge wave |

### GBot — do not

- Merge #66 / #67 / product PRs  
- Force-rebase pushed branches (#57/#58)  
- Kill server/`wimslogd` without owner  
- Re-run GB-N3 unless tip moves  

### Paste brief (GBot)

> Stand by. Leave server + wimslogd as-is. #57/#58 already mergeable — no rebase; if they fall behind later, merge base in (no force-rebase). No merges.

---

## 3. Claude (spec)

Still useful: Spec §5 reply encoding = **windows-1252**; integer `grade` 0/1; point at #64 A.4 / #66 accent bytes `e9 74 e9`.

---

## 4. Critical path

```
#66 live PASS  →  #67 WA-9 PR OPEN (MERGEABLE)
                         │
                         ▼
              Owner review / merge #67
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
   connected WIMS client            #48 / #63 when owner assigns
```

**Owner ball:** merge or request changes on **#67**. GBot/Codex otherwise idle on WA-9.

---

*End of `Planning_GBot_Codex_Next_GROK_V1.md` (GROK_V1_3).*
