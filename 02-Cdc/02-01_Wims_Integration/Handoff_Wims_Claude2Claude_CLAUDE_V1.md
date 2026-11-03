<!-- CLAUDE_V1 -->
# Handoff — GeoGebraPlus WIMS Specs → WIMS Migration Session

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Handoff_Wims_Claude2Claude_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-03 |
| From | Claude session `GeoGebraPlus Architecture` (`D:\ALF_Agents\G1_Geogebra_Migration`) |
| To | Claude session `43-wims-paris-saclay_fr` or `02-wims4win` (`D:\ALF_Scripts`) |
| Purpose | Transmit the WIMS integration specifications already designed in the architecture study, and propose integration axes for the WIMS toolchain side |
| Branch | `feat/grok-sprint3-plan-v1-1` @ `c23986b` |

---

## 1. What has been specified (architecture side)

The GeoGebraPlus project has produced a complete specification layer for WIMS integration. All files are in `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc\02-01_Wims_Integration/`.

### 1.1 Owner decisions — all closed

9 questions (Q-W1..Q-W9 + sub-questions Q-W9a..d) answered by the owner. Full record:

**`QA_WIMS_Integration_Owner_ALF_V2.md`** (ALF_V2_3)

Key decisions:
- **Q-W1:** MVP target = local wims4win (`D:\ALF_ZGit\02-wims4win`). No remote server for MVP.
- **Q-W2:** Offline first. Local engines via `SubprocessEngine` (Java ProcessBuilder).
- **Q-W3:** OEF first → `oef2course_GROK_V1.py` converter (suite 19 passing). 5 schema gaps identified.
- **Q-W4:** Bidirectional: help + answers → structured per-answer feedback.
- **Q-W5:** Teacher authors OEF + .ggb. AlgoGebra is not an OEF editor.
- **Q-W6:** Missing engine = error for grading, WIMS fallback for exploration only.
- **Q-W7:** wims4win runs on student machines (Shadow PC for CPGE).
- **Q-W8:** WIMS CDC = protocol + engine contracts. Course tree owns exercise lifecycle.
- **Q-W9:** Resolution process tree (left panel) + student workspace (right panel → WIMS). Three help layers: teacher text, help JSON templates, LLM/RAG (Phase 3).

### 1.2 JSON schemas — production-ready

