<!-- GROK_V1_2 -->
# Implementation notes — AlgoGebra ↔ WIMS (from wims4win code)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1_2 |
| Completes | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` (engine slice) + WIMS CDC GROK_V2_2 |
| Source of truth (code) | `D:\ALF_ZGit\02-wims4win` (native Windows port of WIMS ~4.33a / r19040 lineage) |
| Related product code | `03-RCP-Spike/engines/{pari,maxima,gnuplot,api}/`, `wims/course-activity-template/` (PRs #40–#42) |
| Status | **Implementation guide** — L1 filters + **L2-1 JSON hook prototype** |
| Security sync | `e7f1ad4` — Gnuplot backtick/eval; PARI `read`/`readvec`/`readstr` |
| Hook commit | wims4win `bb929e3` on `feat/algogebra-wims-integration` |

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
| AlgoGebra extra (BUG-006 + V1_1) | `AGB_ILLEGAL` whole-word: `system`, `extern`, `externstr`, `fileextern`, `install`, **`eval`**, **`read`**, **`readvec`**, **`readstr`** — WIMS empty `illegal[]` + `default(secure,1)` are **not** enough (`secure` does not block file-read APIs; `e7f1ad4`) |

Reference implementation: `PariGPEngine.java` (`Decisions_PARI_Forbidden_GROK_V1.md` + `_V1_1.md`).

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

Host forces PNG output path. Block at least (see `GnuplotEngine.java` / CDC V1_3 + `e7f1ad4`):

| Pattern | Why |
|---|---|
| `system` / `shell` | Process escape |
| `!` shell escape (line/`;`-prefixed) | Same |
| **Backtick `` ` ``** (**HIGH**, `e7f1ad4`) | Command substitution, e.g. `plot sin(x) title \`cat /etc/passwd\`` — bypasses word filters |
| **`eval` / `evaluate`** (**MEDIUM**, `e7f1ad4`) | Builds blocked commands via string concat |
| `set output`, `set print`, `load`, `call`, `save` | Arbitrary file I/O / script include |
| `plot`/`splot` with `"|…"` / `"<…"` process input | Shell via gnuplot data source |

Reject with `COMMAND_REJECTED` **before** spawn.

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

### 3.1 Locked design (D-WIMS-G01) — not D-S01

D-S01 (`job=getresult` on `adm/class/sheet`) is **withdrawn**. Primary grade path:

```
cmd=new  → session + reply/choice fields in HTML
cmd=reply + special_parm=algogebra_json + replyN=… → HTML + ALGOGEBRA_JSON block
```

Client target: rebase `wims-grade-client_GROK_V1.js` / PRs #40–#42 (**WA-9**). **WIMS owns the grade.**

### 3.2 What the WIMS **codebase** implies (updated)

| Topic | Finding from wims4win | Implementation impact |
|---|---|---|
| Entry | CGI binary `wims.cgi` / Windows `wims.cgi.exe` | Default `/wims/wims.cgi` OK |
| Response | OEF modules render **HTML**; JSON is an **additive HTML comment** when the hook is installed | Parse `ALGOGEBRA_JSON_BEGIN`…`END`; ignore surrounding HTML for grade UI |
| Hook files | `scripts/oef/answer.phtml` (injection) + `algogebra_json.phtml` (body) | No `reply.phtml` on verified runtime |
| Field names | Form fields `replyN` / `choiceN` | Never invent `ansN` |
| Scores | Live: `m_sc_replyN`, `module_score` (0–10 → `grade=module_score/10`); session file uses `w_*` | See `OEF_Variable_Map_GROK_V1.md` |
| Trigger | `special_parm=algogebra_json` on **reply only** | On `new`, OEF `select.phtml` would set `exo=$special_parm` |
| Auth | Anonymous local OK for Q-W1 MVP | Still needs a writable `sessions/` tree |
| Engines behind CGI | Same `Interfaces/*.c` | L2 exploration uses **server** engines |

### 3.3 L2 build sequence (status)

| Step | Owner / who | Work | Status |
|---|---|---|---|
| L2-0 | Owner | D-WIMS-G01 locked | **Done** |
| L2-1 | Grok / wims4win | JSON hook on Windows runtime + smoke test | **Done (Windows)** `bb929e3`; residual packaging/Debian |
| L2-2 | Grok | Point suites 21–23 at real wims4win; keep mocks for CI | **Open** |
| L2-3 | Codex | Desktop `HttpClient` twin | **Open** (WA-9 unblocked) |
| L2-4 | Claude / Grok | Schema polish (`feedback`, checkbox `expected` trim, S-03 key) | **Open** |

### 3.4 Client defaults (keep)

| Setting | Default |
|---|---|
| Max reply body | 1 MiB |
| Timeout | 15 s |
| Credentials | `same-origin` |
| Redirects | refuse |
| Grade domain | number in `[0,1]` |
| Feedback render | `textContent` only |
| JSON extract | regex/comment parse of `ALGOGEBRA_JSON_BEGIN`…`END` |

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

## 5. Doc fold-in status (GROK_V1_2)

| Item | Status |
|---|---|
| Canonical WIMS CDC | `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md` |
| Client protocol | `Spec_WIMS_Message_Integration_GROK_V1_1.md` |
| WA-9 unblock | `02-01_Wims_Integration/Handoff_WA9_Mock_Rebase_GROK_V1.md` |
| Engine layer ready for Codex | Still true (L1) |
| WIMS CGI JSON hook | Windows prototype ready; client rebase = WA-9 |

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

### Doc drift note (for Claude)

`Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` EE-12 already lists backticks; add **`eval` / `evaluate`** explicitly to match `e7f1ad4`. PARI `read`/`readvec`/`readstr` already present in V1_3 / `Decisions_PARI_Forbidden_GROK_V1_1.md`.

Optional follow-up: unit/SBX cases for `` title `…` ``, `eval "system …"`, and `read("/etc/passwd")` if not already covered.

---

*End of `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (GROK_V1_1).*
