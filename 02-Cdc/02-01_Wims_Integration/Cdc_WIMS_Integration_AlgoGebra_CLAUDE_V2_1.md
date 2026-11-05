<!-- CLAUDE_V2_1 -->
# CDC — WIMS Integration for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2_1.md` |
| Version | CLAUDE_V2_1 |
| Scope | **WIMS protocol, exercise lifecycle, help architecture, grading contract** — everything above the engine subprocess layer |
| Status | **Decision fold-in** — incorporates locked decisions D-WIMS-G01..L01, validation note corrections, security summary, teacher annex, acceptance matrices |
| Date | 2026-11-05 |
| Supersedes | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md` |
| Depends on | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` (engine layer, L1), `Schema_Course_JSON_CLAUDE_V1_2.json`, `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_2) |
| Owner Q&A | `QA_WIMS_Integration_Owner_ALF_V2.md` (Q-W1..Q-W9, all closed) |
| Locked decisions | `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md` — D-WIMS-G01, D-WIMS-H01, D-WIMS-E01, D-WIMS-C01, D-WIMS-E02, D-WIMS-T01, D-WIMS-L01 (all folded below) |
| Validation note | `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md` — `adm/raw` corrections applied to WI-20/21/22/23 |
| Grok input | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (WIMS code audit) |
| Grok audit | `Audit_Specs_Wims_GBOT_v1.md` (34 findings, 8 owner questions — all answered) |
| Reviews | `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` (OD-1..OD-4 closed) |
| Security | `e7f1ad4` — 3 engine command injection fixes (PARI `read*`, gnuplot backtick, gnuplot `eval`) |
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
| Help templates `*.json` | `Schema_Help_Template_JSON_CLAUDE_V1.json` V1_2 | Help panel loader (TBD) | Help panel within tree node |
| `.ggb` constructions | GeoGebra native | `GgbAPI.openFile()` | GeoGebra workspace (right) |

### WI-05: Schema gaps remaining (from Q-W3 analysis)

| Gap | Problem | Status |
|---|---|---|
| **GAP-1** | No structured help | **Closed** — `help` field on step + help template schema |
| **GAP-2** | No engine routing | **Closed** — `engine` field on step |
| **GAP-3** | No help/exploration contract | **Closed by Q-W9** — resolution tree + right panel |
| **GAP-4** | No submission/session contract | **Phase 2** — §5 below |
| **GAP-5** | Limited check types (4 vs. WIMS's 61 anstypes) | **Closed** — extended `checkAction.type` enum (see WI-31) |
| **GAP-6** | Parameters computed by `wims()/slib()/pari()/maxima()` at `cmd=new` time (214/300 corpus files) | **Closed (D-WIMS-C01)** — frozen variants (see WI-06) |

### WI-06: Frozen variants (GAP-6 resolution, D-WIMS-C01)

214 of 300 corpus exercises compute parameters at `cmd=new` time using `wims()`, `slib()`, `pari()`, or `maxima()` calls. The converter resolves only `random`/`randint`. For the remaining:

**Resolution (D-WIMS-C01):** The converter generates **N=20 frozen variants** per exercise at conversion time, using a WIMS evaluation pass with different seeds. Each variant contains pre-evaluated parameters.

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

### WI-12: Help template mechanism (D-WIMS-H01)

**OEF linking (D-WIMS-H01):** The `\text{algogebra_help=aide_derivation.json}` OEF directive references an external help template file. This uses the standard OEF `\text{}` variable mechanism, which is passed through by the converter without collision.

**Native `\help{}` maps to text only** — it collides with OEF's built-in `\help{}` popup (which shows the literal string; `oef2wims.c:79,197-211`). The 2 exercises in the corpus that use `\help` are inline only and map to `text`-type help nodes. Stock `\help{}` does **not** trigger JSON help loading.

**Sidecar fallback:** If no `\text{algogebra_help=...}` is present, the converter looks for `<exercise_name>.help.json` alongside the OEF file.

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

Stock WIMS CGI (`wims.cgi` / `wims.exe`) renders **HTML** via `html.c` / templates for interactive modules (home, sheet, OEF UI). There is **no built-in JSON grade API** for stock exercise modules.

**Live probe evidence (GV-1, 2026-11-04):** Grok tested wims4win `wims.cgi.exe` directly (WIMS 4.33a). Results:
- `job=getresult` on `adm/class/sheet` → **ignored** (returns worksheet HTML, 200). `job=` is a module-local switch, not a CGI verb.
- `cmd=getresult` → **rejected** (450: "The command 'getresult' is not valid. Valid commands are: new, renew, reply, help, hint, config").
- `cmd=` is a closed list in `wims.c:288-290` (14 verbs). A module **cannot add a `cmd=` verb**.
- Every interactive response was `text/html; charset=windows-1252`.
- Evidence: `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/`

#### WI-20a: Exception — `adm/raw` machine JSON API

**WIMS has a stock JSON machine interface: `module=adm/raw`.** This is NOT an interactive module — it is the admin/machine API for class operations.

```
GET /wims/wims.cgi?module=adm/raw&job=getinfoserver&code=probe1
→ Content-Type: application/json ; charset=iso-8859-1
→ {"status":"OK","code":"probe1","job":"getinfoserver","server_version":"4.33a",...}
```

Mechanism: `defs` → `header_json` + `!shortout` in `var.proc` / job procs. No HTML wrapper. Requires `.connections` identity (`ident`/`passwd`/`code`) for most jobs.

**Role in AlgoGebra:** `adm/raw` is **supporting machinery** for class operations (enroll, read scores, get server info). It is **not** the primary OEF grade path because:
- `testexo` only compiles an OEF in a sandbox (`jobs/testexo.proc:6-17`)
- `getscore*` only reads **stored** aggregate scores (`jobs/getscore.proc:21-42`)
- No existing `adm/raw` job submits student answers and returns per-answer evaluation

The primary OEF grade path is `cmd=new` → `cmd=reply` on the exercise module (see WI-21).

**Consequence:** Connected mode grading uses the stock `cmd=new` + `cmd=reply` flow with a **JSON output hook** in the WIMS `scripts/oef` directory (see WI-21). The earlier D-S01 `cmd=getresult` design is withdrawn. `adm/raw` remains available for class-level operations (Steps 2-3 of WI-23).

### WI-21: Connected mode grading design (D-WIMS-G01)

**Locked decision D-WIMS-G01:** Stock `cmd=new/reply` + wims4win JSON output hook.

The stock WIMS exercise flow is: `cmd=new` (create exercise session with random parameters) → student answers → `cmd=reply` (submit answers, WIMS evaluates with 61 anstypes). The adapter is a `special_parm=algogebra_json` hook in `scripts/oef` that causes the `cmd=reply` response to include a JSON payload with per-answer results alongside the HTML.

**Why this approach (D-WIMS-G01 rationale):**
- `adm/raw` has no OEF evaluation context (see WI-20a — `testexo` compiles only, `getscore*` aggregates only)
- Stock `cmd=new/reply` is what WIMS uses for actual answer evaluation with 61 anstypes
- The JSON hook is a minimal GPL v2 patch to one WIMS script directory, not a new module
- Rejected alternatives: `adm/raw` + new `job=gradeexo` (Option A in validation note — would need to reimplement anstype evaluation); `cmd=getresult` (impossible — closed verb list); HTML scraping (fragile)

**Adapter build sequence:**

| Step | Who | Deliverable | Blocks |
|---|---|---|---|
| **L2-0** | Owner | ~~Decide~~ **Decided (D-WIMS-G01)**: stock `cmd=new/reply` + JSON output hook | — |
| **L2-1** | Grok (Migration_Wims) | JSON output hook in `scripts/oef`: `special_parm=algogebra_json` → JSON `answers[]` appended to reply | L2-2, L2-3 |
| **L2-2** | Grok | Point suites 21–23 at real wims4win with hook; keep mocks for CI | Grok test validation |
| **L2-3** | Codex | Desktop `HttpClient` grade client (same fields as `wims-grade-client_GROK_V1.js`) | RCP connected mode |
| **L2-4** | Claude | Per-answer result schema + `submission` namespace for S-03 idempotency | Schema evolution |

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

#### WI-22a: Per-answer result schema (L2-4)

The `answers[]` array in the JSON hook response uses this structure:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://geogebraplus.local/schemas/wims-grade-response/v1",
  "type": "object",
  "required": ["grade", "answers"],
  "properties": {
    "grade": {
      "type": "number", "minimum": 0, "maximum": 1,
      "description": "Overall exercise score (0.0 = wrong, 1.0 = perfect)."
    },
    "answers": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["id", "correct", "score"],
        "properties": {
          "id": { "type": "string", "pattern": "^ans[0-9]+$" },
          "correct": { "type": "boolean" },
          "score": { "type": "number", "minimum": 0, "maximum": 1 },
          "feedback": { "type": "string", "maxLength": 2000 },
          "expected": { "type": "string", "maxLength": 500 },
          "anstype": { "type": "string", "maxLength": 50 }
        }
      }
    },
    "feedback": { "type": "string", "maxLength": 5000 },
    "submissionKey": {
      "type": "string", "maxLength": 64,
      "description": "Idempotency key for S-03. Client sends this on retry; hook returns cached result if key matches."
    }
  }
}
```