| Schema | File | Status |
|---|---|---|
| **Course tree** | `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` (V1_1) | Accepted. `schemaVersion: "1.0"`. Extended with `help` (helpRef) and `engine` fields per step. |
| **Help template** | `02-Cdc/02-01_Wims_Integration/Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_1) | Accepted. Two content types: `process` (resolution tree) and `text` (flat i18n text). `{{variable}}` placeholders. |
| **Help example** | `02-Cdc/02-01_Wims_Integration/Example_Help_Template_CLAUDE_V1.json` | Derivation exercise: 3 steps, FR/EN, GIAC engineCommand, GeoGebra CMD actions, courseRef. |

### 1.3 Engine CDC — reviewed and corrected

**`Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md`** — covers offline subprocess layer only.

- 4 engines: Pari/GP (1st), Maxima (2nd), Gnuplot (3rd), GAP (optional)
- `ExternalComputeService` interface in `org.geogebra.plus.compute.api` OSGi bundle
- Full PARI AGB_ILLEGAL security filter (aligned with `Decisions_PARI_Forbidden_GROK_V1.md`)
- WIMS command filters ported to Java (D-ENG-03) — not a sandbox, same protection level as WIMS itself
- Phase 4 (connected mode) explicitly deferred

### 1.4 Converter analysis — 5 schema gaps

The OEF→JSON converter (`oef2course_GROK_V1.py`) produces valid `schemaVersion: "1.0"` JSON. Tested against `numeric_GROK_V1.oef`. 5 gaps identified:

| Gap | Problem | Resolution |
|---|---|---|
| **GAP-1** | No cheat sheet / structured help construct | **Solved:** `help` field added to course schema + separate help template schema |
| **GAP-2** | No engine routing per step | **Solved:** `engine` enum field added to course schema step |
| **GAP-3** | No help/exploration contract | **Solved by Q-W9:** resolution tree + right panel → WIMS |
| **GAP-4** | No submission/session contract | **Deferred:** Phase 2 connected mode |
| **GAP-5** | Limited check types (4 types vs. WIMS's richer set) | **Open:** needs `engine_check` type or extended enum |

### 1.5 Reviews completed

- **Grok Bot** (PR #59): validated with reservations, 4 questions for owner → all answered
- **Codex**: conditionally accepted, 8 findings merged
- **Consolidated**: 18 factual fixes applied, 4 owner decisions closed (OD-1..OD-4)

---

## 2. What the WIMS migration session already has

Based on the project status table provided by the owner:

| Stream | What exists | Location |
|---|---|---|
| Chrome MV3 "WIMS Exercise Capture" | V2.x extension (Claude base) + Grok fixes (brace, batch, windows-1252) | `feat/wims-migration` branch |
| Sequential mirror scripts | CLAUDE_V3/V4 crawlers. 450 session errors = operational risk. | `D:\ALF_Scripts\43-wims-paris-saclay_fr` |
| Eleda OEF deploy | 20 graphical exercises deployed to local WIMS (wims4win). Encoding mojibake known. | Session `02-wims4win` |
| xml2oef v2 toolchain | Converter under `ALF_Scripts`. Wired from Eleda `certified_oef` job. | In progress |

---

## 3. Proposed integration axes

### Axis A — OEF → Help Template pipeline (highest value)

**What:** Extend the existing `oef2course_GROK_V1.py` converter (or write a companion script) to also produce help template JSON files alongside the course JSON.

**Why:** The architecture side has defined the help template schema (`Schema_Help_Template_JSON_CLAUDE_V1.json`) but there is no tooling to **generate** those templates from OEF source. Currently, a teacher would have to write them by hand.

**Concrete deliverables:**
1. **OEF tag convention:** Define `\help{filename.json}` or equivalent tag syntax within OEF files. Validate against the actual OEF directive set (Grok GV-6 checks if `\help` already exists in the WIMS exercise bank).
2. **Converter extension:** `oef2course` emits a `help` reference on each step. A companion script generates a skeleton help template JSON from the OEF `\hint` directives and exercise structure.
3. **Variable injection mapping:** Document which OEF `\integer{a=random()}` variables become `{{a}}` placeholders in the help template, and at what point (conversion-time vs. runtime).

**Integration point with architecture:** `Schema_Help_Template_JSON_CLAUDE_V1.json` § `variables` + `helpStep.engineCommand`.

**Who does what:**
- WIMS session: converter extension, OEF tag inventory, encoding fixes
- Architecture session: schema validation, AlgoGebra loader spec

---

### Axis B — wims4win CGI protocol validation (blocks Phase 2)

**What:** Validate that the wims4win CGI endpoint (`wims.cgi`) accepts the same `job=` / `module=` / `lang=` parameters as institutional WIMS, so the transition from local (Step 1) to remote (Step 2) is a config change, not a protocol rewrite.

**Why:** The architecture assumes protocol identity (Q-W1). If wims4win diverges from the standard WIMS CGI protocol, the connected mode CDC cannot be written.

**Concrete deliverables:**
1. **Protocol inventory:** List all CGI parameters wims4win accepts, compared to the WIMS 4.x documentation.
2. **Grade response format:** Capture the exact HTTP response structure when `job=score` is sent. The architecture expects a structured per-answer result (Q-W4) — confirm or deny.
3. **Exercise listing:** Confirm `job=list` or equivalent to enumerate available exercises.

**Integration point with architecture:** `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` §4.4 (connected mode, deferred) and future `Cdc_WIMS_Integration`.

**Who does what:**
- WIMS session: CGI endpoint testing, parameter inventory, response capture
- Architecture session: protocol contract spec, submission schema

---

### Axis C — xml2oef + oef2course end-to-end chain (data pipeline)

**What:** Connect the `xml2oef` converter (WIMS session) with the `oef2course` converter (architecture session) into a single pipeline: WIMS XML export → OEF → course.json + help templates.

**Why:** The Eleda OEF stream and the wims-paris-saclay capture stream both produce OEF files. The architecture side consumes JSON. Connecting the two gives a full authoring pipeline from any WIMS source to AlgoGebra.

**Concrete deliverables:**
1. **Encoding normalization:** The Eleda stream has mojibake (windows-1252 vs. UTF-8). The Chrome extension has the same issue (GROK_V1_3 fix). Agree on a single encoding contract: all OEF files are UTF-8 after conversion.
2. **Fixture corpus:** Select 20 representative OEF exercises (mix of numeric, graphical, multi-answer) as the shared test corpus between both sessions.
3. **Pipeline script:** `xml2oef | oef2course` as a single invocable tool, with help template skeleton generation.

**Integration point with architecture:** `Schema_Course_JSON_CLAUDE_V1.json` schemaVersion `1.0`, GAP-5 (check types for non-numeric answers).

---

### Axis D — Security filter tables (license dependency)

**What:** The architecture specifies porting WIMS `illegal[]` / `illpart[]` filter tables from C to Java. These tables are GPL v2 (from wims4win `src/Interfaces/`). The WIMS session has direct access to the source.

**Why:** Owner decision OD-4 defers the GPL v2 license review to Gate E (O-02). But the filter tables must still be **extracted and documented** for the Codex implementation.

**Concrete deliverables:**
1. **Filter table extraction:** For each engine (Pari, Maxima, GAP, Gnuplot), extract the exact `illegal[]` and `illpart[]` arrays from the C source into a machine-readable format (JSON or CSV).
2. **License provenance:** Record exact file paths, line numbers, and WIMS version for each extracted table. This feeds the Gate E license inventory.
3. **Cross-validation:** Run the filter tables against the OEF exercise corpus — do any legitimate exercises trigger false positives?

**Integration point with architecture:** `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` §5 (per-engine security filter), `Decisions_PARI_Forbidden_GROK_V1.md`.

---

## 4. Priority recommendation

| Priority | Axis | Rationale |
|---|---|---|
| **1st** | **A — Help template pipeline** | Highest pedagogical value. Teacher experience depends on this. Schemas exist, tooling doesn't. |
| **2nd** | **C — End-to-end data chain** | Encoding + fixture corpus unblocks all other testing. Shared corpus enables parallel work. |
| **3rd** | **B — CGI protocol validation** | Blocks Phase 2 but not MVP. Can run in parallel with A/C. |
| **4th** | **D — Filter table extraction** | Deferred to Gate E, but early extraction de-risks the license review. |

---

## 5. Files to read first

If continuing this work in the WIMS session, read these in order:

1. **This document** (you're reading it)
2. `02-Cdc/02-01_Wims_Integration/QA_WIMS_Integration_Owner_ALF_V2.md` — all owner decisions
3. `02-Cdc/02-01_Wims_Integration/Schema_Help_Template_JSON_CLAUDE_V1.json` — the help template schema
4. `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` — the course tree schema (V1_1 with `help` + `engine`)
5. `02-Cdc/02-01_Wims_Integration/Example_Help_Template_CLAUDE_V1.json` — concrete derivation example
6. `02-Cdc/02-01_Wims_Integration/Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` — engine layer spec
7. `03-RCP-Spike/tools/oef2course_GROK_V1.py` — the current OEF→JSON converter

---

## 6. Open questions for the WIMS session

| # | Question | Why it matters |
|---|---|---|
| HQ-1 | Does the OEF format already have a `\help{}` directive or equivalent? If not, what is the least-invasive way to add external JSON references to OEF files? | Axis A depends on this — the tag convention must be OEF-compatible. |
| HQ-2 | The 450 session errors in the sequential mirror — are any of the captured OEF files corrupted? Would they break `oef2course`? | Axis C corpus quality. |
| HQ-3 | The xml2oef converter: does it produce clean UTF-8 OEF, or does the mojibake propagate from the XML source? | Encoding contract for the pipeline. |
| HQ-4 | Can the Chrome MV3 extension capture the exercise's `\hint` / `\feedback` directives, or only the rendered HTML? | Determines whether captured exercises can feed the help template pipeline. |
| HQ-5 | wims4win HTTP listener: is Apache started automatically, or does the user need to launch Laragon/WAMP? What port? | Axis B prerequisite for CGI protocol testing. |

---

*End of `Handoff_Wims_Claude2Claude_CLAUDE_V1.md`.*
