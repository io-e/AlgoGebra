<!-- ALF_V2_3 -->
# Owner Q&A — WIMS Integration CDC

| Field | Value |
|---|---|
| Document | `02-Cdc/QA_WIMS_Integration_Owner_ALF_V2.md` |
| Version | ALF_V2_3 (Q-W9a..d closed, phasing finalized) |
| Date | 2026-11-03 |
| Context | Preparing the WIMS integration CDC; questions raised by Claude, answers and corrections given by owner |
| Depends on | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md`, `Decision_Open_Points_Sprint3_CLAUDE_V1.md` (S-01/S-02), `Spec_Course_Security_CLAUDE_V1_2.md` |
| Validation | **Grok Bot** — verify WIMS CGI protocol assumptions against wims4win source and Debian test evidence |

---

## Q-W1 — WIMS server endpoint and authentication

**Question:** Which WIMS instance(s)? Authentication model? Existing API or new endpoint?

**Answer:** The non-migrated version already present on disk: `D:\ALF_ZGit\02-wims4win` (the wims4win local build, 24/24 tests passing). No remote institutional server for the MVP — the local wims4win instance is the target.

**Phased deployment roadmap:**

| Step | Description |
|---|---|
| **Step 1 (MVP)** | Local wims4win on the same machine. No authentication. Standard WIMS CGI protocol (`wims.cgi`). |
| **Step 2** | WIMS server installed on a dedicated server (institutional or cloud). Network access required. |
| **Step 3** | Certificate setup to simplify authentication and secure the connection (TLS + client certificates or institutional SSO). |

**Implication:** The CDC assumes Step 1 for the MVP. Steps 2–3 are architecture requirements to document now but implement later. The WIMS CGI protocol is the same across all three steps; what changes is the transport (localhost → network → TLS).

**Grok validation:** confirm that the wims4win CGI endpoint accepts the same `job=` / `module=` parameters as institutional WIMS (so Step 1→2 is a config change, not a protocol change).

---

## Q-W2 — Connected vs. Offline: which is the MVP?

**Question:** Connected mode first? Offline mode first? Both?

**Answer:** Offline mode first.

**Current status:** Partially done. The `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` already specifies the offline engine architecture (`SubprocessEngine`, `PariGPEngine`, `MaximaEngine`, `GnuplotEngine`). The Codex implementation plan (Phase 1) covers Windows subprocess proof. What remains for the WIMS CDC: the **evaluation contract** (how an exercise defines what the engine must compute and how the answer is scored locally) and the **formative feedback contract** (help flow).

**Implication:** The WIMS CDC does not re-specify the engine subprocess layer — it references `Cdc_External_Engines`. It adds the exercise-evaluation and feedback contracts on top.

**Grok validation:** confirm that suites 21–23 (WIMS template / grade client / full cycle) on the PR branches (`feat/grok-g14-wims-template`, etc.) align with the offline-first assumption, or note where they assume a running WIMS server.

---

## Q-W3 — Exercise format: OEF, XWims, or both?

**Question:** OEF primary? XWims JSON? Or OEF→course.json converter as bridge?

**Answer:** Both formats, OEF first. The OEF converter (`oef2course_GROK_V1.py`) already works (suite 19 passing on Debian).

**Owner note:** The converter script already generates OEF exercises as JSON. However, the study for how AlgoGebra consumes that JSON is not done yet — that is the work this CDC must cover.

**Implication:** The pipeline is:
1. Teacher writes OEF (existing WIMS authoring workflow)
2. Converter (`oef2course_GROK_V1.py`) produces JSON representation
3. **AlgoGebra loads and interprets that JSON** ← this contract is undefined and must be specified in the CDC

The CDC must define: the JSON schema that AlgoGebra expects, what OEF constructs map to which AlgoGebra behaviors, and what happens when an OEF feature has no AlgoGebra equivalent (graceful degradation or error).

### Converter analysis — current JSON output vs. CDC needs

The converter (`oef2course_GROK_V1.py`) targets `Schema_Course_JSON_CLAUDE_V1.json` (schemaVersion `1.0`). Verified output from `numeric_GROK_V1.oef`:

```json
{
  "schemaVersion": "1.0",
  "course": "Line through two points",
  "description": "Converted from WIMS OEF by oef2course_GROK_V1 (seed 1); formative checks only.",
  "author": "Grok Bot fixture",
  "locale": "en",
  "tree": [
    { "title": "Line through two points",
      "children": [
        { "title": "Statement",
          "description": "Compute 2a+b for a=3 and b=1.\n [figure] \nAnswer: [input]",
          "actions": [
            {"directive": "CMD", "value": "d1 = Segment((0, -5), (0, 5))"},
            {"directive": "CMD", "value": "d2 = Segment((-5, 0), (5, 0))"},
            {"directive": "CMD", "value": "d3 = Point({3, 1})"}
          ]
        },
        { "title": "1. Value of 2a+b",
          "description": "Type ans1 = <your answer> in the input bar, then press Check. Hint: Multiply first.",
          "check": {"type": "value_equals", "variable": "ans1", "expected": 7,
                    "tolerance": 0.001,
                    "feedback": {"pass": "Correct.", "fail": "Not yet - check your computation."}}
        }
      ]
    }
  ]
}
```

**What the converter handles today:**

| OEF construct | JSON mapping | Status |
|---|---|---|
| `\title`, `\language`, `\author` | `course`, `locale`, `author` | OK |
| `\precision` | `check.tolerance` (1/precision) | OK |
| `\integer`, `\real`, etc. with `random()` | Resolved at conversion time (deterministic seed) | OK |
| `\statement` text | `step.description` (HTML stripped) | OK |
| `\draw{}{}` primitives | `actions[]` with `directive: "CMD"` | OK — limited to `SAFE_EMIT` set (Segment, Line, Point, Circle, Polygon, Vector) |
| `\answer` numeric | `check: {type: "value_equals", expected, tolerance}` | OK |
| `\answer` non-numeric (menu, clickfill, draw, etc.) | `check: {type: "object_exists"}` + warning | Degraded — type information lost |
| `\hint` | Appended as text in `step.description` | Flat text only, no structure |

**5 gaps the WIMS CDC must fill:**

| # | Gap | Impact | CDC action needed |
|---|---|---|---|
| **GAP-1** | **No cheat sheet construct.** `\hint` is inlined as text in the description. The Q-W5 "teacher cheat sheets" have no dedicated schema slot. | Cheat sheets cannot be displayed separately from the exercise instruction. | Extend schema: add a `hints` array to the `step` object (or a top-level `cheatSheet` on the chapter). |
| **GAP-2** | **No engine routing.** The JSON has no field saying "this exercise needs Pari/GP" or "this answer needs Maxima." The engine selection from D-ENG-05 is absent. | AlgoGebra cannot know which engine to call for computation help. | Extend schema: add an `engine` field (per-chapter or per-step) with values like `"pari"`, `"maxima"`, `"gnuplot"`, `"giac"` (default). |
| **GAP-3** | **No help/exploration request contract.** The JSON is one-shot formative check only. There is no contract for "student asks for computation help" (the bidirectional flow from Q-W4). | The interactive exploration flow (student types expression → engine computes → result displayed) has no schema representation. | Define a `computeRequest` contract: what the student can send, which engine processes it, how the result is displayed. This is runtime behavior, not static JSON — but the exercise must declare what is allowed. |
| **GAP-4** | **No submission/session contract.** The JSON is local-only. No WIMS CGI endpoint or session reference for connected mode. | Phase 2 connected mode has no wire format. | Phase 2 — define `submission` object with endpoint, session ID, idempotency key. Not needed for offline MVP but the schema should reserve the namespace. |
| **GAP-5** | **Check types are limited.** Schema allows only `value_equals`, `value_range`, `object_exists`, `cas_equals`. WIMS exercises use richer comparison types (regex match, set equality, ordered list, interval containment, etc.). | Many WIMS exercise types cannot be faithfully converted. The converter already warns and falls back to `object_exists` for non-numeric answers. | Extend `checkAction.type` enum or add an `engine_check` type that delegates evaluation to the named engine (bridges to GAP-2). |

**Grok validation:** run suite 19 on tip, review the JSON output structure, confirm the 5 gaps above against the OEF corpus (300 exercises from `19_OefConverter_corpus300`), and report which gap blocks the most exercises.

---

## Q-W4 — Grading contract: what crosses the wire?

**Question:** What does AlgoGebra send? What does WIMS return? Retry semantics?

**Answer (AlgoGebra → WIMS):** Not only final answers. AlgoGebra sends **computation help requests** as well — the student can ask WIMS/engines for intermediate calculation assistance, explanations, and exploration, not just submit final answers for grading.

**Answer (WIMS → AlgoGebra):** Structured object with per-answer detail (not just a single score). This includes: per-answer correctness, partial credit, feedback text, and hints when the teacher has configured them.

**Answer (Retry / idempotency):** Phase 2 only. See explanation below.

### Explanation: S-03 idempotency (Phase 2)

The V2 scenario S-03 says: "Retry the same idempotency key → one grade record." This is a technical safeguard for connected mode:

- **Problem it solves:** if the network drops during submission, the student clicks "Submit" again. Without protection, WIMS could record two grade entries for the same attempt.
- **Idempotency key:** a unique ID (e.g. UUID) generated by AlgoGebra for each submission attempt. If WIMS receives the same key twice, it returns the existing grade instead of creating a duplicate.
- **For offline mode (MVP):** the local scorer is deterministic and there is no network retry issue. The idempotency contract matters when connected mode lands (Phase 2).

**Owner decision:** no action needed now. The CDC will note S-03 as a Phase 2 requirement for connected mode.

---

## Q-W5 — Teacher authoring scope

**Question:** Teacher creates in WIMS only (read-only client)? AlgoGebra includes authoring? Middle ground?

**Answer:** The teacher creates **OEF exercises** and **GeoGebra (.ggb) constructions**. AlgoGebra is not an OEF editor.

**Owner addition — Cheat Sheets:** Using OEF, the teacher also creates **cheat sheets** for AlgoGebra. These are structured hints and reference material that help the student answer the exercise. The cheat sheets are part of the exercise package (authored in OEF, converted to JSON, displayed by AlgoGebra alongside the construction).

**Implication:** The teacher authors in two tools:
1. **OEF files** — exercises + cheat sheets (hints/reference material for the student)
2. **GeoGebra constructions** (`.ggb` files) — the interactive geometry/algebra workspace

AlgoGebra must be able to:
- Display exercise instructions
- Display cheat sheets (formative help authored by the teacher)
- Accept student interaction with the GeoGebra construction
- Request computation help from engines (step-by-step calculation assistance)
- Present structured feedback from the exercise evaluation

The "help" flow has two sources:
1. **Teacher-authored:** cheat sheets embedded in the OEF exercise (static, curated)
2. **Engine-computed:** formative feedback from running the student's expression through the engine (dynamic)

**Grok validation:** check if the OEF format has a standard construct for hints/cheat sheets (`\hint`, `\help`, `\feedback` directives) and how the converter currently handles them.

---

## Q-W6 — Engine availability vs. WIMS server fallback

**Question:** Missing local engine = error or silent fallback to WIMS CGI?

**Answer:** Fallback to WIMS applies **only to interactive exploration** (computation help), not to grading. **OK for the MVP.**

**Implication:** Two rules coexist:
- **Grading (offline):** local engine must be present. Missing binary = error. No silent fallback. The student/teacher is told which engine is missing and how to install it.
- **Interactive exploration:** if the local engine is missing but a WIMS server is reachable, AlgoGebra **may** send the computation request to WIMS CGI as a convenience. This is a degraded mode, not a silent substitution — the UI indicates "remote computation" so the student knows.

This reconciles D-ENG-02 ("missing = error") with S-01 ("WIMS as remote compute"): the error rule applies to grading; the fallback applies to exploration only.

---

## Q-W7 — wims4win as local server

**Question:** Is wims4win the local WIMS server? Student machine or teacher/developer only?

**Answer:** Yes, wims4win is the local server. Yes, the student can use it — specifically:
- **CPGE students** (classes préparatoires) can run it on a Shadow PC (cloud gaming/workstation service).
- **Teachers** use it for test authoring and exercise validation.

**Implication:** wims4win is not developer-only. The CDC must assume it runs on student machines (possibly via Shadow PC) and on teacher machines. Install/config instructions and resource requirements matter.

### Explanation: offline vs. local-connected vs. institutional-connected

| Mode | How it works | When |
|---|---|---|
| **Offline** | AlgoGebra calls `gp.exe` / `maxima` directly via `SubprocessEngine`. No `wims.cgi` in the loop. | **MVP** |
| **Local-connected** | AlgoGebra sends HTTP to `localhost:port/wims/wims.cgi`. WIMS (wims4win) runs its own engine instances. Same scorer as institutional deployment. | **Phase 2 — Step 1** |
| **Institutional-connected** | AlgoGebra sends HTTP to a remote WIMS server. Teacher/admin manages the server. | **Phase 2 — Steps 2–3** |

The MVP is offline. Local-connected (wims4win on localhost) is the natural Phase 2 stepping stone — it validates the HTTP protocol without requiring network infrastructure.

**Grok validation:** confirm wims4win can run as a local HTTP service on Windows (Apache/CGI listener on localhost) and note the startup procedure.

---

## Q-W8 — Scope boundary with the course tree

**Question:** WIMS CDC covers protocol only, or the full exercise lifecycle?

**Answer:** The course tree owns the exercise lifecycle. The WIMS CDC covers **the protocol and engine integration only.**

**Implication — scope split:**

| WIMS CDC specifies | Course tree CDC specifies |
|---|---|
| Engine subprocess contracts (ref: `Cdc_External_Engines`) | Loading OEF/course.json |
| WIMS CGI submission/response protocol (Phase 2) | Presenting exercise steps to the student |
| Exercise evaluation contract (engine input → scored output) | Collecting student input from the GeoGebra construction |
| Formative feedback contract (help/explanation flow) | Displaying grades, feedback, and cheat sheets |
| Cheat sheet data schema (what the engine/OEF provides) | Cheat sheet rendering (how AlgoGebra displays them) |

The boundary: **the course tree calls the evaluation contract; the WIMS CDC defines that contract.**

---

## Q-W9 — Resolution process and student help architecture

**Question:** How does the student help system work? What is the structure of the help content?

**Answer (owner, 2026-11-03):** The teacher provides a **resolution process** as a JSON file, linked from OEF via tags. This is the core pedagogical structure.

### 9.1 Resolution process tree

The resolution process JSON is loaded into the **course tree (left panel)**. Each node is a **transformation step** in the resolution — not just text, but an active step that changes the mathematical state.

```
Course Tree (left panel)                    GeoGebra Workspace (right panel)
─────────────────────────                   ──────────────────────────────────
Exercise: Dérivation de x²+3x              Student experiments here:
├─ Étape 1: Identifier f(x)                 - replay the current step
│   ├─ [explication FR/EN]                   - test another function
│   ├─ [aide JSON → variables injectées]     - modify random values
│   └─ [LLM Q&A / RAG sur le cours]         - try a different approach
├─ Étape 2: Appliquer la règle              
│   ├─ [explication FR/EN]                  Student work on the right panel
│   ├─ [aide JSON]                          is sent back to WIMS for
│   └─ [LLM / RAG]                         evaluation.
├─ Étape 3: Simplifier                     
│   └─ ...                                 
└─ Étape 4: Vérifier le résultat           
    └─ ...                                 