**`submissionKey`** enables S-03 idempotency: the client generates a UUID before each submission and includes it in the POST. The hook stores `{key → response}` in the session directory. A retry with the same key returns the cached response without re-evaluation.

### WI-23: Session and authentication (Q-W1)

| Step | Auth model | Session | Notes |
|---|---|---|---|
| **Step 1 (formative, anonymous)** | None | `cmd=new` creates an anonymous session. WIMS generates a session dir for scoring. No class, no login, no `.connections` entry. | Sufficient for offline MVP and anonymous practice. No grade recorded in any class. |
| **Step 2 (class-connected, local)** | `.connections` ident | `log/classes/.connections/<ident>` with `passwd`, `ident_site` IP allowlist. AlgoGebra uses `adm/raw` for **class operations only** (enroll, read scores — not OEF evaluation). OEF grading goes through `cmd=new/reply` on the exercise module. | Required for any grade-recording path. Only 5 `adm/raw` jobs need no auth. |
| **Step 3 (institutional, remote)** | TLS + `.connections` + optional SSO | Cookie + certificate. `ident_site` includes the institutional server IP range. | HTTPS required. |

**Clarification (from validation note):** WI-23 Step 1 "no authentication" applies to **anonymous OEF play** (`module=<exo>&cmd=new|reply`). It does **not** apply to `adm/raw` class operations — those always require a declared `.connections/` identity, even on localhost.

