<!-- GROK_V1 -->
# Review: `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` (GROK_V1)

| Field | Value |
|---|---|
| Reviewer | Grok Bot (Debian lane), 2026-11-03 |
| Reviewed ref | `origin/feat/grok-sprint3-plan-v1-1` @ `49d98f9` (PR #56). This is the newest ref with QA ALF_V2_3 + help-template schema (`7552af2`). |
| Layout note | The owner's local folder `02-Cdc/02-01_Wims_Integration/` (with `00-00_archives/`) **does not exist on any GitHub ref**. The files are flat in `02-Cdc/`. `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md` and `Review_WIMS_CDC_Schemas_Owner_GROK_V1.md` are **not on GitHub**, so they were not reviewed. This review sits next to the other files in `02-Cdc/`. Move it with them when the folder is pushed. |
| Inputs | CDC V1 → V1_1 diff, `QA_WIMS_Integration_Owner_ALF_V2.md` (ALF_V2_3), `Decisions_External_Engines_GROK_V1.md`, `Decisions_PARI_Forbidden_GROK_V1.md`, `Decisions_GIAC_*_GROK_V1.md`, `Cdc_GIAC_MVP_GROK_V1.md`, `Schema_Help_Template_JSON_CLAUDE_V1.json`, `Example_Help_Template_CLAUDE_V1.json`, `Schema_Course_JSON_CLAUDE_V1.json`, PRs #40/#41/#42 (`0222ce1`, `a30f8ec`, `c9a6dd5`) |

## Verdict: **Validated with reservations**

- The **engine layer** (§2–§5, D-ENG-01..05) is sound. It matches Grok's decision docs and can be built. V1→V1_1 only closed §7 and wrote the decisions into §3/§4/§6. That change is correct.
- V1_1 is dated **2026-10-29**. That is **before** the owner Q&A V2 (2026-11-03). As a result, almost none of the Q-W decisions appear in it.
- The status line "Decisions closed — ready for Codex implementation" is accurate **only for the subprocess engine slice**. It is not accurate for WIMS integration as a whole.
- The QA (Q-W2, Q-W8) itself says the evaluation, feedback, help and submission contracts belong in a **separate WIMS CDC** that references this one. That WIMS CDC does not exist on GitHub yet.
- The example JSON **fails** schema validation (B-1).

## (a) Owner decisions (QA ALF_V2_3) vs CDC V1_1

| Q | Owner decision | In V1_1? | Ref / note |
|---|---|---|---|
| Q-W1 | MVP = local wims4win, no auth; then server, then TLS | **Missing** | §4.4 just says "WIMS server (HTTP)". No transport steps. |
| Q-W2 | Offline first | **Partial / contradicts** | §1 lists both modes with no priority. §6 puts connected mode in Phase 4 but leaves the offline scorer unspecified. `Decisions_External_Engines_GROK_V1.md` ("Not in this decision") says *"Offline scoring waits until the Java wrappers match WIMS output on a written fixture set"*. That gate has to be stated explicitly (it becomes Phase 2d). |
| Q-W3 | OEF first, JSON via `oef2course`, plus GAP-1..5 | **Missing** (out of scope) | Belongs to the WIMS CDC. V1_1 §2 Perl "OEF reader" **conflicts** with the actual Python converter `oef2course_GROK_V1.py` (see M-5). |
| Q-W4 | Bidirectional: help requests plus answers; structured per-answer feedback; S-03 deferred to Phase 2 | **Missing** | §4.4 has only "grade + feedback". |
| Q-W5 | Teacher authors OEF + cheat sheets + .ggb; no OEF editor | Missing (out of scope) | WIMS CDC / course-tree CDC. |
| Q-W6 | Missing engine: **error for grading**, but **WIMS fallback allowed for exploration**, with a "remote computation" label | **Contradicts** | §4.1 says "Missing binary → error, not fallback to another CAS". §4.3 says "No overlap, no fallback". These need to be qualified (M-1). |
| Q-W7 | wims4win runs on student (Shadow PC/CPGE) and teacher machines | **Missing** | §8 risk register has no row for wims4win install or resources. |
| Q-W8 | WIMS CDC = protocol + engine contracts; course tree owns lifecycle | Consistent | V1_1 keeps to the engine layer. Add a pointer to it in §9. |
| Q-W9/9a–d | Resolution tree, help templates, `engine` per step, LLM/RAG in Phase 3 | **Missing** | The `engine` field (GAP-2) enum `giac/pari/maxima/gnuplot/gap` is consistent with §2/§4.3. The help schema is reviewed in (e). |

## (b)–(d) Findings

| ID | Sev | Where | Finding | Proposed fix |
|---|---|---|---|---|
| B-1 | **Blocking** | `Example_Help_Template_CLAUDE_V1.json` | Fails `Schema_Help_Template_JSON_CLAUDE_V1.json`. The top-level `$comment` is not allowed, because `additionalProperties: false` (see (e)). | Add `"$comment": {"type":"string"}` to the schema properties, or remove it from the example. Add a CI validation step. |
| B-2 | **Blocking** (for "ready for Codex" on WIMS) | Header "Status", §6 Phase 4 | The status claims readiness, but Q-W1/2/4/6/7/9 are absent. The Phase 4 connected design contradicts "offline first". | Rename the scope to "engine layer (offline subprocess) — ready". Publish a V1_2 or a separate WIMS CDC that covers the QA, with Phase 4 = local-connected wims4win (Q-W7 table). |
| M-1 | Major | §4.1, §4.3, §7 D-ENG-02 | Q-W6 exploration fallback to WIMS CGI is not reflected. "No fallback" reads as absolute. | State: grading means a missing engine is an error (D-ENG-02). Exploration may route to a reachable WIMS, shown in the UI as "remote computation". It never falls back to another CAS. |
| M-2 | Major | §5.1 Security filter | Out of date vs `Decisions_PARI_Forbidden_GROK_V1.md` (BUG-006, owner-accepted 2026-10-29). The decision also blocks `system`, `extern`, `externstr`, `fileextern`, `install` and `eval` (whole word, before spawn, `COMMAND_REJECTED`), and keeps `default(secure,1)` in the header. Without those blocks the CDC describes an exploitable filter (`install` works even in secure mode). | Copy the AGB_ILLEGAL list and the "not a sandbox" note into §5.1. Reference SBX-14..19. |
| M-3 | Major | §2, §3, §6 vs `Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1 | That Grok doc says that PARI/Maxima/GAP/Gnuplot run on the **WIMS server** and that we "do not embed GAP, PARI … in the RCP". V1_1 and D-ENG-01/02 run them as local subprocesses (offline mode). This is an internal inconsistency in Grok's own docs, which the owner's offline-first decision resolves in favour of V1_1. | Owner to confirm. Grok will then supersede `Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1 ("engines are external host subprocesses, never inside the GeoGebra kernel"). |
| M-4 | Major | §4.4 vs PRs #41/#42 | The implemented D-S01 client (`wims-grade-client_GROK_V1.js`) expects `{grade: 0..1, feedback}`, a **single score**. Q-W4 asks for **per-answer** correctness, partial credit and hints. Suites 21–23 assume a (mock) WIMS server, i.e. connected mode. They test Phase 2, not the offline MVP (answers GV-2). | The WIMS CDC defines the per-answer result object. Then #41 is either extended (`answers[]`) or explicitly labelled Phase 2. The owner decides whether #40–#42 stay parked as Phase 2. |
| M-5 | Major | §2 "Text processing layer" | Perl is called **required** as the OEF reader. The real reader is the Python `oef2course_GROK_V1.py` (suite 19), and `Decisions_External_Engines` keeps Perl only "when an activity is stored as OEF". This creates an unneeded runtime dependency for students. | Say: OEF→JSON is done at conversion time (Python). Perl is needed only if raw OEF is interpreted at runtime, and that is not in the MVP. |
| M-6 | Major | Whole doc | There are no requirement IDs (only D-ENG-xx and phase steps). Phase 2/3/4 have deliverables without acceptance criteria. | Add `EE-xx` IDs and a "done when" column for every step, e.g. 2d: "byte-identical output on fixture set F (N cases per engine)". |
| m-1 | Minor | §5.1 test | The expected `factor(2^64-1)` string assumes post-`output()` cleanup. Raw gp prints `[3 1]` rows. | Say "after output parser" and pin the gp version (Debian has 2.17.x, `Decisions_PARI_Forbidden`). |
| m-2 | Minor | §5.3 | The Gnuplot filter (`system`, `shell`, `!`) misses `set output`/`load`/`call`/`print`-to-file, which can write or read files. D-ENG-04 requires the output path to be forced by the host. | Block `set output`, `set print`, `load`, `call`, `save`, and backticks. The host sets the output path. |
| m-3 | Minor | §6, RQ-1 | No JVM is stated. RQ-1 (owner-locked) makes Java 21 the default on Debian for RCPTT/AUT. `Cdc_GIAC_MVP` uses Java 25 on Windows. | State "Java 21 baseline (RQ-1); Java 25 tested on Windows". `ProcessBuilder` usage is 21-compatible. |
| m-4 | Minor | §6 Phase 2b | It assumes the WIMS C binaries `bin/pari`, `bin/maxima` and `bin/gap` are built on Debian. Their provenance and build are not specified. | Name the source (wims4win build or Debian `wims` package) and the version. |
| m-5 | Minor | IDs | `WIMS_Open_Questions_GROK_V1.md` (#41) uses **Q-W1..Q-W4** for different questions than the owner QA Q-W1..Q-W9. This is an ID collision. | Rename the #41 draft to `Q-GC1..4` before merging #41. |
| m-6 | Minor | §9 | Missing references: `Decisions_PARI_Forbidden_GROK_V1.md`, `QA_WIMS_Integration_Owner_ALF_V2.md`, the schemas, and `Decision_Open_Points_Sprint3_CLAUDE_V1.md` (D-S01). §9 cites `Gate_Decision_D-04_D-05_GROK_V1.md`, but the accepted version is `_V1_1`. | Update §9. |
| m-7 | Minor | §8 | GPL v2 licensing is mentioned only in §9 (copying the WIMS header strings and filter tables). There is no risk row or owner decision for it. | Add a risk row and a license decision. |

## (e) JSON validation

Tool: Python `jsonschema` 4.x, `Draft202012Validator` (both schemas declare draft 2020-12). `check_schema` passes for `Schema_Help_Template_JSON_CLAUDE_V1.json` and `Schema_Course_JSON_CLAUDE_V1.json`.

- **Example vs help schema: FAIL, 1 error**: `[] Additional properties are not allowed ('$comment' was unexpected)`.
- With `$comment` removed: **0 errors**. The `{{a}}`, `{{b}}` and `{{s}}` placeholders all match the declared `variables`.
- Draft notes:
  - `$comment` is a 2020-12 keyword **inside schemas** only. In an instance it is ordinary data.
  - `$id` uses `geogebraplus.local`, which is fine as an identifier and is never fetched.
  - `i18nString` locale keys allow `fr` / `fr_FR`, but course `locale` / BCP 47 style `fr-FR` would be rejected. Align the two.
  - Placeholder/variable consistency is **not** enforceable in JSON Schema. It needs a loader check (proposed test, below).

## (f) Debian test mapping

| Requirement | Existing test | Needed |
|---|---|---|
| Pari filter + output (§5.1, BUG-006) | `05_Test_Sandbox_GROK_V1.ps1` SBX-01..19, PariEngineTests | — |
| Maxima / Gnuplot / GAP (1c/1d/1f) | none | engine smoke suite `EE_*_GROK_V1.ps1` (headless, no X needed; Gnuplot `pngcairo` to a temp file plus a PNG magic check) |
| 2d WIMS C vs Java parity | none | fixture TSV (≥20 cases/engine) and a diff runner; needs the WIMS C binaries (m-4) |
| 1e `isAvailable()` / missing-engine error vs Q-W6 fallback | none | PATH-stripped run; assert error on grading and a "remote" label on exploration |
| OEF→JSON (Q-W3) | suite 19 | GAP-1..5 count on corpus 300 (GV-3) |
| Connected grade (Phase 4) | suites 21/22/23 (mock D-S01, Firefox headless) | rework once the per-answer object is specified (M-4) |
| Help template schema | none | `jsonschema` validation of all `*Help_Template*.json` plus a placeholder check in Run_All |
| 3c UI compute panel | none | SWT on a dedicated Xvfb display; attended checks on Windows |

## Open questions for the owner

1. **Scope:** should V1_1 be restricted to the engine layer, with a new `Cdc_WIMS_Integration` carrying Q-W1..Q-W9? Or should Claude fold the QA into a V1_2?
2. **M-3:** confirm that local subprocess engines (offline-first) supersede "engines only on the WIMS server" in `Decisions_GIAC_Complet_WIMS_GROK_V1.md`.
3. **M-4:** are PRs #40–#42 (D-S01 single grade) Phase 2 work to keep parked, or should G-15 be reshaped for per-answer results now?
4. **m-7:** should we accept GPL v2 obligations for the WIMS-derived tables in the product?
