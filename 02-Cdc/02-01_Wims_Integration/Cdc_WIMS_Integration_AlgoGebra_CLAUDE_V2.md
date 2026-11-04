<!-- CLAUDE_V2 -->
# CDC — WIMS Integration for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md` |
| Version | CLAUDE_V2 |
| Scope | **WIMS protocol, exercise lifecycle, help architecture, grading contract** — everything above the engine subprocess layer |
| Status | **Post-audit revision** — incorporates all Grok audit findings (A-01..A-15) and owner decisions Q1–Q8 |
| Date | 2026-11-04 |
| Supersedes | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` |
| Depends on | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` (engine layer, L1), `Schema_Course_JSON_CLAUDE_V1_2.json`, `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_1) |
| Owner Q&A | `QA_WIMS_Integration_Owner_ALF_V2.md` (Q-W1..Q-W9, all closed) |
| Grok input | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (WIMS code audit) |
| Grok audit | `Audit_Specs_Wims_GBOT_v1.md` (34 findings, 8 owner questions — all answered) |
| Reviews | `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` (OD-1..OD-4 closed) |
| License | EUPL 1.2 (source). WIMS-derived material is GPL v2 — deferred to Gate E / O-02 |

---

## 1. Purpose and scope split

This CDC specifies the **WIMS integration layer** for AlgoGebra: how exercises are loaded, how students interact with them, how help is delivered, and how grading works.

**Scope split (owner decision OD-1):**

| This CDC (L2 + exercise lifecycle) | Engine CDC (L1, separate) |
|---|---|
| OEF → JSON conversion pipeline | `SubprocessEngine` abstract class |
| Exercise loading and display contract | Per-engine headers, filters, output parsers |
| Help template architecture (Q-W9) | Engine binary discovery and availability |
| Resolution process tree | Security filter tables |
| Student workspace → submission | Process timeout and kill |
| WIMS CGI protocol (connected mode) | — |
| Grading contract (per-answer results) | — |

The engine subprocess layer is fully specified in `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md`. This CDC references it for engine invocation but does not re-specify it.

---

## 2. Deployment modes and phasing

### WI-01: Three deployment modes (Q-W2, Q-W7)

| Mode | How engines run | How grading works | When |
|---|---|---|---|
| **Offline** | Local `SubprocessEngine` (Java ProcessBuilder) | Local evaluation against exercise-defined criteria | **MVP** |
| **Local-connected** | Local engines + wims4win on localhost | WIMS owns the grade via CGI on `localhost` | **Phase 2 — Step 1** |
| **Institutional** | Local engines + remote WIMS server (TLS) | WIMS owns the grade via CGI over network | **Phase 2 — Steps 2-3** |

**MVP is offline.** The student runs AlgoGebra with engines installed locally (Q-W2). No WIMS server is required. The transition to connected mode is a transport change (localhost → network → TLS), not a protocol change — **if** the CGI adapter exists (see §5).

### WI-02: Target audience (Q-W7)

wims4win is not developer-only. It runs on:
- **CPGE student machines** (Shadow PC cloud workstations)
- **Teacher machines** (exercise authoring + validation)

Served WIMS runtime: `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime` (not the `02-wims4win` sources directory). Install guide and resource requirements are deliverables.

---

## 3. Exercise pipeline: OEF → course.json → AlgoGebra

### WI-03: Conversion pipeline

```
Teacher writes OEF              Teacher creates .ggb
(Createxo / Modtool)                  │
     │                                │
     ▼                                │
oef2course_GROK_V1.py                │
(Python, conversion-time)             │
     │                                │
     ├─► course.json                  │
     │   (Schema_Course V1_2)         │
     │                                │
     ├─► help templates (*.json)      │
     │   (Schema_Help_Template)       │
     │                                │
     └─► linked .ggb files ◄─────────┘
              │
              ▼
     AlgoGebra loads and displays
     course tree + GeoGebra workspace
