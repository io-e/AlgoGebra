<!-- GROK_V1 -->
# Implementation notes — AlgoGebra ↔ WIMS (from wims4win code)

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Completes | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` (engine slice) + Claude WIMS Q&A / schemas on `feat/grok-sprint3-plan-v1-1` |
| Source of truth (code) | `D:\ALF_ZGit\02-wims4win` (native Windows port of WIMS ~4.33a / r19040 lineage) |
| Related product code | `03-RCP-Spike/engines/{pari,maxima,gnuplot,api}/`, `wims/course-activity-template/` (PRs #40–#42) |
| Status | **Implementation guide** — not a merge of #40–#42; respects Planning V1_1 / offline-first (Q-W2) |

This document fills what Claude’s CDC leaves abstract by pinning **concrete WIMS behaviours** from the C interfaces and CGI. It does **not** replace GV-1…GV-7 or the owner pedagogy review.

---

## 1. Two integration layers (keep separate)

| Layer | What it is | MVP? | Depends on D-04? |
|---|---|---|---|
| **L1 — Offline engines** | Java `ProcessBuilder` wrappers that **port** WIMS `Interfaces/*.c` headers, illegal lists, and output cleanup | **Yes (first)** | **No** |
| **L2 — WIMS CGI (connected)** | HTTP POST to `wims.cgi` / `wims.exe` so **WIMS owns the grade** (D-S01) | Phase 2 / local-connected (Q-W7) | Soft (web host can proceed; RCP panel residual is #33 only) |

Claude’s V1_1 CDC is ready for **L1**. L2 needs a short **WIMS CDC** (protocol + result object) because stock CGI returns **HTML**, not the D-S01 JSON.

```
Teacher OEF ──oef2course──► course.json (+ help templates)
                              │
              ┌───────────────┼────────────────┐
              ▼               ▼                ▼
         AlgoGebra UI    L1 local engines    L2 wims.cgi (optional)
         (course tree)   pari/maxima/gap/    grade + exploration
                         gnuplot/giac        when engine missing
```

---

## 2. L1 — Port the WIMS C interfaces (not the CGI)

### 2.1 Provenance (already documented)

`03-RCP-Spike/engines/licenses/WIMS-INTERFACES.md`:

- Pari/Maxima bundles preserve strings from `src/Interfaces/pari.c`, `maxima.c`, helpers in `common.c`
- GPL-2.0+ on those WIMS-derived filter/header tables
- Java runner / Gnuplot adapter are **new** code (separate license decision)

### 2.2 Spawn model in WIMS (what Java must emulate)

From `src/Interfaces/common.c` + `Platform/`:

| WIMS C | AlgoGebra Java (D-ENG-01) |
|---|---|
| `wp_spawn` / `wp_chan` pipe to CAS | `ProcessBuilder` + stdin/stdout |
| Job kill on session end | destroy process tree on timeout |
| Optional `ch..root` / AppContainer | **Not** in MVP (D-ENG-03: filters + timeout only) |
| `fsizelim` ~ 131072 on iface I/O | Cap stdout bytes similarly |
| Header script then user command | Send header once per session or per call (match existing Java engines) |

### 2.3 Exact filter tables (copy these)

#### PARI (`pari.c`)

| Item | Value |
|---|---|
| Command | `gp -f -q` |
| Header (excerpt) | `default(output,0)` + **`default(secure,1)`** + aliases (`ln`→`log`, …) |
| `illegal[]` | **empty** in upstream WIMS |
| `illpart[]` | `plot`, `write`, `help` |
| `check_parm` | `_` → `K`; escapes after newline limited |
| AlgoGebra extra (owner BUG-006) | `AGB_ILLEGAL`: `system`, `extern`, `externstr`, `fileextern`, `install`, **`eval`** (whole word) — keep; WIMS empty `illegal[]` is **not** enough |

Reference implementation: `PariGPEngine.java`.

#### Maxima (`maxima.c`)

| Item | Value |
|---|---|
| Command | `maxima` |
| Header | `display2d:false`, `letrat:true`, aliases, `kill(labels)` |
| `illegal[]` | `system`, `describe`, `example`, `save`, `fassave`, `stringout`, `batcon`, `batcount`, `cursordisp`, `direc`, `readonly`, `with_stdout`, `pscom`, `demo`, `ttyintfun`, `bug` |
| `illpart[]` | `file`, `debug`, `plot`, `load`, `store`, `batch` |
| `check_parm` | `_`→`K`; `?`→space; **tolower** whole command |

Reference: `MaximaEngine.java` (must stay verbatim lists).

#### GAP (`gap.c`)

| Item | Value |
|---|---|
| Command (Windows) | `gap.exe -T -n` (Unix: `gap.sh -T -n`) |
| `illegal[]` | `Reread`, `Process`, `Exec`, `Filename`, `SaveWorkspace` |
| `illpart[]` | `File`, `Path`, `Read`, `To` |
| Note | Migration_Wims / Laragon already exercises Factorial / SymmetricGroup on Windows |

#### Gnuplot (D-ENG-04 — **not** a WIMS `Interfaces/*.c` twin)

Host forces PNG output path; block at least: `system`, `shell`, `!`, backticks, `set output`, `set print`, `load`, `call`, `save` (see Grok review m-2 on CDC V1_1).

### 2.4 `find_illegal` semantics (port carefully)

`common.c` does **not** reject with an error by default: it **mutates** the command (replace character with `J`/`Z`) so the CAS fails oddly. AlgoGebra’s stronger policy (`COMMAND_REJECTED` before spawn for `AGB_ILLEGAL`) is **intentional** and must remain documented as defence-in-depth on top of WIMS.

### 2.5 L1 implementation checklist (Codex) — EE-P1

Align with CDC Phase 1; IDs for tracking:

| ID | Deliverable | Done when | WIMS code anchor |
|---|---|---|---|
| **EE-P1a** | `SubprocessEngine` timeout + kill | Unit test with mock process | `common.c` spawn/wait |
| **EE-P1b** | `PariGPEngine` header + filters + AGB_ILLEGAL | SBX / existing Pari tests green | `pari.c` |
| **EE-P1c** | `MaximaEngine` header + illegal/illpart | Existing Maxima tests green | `maxima.c` |
| **EE-P1d** | `GnuplotEngine` PNG to host temp | PNG signature test | D-ENG-04 (new) |
| **EE-P1e** | `isAvailable()` / missing binary | Grading path → hard error (Q-W6) | D-ENG-02 |
| **EE-P1f** | GAP engine (if not present) | Factorial/SymmetricGroup smoke | `gap.c` |
| **EE-P1g** | Fixture parity plan (Phase 2d) | TSV of ≥20 cmds/engine vs WIMS `bin/pari` etc. | Debian Phase 2 |

**Q-W6 nuance for implementers:** missing local engine = **error for grading**; exploration **may** call L2 with UI label `remote computation`. Never fall back to a **different** CAS.

---

## 3. L2 — WIMS CGI (connected / local wims4win)

### 3.1 What D-S01 says (Claude decision)

```
POST /wims/wims.cgi
  module=adm/class/sheet
  &job=getresult
  &exercise=<id>
  &ans1=<construction_base64>
→ { "grade": 0..1, "feedback": "..." }
```

Client: `wims-grade-client_GROK_V1.js` (PR #41). **WIMS owns the grade.**

### 3.2 What the WIMS **codebase** actually implies

| Topic | Finding from wims4win | Implementation impact |
|---|---|---|
| Entry | CGI binary is `wims.cgi` / Windows `wims.exe` (`config.c`: `cgi_name="wims.cgi"`) | Endpoint path configurable; default `/wims/wims.cgi` OK |
| Response | Modules render **HTML** via `html.c` / templates — **no built-in JSON grade API** matching D-S01 | Need a **WIMS-side adapter module** (preferred) or opt-in HTML marker (`htmlAdapter`, default OFF) |
| Session | Grades go through `score.c` / `wimslogd` with `wims_user`, `wims_class`, `wims_session` | D-S01 sends **no** `session=`; rely on **same-origin cookie** until confirmed (open Q-GC2 / Q-W1 family) |
| Score API | `getscore*` are **calc/exec** builtins for **module authors**, not a public `job=getresult` HTTP contract | **`job=getresult` on `adm/class/sheet` is unverified** in this tree — treat as **adapter contract to implement**, not as stock WIMS |
| Auth | `auth.c` thresholds for anonymous / new session | MVP Q-W1: local wims4win, no auth — still need a session directory for scoring |
| Engines behind CGI | Same `Interfaces/*.c` binaries under WIMS | L2 exploration fallback uses **server-installed** engines, not AlgoGebra’s Java wrappers |

### 3.3 Recommended L2 build sequence

| Step | Owner / who | Work |
|---|---|---|
| L2-0 | Owner | Settle JSON-vs-HTML (prefer WIMS adapter) and session cookie rules — rename Grok draft Q-W1…4 to **Q-GC1…4** to avoid clash with owner Q-W1…9 |
| L2-1 | WIMS / Grok | Small module or wrapper that accepts D-S01 POST and returns JSON `{grade, feedback}` (later `{answers:[…]}` per Q-W4) |
| L2-2 | Grok | Point suites 21–23 at **real** wims4win once adapter exists; keep mocks for CI |
| L2-3 | Codex | Desktop `HttpClient` twin of the JS client (same body fields) |
| L2-4 | Claude | WIMS CDC: per-answer result schema; reserve `submission` for Phase 2 idempotency (S-03) |

Until L2-1 exists, **do not** claim D-S01 works against stock CGI.

### 3.4 Payload / deployment defaults (from Grok client — OK to keep)

| Setting | Default |
|---|---|
| Max `ans1` base64 | 1 MiB (`maxAnsBytes`) |
| Timeout | 15 s |
| Credentials | `same-origin` |
| Redirects | refuse |
| Grade domain | number in `[0,1]` |
| Feedback render | `textContent` only |

---

## 4. OEF → course.json → help (Claude schemas)

| Piece | Role | Impl note |
|---|---|---|
| `oef2course_GROK_V1.py` | Conversion-time OEF→`Schema_Course_JSON` | **MVP path** — students do **not** need Perl |
| `Schema_Course_JSON` V1_1 | `help` + `engine` on steps | Closes GAP-1/GAP-2 as decided |
| `Schema_Help_Template` | process/text trees; CMD/CAS/VAL only | Runtime must enforce same security as course actions |
| Example help | Derivation FR/EN | **Fix `$comment`** before schema CI (B-1) |

Converter still lacks GAP-3…5 (computeRequest, submission, rich checks) — document as Phase 2+.

---

## 5. What to add to Claude’s docs (editorial)

Ask Claude (or fold into `Cdc_WIMS_Integration_…_CLAUDE_V1.md`):

1. Split status: **“Engine layer ready for Codex”** vs **“WIMS CGI not ready until adapter”**.
2. Patch Q-W6 into D-ENG-02 wording (grading error vs exploration remote).
3. Replace “Perl required OEF reader” with **Python converter at build time**.
4. Link this file + `WIMS-INTERFACES.md` + `pari.c`/`maxima.c`/`gap.c` paths.
5. Align Q-W4 multi-answer object with a future bump of `wims-grade-client` (single `grade` today).
6. Example JSON: allow or remove `$comment`.

---

## 6. Parallel work map (now)

| Lane | Action |
|---|---|
| **Codex** | Continue **L1 EE-P1a…g** against existing engines + GAP if missing; no dependency on #33 |
| **Claude** | WIMS CDC doc + schema `$comment` fix + Q-W fold-in |
| **Grok Bot** | GV-1…GV-7; optional probe whether `adm/class/sheet`+`getresult` exists in a full WIMS data tree / wims4win install |
| **Owner** | Pedagogy relecture; decide L2 adapter ownership |

---

## 7. File index

| Path | Use |
|---|---|
| `D:\ALF_ZGit\02-wims4win\src\Interfaces\pari.c` | PARI header + illpart |
| `…\maxima.c` | Maxima illegal/illpart |
| `…\gap.c` | GAP illegal/illpart |
| `…\common.c` | `find_illegal`, spawn |
| `…\score.c` | Session-bound scoring (not HTTP JSON) |
| `…\wims.c` | CGI main |
| `03-RCP-Spike/engines/pari|maxima|…` | Java ports |
| `wims/course-activity-template/` | L2 client (PRs #40–#42) |

---

*End of `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md`.*
