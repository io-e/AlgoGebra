<!-- CLAUDE_V1 -->
# CDC — WIMS Integration for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Scope | **WIMS protocol, exercise lifecycle, help architecture, grading contract** — everything above the engine subprocess layer |
| Status | Draft — ready for owner + Grok validation |
| Date | 2026-11-04 |
| Depends on | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` (engine layer, L1), `Schema_Course_JSON_CLAUDE_V1.json` (V1_1), `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_1) |
| Owner Q&A | `QA_WIMS_Integration_Owner_ALF_V2.md` (Q-W1..Q-W9, all closed) |
| Grok input | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (WIMS code audit) |
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

The engine subprocess layer is fully specified in `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md`. This CDC references it for engine invocation but does not re-specify it.

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

Install guide and resource requirements are deliverables.

---

## 3. Exercise pipeline: OEF → course.json → AlgoGebra

### WI-03: Conversion pipeline

```
Teacher writes OEF          Teacher creates .ggb
     │                           │
     ▼                           │
oef2course_GROK_V1.py           │
(Python, conversion-time)        │
     │                           │
     ├─► course.json             │
     │   (Schema_Course V1_1)    │
     │                           │
     ├─► help templates (*.json) │
     │   (Schema_Help_Template)  │
     │                           │
     └─► linked .ggb files ◄────┘
              │
              ▼
     AlgoGebra loads and displays
     course tree + GeoGebra workspace
```

**Converter status:** `oef2course_GROK_V1.py` (suite 19 passing on Debian). Produces `schemaVersion: "1.0"` JSON. Python is a **conversion-time** dependency, not an RCP runtime dependency.

### WI-04: What AlgoGebra loads

| File type | Schema | Loaded by | Display |
|---|---|---|---|
| `course.json` | `Schema_Course_JSON_CLAUDE_V1.json` V1_1 | `CourseModel` (Java) | Course tree panel (left) |
| Help templates `*.json` | `Schema_Help_Template_JSON_CLAUDE_V1.json` V1_1 | Help panel loader (TBD) | Help panel within tree node |
| `.ggb` constructions | GeoGebra native | `GgbAPI.openFile()` | GeoGebra workspace (right) |

### WI-05: Schema gaps remaining (from Q-W3 analysis)