```

**Converter status:** `oef2course_GROK_V1.py` (suite 19 passing on Debian). Produces `schemaVersion: "1.0"` JSON. Python is a **conversion-time** dependency, not an RCP runtime dependency.

### WI-04: What AlgoGebra loads

| File type | Schema | Loaded by | Display |
|---|---|---|---|
| `course.json` | `Schema_Course_JSON_CLAUDE_V1_2.json` | `CourseModel` (Java) | Course tree panel (left) |
| Help templates `*.json` | `Schema_Help_Template_JSON_CLAUDE_V1.json` V1_1 | Help panel loader (TBD) | Help panel within tree node |
| `.ggb` constructions | GeoGebra native | `GgbAPI.openFile()` | GeoGebra workspace (right) |

### WI-05: Schema gaps remaining (from Q-W3 analysis)

| Gap | Problem | Status |
|---|---|---|
| **GAP-1** | No structured help | **Closed** — `help` field on step + help template schema |
| **GAP-2** | No engine routing | **Closed** — `engine` field on step |
| **GAP-3** | No help/exploration contract | **Closed by Q-W9** — resolution tree + right panel |
| **GAP-4** | No submission/session contract | **Phase 2** — §5 below |
| **GAP-5** | Limited check types (4 vs. WIMS's 61 anstypes) | **Closed** — extended `checkAction.type` enum (see WI-31) |
| **GAP-6** | Parameters computed by `wims()/slib()/pari()/maxima()` at `cmd=new` time (214/300 corpus files) | **Closed** — frozen variants (see WI-06) |

### WI-06: Frozen variants (GAP-6 resolution)

214 of 300 corpus exercises compute parameters at `cmd=new` time using `wims()`, `slib()`, `pari()`, or `maxima()` calls. The converter resolves only `random`/`randint`. For the remaining:

**Resolution:** The converter generates **N=20 frozen variants** per exercise at conversion time, using a WIMS evaluation pass with different seeds. Each variant contains pre-evaluated parameters.

```bash
python oef2course_GROK_V1.py input.oef --variants 20 --seed 42 --output course.json
```

The `variants[]` array in `course.json` holds the pre-baked parameter sets. AlgoGebra picks a random variant at student session start.

**Accepted trade-off (WI-R10):** Answer keys ship offline in frozen variants. This is inherent to the offline-first model (Q-W2). Connected mode (Phase 2) evaluates dynamically.

---

## 4. Help and resolution architecture (Q-W9)

### WI-10: Resolution process tree

The teacher provides a **resolution process** as a JSON help template. It is loaded into the course tree. Each node is a **transformation step** — not just text, but an active step in the resolution path.

```
Course Tree (left panel)                    GeoGebra Workspace (right panel)
─────────────────────────                   ──────────────────────────────────
Exercise: Dérivation de x²+3x              Student experiments here:
├─ Étape 1: Identifier f(x)                 - replay current step
│   ├─ [explanation FR/EN]                   - test another function
│   ├─ [help template → injected values]     - modify random values
│   └─ [LLM Q&A / RAG — Phase 3]            - try different approach
├─ Étape 2: Appliquer la règle              
│   ├─ [explanation FR/EN]                  Right panel work is sent
│   └─ [help template]                      to WIMS for evaluation
├─ Étape 3: Simplifier                      (connected mode)
└─ Étape 4: Vérifier le résultat           
```

### WI-11: Three help layers per node

| Layer | Source | Content | Phase |
|---|---|---|---|
| **1. Explanations** | Teacher-authored in help template JSON | Multilingual `i18nString` (FR/EN/...) | **MVP** |
| **2. Engine-assisted help** | Help template `engineCommand` + `actions` | CMD/CAS/VAL actions, engine computation | **MVP** |
| **3. LLM/RAG** | AI model (local or remote) | Answers questions, RAG on student's course material | **Phase 3** |

### WI-12: Help template mechanism

**OEF linking (A-04 fix):** The `\text{algogebra_help=aide_derivation.json}` OEF directive references an external help template file. This uses the standard OEF `\text{}` variable mechanism, which is passed through by the converter without collision.

**Native `\help{}` is NOT used** — it collides with OEF's built-in `\help{}` popup (which shows the literal string; `oef2wims.c:79,197-211`). The 2 exercises in the corpus that use `\help` are inline only and map to `text`-type help nodes.

**Fallback:** If no `\text{algogebra_help=...}` is present, the converter looks for a sidecar file `<exercise_name>.help.json` alongside the OEF file.

**Template location:** Two models:
- **Exercise-specific:** `aide_xxx.json` alongside the OEF file
- **Shared library:** reusable templates (e.g. `aide_derivation.json` shared by many exercises)

**Variable injection** (`{{variable}}` placeholders):
- **Conversion-time:** converter resolves OEF random variables with seed → bakes defaults
- **Runtime:** AlgoGebra re-injects values (session seed, student locale, student progress)

**Security:** Help actions are restricted to **CMD/CAS/VAL** only (no OPEN/SAVE/PNG). Same allowlist and Sequence budget as course actions. See `Spec_Course_Security_CLAUDE_V1_2.md`.

### WI-13: LLM/RAG configuration (Phase 3, Q-W9a..c)

| Setting | Decision |
|---|---|
| LLM routing | Local model (Ollama/llama.cpp) for simple questions. Remote API (Claude) for hard questions. |
| RAG source | Teacher-provided Markdown course with index. Teacher specifies chapter in OEF. |
| Scope | Per-exercise RAG, not full corpus. |
| Phase | **Phase 3.** Not required for MVP or Phase 2. |

The `courseRef` field in the help template schema (`Schema_Help_Template_JSON_CLAUDE_V1.json` §`courseRef`) reserves the RAG pointer for Phase 3.

---

## 5. WIMS CGI protocol — connected mode (Phase 2)

### WI-20: Critical finding — WIMS CGI returns HTML, not JSON

**Source:** Grok code audit (`Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` §3.2).

Stock WIMS CGI (`wims.cgi` / `wims.exe`) renders **HTML** via `html.c` / templates. There is **no built-in JSON grade API** — except `adm/raw`, which returns `application/json; charset=iso-8859-1` (machine API, used for aggregate scores and admin jobs, not per-answer OEF evaluation).

**Live probe evidence (GV-1, 2026-11-04):** Grok tested wims4win `wims.cgi.exe` directly (WIMS 4.33a). Results:
- `job=getresult` on `adm/class/sheet` → **ignored** (returns worksheet HTML, 200). `job=` is a module-local switch, not a CGI verb.
- `cmd=getresult` → **rejected** (450: "The command 'getresult' is not valid. Valid commands are: new, renew, reply, help, hint, config").
- `cmd=` is a closed list in `wims.c:288-290` (14 verbs). A module **cannot add a `cmd=` verb**.
- Every response was `text/html; charset=windows-1252`. No `application/json` was returned in any probe.
- Evidence: `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/`

**Consequence:** Connected mode grading uses the stock `cmd=new` + `cmd=reply` flow with a **JSON output hook** in the WIMS `scripts/oef` directory (see WI-21). The earlier D-S01 `cmd=getresult` design is withdrawn.

### WI-21: Connected mode grading design (owner decision Q1)

**Chosen approach: stock `cmd=new/reply` + wims4win JSON output hook.**

The stock WIMS exercise flow is: `cmd=new` (create exercise session with random parameters) → student answers → `cmd=reply` (submit answers, WIMS evaluates). The adapter is a `special_parm=algogebra_json` hook in `scripts/oef` that causes the `cmd=reply` response to include a JSON payload with per-answer results alongside the HTML.

**Why this approach:**
- `adm/raw` has no OEF evaluation context (`testexo` compiles only, `getscore*` aggregates only — `jobs/testexo.proc:6-17`, `jobs/getscore.proc:21-42`, `anstype/numeric:59-60`)
- Stock `cmd=new/reply` is what WIMS uses for actual answer evaluation with 61 anstypes
- The JSON hook is a minimal GPL v2 patch to one WIMS script directory, not a new module

**Adapter build sequence:**

| Step | Who | Deliverable | Blocks |
|---|---|---|---|
| **L2-0** | Owner | ~~Decide~~ **Decided**: stock `cmd=new/reply` + JSON output hook | — |
| **L2-1** | Grok (Migration_Wims) | JSON output hook in `scripts/oef`: `special_parm=algogebra_json` → JSON `answers[]` appended to reply | L2-2, L2-3 |
| **L2-2** | Grok | Point suites 21–23 at real wims4win with hook; keep mocks for CI | Grok test validation |
| **L2-3** | Codex | Desktop `HttpClient` grade client (same fields as `wims-grade-client_GROK_V1.js`) | RCP connected mode |
| **L2-4** | Claude | Per-answer result schema; `submission` namespace for S-03 idempotency | Schema evolution |

**PRs #40–#42 are parked** (owner decision OD-3). The JS grade client (`wims-grade-client_GROK_V1.js`) returns a single `{grade: 0..1, feedback}` object. Q-W4 requires **per-answer structured results** — #40–#42 will be rebased on the hook protocol before Phase 2 reopens.

### WI-22: Wire format (target for L2-1 hook)

**Important:** This is the **target wire format for the L2-1 JSON hook**, not a description of existing WIMS behavior.

```
AlgoGebra POST /wims/wims.cgi
  Content-Type: application/x-www-form-urlencoded
  
  module=<class_module>          ← standard WIMS class/sheet module
  &cmd=reply                     ← stock WIMS verb (not a new verb)
  &special_parm=algogebra_json   ← triggers the JSON hook
  &exercise=<id>
  &ans1=<value>
  &ans2=<value>
  ...
  &session=<wims_session>        ← from cookie or explicit param