```

### 9.2 Each node has three help layers

| Layer | Source | Content | When |
|---|---|---|---|
| **1. Explanations** | Teacher-authored, in the resolution JSON | Multilingual text (FR/EN/...) explaining the transformation at this step | Always available, static |
| **2. Help JSON** | Teacher-authored template, linked from OEF via `\help{file.json}` tag | Populated at conversion time (seed-based defaults) AND at runtime (student's actual random values, context, language) | On demand — student clicks "help" |
| **3. LLM assistance** | AI model (local or remote) | Answers student questions about this step; can do RAG on the student's course material | On demand — student asks a question |

### 9.3 Help JSON template mechanism

**Tags in OEF:** The OEF file contains `\help{aide_derivation.json}` tags that reference external JSON files.

**File location:** Both models supported:
- **Exercise-specific:** `aide_xxx.json` alongside the `.oef` file (teacher creates them for this exercise)
- **Shared library:** reusable templates referenced by name (e.g. `aide_derivation.json` used by many exercises). Exercise-specific overrides shared.

**Variable injection:** The help JSON is a **template**. It is populated with:
- **Random variable values** from the OEF (`\integer{a=random(2..5)}` → `"a": 3`)
- **Student context** (current step, previous answers, error history)
- **Language** (student's locale preference)

**Injection timing:** Both:
- **At conversion time:** the converter resolves random variables with the seed and bakes default values into the JSON (reproducible, works offline)
- **At runtime:** AlgoGebra re-injects values when the student opens the exercise (adapts to session seed, student locale, student progress)

### 9.4 Right panel: student workspace → WIMS

The GeoGebra workspace (right panel) is where the student **replays, tests, and experiments**:
- **Replay:** execute the current resolution step in the construction
- **Test:** try a different approach or different values
- **Experiment:** modify the construction freely

The student's workspace interactions are **sent back to WIMS** for evaluation. This is the submission path: the right panel produces the construction state that WIMS evaluates.

### 9.5 Impact on schema gaps

This architecture resolves and redefines the 5 gaps identified in Q-W3:

| Gap | Original | New status |
|---|---|---|
| **GAP-1** (cheat sheets) | No structured help in schema | **Resolved by Q-W9:** help is a full resolution tree with per-node explanations + linked JSON templates. Schema needs `help` array on each step node. |
| **GAP-2** (engine routing) | No engine field | **Still needed:** each resolution step may call a different engine. Add `engine` field per step. |
| **GAP-3** (help/exploration) | No bidirectional contract | **Resolved by Q-W9:** right panel interactions → WIMS. Plus LLM/RAG layer for Q&A. Three distinct channels: teacher help, engine compute, LLM Q&A. |
| **GAP-4** (submission) | No wire format | **Clarified:** right panel construction state is the submission payload. Phase 2 for connected mode. |
| **GAP-5** (check types) | Limited check types | **Still needed.** Resolution steps may need richer checks (intermediate results, not just final answer). |

### 9.6 New schema elements needed

The `Schema_Course_JSON_CLAUDE_V1.json` must be extended with:

```
step: {
  ...existing fields...
  "help": {                          ← NEW
    "explanations": {                  multilingual teacher text
      "fr": "...",
      "en": "..."
    },
    "template": "aide_derivation.json",  linked help JSON template
    "llm": {                           LLM/RAG configuration
      "enabled": true,
      "ragSource": "course"            RAG on student's course material
    }
  },
  "engine": "maxima",                ← NEW (GAP-2)
  "transform": {                     ← NEW: what this step does
    "input": "expression from previous step",
    "operation": "derive",
    "output": "variable to check"
  }
}
```

### 9.7 Open questions from Q-W9

| # | Question | Answer | Status |
|---|---|---|---|
| Q-W9a | Which LLM? | **Both.** Local model (Ollama/llama.cpp) handles simple questions (low latency, no cost, offline). Harder questions are routed to a remote API (Claude, etc.). Routing heuristic: complexity of the question determines local vs. remote. | **Decided** |
| Q-W9b | RAG source? | **Markdown course material with an index.** The teacher provides the course as Markdown files. The teacher specifies the relevant chapter/section **inside the OEF** (via a tag), so the RAG scope is per-exercise, not the entire corpus. | **Decided** |
| Q-W9c | LLM/RAG phase? | **Phase 3.** The resolution tree + help JSON templates are MVP/Phase 2. LLM Q&A and RAG are Phase 3 — they add significant infrastructure (model hosting, embedding, retrieval) that does not block the core exercise flow. | **Decided** |
| Q-W9d | Help JSON template format? | **Schema defined:** `Schema_Help_Template_JSON_CLAUDE_V1.json`. Two content types: `"process"` (step-by-step resolution tree with per-node explanations, actions, engine commands, sub-steps) and `"text"` (flat multilingual text). Variables via `{{name}}` placeholders. Course schema extended with `help` and `engine` fields on steps. Example: `Example_Help_Template_CLAUDE_V1.json`. | **Done** |

---

## Summary of decisions

| Question | Decision | Phase | Status |
|---|---|---|---|
| Q-W1 Server | Local wims4win → server → certificates (3 steps) | MVP: local | **Decided** |
| Q-W2 Mode | Offline first; engine layer partially done | MVP offline, Phase 2 connected | **Decided** |
| Q-W3 Format | OEF first → JSON converter exists; AlgoGebra JSON contract TBD | MVP | **Decided — CDC work needed** |
| Q-W4 Payload | Bidirectional: help + answers → structured per-answer feedback | MVP (help), Phase 2 (grading) | **Decided** |
| Q-W4 Retry | S-03 idempotency for connected mode | Phase 2 | **Deferred** |
| Q-W5 Authoring | Teacher creates OEF (exercises + cheat sheets) + .ggb | MVP | **Decided** |
| Q-W6 Fallback | Exploration: fallback OK. Grading: error if engine missing | MVP | **Decided** |
| Q-W7 wims4win | Local server for students (Shadow PC / CPGE) and teachers | MVP | **Decided** |
| Q-W8 Scope | Protocol + engine contracts; course tree owns lifecycle | MVP | **Decided** |
| Q-W9 Resolution process | Teacher provides resolution tree JSON; per-node help (multilingual + template + LLM/RAG); right panel → WIMS | MVP (tree + help templates), Phase 3 (LLM/RAG) | **Decided — all sub-questions closed** |
| Q-W9a LLM routing | Local for simple, remote (Claude) for hard questions | Phase 3 | **Decided** |
| Q-W9b RAG source | Markdown course + index; teacher specifies chapter in OEF | Phase 3 | **Decided** |
| Q-W9c LLM phase | Phase 3 | Phase 3 | **Decided** |

---

## Grok validation checklist

| # | Check | Branch / source |
|---|---|---|
| GV-1 | wims4win CGI accepts same `job=`/`module=` params as institutional WIMS | `D:\ALF_ZGit\02-wims4win` |
| GV-2 | Suites 21–23 alignment with offline-first assumption | `feat/grok-g14-wims-template`, `g15`, `g16` |
| GV-3 | Suite 19 JSON output: confirm 5 gaps (GAP-1..GAP-5) against OEF corpus 300 — which gap blocks the most exercises? | tip, `oef2course_GROK_V1.py`, corpus 300 |
| GV-4 | OEF hint/help/cheat-sheet directives (`\hint`, `\help`, `\feedback`) — what constructs exist in real OEF files? | OEF format spec + wims4win examples |
| GV-5 | wims4win local HTTP service on Windows (Apache/CGI on localhost) | `D:\ALF_ZGit\02-wims4win` |
| GV-6 | OEF exercises with `\help` or equivalent tags — do any exist in the WIMS exercise bank? What format? | wims4win OEF corpus, WIMS documentation |
| GV-7 | Resolution process JSON: review if any existing WIMS/XWims format already encodes step-by-step resolution | WIMS source, XWims docs |

---

*End of `QA_WIMS_Integration_Owner_ALF_V2.md`.*