### WI-24: Exploration fallback (D-WIMS-E01) — Phase 2

**Locked decision D-WIMS-E01:** MVP shows hard error if engine missing. Remote exploration is Phase 2 only.

When a local engine is missing:
- **Grading:** error. Missing binary = error. No fallback. The student is told which engine is missing and how to install it.
- **Exploration:** **Phase 2 (D-WIMS-E01).** Requires a local WIMS compute module (e.g. `local/algogebra_compute`) that can accept a computation request and return a result. No stock WIMS compute endpoint exists for this (CGI returns HTML). MVP shows an explicit "engine not installed" error with install guide link.

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
| Not mappable (interactive, drag, etc.) | ~34 | — | `gradable: false` (D-WIMS-E02) |

**Extended check type enum:**

| Type | Evaluator | Comparison | New? |
|---|---|---|---|
| `value_equals` | AlgoGebra built-in | `|actual - expected| ≤ tolerance`. Supports `mode`: `absolute` (default) or `relative` (`|actual - expected| / |expected| ≤ tolerance`). `precision` field for sig-figs checks. | Extended |
| `value_range` | AlgoGebra built-in | `min ≤ actual ≤ max` | Unchanged |
| `object_exists` | AlgoGebra built-in | GeoGebra object with given name exists | Unchanged |
| `cas_equals` | GeoGebra CAS (GIAC via `Ggb2giac.java`) | `Simplify(actual - expected) == 0` | Unchanged |
| **`choice_equals`** | AlgoGebra built-in | Selected option(s) match expected. Supports single/multi choice. | **New** |
| **`sequence_equals`** | AlgoGebra built-in | Ordered list of values matches expected sequence. | **New** |
| **`set_equals`** | AlgoGebra built-in | Unordered set of values matches expected set. | **New** |
| **`engine_check`** | Named external engine | Engine evaluates `engineCommand` with student answer substituted; compare result to `expected` | **New** |