→ 200 OK  Content-Type: text/html (stock) + embedded JSON block

  <!-- ALGOGEBRA_JSON_BEGIN
  {
    "grade": 0.75,
    "answers": [
      {"id": "ans1", "correct": true, "score": 1.0, "feedback": "..."},
      {"id": "ans2", "correct": false, "score": 0.5, "feedback": "Partially correct."}
    ],
    "feedback": "Overall feedback text."
  }
  ALGOGEBRA_JSON_END -->
```

The `answers[]` array is the Q-W4 per-answer result. The client extracts the JSON block from the HTML response. The HTML response remains valid for non-AlgoGebra consumers.

### WI-23: Session and authentication (Q-W1)

| Step | Auth model | Session | Notes |
|---|---|---|---|
| **Step 1 (formative, anonymous)** | None | `cmd=new` creates an anonymous session. WIMS generates a session dir for scoring. No class, no login, no `.connections` entry. | Sufficient for offline MVP and anonymous practice. No grade recorded in any class. |
| **Step 2 (class-connected, local)** | `.connections` ident | `log/classes/.connections/<ident>` with `passwd`, `ident_site` IP allowlist. AlgoGebra uses `adm/raw` for class operations (enroll, read scores). | Required for any grade-recording path through `adm/raw` (`adm/raw/var.check:27,37-38,44,49,59`). Only 5 `adm/raw` jobs need no auth. |
| **Step 3 (institutional, remote)** | TLS + `.connections` + optional SSO | Cookie + certificate. `ident_site` includes the institutional server IP range. | HTTPS required. |

### WI-24: Exploration fallback (Q-W6) — Phase 2

When a local engine is missing:
- **Grading:** error. Missing binary = error. No fallback. The student is told which engine is missing and how to install it.
- **Exploration:** **Phase 2.** Requires a local WIMS compute module (e.g. `local/algogebra_compute`) that can accept a computation request and return a result. No stock WIMS compute endpoint exists for this (CGI returns HTML). MVP shows an explicit "engine not installed" error with install guide link.

---

## 6. Offline evaluation contract (MVP)

### WI-30: What offline evaluation means

In offline mode, AlgoGebra evaluates student answers locally. There is no WIMS server. The evaluation criteria come from the course.json `check` object.

### WI-31: Check types (extended enum — closes GAP-5)

**Corpus analysis (Grok GV-3 addendum):** 1,824 of 1,840 answers (281/300 files) previously degraded to `object_exists`. Breakdown by answer family:

| Answer family | Answers | Files | New check type |
|---|---|---|---|
| Choice (clickfill, dragfill, etc.) | 459 | 107 | `choice_equals` |
| Variable-typed (numeric with units, etc.) | 616 | 63 | `value_equals` (mode: relative/absolute) |
| Fill (text/formula input) | 588 | 53 | `sequence_equals` or `set_equals` |
| Numeric (not computable offline) | 89 | 24 | `engine_check` |
| Symbolic (CAS) | 38 | 17 | `cas_equals` |
| Not mappable (interactive, drag, etc.) | ~34 | — | `gradable: false` |

**Extended check type enum:**

| Type | Evaluator | Comparison | New? |
|---|---|---|---|
| `value_equals` | AlgoGebra built-in | `\|actual - expected\| ≤ tolerance`. Supports `mode`: `absolute` (default) or `relative` (`\|actual - expected\| / \|expected\| ≤ tolerance`). `precision` field for sig-figs checks. | Extended |
| `value_range` | AlgoGebra built-in | `min ≤ actual ≤ max` | Unchanged |
| `object_exists` | AlgoGebra built-in | GeoGebra object with given name exists | Unchanged |
| `cas_equals` | GeoGebra CAS (GIAC via `Ggb2giac.java`) | `Simplify(actual - expected) == 0` | Unchanged |
| **`choice_equals`** | AlgoGebra built-in | Selected option(s) match expected. Supports single/multi choice. | **New** |
| **`sequence_equals`** | AlgoGebra built-in | Ordered list of values matches expected sequence. | **New** |
| **`set_equals`** | AlgoGebra built-in | Unordered set of values matches expected set. | **New** |
| **`engine_check`** | Named external engine | Engine evaluates `engineCommand` with student answer substituted; compare result to `expected` | **New** |

**Non-mappable answers:** Exercises whose answers cannot be evaluated offline (interactive drag, applet state) are marked `gradable: false` in the course JSON. The converter emits a warning. These exercises work in exploration mode but show "grading requires connected mode" in offline.

### WI-32: Feedback contract

Each `check` object has an optional `feedback` with `pass` and `fail` messages. These are displayed in the course tree panel when the student clicks "Check."

For help-based feedback (richer than pass/fail), the help template's resolution tree provides per-step explanations. The check tells the student *if* they're right; the help template tells them *how to get there*.

---

## 7. Teacher authoring workflow (Q-W5)

### WI-40: What the teacher creates

| Artifact | Tool | Format | Consumed by |
|---|---|---|---|
| Exercise definition | **Createxo** (class-level) or **Modtool** (module-level) | `.oef` file | `oef2course` converter |
| GeoGebra construction | GeoGebra desktop | `.ggb` file | AlgoGebra `OPEN` action |
| Help templates | Text editor / JSON editor | `.json` (Schema_Help_Template) | AlgoGebra help panel |
| Course material (Phase 3) | Any Markdown editor | `.md` files + index | LLM/RAG |

AlgoGebra is **not** an OEF editor. The teacher creates OEF in the standard WIMS workflow (Createxo for class exercises, Modtool for shareable modules), then runs the converter.

### WI-41: Conversion command

```bash
# Single variant (development)
python oef2course_GROK_V1.py input.oef --seed 42 --output course.json

