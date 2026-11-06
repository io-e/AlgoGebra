<!-- GROK_V1_2 -->
# Planning — next actions (GBot + Codex)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1_2 |
| Supersedes | GROK_V1_1 (GB-N3 was P0) |
| Tip product | `origin/feat/external-engines` @ `9d67b57` |
| Tip docs | `feat/grok-sprint3-plan-v1-1` @ **`134277a`** (handoff on origin) |
| WA-9 client | **`codex/wims-wa9-client` @ `9177a5a`** — fixture green + **live PASS** |
| Live evidence | **PR [#66](https://github.com/io-e/AlgoGebra/pull/66)** (`grok/gbot-wa9-live-9177a5a` @ `7cfc9e6`) — evidence only, **no merge** |
| Hook evidence | **PR [#64](https://github.com/io-e/AlgoGebra/pull/64)** — GB-W1…W8 |
| Handoff (historical) | `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md` |

---

## 0. Just closed — do not reopen

| Item | Result |
|---|---|
| GB-W1…W8 Debian hook | PASS (#64) |
| Codex CX-W1…W8 WA-9 client | DONE @ `9177a5a` (fixture suites) |
| **GB-N3 live re-smoke** | **PASS** (#66) — see counts below |
| Planning branch push | **`134277a` on origin** (handoff available) |

### GB-N3 live counts (`9177a5a` vs `:18431`)

| Run | Pass | Fail | Skip |
|---|---|---|---|
| `test-wims-live.ps1` 00006 right (grade 1) | 3 | 0 | 0 |
| `test-wims-live.ps1` 00006 wrong (grade 0) | 3 | 0 | 0 |
| Suite 23 (incl. **W4-live** executed) | **30** | 0 | 0 |
| Accent `été` cp1252 (grade 1; given/expected `e9 74 e9`) | 3 | 0 | 0 |

Server left up (PID 3966079); `wimslogd` auto-started (3988139) — leave as GBot left it unless owner tears down.

---

## 1. Codex — P0 now

| ID | Action | Notes |
|---|---|---|
| **CX-W9** | **Open PR** for `codex/wims-wa9-client` @ `9177a5a` (stack on owner base as directed) | Cite live **#66** + fixture results; **do not merge** alone |
| **CX-R1** | Finish **#48 / #33** 3D focus | Parallel |
| **CX-R2** | Land **#63** after `-Headless -D06` re-smoke | Parallel |
| **CX-R3** | Optional `e7f1ad4` engine regression tests | If gaps remain |

### Codex — do not

- Merge #66 / #64 / #40–#42 / WA-9 without owner  
- Drop live citation when opening CX-W9  

### Paste brief (Codex)

> Live proof is green: PR #66 against `9177a5a`. Open **CX-W9** PR for `codex/wims-wa9-client`; link #66 (30/0/0 suite 23 + live smokes). Do not merge. Parallel: #48, #63.

---

## 2. Grok Bot — after GB-N3

### Idle / P1 hygiene

| ID | Action |
|---|---|
| **GB-N1** | Skip — Codex already ships `tests/fixtures/wims-live/` |
| **GB-N4** | Rebase **#57**, **#58** onto tip when free; no merge |
| **GB-N5** | Optional: comment on #64 that #66 closed live WA-9 proof |
| **GB-N6** | If #63 merges: Debian N/A note or skip |
| **GB-N11** | When owner asks: tear down CGI 3966079 + wimslogd 3988139 |

### P2 — later (owner ask)

| ID | Action |
|---|---|
| **GB-N7** | Track-E demo script |
| **GB-N8** | More `\choice` coverage |
| **GB-N9** | #48 Debian watch after Codex new head |
| **GB-N10** | Full `Run_All` after product merge wave |

### GBot — do not

- Merge #66 or product PRs  
- Kill wimslogd mid-Codex use without owner  
- Re-run GB-N3 unless tip moves  

### Paste brief (GBot)

> GB-N3 done (#66). Nothing blocking. Optional: rebase #57/#58; leave server/wimslogd as-is until owner says stop. No merges.

---

## 3. Claude (spec)

Still useful: Spec §5 reply encoding = **windows-1252**; integer `grade` 0/1; point at #64 A.4 / #66 accent bytes `e9 74 e9`.

---

## 4. Critical path

```
9177a5a fixture green  +  #66 live PASS
              │
              ▼
     Codex CX-W9 open PR  ══parallel══  #48 / #63
              │
              ▼
     Owner review / merge WA-9
```

---

*End of `Planning_GBot_Codex_Next_GROK_V1.md` (GROK_V1_2).*