**Non-mappable answers (D-WIMS-E02):** Exercises whose answers cannot be evaluated offline (interactive drag, applet state) or that require `yacas`/`m2`/`scilab` (no SubprocessEngine wrapper) are marked `gradable: false` in the course JSON. The converter emits a warning. These exercises work in exploration mode but show "grading requires connected mode" in offline.

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

# Frozen variants (production — resolves GAP-6 / D-WIMS-C01)
python oef2course_GROK_V1.py input.oef --variants 20 --seed 42 --output course.json
```

The converter produces:
- `course.json` (schemaVersion 1.0)
- Help template skeletons from `\text{algogebra_help=...}` references
- Warning log for unconvertible OEF features → `gradable: false`

**Not yet implemented:** help template skeleton generation from `\hint` directives. This is Axis A from the Claude-to-Claude handoff.

### WI-43: Teacher packaging guide

A teacher packages an exercise for AlgoGebra offline use as follows:

```
my_exercise/
├── exercise.oef              ← OEF source (Createxo / Modtool)
├── construction.ggb          ← GeoGebra construction (optional)
├── aide_exercise.json        ← help template (optional, or via \text{algogebra_help=...})
└── run_convert.sh            ← conversion script
```

**Step 1 — Author OEF.** Use Createxo (class exercises) or Modtool (shareable modules) in the WIMS web interface. Add `\text{algogebra_help=aide_exercise.json}` to link structured help.

**Step 2 — Create .ggb.** Open GeoGebra desktop, build the construction, save as `.ggb`. Reference it in the OEF via the converter's `--ggb` flag or course JSON `OPEN` action.

**Step 3 — Write help template (optional).** Author `aide_exercise.json` following `Schema_Help_Template_JSON_CLAUDE_V1.json`. Use `{{variable}}` placeholders for OEF random values. Help is optional — exercises work without it.

**Step 4 — Convert.**
```bash
python oef2course_GROK_V1.py exercise.oef --variants 20 --seed 42 --output course.json
```
Review converter warnings. Exercises with `gradable: false` require connected mode for grading.

**Step 5 — Test in AlgoGebra.** Open `course.json` in AlgoGebra. Verify: tree renders, help displays, GeoGebra workspace loads, check evaluates correctly.

**What offline MVP guarantees vs Phase 2 connected:**

| Feature | Offline MVP | Phase 2 connected |
|---|---|---|
| Exercise display + GeoGebra workspace | Yes | Yes |
| Help templates (resolution tree) | Yes | Yes |
| Local engine computation (PARI, Maxima, Gnuplot, GAP) | Yes (if installed) | Yes + WIMS fallback |
| Answer checking (8 check types) | Yes | Yes + all 61 WIMS anstypes |
| Grade recording in class | No | Yes (`.connections` identity) |
| Dynamic parameters (live `wims()` calls) | No (frozen variants) | Yes |
| `gradable: false` exercises | Exploration only | Full grading via WIMS |

**Install expectations (Q-W7):** wims4win runs on student Shadow PC workstations and teacher machines. Requirements: Windows 10+, ~500 MB disk, engines installed via standard package managers (PARI/GP, Maxima, Gnuplot). The install guide is a deliverable (WA-3 scope).

---

## 8. Engine list and gradability

### WI-42: Engine coverage (wims4win interfaces)

| Engine | WIMS interface | AlgoGebra status | Offline gradable? | Engine ID (D-WIMS-L01) |
|---|---|---|---|---|
| **pari** | `src/Interfaces/pari.c` | **MVP** (EE-P1b) | Yes | `pari` |
| **maxima** | `src/Interfaces/maxima.c` | **MVP** (EE-P1c) | Yes | `maxima` |
| **gnuplot** | (direct call) | **MVP** (EE-P1d) | Yes (plot output) | `gnuplot` |
| **gap** | `src/Interfaces/gap.c` | **Optional** (EE-P1f) | Yes | `gap` |
| **geogebra-cas** | GeoGebra CAS / Ggb2giac.java | **Native** (always available) | Yes | `geogebra-cas` (D-WIMS-L01) |
| **octave** | `src/Interfaces/octave.c` | **Phase 2+** | Yes (when implemented) | `octave` |
| **yacas** | `src/Interfaces/yacas.c` | **Not planned (D-WIMS-E02)** | `gradable: false` offline | — |
| **m2** (Macaulay2) | `src/Interfaces/m2.c` | **Not planned (D-WIMS-E02)** | `gradable: false` offline | — |
| **scilab** | `src/Interfaces/scilab.c` | **Not planned (D-WIMS-E02)** | `gradable: false` offline | — |

**D-WIMS-L01 (giac rename):** The engine ID for GeoGebra's built-in CAS is **`geogebra-cas`**, not `giac`. This reflects that commands use GeoGebra CAS syntax (`Derivative(...)`) routed through `Ggb2giac.java`, not raw GIAC CLI syntax (`diff(...)`). Schemas, help templates, converter output, and examples all use `geogebra-cas`.

Exercises naming `yacas`, `m2`, or `scilab` as their engine are converted with `gradable: false` (D-WIMS-E02). They work in exploration mode (connected to WIMS) but cannot be graded offline.

---

## 9. Security summary

### WI-45: Engine security filters (commit `e7f1ad4`)

The engine subprocess layer enforces defence-in-depth security filters documented in `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md`. The following table summarizes the current state after the security review fixes:

| Engine | Filter layer | Blocked | Reference |
|---|---|---|---|
| **PARI/GP** | `AGB_ILLEGAL` (whole-word) | `system`, `extern`, `externstr`, `fileextern`, `install`, `eval`, **`read`**, **`readvec`**, **`readstr`** | `Decisions_PARI_Forbidden_GROK_V1.md` (V1 base) + `..._V1_1.md` (file-read extension) |
| **PARI/GP** | `WIMS_ILLPART` (substring) | `plot`, `write`, `help` | WIMS `pari.c` parity |
| **PARI/GP** | GP secure mode | `default(secure,1)` in header — blocks `system`, `extern`, `install` at GP level | Defence in depth; does NOT block `read`/`readvec`/`readstr` |
| **Maxima** | `WIMS_ILLEGAL` (whole-word) | 16 commands incl. `system`, `describe`, `save`, `fassave`, `stringout`, `demo` | WIMS `maxima.c` parity |
| **Maxima** | `WIMS_ILLPART` (substring) | `file`, `debug`, `plot`, `load`, `store`, `batch` | WIMS `maxima.c` parity |
| **Gnuplot** | `SHELL_ESCAPE` | `!` at line start | Blocks `!cmd` escape |
| **Gnuplot** | **`BACKTICK`** | `` ` `` anywhere | **New (`e7f1ad4`)** — blocks `` `cmd` `` substitution |
| **Gnuplot** | **`FORBIDDEN_EVAL`** | `eval`, `evaluate` | **New (`e7f1ad4`)** — blocks dynamic string → command construction |
| **Gnuplot** | `FORBIDDEN_COMMAND` | `system`, `shell` | Blocks direct OS calls |
| **Gnuplot** | `FORBIDDEN_IO` | `load`, `save`, `cd`, `set output`, `set terminal`, `set print` | Blocks file I/O |
| **Gnuplot** | `PROCESS_INPUT` | `plot '<cmd'`, `plot '|cmd'` | Blocks pipe sources |
| **All** | `SubprocessEngine` | 128 KB command limit, 1 MB output capture, process tree kill on timeout, control-char normalization, WIMS marker extraction | Framework-level limits |