# Frozen variants (production — resolves GAP-6)
python oef2course_GROK_V1.py input.oef --variants 20 --seed 42 --output course.json
```

The converter produces:
- `course.json` (schemaVersion 1.0)
- Help template skeletons from `\text{algogebra_help=...}` references
- Warning log for unconvertible OEF features → `gradable: false`

**Not yet implemented:** help template skeleton generation from `\hint` directives. This is Axis A from the Claude-to-Claude handoff.

---

## 8. Engine list and gradability

### WI-42: Engine coverage (wims4win interfaces)

| Engine | WIMS interface | AlgoGebra status | Offline gradable? |
|---|---|---|---|
| **pari** | `src/Interfaces/pari.c` | **MVP** (EE-P1b) | Yes |
| **maxima** | `src/Interfaces/maxima.c` | **MVP** (EE-P1c) | Yes |
| **gnuplot** | (direct call) | **MVP** (EE-P1d) | Yes (plot output) |
| **gap** | `src/Interfaces/gap.c` | **Optional** (EE-P1f) | Yes |
| **geogebra-cas** | GeoGebra CAS / Ggb2giac.java | **Native** (always available) | Yes |
| **octave** | `src/Interfaces/octave.c` | **Phase 2+** | Yes (when implemented) |
| **yacas** | `src/Interfaces/yacas.c` | **Not planned** | `gradable: false` offline |
| **m2** (Macaulay2) | `src/Interfaces/m2.c` | **Not planned** | `gradable: false` offline |
| **scilab** | `src/Interfaces/scilab.c` | **Not planned** | `gradable: false` offline |

Exercises naming `yacas`, `m2`, or `scilab` as their engine are converted with `gradable: false`. They work in exploration mode (connected to WIMS) but cannot be graded offline.

---

## 9. Scenario and gate mapping

### WI-50: Scenarios covered by this CDC

| Scenario | What it tests | Status |
|---|---|---|
| **S-01** | WIMS schema/capability registration | **Phase 2** — needs L2-1 JSON hook |
| **S-02** | Submission → grade → display | **Phase 2** — needs wire format |
| **S-03** | Idempotency (retry same key) | **Phase 2** — connected mode only |
| **X-04** | External compute → kernel (one-shot write) | **Not run** — depends on engine Phase 3 (EE-P3d) |
| **X-05** | Notebook / help display | **MVP** — resolution tree covers this |
| **X-06** | Malformed input error handling | **Open** — BUG-015, addressed in engine CDC |

### WI-51: Gate dependencies

| Gate | Requirement | This CDC's contribution |
|---|---|---|
| **C** | W-01 scored, GWT stays until W-02 passes | Web help template rendering (TBD) |
| **D** | X-01–06 + S-01–05 on both hosts | S-01/S-02 require L2-1 JSON hook (Phase 2) |
| **E** | O-02 security + license | GPL v2 filter tables (deferred, OD-4) |

---

## 10. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **WI-R1** | WIMS CGI JSON hook never built — connected mode blocked | Medium | Phase 2 stuck | MVP is offline, no dependency. L2-0 decided (stock `cmd=new/reply` + hook). |
| **WI-R2** | OEF exercises use features the converter can't handle | High | Degraded conversion (`gradable: false`) | Track coverage against corpus 300 (GV-3). Extend converter incrementally. |
| **WI-R3** | Help templates too complex for teachers to author | Medium | Low adoption | Provide skeleton generator. Example template exists. |
| **WI-R4** | `engine_check` type not expressive enough for WIMS answer variety | Medium | GAP-5 only partially closed | Connected mode delegates to WIMS's own evaluator via L2-1 hook. |
| **WI-R5** | wims4win on student Shadow PC — config/resource issues | Low | Student can't run exercises | Install guide + resource documentation (Q-W7). |
| **WI-R6** | LLM/RAG Phase 3 scope creep into MVP | Low | Delay MVP | Phase 3 is explicitly deferred. `courseRef` is reserved but not loaded. |
| **WI-R7** | GPL v2 obligations for JSON hook patch and filter tables | Medium | License conflict with EUPL 1.2 | Deferred to O-02 / Gate E. Do not distribute until license inventory complete. |
| **WI-R8** | Encoding mismatch: WIMS `iso-8859-1`/`cp1252` vs AlgoGebra UTF-8 | Medium | Mojibake in exercise text | Converter normalizes to UTF-8 at conversion time. WA-5. |
| **WI-R9** | WIMS version drift (wims4win 4.31b vs server 4.33a) | Low | Protocol differences | Pin wims4win version. Test hook on both. |
| **WI-R10** | Offline answer keys visible in frozen variants | Medium | Student cheating | Accepted trade-off for offline-first. Connected mode evaluates dynamically. Frozen variants can be obfuscated (not encrypted — not a security boundary). |

---

## 11. Relation to other documents

| Document | Relation |
|---|---|
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` | Engine subprocess layer (L1). This CDC adds exercise lifecycle on top. |
| `QA_WIMS_Integration_Owner_ALF_V2.md` | All owner decisions Q-W1..Q-W9, OD-1..OD-4. |
| `Audit_Specs_Wims_GBOT_v1.md` | Grok audit: 34 findings, 8 owner questions. This V2 incorporates all. |
| `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` | Grok code audit: filter tables, CGI findings, L2 build sequence. |
| `Schema_Course_JSON_CLAUDE_V1_2.json` | Course tree schema with extended check types, `gradable`, `variants[]`. |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_1) | Help template schema (process tree + text). |
| `Example_Help_Template_CLAUDE_V1.json` | Derivation exercise example. |
| `Spec_Course_Security_CLAUDE_V1_2.md` | Security constraints: action allowlist, Sequence budget. |
| `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` | Review findings F-01..F-18, owner decisions OD-1..OD-4. |
| `Handoff_Wims_Claude2Claude_CLAUDE_V1.md` | Integration axes for WIMS migration session. |
| `Decision_Open_Points_Sprint3_CLAUDE_V1.md` | D-S01 (withdrawn — replaced by L2-1 hook design), D-S02 (Lean 4 = batch). |

