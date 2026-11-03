<!-- CLAUDE_V1 -->
# Handoff to Grok Bot — WIMS CDC validation

| Field | Value |
|---|---|
| Document | `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md` |
| Author | Claude |
| Date | 2026-11-03 |
| Branch | `feat/grok-sprint3-plan-v1-1` @ `7552af2` |
| Owner | Doing parallel review of the same files |

---

## Context

Claude and the owner produced the WIMS integration Q&A and help template schema in this session. The owner is reviewing from the content/pedagogy side. Grok Bot validates from the technical/WIMS-compatibility side.

## Files to validate

### 1. Q&A document — owner decisions

**File:** `02-Cdc/QA_WIMS_Integration_Owner_ALF_V2.md` (version ALF_V2_3)

**What it contains:** 9 owner decisions (Q-W1..Q-W9) on WIMS integration scope: offline-first MVP, OEF format, bidirectional help, engine fallback rules, wims4win as local server, resolution process tree, LLM/RAG in Phase 3.

**What to validate:**
- Do the WIMS CGI protocol assumptions (Q-W1) match what wims4win actually exposes?
- Do suites 21–23 on the PR branches align with the offline-first assumption (Q-W2)?
- Does the converter gap analysis (Q-W3, GAP-1..GAP-5) match what you see in the OEF corpus 300 output?

### 2. Help template schema — new

**File:** `02-Cdc/Schema_Help_Template_JSON_CLAUDE_V1.json`

**What it contains:** JSON Schema for teacher-authored help templates linked from OEF via `\help{file.json}`. Two content types:
- `"process"`: resolution tree — `helpStep` nodes with multilingual `title`, `explanation`, `hint`, GeoGebra `actions` (CMD/CAS/VAL only), `engine`/`engineCommand`, `expectedResult`, nested `children` (max depth 3)
- `"text"`: flat multilingual text with `{{variable}}` placeholders and LaTeX

**What to validate:**
- Does the `engine` enum (`giac`, `pari`, `maxima`, `gnuplot`, `gap`) match the engines available in wims4win?
- Are the `helpAction` directives (CMD/CAS/VAL — no OPEN/SAVE/PNG) correct for a help context?
- Does the `{{variable}}` placeholder syntax conflict with any OEF or WIMS syntax?
- Is `maxItems: 20` for process steps and `maxItems: 10` for children/actions reasonable for real exercises?

### 3. Course schema extension — updated

**File:** `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` (version V1_1)

**What changed:** Two new fields on the `step` object:
- `help`: reference to an external help template OR inline i18n text + variable overrides
- `engine`: which computation engine this step requires (`giac` default, `pari`, `maxima`, `gnuplot`, `gap`)

**What to validate:**
- Does the `helpRef` structure (template path OR inline text, plus variables) work with the OEF converter pipeline?
- Does the `engine` field per step match how WIMS exercises specify their engine?

### 4. Example — concrete illustration

**File:** `02-Cdc/Example_Help_Template_CLAUDE_V1.json`

**What it contains:** A derivation exercise help template (FR/EN) with 3 resolution steps, sub-steps for term-by-term derivation, engine command (GIAC), GeoGebra CMD actions, and a `courseRef` for Phase 3 RAG.

**What to validate:**
- Does the engineCommand (`Derivative(x^2 + {{a}}*x + {{b}}, x)`) work with GIAC syntax?
- Is the LaTeX rendering syntax (`\\( ... \\)`) compatible with what GeoGebra/JLaTeXMath supports?
- Is the example representative of real WIMS/OEF exercises you've seen?

---

## Grok validation checklist

From `QA_WIMS_Integration_Owner_ALF_V2.md` — the full list:

| # | Check | Source | Priority |
|---|---|---|---|
| **GV-1** | wims4win CGI accepts same `job=`/`module=` params as institutional WIMS | `D:\ALF_ZGit\02-wims4win` | P0 |
| **GV-2** | Suites 21–23 alignment with offline-first assumption | `feat/grok-g14-wims-template`, `g15`, `g16` | P1 |
| **GV-3** | Suite 19 JSON output: confirm 5 gaps (GAP-1..GAP-5) against OEF corpus 300 | tip, `oef2course_GROK_V1.py` | P0 |
| **GV-4** | OEF hint/help/cheat-sheet directives — what constructs exist in real OEF files? | OEF format spec + wims4win examples | P0 |
| **GV-5** | wims4win local HTTP service on Windows (Apache/CGI on localhost) | `D:\ALF_ZGit\02-wims4win` | P1 |
| **GV-6** | OEF exercises with `\help` or equivalent tags — do any exist? What format? | wims4win OEF corpus | P0 |
| **GV-7** | Resolution process JSON: does any existing WIMS/XWims format encode step-by-step resolution? | WIMS source, XWims docs | P1 |

**Priority guidance:**
- **P0:** blocks the CDC — if the assumption is wrong, the schema design changes
- **P1:** informs the CDC — useful context but does not change the schema

---

## What NOT to do

- **No merges.** Owner is reviewing in parallel. No PR creation until owner approves.
- **No implementation.** This is validation/review only.
- **No schema edits.** Report findings; Claude or the owner will apply corrections.
- **Respect Planning V1_1 policy:** WIMS skim only, no S-01/S-02 settlement, no merge of #40/#41/#42.

## Expected output

A validation report (Markdown) with:
1. Per-file: OK / issues found (with specifics)
2. GV-1..GV-7 results (PASS / FAIL / PARTIAL with evidence)
3. Any OEF constructs or WIMS patterns that the schema doesn't cover

Place the report at: `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md` (repo root).

---

*End of `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md`.*