**EE-12 errata:** The engines CDC V1_3 should add `eval`/`evaluate` to the Gnuplot filter documentation alongside the backtick finding (both from `e7f1ad4`). The code is already fixed; the spec citation is a documentation follow-up.

**Not a sandbox claim (D-ENG-03):** These filters are defence in depth. OS-level isolation (containers, seccomp, AppArmor) is Gate E scope. Resource exhaustion is not filtered.

---

## 10. Scenario and gate mapping

### WI-50: Scenarios covered by this CDC

| Scenario | What it tests | Status |
|---|---|---|
| **S-01** | WIMS schema/capability registration | **Phase 2** — needs L2-1 JSON hook |
| **S-02** | Submission → grade → display | **Phase 2** — needs wire format |
| **S-03** | Idempotency (retry same key) | **Phase 2** — `submissionKey` in WI-22a |
| **X-04** | External compute → kernel (one-shot write) | **Not run** — depends on engine Phase 3 (EE-P3d) |
| **X-05** | Notebook / help display | **MVP** — resolution tree covers this |
| **X-06** | Malformed input error handling | **Open** — BUG-015, addressed in engine CDC |

### WI-51: Gate dependencies

| Gate | Requirement | This CDC's contribution |
|---|---|---|
| **C** | W-01 scored, GWT stays until W-02 passes | Web help template rendering (TBD) |
| **D** | X-01–06 + S-01–05 on both hosts | S-01/S-02 require L2-1 JSON hook (Phase 2) |
| **E** | O-02 security + license | GPL v2 filter tables (deferred, OD-4). Security filters documented in §9. |