---

## 12. Audit finding resolution

| Audit finding | Resolution in this V2 |
|---|---|
| **A-01** (cmd=getresult impossible) | WI-21/22 rewritten: stock `cmd=new/reply` + JSON output hook |
| **A-02** (WI-23 "no auth" false) | WI-23 rewritten: anonymous for formative, `.connections` for `adm/raw` |
| **A-03** (grading design disagree) | Owner chose: stock `cmd=new/reply` + hook (Migration_Wims proposal) |
| **A-04** (`\help{}` collision) | WI-12 rewritten: `\text{algogebra_help=...}` + sidecar fallback |
| **A-05** (1824/1840 → object_exists) | WI-31 extended enum: 8 types including `choice_equals`, `sequence_equals`, `set_equals`, `engine_check` |
| **A-06** (GAP-6 missing) | WI-06 added: 20 frozen variants at conversion time |
| **A-07** (exploration fallback) | WI-24: Phase 2 with explicit error in MVP |
| **A-08** (GAP-5 text oversimplified) | WI-31 references A-05 family table |
| **A-09** (WI-R4 depends on non-existent L2-1) | WI-R4 updated: links to L2-1 hook design |
| **A-10** (`adm/raw` returns JSON) | WI-20: noted as exception |
| **A-13** (missing risks) | WI-R7..R10 added |
| **A-14** (teacher workflow) | WI-40: Createxo/Modtool named |
| **A-15** (runtime path) | WI-02: runtime path documented |