| Gap | Problem | Status |
|---|---|---|
| **GAP-1** | No structured help | **Closed** — `help` field on step + help template schema |
| **GAP-2** | No engine routing | **Closed** — `engine` field on step |
| **GAP-3** | No help/exploration contract | **Closed by Q-W9** — resolution tree + right panel |
| **GAP-4** | No submission/session contract | **Phase 2** — §5 below |
| **GAP-5** | Limited check types (4 vs. WIMS's richer set) | **Open** — needs `engine_check` type or extended enum |

**GAP-5 resolution path:** Add an `engine_check` check type that delegates evaluation to the named engine. The engine command is in the step's `engine` field. The expected result is compared by the engine, not by AlgoGebra's built-in comparator. This bridges OEF's richer answer types (regex, set equality, ordered list) to AlgoGebra's check framework.

```json
{
  "check": {
    "type": "engine_check",
    "variable": "ans1",
    "engineCommand": "simplify(ans1 - expected)",
    "expected": "0",
    "tolerance": 0.001
  }
}
```

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

**OEF tags:** `\help{aide_derivation.json}` references an external help template file.

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

Stock WIMS CGI (`wims.cgi` / `wims.exe`) renders **HTML** via `html.c` / templates. There is **no built-in JSON grade API** matching the D-S01 assumption (`POST job=getresult → {"grade": 0..1, "feedback": "..."}`).

The `getscore*` builtins are **calc/exec** builtins for module authors, not a public HTTP contract. `job=getresult` on `adm/class/sheet` is **unverified** in the wims4win codebase.

**Consequence:** Connected mode requires a **WIMS-side adapter module** that accepts the D-S01 POST and returns JSON. Until this adapter exists, D-S01 is unimplemented.

### WI-21: Adapter build sequence

| Step | Who | Deliverable | Blocks |
|---|---|---|---|
| **L2-0** | Owner | Decide JSON-vs-HTML adapter approach + session/cookie rules | Everything below |
| **L2-1** | Grok | WIMS adapter module: accepts D-S01 POST, returns `{grade, feedback}` | L2-2, L2-3 |
| **L2-2** | Grok | Point suites 21–23 at real wims4win with adapter; keep mocks for CI | Grok test validation |
| **L2-3** | Codex | Desktop `HttpClient` twin of `wims-grade-client_GROK_V1.js` (same fields) | RCP connected mode |
| **L2-4** | Claude | Per-answer result schema; `submission` namespace for S-03 idempotency | Schema evolution |

**PRs #40–#42 are parked** (owner decision OD-3). The JS grade client (`wims-grade-client_GROK_V1.js`) returns a single `{grade: 0..1, feedback}` object. Q-W4 requires **per-answer structured results** — this is a future bump of the client + adapter.

### WI-22: Wire format (target, not implemented)

```
AlgoGebra POST /wims/wims.cgi
  Content-Type: application/x-www-form-urlencoded
  
  module=adm/class/sheet
  &job=getresult
  &exercise=<id>
  &ans1=<value_or_base64>
  &ans2=<value_or_base64>
  ...
  &session=<wims_session>       ← from cookie or explicit param

→ 200 OK  Content-Type: application/json

  {
    "grade": 0.75,
    "answers": [
      {"id": "ans1", "correct": true, "score": 1.0, "feedback": "..."},
      {"id": "ans2", "correct": false, "score": 0.5, "feedback": "Partially correct."}
    ],
    "feedback": "Overall feedback text."
  }
```

**This format is a design target, not a description of existing WIMS behavior.** The `answers[]` array is the Q-W4 per-answer result. It requires the L2-1 adapter.

### WI-23: Session and authentication (Q-W1)

| Step | Auth model | Session |
|---|---|---|
| **Step 1 (MVP local)** | None. `localhost` access. | WIMS creates anonymous session dir for scoring |
| **Step 2 (network)** | Same-origin cookie (default `wims-grade-client`) | WIMS session via `wims_session` param |
| **Step 3 (institutional)** | TLS + client certificates or institutional SSO | Cookie + certificate |

### WI-24: Exploration fallback (Q-W6)

When a local engine is missing but a WIMS server is reachable:
- **Grading:** error. Missing binary = error. No fallback.
- **Exploration:** AlgoGebra **may** route the computation to WIMS CGI. UI shows "remote computation" label. Never a silent substitution. Never falls back to a *different* CAS engine.

---

## 6. Offline evaluation contract (MVP)

### WI-30: What offline evaluation means

In offline mode, AlgoGebra evaluates student answers locally. There is no WIMS server. The evaluation criteria come from the course.json `check` object.

### WI-31: Check types (current + proposed)

| Type | Evaluator | Comparison |
|---|---|---|
| `value_equals` | AlgoGebra built-in | `|actual - expected| ≤ tolerance` |
| `value_range` | AlgoGebra built-in | `min ≤ actual ≤ max` |
| `object_exists` | AlgoGebra built-in | GeoGebra object with given name exists |
| `cas_equals` | GIAC (native CAS) | `Simplify(actual - expected) == 0` |
| **`engine_check`** (proposed) | Named external engine | Engine evaluates `engineCommand` with student answer substituted; compare result to `expected` |

`engine_check` closes **GAP-5** — it delegates comparison to the engine that understands the domain (e.g. Maxima for symbolic equality, GAP for group-theoretic equivalence).

### WI-32: Feedback contract

Each `check` object has an optional `feedback` with `pass` and `fail` messages. These are displayed in the course tree panel when the student clicks "Check."

For help-based feedback (richer than pass/fail), the help template's resolution tree provides per-step explanations. The check tells the student *if* they're right; the help template tells them *how to get there*.

---

## 7. Teacher authoring workflow (Q-W5)

### WI-40: What the teacher creates

| Artifact | Tool | Format | Consumed by |
|---|---|---|---|
| Exercise definition | WIMS OEF editor | `.oef` file | `oef2course` converter |
| GeoGebra construction | GeoGebra desktop | `.ggb` file | AlgoGebra `OPEN` action |
| Help templates | Text editor / JSON editor | `.json` (Schema_Help_Template) | AlgoGebra help panel |
| Course material (Phase 3) | Any Markdown editor | `.md` files + index | LLM/RAG |

AlgoGebra is **not** an OEF editor. The teacher creates OEF in the standard WIMS workflow, then runs the converter.

### WI-41: Conversion command

```bash
python oef2course_GROK_V1.py input.oef --seed 42 --output course.json
```

The converter produces:
- `course.json` (schemaVersion 1.0)
- Warning log for unconvertible OEF features (e.g. non-numeric answers → `object_exists`)

**Not yet implemented:** help template skeleton generation from `\hint` directives. This is Axis A from the Claude-to-Claude handoff.

---

## 8. Scenario and gate mapping

### WI-50: Scenarios covered by this CDC

| Scenario | What it tests | Status |
|---|---|---|
| **S-01** | WIMS schema/capability registration | **Phase 2** — needs L2-1 adapter |
| **S-02** | Submission → grade → display | **Phase 2** — needs wire format |
| **S-03** | Idempotency (retry same key) | **Phase 2** — connected mode only |
| **X-04** | External compute → kernel (one-shot write) | **Not run** — depends on engine Phase 3 (EE-P3d) |
| **X-05** | Notebook / help display | **MVP** — resolution tree covers this |
| **X-06** | Malformed input error handling | **Open** — BUG-015, addressed in engine CDC |

### WI-51: Gate dependencies

| Gate | Requirement | This CDC's contribution |
|---|---|---|
| **C** | W-01 scored, GWT stays until W-02 passes | Web help template rendering (TBD) |
| **D** | X-01–06 + S-01–05 on both hosts | S-01/S-02 require L2 adapter (Phase 2) |
| **E** | O-02 security + license | GPL v2 filter tables (deferred, OD-4) |

---

## 9. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **WI-R1** | WIMS CGI adapter never built — connected mode blocked | Medium | Phase 2 stuck | MVP is offline, no dependency. L2-0 owner decision required. |
| **WI-R2** | OEF exercises use features the converter can't handle | High | Degraded conversion (object_exists fallback) | Track coverage against corpus 300 (GV-3). Extend converter incrementally. |
| **WI-R3** | Help templates too complex for teachers to author | Medium | Low adoption | Provide skeleton generator. Example template exists. |
| **WI-R4** | `engine_check` type not expressive enough for WIMS answer variety | Medium | GAP-5 only partially closed | Fallback: connected mode delegates to WIMS's own evaluator. |
| **WI-R5** | wims4win on student Shadow PC — config/resource issues | Low | Student can't run exercises | Install guide + resource documentation (Q-W7). |
| **WI-R6** | LLM/RAG Phase 3 scope creep into MVP | Low | Delay MVP | Phase 3 is explicitly deferred. `courseRef` is reserved but not loaded. |

---

## 10. Relation to other documents

| Document | Relation |
|---|---|
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` | Engine subprocess layer (L1). This CDC adds exercise lifecycle on top. |
| `QA_WIMS_Integration_Owner_ALF_V2.md` | All owner decisions Q-W1..Q-W9, OD-1..OD-4. |
| `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` | Grok code audit: filter tables, CGI findings, L2 build sequence. |
| `Schema_Course_JSON_CLAUDE_V1.json` (V1_1) | Course tree schema with `help` and `engine` fields. |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_1) | Help template schema (process tree + text). |
| `Example_Help_Template_CLAUDE_V1.json` | Derivation exercise example. |
| `Spec_Course_Security_CLAUDE_V1_2.md` | Security constraints: action allowlist, Sequence budget. |
| `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` | Review findings F-01..F-18, owner decisions OD-1..OD-4. |
| `Handoff_Wims_Claude2Claude_CLAUDE_V1.md` | Integration axes for WIMS migration session. |
| `Decision_Open_Points_Sprint3_CLAUDE_V1.md` | D-S01 (WIMS compute = HTTP POST), D-S02 (Lean 4 = batch). |

---

## 11. Open actions

| # | Action | Who | Blocks |
|---|---|---|---|
| **WA-1** | Owner decides L2 adapter approach (JSON module vs HTML scraping) | Owner | L2-1 |
| **WA-2** | Extend `checkAction` enum with `engine_check` type | Claude | GAP-5 closure |
| **WA-3** | Help template skeleton generator from OEF `\hint` | Grok / WIMS session | Axis A |
| **WA-4** | Fixture corpus (20 exercises) shared between sessions | Grok | Axis C |
| **WA-5** | Encoding normalization (UTF-8 contract for all OEF) | Grok / WIMS session | Pipeline reliability |
| **WA-6** | Grok GV-1..GV-7 validation | Grok | CDC acceptance |
| **WA-7** | GAP engine implementation (optional, EE-P1f) | Codex | Group theory courses |

---

*End of `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md`.*