---

## 11. Acceptance criteria

### WI-60: Offline MVP acceptance (Given / When / Then)

| ID | Given | When | Then |
|---|---|---|---|
| **AC-O1** | course.json with 3 chapters, 5 exercises, `schemaVersion: "1.0"` | Student opens the file in AlgoGebra | Tree panel renders chapters, exercises, steps. No errors in console. |
| **AC-O2** | Exercise with `OPEN` action referencing `construction.ggb` | Student navigates to the exercise | GeoGebra workspace loads the .ggb; Algebra View, 2D/3D visible. |
| **AC-O3** | Exercise with `check: { type: "value_equals", expected: "4", tolerance: 0.01 }` | Student enters `4.005` and clicks Check | Check passes (within tolerance). Feedback "pass" message displayed. |
| **AC-O4** | Exercise with `check: { type: "choice_equals", expected: "B" }` | Student selects option A and clicks Check | Check fails. Feedback "fail" message displayed. |
| **AC-O5** | Exercise with `check: { type: "cas_equals", expected: "2*x+3" }` | Student enters `3+2*x` and clicks Check | CAS simplifies difference to 0 → Check passes. |
| **AC-O6** | Exercise with `check: { type: "engine_check", engine: "pari", engineCommand: "isprime({{answer}})" }` | Student enters `7` | PARI evaluates `isprime(7)` → `1`. Check passes. |
| **AC-O7** | Exercise with `engine: "pari"`, PARI not installed | Student navigates to the exercise | Error: "Engine 'pari' is not installed. [Install guide link]". No crash. (D-WIMS-E01) |
| **AC-O8** | Exercise with `gradable: false` | Student navigates to the exercise | Exercise displays normally. Check button disabled or shows "grading requires connected mode". (D-WIMS-E02) |
| **AC-O9** | Help template with 4 resolution steps, `{{a}}` variable | Student clicks a help step | Explanation renders with injected variable value. Actions execute in GeoGebra workspace. |
| **AC-O10** | Exercise with `variants[]` (20 frozen variants) | Student opens the exercise twice | Different variant selected each time (random). Parameters differ. |
| **AC-O11** | course.json with `\text{algogebra_help=aide.json}` link | Help panel opened | Sidecar `aide.json` loaded and rendered in help panel. |
| **AC-O12** | PARI command `read("/etc/passwd")` submitted via engine_check | Filter runs | `COMMAND_REJECTED` — `read` is in AGB_ILLEGAL (V1_1). |
| **AC-O13** | Gnuplot command `` plot sin(x) title `whoami` `` submitted | Filter runs | `COMMAND_REJECTED` — backtick blocked (`e7f1ad4`). |
| **AC-O14** | Gnuplot command `a="sys"; eval a."tem('ls')"; plot sin(x)` submitted | Filter runs | `COMMAND_REJECTED` — `eval` blocked (`e7f1ad4`). |