---

## 13. Open actions

| # | Action | Who | Blocks | Status |
|---|---|---|---|---|
| **WA-1** | ~~Owner decides L2 adapter approach~~ | Owner | — | **Closed** — stock `cmd=new/reply` + JSON hook |
| **WA-2** | ~~Extend `checkAction` enum~~ | Claude | — | **Closed** — done in Schema_Course V1_2 |
| **WA-3** | Help template skeleton generator from OEF `\text{algogebra_help}` + `\hint` | Grok / WIMS session | Axis A | **Open** |
| **WA-4** | Fixture corpus (20 exercises) shared between sessions | Grok | Axis C | **Open** |
| **WA-5** | Encoding normalization (UTF-8 contract for all OEF) | Grok / WIMS session | Pipeline reliability | **Open** |
| **WA-6** | ~~Grok GV-1..GV-7 validation~~ | Grok | — | **Closed** — audit completed |
| **WA-7** | GAP engine implementation (optional, EE-P1f) | Codex | Group theory courses | **Open** |
| **WA-8** | L2-1 JSON output hook prototype on wims4win | Grok (Migration_Wims) | Phase 2 connected mode | **Open** |
| **WA-9** | Rebase #40–#42 on hook protocol + per-answer `answers[]` | Grok | Phase 2 test suites | **Open** (blocked by WA-8) |
| **WA-10** | Converter: `\text{algogebra_help}`, `--variants`, new check types; rerun suite 19 + GAP-5 breakdown | Grok / Migration_Wims | MVP converter completion | **Open** |

---

*End of `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md`.*
