<!-- GROK_V1 -->
# Planning — Grok Bot next actions

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1 |
| Audience | **Grok Bot** (Debian VM + WIMS HTTP + evidence PRs) |
| Tip (product) | `origin/feat/external-engines` @ `9d67b57` (+ #49, #60, #61) |
| Context | Codex lanes **unblocked** to finish (#48/#33, #63, engines). GBot stays off those product branches. |
| Supersedes (GBot rows) | `Planning_Sprint3_Next_Actions_GROK_V1_1.md` §Grok Bot (stale: #49 merged, #48 watch policy changed) |
| Primary handoff | `02-Cdc/02-01_Wims_Integration/Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` |

---

## 0. Role this sprint

| Lane | Owner | GBot does |
|---|---|---|
| 3D focus #48 / #33 | **Codex** | Idle watch only if owner asks; **no** focus rebuild loops |
| D-06 #63 | **Codex** | Optional read-only recheck after merge; no host edits |
| Engines / GAP adapter | **Codex** | No Java; evidence only if asked |
| **WIMS JSON hook on Debian** | **GBot** | **Main job** — GB-W1…W4 then W5…W8 |
| Evidence PRs #57 / #58 | GBot | Rebase / refresh mergeability vs new tip; **no merge** without owner |
| WIMS CDC / schemas | Claude / Grok Build | Read-only; do not edit unless asked |

**Merge rule:** nothing merges without owner OK. Prefer evidence folders + draft PRs.

---

## 1. Closed — do not reopen

| Item | Result |
|---|---|
| #49 suite 09 hygiene | **MERGED** |
| #60 EE-P1 harden | **MERGED** (`c593c8d`) |
| #61 EE-P2 Linux validation | **MERGED** |
| #62 GV residual GB-R2..R5 | **MERGED** (evidence) |
| GV desktop WA-6 / live GV-1 | Done (Windows + CDC fold-in) |
| Watches #48 / #60 (prior session) | Paused at sign-off — leave paused unless owner resumes |

---

## 2. P0 — do now (WIMS Debian JSON hook)

Execute in order from the AlgoGebra×WIMS handoff. Wire rules are binding:

1. Grade path = `cmd=new` → `cmd=reply` + `special_parm=algogebra_json` (**reply only**)  
2. Fields = `replyN` / `choiceN` (never invent `ansN`)  
3. Extract `<!-- ALGOGEBRA_JSON_BEGIN … ALGOGEBRA_JSON_END -->`  
4. Primary grade is **not** `adm/raw` / `job=getresult`

| ID | Action | Done when | Est. |
|---|---|---|---|
| **GB-W1** | Pull `feat/algogebra-wims-integration` (≥ `bb929e3`); read `OEF_Variable_Map` + `runtime_patch/` | Tip noted in report | 0.5 h |
| **GB-W2** | Install hook on Debian WIMS: `algogebra_json.phtml` + `answer.phtml` patch; keep `.bak` | Paths + backup recorded | 1 h |
| **GB-W3** | Live smoke vs `http://127.0.0.1:18431/wims/wims.cgi` (or current GB-R5 URL): **00006** / **00076** wrong+right | Evidence pack: raw HTML + JSON + PASS/FAIL table | 2 h |
| **GB-W4** | Negative: `cmd=reply` **without** `special_parm` → no JSON markers | Same pack | 0.5 h |

**Evidence path:**  
`03-RCP-Spike/evidence/YYYYMMDD-gbot-algogebra-json-debian_GROK_V1/`

**Report:**  
`02-Cdc/02-01_Wims_Integration/Report_GBot_AlgoGebra_JSON_Debian_GROK_V1.md`

---

## 3. P1 — after P0 green

| ID | Action | Done when | Est. |
|---|---|---|---|
| **GB-W5** | Wire hook into wims4win `tools/build-runtime-tree.sh` (draft PR OK) | Commit/PR link; no merge required | 2–3 h |
| **GB-W7** | Suites **21–23** against **live** Debian+hook (mocks stay green separately); list WA-9 gaps for Codex | TAP + gap list | 3 h |
| **GB-W8** | Encoding / charset spot-check (WIMS often `windows-1252` / `iso-8859-1`) | Note in report | 1 h |
| **GB-E1** | Rebase / recheck open evidence PRs **#57**, **#58** on tip `9d67b57+`; comment mergeability | Comment on each PR | 1 h |
| **GB-E2** | If Codex merges #63: optional Debian note “D-06 N/A on Linux product image” or skip | One paragraph | 0.5 h |

---

## 4. P2 — later / owner must ask

| ID | Action |
|---|---|
| **GB-W9** | Full student track-E demo script on Debian |
| **GB-W10** | True `\choice` exercise (`choiceN` in JSON) |
| **GB-W11** | Record real Debian JSON fixtures for Codex WA-9 mock rebase |
| **GB-W12** | Refresh GB-R5 URL note if port/path changed |
| **GB-F1** | Resume #48 watch only after Codex pushes a new head — Debian suite 09/10 evidence, no product edits |
| **GB-F2** | #53 null-panel evidence only |
| **GB-F3** | Full `Run_All` after next product merge wave |

---

## 5. Explicit non-goals

| ID | Do not |
|---|---|
| **GB-X1** | Merge any PR without owner OK (#40–#42, #57–#59, #63, wims4win, …) |
| **GB-X2** | Redesign hook as `adm/raw` or new `cmd=getresult` |
| **GB-X3** | Send `special_parm=algogebra_json` on `cmd=new` |
| **GB-X4** | Edit GeoGebra `common` or RCP host Java on Codex branches |
| **GB-X5** | Compete with Codex on #48 / #33 / #63 |
| **GB-X6** | Settle S-01/S-02 or rewrite WIMS CDC (Claude/Grok Build) |
| **GB-X7** | Blind focus iterations / scanner / BUG-015 |

---

## 6. Critical path

```
Codex finishes #48 / #63 / engines  ──parallel──►  GBot GB-W1…W4 (Debian JSON hook)
                                                         │
                                                         ▼
                                              Report + evidence pack
                                                         │
                              ┌──────────────────────────┼──────────────────────────┐
                              ▼                          ▼                          ▼
                         GB-W5 packaging            GB-W7 suites 21–23          GB-E1 #57/#58
                              │                          │
                              └──────────► WA-9 fixtures / Codex client rebase (later)
```

Owner later: merge WIMS stack #40–#42 **only after** live hook + WA-9 client alignment, or keep parked.

---

## 7. Paste brief for GBot session start

> **P0:** Install AlgoGebra JSON hook on Debian WIMS (`algogebra_json.phtml` + `answer.phtml`); smoke 00006/00076 wrong+right with `cmd=reply&special_parm=algogebra_json`; negative without `special_parm`. Evidence under `03-RCP-Spike/evidence/…-gbot-algogebra-json-debian_GROK_V1/`. Report `Report_GBot_AlgoGebra_JSON_Debian_GROK_V1.md`.  
> **P1:** `build-runtime-tree.sh` wire-up; suites 21–23 vs live hook; recheck #57/#58 vs tip.  
> **Do not:** merge PRs, touch #48/#63 product code, invent `ansN` / `adm/raw` grade path.  
> Read: `Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` + this planning file.

---

## 8. Related docs

| Doc | Use |
|---|---|
| `Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` | Full GB-W* task text |
| `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md` (or CLAUDE_V2 if tip name differs) | Canonical CDC |
| `Spec_WIMS_Message_Integration_GROK_V1_1.md` | Wire protocol |
| `Handoff_WA9_Mock_Rebase_GROK_V1.md` | Codex client; GBot supplies live fixtures |
| `GV_Residual_Results_GBOT_V1.md` | Prior GB-R2..R5 / G-A* results |
| `Planning_Sprint3_Next_Actions_GROK_V1_1.md` | Historical; GBot § superseded by this file |

---

*End of `Planning_GBot_Next_Actions_GROK_V1.md`.*