### WI-61: Phase 2 connected mode acceptance (Given / When / Then)

| ID | Given | When | Then |
|---|---|---|---|
| **AC-C1** | wims4win running on localhost with L2-1 JSON hook installed | AlgoGebra sends `cmd=new` | WIMS creates exercise session. AlgoGebra receives session ID. |
| **AC-C2** | Active session from AC-C1 | AlgoGebra sends `cmd=reply` + `special_parm=algogebra_json` + `ans1=42` | Response contains HTML + `<!-- ALGOGEBRA_JSON_BEGIN ... -->` block with `answers[]`. |
| **AC-C3** | AC-C2 response received | AlgoGebra parses the JSON block | Per-answer results displayed in course tree: correct/incorrect icons, score, feedback. |
| **AC-C4** | AC-C2 with same `submissionKey` | AlgoGebra retries the POST | Hook returns cached result (S-03 idempotency). Grade unchanged. |
| **AC-C5** | `.connections` identity configured for `adm/raw` | AlgoGebra queries `adm/raw&job=getscores` | Stored class scores returned as JSON. |
| **AC-C6** | Exercise requiring `yacas` engine, WIMS has yacas | Student submits answer in connected mode | WIMS evaluates via `yacas` interface. Grade returned via JSON hook. |
| **AC-C7** | L2-1 hook NOT installed on WIMS server | AlgoGebra sends `cmd=reply` + `special_parm=algogebra_json` | HTML returned without JSON block. Client detects absence, shows "connected grading unavailable" error. |

---

## 12. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **WI-R1** | WIMS CGI JSON hook never built — connected mode blocked | Medium | Phase 2 stuck | MVP is offline, no dependency. L2-0 decided (D-WIMS-G01: stock `cmd=new/reply` + hook). |
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

## 13. Relation to other documents

| Document | Relation |
|---|---|
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` | Engine subprocess layer (L1). This CDC adds exercise lifecycle on top. |
| `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md` | **Locked decisions D-WIMS-G01..L01 — all folded into this V2_1.** |
| `Decisions_PARI_Forbidden_GROK_V1.md` / `..._V1_1.md` | PARI AGB_ILLEGAL base list + file-read extension. Referenced in §9. |
| `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md` | `adm/raw` corrections — applied to WI-20a, WI-21, WI-23. |
| `QA_WIMS_Integration_Owner_ALF_V2.md` | All owner decisions Q-W1..Q-W9, OD-1..OD-4. |
| `Audit_Specs_Wims_GBOT_v1.md` | Grok audit: 34 findings, 8 owner questions. This V2 incorporates all. |
| `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` | Grok code audit: filter tables, CGI findings, L2 build sequence. |
| `Schema_Course_JSON_CLAUDE_V1_2.json` | Course tree schema with extended check types, `gradable`, `variants[]`. |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_2) | Help template schema (process tree + text, `geogebra-cas` engine ID). |
| `Example_Help_Template_CLAUDE_V1.json` | Derivation exercise example. |
| `Spec_Course_Security_CLAUDE_V1_2.md` | Security constraints: action allowlist, Sequence budget. |
| `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` | Review findings F-01..F-18, owner decisions OD-1..OD-4. |
| `Handoff_Wims_Claude2Claude_CLAUDE_V1.md` | Integration axes for WIMS migration session. |
| `Decision_Open_Points_Sprint3_CLAUDE_V1.md` | D-S01 (withdrawn — replaced by L2-1 hook design), D-S02 (Lean 4 = batch). |

---

## 14. Audit finding resolution

| Audit finding | Resolution |
|---|---|
| **A-01** (cmd=getresult impossible) | WI-21/22 rewritten: stock `cmd=new/reply` + JSON output hook (D-WIMS-G01) |
| **A-02** (WI-23 "no auth" false) | WI-23 rewritten: anonymous for formative, `.connections` for `adm/raw` class ops |
| **A-03** (grading design disagree) | Owner chose: stock `cmd=new/reply` + hook (D-WIMS-G01) |
| **A-04** (`\help{}` collision) | WI-12 rewritten: `\text{algogebra_help=...}` + sidecar fallback (D-WIMS-H01) |
| **A-05** (1824/1840 → object_exists) | WI-31 extended enum: 8 types including `choice_equals`, `sequence_equals`, `set_equals`, `engine_check` |
| **A-06** (GAP-6 missing) | WI-06 added: 20 frozen variants at conversion time (D-WIMS-C01) |
| **A-07** (exploration fallback) | WI-24: Phase 2 with explicit error in MVP (D-WIMS-E01) |
| **A-08** (GAP-5 text oversimplified) | WI-31 references A-05 family table |
| **A-09** (WI-R4 depends on non-existent L2-1) | WI-R4 updated: links to L2-1 hook design |
| **A-10** (`adm/raw` returns JSON) | WI-20a: documented as exception with role clarification |
| **A-13** (missing risks) | WI-R7..R10 added |
| **A-14** (teacher workflow) | WI-40/WI-43: Createxo/Modtool named + teacher packaging guide |
| **A-15** (runtime path) | WI-02: runtime path documented |
| **EE-12** (gnuplot eval/backtick) | §9: security summary table documents `eval`/`evaluate` + backtick filters from `e7f1ad4` |

---

## 15. Decision cross-reference

All decisions below are locked in `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`.

| Decision ID | Summary | CDC section |
|---|---|---|
| **D-WIMS-G01** | Grading via stock `cmd=new/reply` + JSON output hook | WI-21, WI-22 |
| **D-WIMS-H01** | Help via `\text{algogebra_help=file.json}` + sidecar; stock `\help{}` = text only | WI-12 |
| **D-WIMS-E01** | MVP = hard error if engine missing; remote exploration = Phase 2 | WI-24 |
| **D-WIMS-C01** | Converter default N=20 frozen variants | WI-06 |
| **D-WIMS-E02** | yacas/m2/scilab = `gradable: false` offline | WI-31, WI-42 |
| **D-WIMS-T01** | Fixture acceptance bar = "values match, rejections at least as strict" | §9 (engines CDC EE-P2d) |
| **D-WIMS-L01** | Engine ID `giac` renamed to `geogebra-cas` | WI-42 |

---

## 16. Open actions

| # | Action | Who | Blocks | Status |
|---|---|---|---|---|
| **WA-1** | ~~Owner decides L2 adapter approach~~ | Owner | — | **Closed (D-WIMS-G01)** |
| **WA-2** | ~~Extend `checkAction` enum~~ | Claude | — | **Closed** — done in Schema_Course V1_2 |
| **WA-3** | Help template skeleton generator from OEF `\text{algogebra_help}` + `\hint` | Grok / WIMS session | Axis A | **Open** |
| **WA-4** | Fixture corpus (20 exercises) shared between sessions | Grok | Axis C | **Open** |
| **WA-5** | Encoding normalization (UTF-8 contract for all OEF) | Grok / WIMS session | Pipeline reliability | **Open** |
| **WA-6** | ~~Grok GV-1..GV-7 validation~~ | Grok | — | **Closed** — audit completed |
| **WA-7** | GAP engine implementation (optional, EE-P1f) | Codex | Group theory courses | **Open** |
| **WA-8** | L2-1 JSON output hook prototype on wims4win | Grok (Migration_Wims) | Phase 2 connected mode | **Open** |
| **WA-9** | Rebase #40–#42 on hook protocol + per-answer `answers[]` | Grok | Phase 2 test suites | **Open** (blocked by WA-8) |
| **WA-10** | Converter: `\text{algogebra_help}`, `--variants`, new check types; rerun suite 19 + GAP-5 breakdown | Grok / Migration_Wims | MVP converter completion | **Open** |
| **WA-11** | ~~EE-12: add `eval`/`evaluate` to engines CDC gnuplot filter table~~ | Claude | Spec hygiene | **Closed** — documented in §9 of this V2_1 |

---

*End of `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2_1.md`.*
