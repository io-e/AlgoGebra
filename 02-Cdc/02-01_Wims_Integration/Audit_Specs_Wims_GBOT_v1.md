<!-- GBOT_v1 -->
# Audit of the WIMS specs (consolidated)

| Field | Value |
|---|---|
| Author | Grok Bot G1_Geogebra_Migration (Debian validation lane) |
| Date | 2026-11-04 |
| Requested by | Owner (ALF): "generate a file Audit_Specs_Wims_GBOT_v1.md" |
| Spec base audited | `feat/grok-sprint3-plan-v1-1` @ `322c723` (2026-11-04 09:17 CET), folder `02-Cdc/02-01_Wims_Integration/` |
| Grok review (PR #59) | `grok/review-cdc-wims-v1_1` @ `4153db6` — `02-Cdc/Review_Cdc_External_Engines_V1_1_GROK_V1.md` |
| GV report (Debian lane) | `grok/gv-validation-wims-cdc` @ `bf0184b` — `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md` (+ GAP-5 addendum) |
| GV report (desktop lane) | `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` (GROK_V1_1) on `322c723` |
| EE-P2 evidence (PR #61) | `grok/ee-p2-linux-validation` @ `d852ef7` — `03-RCP-Spike/evidence/20261104_0742_EE-P2_GROK_V1/EE-P2_Linux_Validation_Report_GROK_V1.md` (run on #60 @ `dd8ba96`) |
| Migration_Wims validation | `migration-wims/validate-cdc-wims-v1` @ `483c07f` — `Validation_CDC_WIMS_Integration_MIGRATION_WIMS_V1.md` |
| Other inputs | `Consolidated_Review_Grok_Codex_CLAUDE_V1.md`, `Handoff_Migration_Wims_CDC_Validation_GROK_V1.md`, `02-Cdc/Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (pushed) |
| Missing source | `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md` is **not on GitHub** (owner's local commit `fbc`, not pushed). Its content is used only as restated in the Migration_Wims handoff (F-2) and validation report. |
| PR states (gh, 2026-11-04) | #40 OPEN `0222ce1`, #41 OPEN `a30f8ec`, #42 OPEN `c9a6dd5` (all parked, OD-3); #56 OPEN `322c723`; #60 OPEN `60fc43e` (no CI checks reported) |
| Policy | **Audit only.** No spec/schema edits, no PR, no merge, no GitHub comments. Corrections are proposals for Claude/owner. |

---

## 1. Executive summary

| Spec | Verdict | Why |
|---|---|---|
| `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` | **Validated with reservations — not implementable for connected mode or help linking as written** | Offline-MVP architecture and phasing are sound and match Q-W2/Q-W7/Q-W8/Q-W9. Connected grading (WI-20 last ¶, WI-21 L2-1, WI-22, WI-23) and the help link (WI-12) describe things stock WIMS cannot do. GAP-5 fix (`engine_check`) targets the minority of blocked answers; GAP-6 is missing. |
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` | **Validated with minor reservations (engine layer)** | V1_2 fixed every PR #59 blocking/major item (scope, Q-W6, Pari AGB_ILLEGAL, Perl, IDs/done-when, Gnuplot filter, JVM, GPL risk). Remaining: EE-11 Maxima filter is shorter than `maxima.c` (and than #60's code), EE-P2b/P2c "done when" cells are not acceptance criteria, EE-P2d fixture size (≥20/engine) not yet met by #61, engine list vs wims4win. |
| Help + course schemas (`Schema_Help_Template_JSON_CLAUDE_V1.json`, `Example_Help_Template_CLAUDE_V1.json`, `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` V1_1) | **Validated with reservations** | Example now **validates** against the help schema (re-run today, Draft 2020-12: 0 errors; fixed in `619ac5d`). Course schema `check_schema` passes. Open: `checkAction.type` enum has no `engine_check`/choice/fill types; `engine` enum ≠ wims4win; `giac` + `Derivative(...)` is GeoGebra CAS syntax. |

**Top P0 items (all still open in current spec text):**
1. **A-01/A-03** WI-22 uses an "adapter-defined `cmd=getresult`" — impossible (`cmd=` is a closed list in `wims.c`; probe E → 450). The L2-1 grading design must be redone; sources disagree on *how* (see §5.2).
2. **A-02** WI-23 Step 1 "None. localhost" auth is false for any `adm/raw` path (`.connections` ident + passwd + IP).
3. **A-04** WI-12 `\help{file.json}` collides with the native OEF `\help{}` popup.
4. **A-05** WI-31/WI-05: 1,824 of 1,840 corpus-300 answers degrade to `object_exists`; most are choice/fill types that `engine_check` does not address.
5. **A-06** GAP-6 (parameters computed by `wims()/slib()/pari()/maxima()`, 214/300 files) missing from WI-05.

---

## 2. Spec inventory

| File (`02-Cdc/02-01_Wims_Integration/` unless noted) | Version | Status | Owner |
|---|---|---|---|
| `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` | CLAUDE_V1, 2026-11-04, "Draft — ready for owner + Grok validation" | **Current** | Claude |
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` | CLAUDE_V1_2, 2026-11-03 | **Current** | Claude |
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` | CLAUDE_V1_1 | Superseded by V1_2 (still in folder root, not moved to archives) | Claude |
| `00-00_archives/Cdc_External_Engines_AlgoGebra_CLAUDE_V1.md` | V1 | Archived | Claude |
| `QA_WIMS_Integration_Owner_ALF_V2.md` | ALF_V2_3 | **Current** (source of truth) | Owner |
| `00-00_archives/QA_WIMS_Integration_Owner_CLAUDE_V1.md` | V1 | Archived | Claude |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` | V1_1 (per CDC) | Current | Claude |
| `Example_Help_Template_CLAUDE_V1.json` | V1 | Current | Claude |
| `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` | CLAUDE_V1_1 (`$comment`) | Current | Claude |
| `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` | V1, 2026-11-03 | Current (OD-1..OD-4 closed) | Claude |
| `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` | GROK_V1_1 | Current (desktop lane) | Grok (desktop) |
| `02-Cdc/Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` | GROK_V1 | Current (code audit input) | Grok |
| `Handoff_Migration_Wims_CDC_Validation_GROK_V1.md` | GROK_V1 | Current | Grok G1 |
| `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md`, `Cdc_GIAC_MVP_GROK_V1.md`, `Decisions_*_GROK_V1.md` | — | Context, not audited here | Claude / Grok |
| `Validation_CDC_WIMS_Integration_MIGRATION_WIMS_V1.md` | MIGRATION_WIMS_V1 | Branch only (`483c07f`) | Migration_Wims |
| `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md` | — | **Not pushed** | Owner checkout |

---

## 3. Q-W1..Q-W9 traceability

| Decision (QA ALF_V2_3) | CDC sections | Status | Evidence |
|---|---|---|---|
| Q-W1 local wims4win → server → certificates | WIMS WI-01, WI-23 | **Contradicts** (WI-23 Step 1 "no auth") | MW F-2/F-3 (`adm/raw/var.check:27,44,49`); GV-1 (Debian). Same `module=`/`cmd=` params: **yes** (GV-1 both lanes) |
| Q-W2 offline first | WI-01, WI-30; EE §1 scope, Phase 4 deferred | **OK** | V1_2 header + §6 Phase 4; GV-2 suites 21–23 are Phase 2 assets |
| Q-W3 OEF first + converter, GAP-1..5 | WI-03..WI-05, WI-41 | **Partial** (GAP-6 missing; GAP-5 resolution too narrow) | GV-3 214/300; GAP-5 addendum |
| Q-W4 per-answer structured result | WI-22 (`answers[]`), WI-21 L2-4 | **Partial** — format defined, no implementable source in stock WIMS | MW P0-1 (`getscore*` aggregate only, `testexo` compile only) |
| Q-W4 retry / S-03 | WI-50 | OK (Phase 2) | — |
| Q-W5 teacher authoring OEF + .ggb | WI-40, WI-41 | OK with nuance (Createxo/Modtool) | MW-8 |
| Q-W6 fallback: exploration yes, grading error | WI-24; EE §4.1, D-ENG-02, EE-R1 | **Partial** — reflected in text (PR #59 M-1 fixed) but no stock WIMS compute endpoint | MW-5 |
| Q-W7 wims4win for students/teachers | WI-02, WI-R5; EE-R9 | OK | GV-5: Laragon present, runtime path is `…\Reprise_Wims_Grok\wims-runtime`, not `02-wims4win` |
| Q-W8 scope boundary | WIMS §1; EE header | OK | — |
| Q-W9 resolution tree / help templates | WI-10..WI-12 | **Partial** — link mechanism collides with `\help` | GV-4/GV-6, MW F-4 (oef2wims run) |
| Q-W9a–c LLM/RAG Phase 3 | WI-13 | OK | — |
| Q-W9d help schema | Schema_Help_Template, Example | OK (example valid now) | jsonschema re-run 2026-11-04 |

---

## 4. Consolidated findings

Severity: **P0** blocking, **P1** major, **P2** minor. Status checked against the **current** text at `322c723`.
Sources: **R59** = Grok review PR #59; **GV** = Debian GV report (`bf0184b`); **GVd** = desktop `Validation_GV1_GV7`; **EE** = PR #61; **MW** = Migration_Wims `483c07f`; **CR** = Consolidated review (Claude/Codex); **IMPL** = Implementation doc.

### 4.1 WIMS Integration CDC

| ID | Section | Sev | Finding | Evidence | Source(s) | Status | Proposed correction |
|---|---|---|---|---|---|---|---|
| A-01 | WI-22 | P0 | Wire format uses `module=<adapter>&cmd=getresult` "adapter-defined verb". A module cannot add a `cmd=` verb. | `src/wims.c:288-290` (14 verbs); probe E → 450 | GV, GVd, MW F-1/F-3, Validation Note (unpushed) | **Open** | Replace per §5.2 decision (stock `cmd=new/reply` + JSON hook, or new `job=` on `adm/raw`/sibling module). |
| A-02 | WI-23 Step 1 | P0 | "None. localhost access" is false for any grade/score path through `adm/raw`: needs `log/classes/.connections/<ident>` with passwd, IP `ident_site`, allow list. Only an anonymous `cmd=new/reply` session needs no auth, and it records no class score. | `adm/raw/var.check:27,37-38,44,49,59`; `defs:33` (only 5 no-auth jobs) | GV-1, MW F-2/F-3 | **Open** | Use MW's WI-23 replacement text (anonymous formative session; `.connections` ident for any `adm/raw`; class session Step 2; https Step 3). |
| A-03 | WI-20 last ¶, WI-21 L2-1 | P0 | "Adapter must use the stock `cmd=` verb namespace or implement a new WIMS module" and L2-1 "accepts D-S01 POST" keep `getresult` alive. No stock path emits per-answer JSON. **Sources disagree on the fix** (§5.2). | MW P0-1 (`jobs/testexo.proc:6-17`, `jobs/getscore.proc:21-42`, `anstype/numeric:59-60`) | GV, MW, Validation Note, IMPL §3.3 | **Open** (owner decision L2-0/WA-1) | Owner chooses; Claude rewrites WI-20/21/22 accordingly. |
| A-04 | WI-12 | P0 | `\help{aide.json}` overrides the native OEF help popup; stock WIMS shows the literal "aide.json". Corpus: 2/300 use `\help`, inline only. Unknown directives (e.g. `\helptemplate`) are silently dropped. | `oef2wims.c:79,197-211`; `oefcommand` L91-93; `log/classes/9001/src/ex6.oef` L9; MW `oef2wims` run | GV-4/6, GVd, MW F-4/P0-2 | **Open** | `\text{algogebra_help=file.json}` (+ optional `algogebra_course=`), fallback sidecar `<exo>.help.json`; native `\help{}` → `text` help node. (GV also proposed a `%%algogebra-help:` comment line.) |
| A-05 | WI-05 GAP-5, WI-31, WA-2; course schema `checkAction.type` | P0 | 1,824/1,840 answers (281/300 files) → `object_exists`. By family: choice 459 ans/107 files, variable-typed 616/63, fill 588/53, numeric not computable offline 89/24, symbolic 38/17. `engine_check` helps only ≈41 files. Enum still `value_equals, value_range, object_exists, cas_equals`. | GV-3 addendum (`gap5_by_type_corpus300_GROK_V1.csv`); `Schema_Course` L193; MW P0-3 | GV, MW F-5/MW-3 | **Open** | Closed enum: `value_equals`(+`mode` relative/absolute, `precision`), `value_range`, `choice_equals`, `sequence_equals`, `set_equals`, `cas_equals`, `engine_check`; non-mappable → `gradable:false` + warning, not `object_exists`. |
| A-06 | WI-05 | P0 | GAP-6 missing: 214/300 files compute parameters with `wims()`/`slib()`/`pari()`/`maxima()` (evaluated at `cmd=new`), converter resolves only `random/randint`. | GV-3; `OefMsg2wims/process.c:68` | GV, MW F-6/MW-4 | **Open** | Add GAP-6; resolution = conversion-time WIMS evaluation into `variants[]` (MW proposes N=20); WI-41 `--variants N --seed S`. |
| A-07 | WI-24 | P1 | Q-W6 exploration fallback to WIMS CGI has no stock compute endpoint (CGI returns HTML). | MW-5 | MW | **Open** (owner Q) | Mark WI-24 Phase 2 (e.g. `local/algogebra_compute` module) or confirm; MVP = explicit "engine missing" error. |
| A-08 | WI-05 GAP-5 text | P1 | Says OEF has "regex, set equality, ordered list"; real set is 61 anstypes. | `scripts/anstype/` (61) | MW V-2 | **Open** | Reference the A-05 family table. |
| A-09 | WI-R4 | P1 | Mitigation "connected mode delegates to WIMS's own evaluator" depends on the non-existent L2-1. | MW V-3 | MW | **Open** | Link to chosen L2-1 design. |
| A-10 | WI-20 | P2 | "No `application/json` in any probe" true for the probed modules; `adm/raw` returns `application/json; charset=iso-8859-1`. | `adm/raw/defs:2,5-11`; Validation Note (getinfoserver) | MW V-1, F-2 | **Open** | Add "except `adm/raw` (machine API)". |
| A-11 | WI-20 probe citation | — | WI-20 now cites the live probe (job ignored, cmd 450, text/html, evidence path). | WI-20 text at `322c723`; GVd ("WI-20 at `e48d1dd` matches the probe") | GVd, Validation Note | **Fixed** | — |
| A-12 | WI-21/L2-4, EE §4.4 | P1 | #41 client returns single `{grade 0..1, feedback}` ≠ Q-W4 per-answer. | WI-21; R59 M-4 | R59, GV-2, CR OD-3 | **Acknowledged/deferred** (OD-3: parked Phase 2) | Keep; rebase mock on chosen protocol before Phase 2. |
| A-13 | §9 risks | P2 | Missing risks: GPL v2 (only via WI-51/OD-4), encoding iso-8859-1/cp1252 (WA-5), version drift 4.31b vs 4.33a, offline answer keys in frozen variants. | MW-9 (WI-R7..R10) | MW | **Open** | Add WI-R7..R10. |
| A-14 | WI-40/41 | P2 | Teachers author via Createxo (class) and Modtool, not a generic "WIMS OEF editor"; `--seed 42` single variant. | MW-8, V-5 | MW | **Open** | Name both sources; variant flag. |
| A-15 | GV-5 / Q-W7 | P2 | Served runtime is `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime`, not `02-wims4win` (sources only). | GV-5 | GV | **Open** | Name runtime path in install guide/Q&A. |

### 4.2 External Engines CDC V1_2

| ID | Section | Sev | Finding | Evidence | Source(s) | Status | Proposed correction |
|---|---|---|---|---|---|---|---|
| A-16 | Header/§6 | P0 (was) | "Ready for Codex" claimed for WIMS scope; Phase 4 contradicted offline-first. | V1_2 header "Engine layer only"; Phase 4 DEFERRED | R59 B-2, CR F-05 | **Fixed** | — |
| A-17 | EE-10 | P1 | Pari filter missing `system, extern, externstr, fileextern, install, eval`. | EE-10 now lists full AGB_ILLEGAL + not-a-sandbox note; #61 P-08 shows `install` only blocked by Java | R59 M-2, CR F-01, EE | **Fixed** | — |
| A-18 | EE-11 | P1 | Maxima filter is `system, save, load, file, debug, plot, batch, demo` — shorter than `maxima.c` `illegal[]` (16) + `illpart[]` (6): missing `describe, example, fassave, stringout, batcon, batcount, cursordisp, direc, readonly, with_stdout, pscom, ttyintfun, bug, store`. #60 code (`MaximaEngine.java` L58-62) already has the full lists. | IMPL §2.3; #60 @ `60fc43e` | IMPL, Owner relay to Codex | **Open** (spec lags code) | Copy `illegal[]`/`illpart[]` from IMPL §2.3 into EE-11. |
| A-19 | §4.1, D-ENG-02, EE-R1 | P1 | Q-W6 exploration fallback absent. | V1_2 §4.1 L168-173 | R59 M-1, CR F-03 | **Fixed** (text); implementability → A-07 | — |
| A-20 | EE-03 | P1 | Perl listed as required OEF reader. | EE-03 "Optional" | R59 M-5, CR F-02 | **Fixed** | — |
| A-21 | §6 | P1 | No requirement IDs / acceptance criteria. | EE-01..13, EE-P1a..P4d with "Done when" | R59 M-6, CR F-06 | **Fixed**, with residue A-22 | — |
| A-22 | EE-P2b, EE-P2c | P2 | "Done when" cells state provenance / JVM, not a pass criterion. | V1_2 L281-282 | this audit | **Open** | e.g. P2b "all EE-P1 test commands produce output via `bin/*`, provenance recorded"; P2c "EngineAcceptanceTest green on Debian, Java 21". |
| A-23 | EE-P2d | P1 | Requires byte-identical output on fixture set F (≥20 cases/engine). #61 ran 27 cases total (Pari P-01..P-12, Maxima M-01..M-06, GAP G-01..G-03, Gnuplot N-01..N-06), values identical, negatives intentionally divergent. No fixture set F exists. | EE-P2 report | EE | **Open** | Owner/Claude: define F; reword 2d as "values match; rejections at least as strict" (EE finding 2). |
| A-24 | EE-02, Phase 2+; schemas `engine` enum | P1 | wims4win interfaces = `gap, m2, maxima, octave, pari, scilab, yacas`; GIAC is not a WIMS engine; gnuplot plot-only. V1_2 lists octave as future; yacas/m2/scilab absent. | `src/Interfaces/`; GV H2; MW F-7/MW-6 | GV, MW | **Open** | Add line: exercises naming yacas/m2/scilab → `gradable:false` offline. |
| A-25 | EE-12 | P2 | Gnuplot filter missed `set output/print`, `load`, `call`, `save`, backticks. | EE-12 now complete; #61 N-03/N-06 show raw gnuplot runs `system("id")` and backticks | R59 m-2, CR F-09, EE | **Fixed** | — |
| A-26 | header, EE-10 test, EE-P2b, §10, EE-R8 | P2 | JVM, post-parser expected output, provenance, refs, GPL risk row. | V1_2 header L16, EE-10, EE-P2b, §10 (`Gate_Decision…_V1_1`), EE-R8 | R59 m-1/m-3/m-4/m-6/m-7, CR | **Fixed** | — |
| A-27 | EE-02 GAP Windows | P2 | wims4win runs GAP via Cygwin (`gap_command`, DLL path). | MW V-4 | MW | **Open** | Windows note. |
| A-28 | EE-P1f/EE-13 | P2 | No Java GAP adapter → GAP parity one-sided. | EE finding 5 | EE | **Open (optional by spec)** | — |
| A-29 | M-3 | P1 | Local engines vs "engines only on WIMS server" (`Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1). | CR OD-2 | R59, CR | **Decided** (OD-2: local supersedes). Superseding edit to the Grok decision doc not verified in this audit. | Grok updates its doc. |
| A-30 | #41 draft | P2 | `WIMS_Open_Questions_GROK_V1.md` (#41) reuses Q-W1..Q-W4 IDs. | R59 m-5, CR F-13 | R59, CR | **Open** (not verified in #41) | Rename to Q-GC1..4 before #41 merges. |

### 4.3 Schemas

| ID | Path | Sev | Finding | Evidence | Source(s) | Status | Proposed correction |
|---|---|---|---|---|---|---|---|
| A-31 | Example top-level `$comment` | P0 (was) | Example failed help schema. | Re-run 2026-11-04 (`jsonschema`, Draft 2020-12): **0 errors** | R59 B-1, GV X1, CR (`619ac5d`) | **Fixed** | Add CI validation step (R59). |
| A-32 | Example `steps[].engineCommand`, `engine:"giac"` | P1 | `Derivative(x^2 + {{a}}*x + {{b}}, x)` is GeoGebra CAS syntax (`Ggb2giac.java` L264); a native giac process expects `diff(...)`. | GV X2 | GV | **Open** | Define `giac` = GeoGebra CAS command language (or rename `geogebra-cas`). |
| A-33 | `$defs/i18nString` locale pattern | P2 | `^[a-z]{2}(_[A-Z]{2})?$` in both schemas — consistent with each other, rejects BCP 47 `fr-FR`. | Help L86, Course L34/L160 | R59 (e) | **Open (low)** | Decide convention; document. |
| A-34 | `Schema_Course` `engine` enum, `checkAction` | P1 | Same enum issue as A-24; check cannot route to an engine (no `engine_check`). | Course L106, L193; GV C-c | GV | **Open** (dup of A-05/A-24 for schema) | Covered by WA-2. |

**Counts:** 34 findings. **P0: 8** (6 open: A-01..A-06; 2 fixed: A-16, A-31). **P1: 14** (8 open: A-07, A-08, A-09, A-18, A-23, A-24, A-32, A-34; 4 fixed: A-17, A-19, A-20, A-21; A-12 deferred by OD-3; A-29 decided by OD-2). **P2: 11** (8 open: A-10, A-13, A-14, A-15, A-22, A-27, A-30, A-33; 2 fixed: A-25, A-26; A-28 optional). A-11 (no severity) fixed. **Already fixed in current text: 9.**

### 4.4 Disagreements between sources

| Topic | Side A | Side B | Evidence assessment |
|---|---|---|---|
| **Grading via `adm/raw`** | Validation Note (owner `fbc`, unpushed) + IMPL §3.3 + G1 handoff MW-1: L2-1 = new `job=` on `adm/raw` (or sibling module) with `!shortout` JSON. | MW P0-1: `adm/raw` has no OEF evaluation context; `testexo` compiles only, `getscore*` aggregate only → grade via stock `cmd=new` + `cmd=reply` with a wims4win JSON output hook in `scripts/oef` (`special_parm=algogebra_json`). | Both agree `cmd=getresult` is impossible and `adm/raw` needs auth. MW's claim cites specific source lines (`testexo.proc:6-17`, `getscore.proc:21-42`, `anstype/numeric:59-60`); Side A's note is not on GitHub to inspect. **Evidence favours B for per-answer grading**; `adm/raw` stays useful for reading aggregate scores, `authuser`, `getexofile`. Both are GPL patches to WIMS. Owner decides (WA-1). |
| GV-1 verdict | GVd: PASS (live) | GV: PARTIAL | Same facts; GV marks PARTIAL because the D-S01 call used by #40–#42 does not exist. |
| GV-2 verdict | GVd: PASS (aligned) | GV: FAIL (aligned with Phase 2, not MVP) | Same facts: suites 21–23 test a mock only, no offline scoring. Status label differs. |
| Suite 19 | GVd: 15 PASS / 1 SKIP (no `OEF_CORPUS`, Windows) | GV: 16/0/0 with corpus 300 at `4e13b83` and `49d98f9` | Not contradictory: SKIP is OC-16 without the corpus. |
| GAP-5 literal counts | GV main table at `4e13b83`: clickfill 334, dragfill 261 | GV addendum at `49d98f9`: clickfill 330, dragfill 258 | Different tips; this audit cites the addendum. |
| `\help` carrier | GV: `\text{algogebra_help=…}` or `%%algogebra-help:` comment | MW: `\text{algogebra_help=…}` + sidecar `<exo>.help.json` | Converge on `\text{algogebra_help=…}`. |

---

## 5. Check status

### 5.1 GV-1..GV-7

| Check | Debian GV (`bf0184b`) | Desktop GVd | Notes |
|---|---|---|---|
| GV-1 CGI params | PARTIAL | PASS (live probe) | Same CGI as stock; `getresult` absent; `adm/raw` needs auth |
| GV-2 suites 21–23 | FAIL (Phase 2 assets) | PASS (aligned) | Mock-only |
| GV-3 suite 19 + gaps | PASS + GAP-6 | PASS | 16/0/0, 300/300; GAP-5 #1 |
| GV-4 OEF help directives | PASS → schema impact | PASS | `\hint`, `\help`, `\feedback`, `\solution`, `\steps`, `\nextstep` |
| GV-5 local HTTP Windows | PARTIAL (Laragon not running, not started) | PASS (CGI runs without Apache via env) | |
| GV-6 `\help` in bank | PASS (2/300, inline) | PASS | |
| GV-7 step-by-step format | PASS (none exists) | PASS (negative) | `process` type is new |

### 5.2 MW-1..MW-9 (Migration_Wims `483c07f`)

| Check | Result | Audit finding |
|---|---|---|
| MW-1 grading design | FAIL (CDC) / design proposed | A-01..A-03 |
| MW-2 `\help` collision | FAIL / fix proposed | A-04 |
| MW-3 check types | PARTIAL | A-05 |
| MW-4 GAP-6 | PASS for F-6, CDC FAIL | A-06 |
| MW-5 exploration fallback | FAIL | A-07 |
| MW-6 engine list | PARTIAL | A-24 |
| MW-7 Q-W traceability | PARTIAL | §3 |
| MW-8 teacher workflow | PARTIAL | A-14 |
| MW-9 risks | FAIL (missing) | A-13 |

F-1..F-9 per MW: confirmed F-1, F-2, F-3, F-4, F-6, F-7; accepted on cited evidence F-5, F-8, F-9.

---

## 6. Implementation alignment

| PR | State | Implements | Spec alignment |
|---|---|---|---|
| #40 G-14 template (`0222ce1`) | OPEN, parked | D-S01 placeholders, suite 21 | Phase 2 asset (OD-3). Targets `job=getresult`, which does not exist (A-01). |
| #41 G-15 grade client (`a30f8ec`) | OPEN, parked | JS client vs `mock_wims_cgi_GROK_V1.mjs`, single `{grade 0..1, feedback}`, suite 22 | Contradicts Q-W4 per-answer (A-12); protocol obsolete (A-01..A-03); Q-W ID collision (A-30). Rework after WA-1. |
| #42 G-16 full cycle (`c9a6dd5`) | OPEN, parked, stacked on #40/#41 | Firefox/Playwright vs same mock, suite 23 | Same as #41. |
| #56 sprint plan (`322c723`) | OPEN | Holds all specs audited here | — |
| #60 EE-P1 (`60fc43e`) | OPEN, no CI checks reported | Pari AGB_ILLEGAL, full Maxima `illegal/illpart`, Gnuplot pngcairo/call/backticks, BUG-015 empty output | Ahead of spec for Maxima (A-18). Head moved from `dd8ba96` to `53b807a`/`60fc43e` after #61; Linux rerun waits for Windows checks per owner rule. |
| #61 EE-P2 (`d852ef7`) | OPEN, not merged | 27/27 Linux compare on `dd8ba96`; ID mapping to V1_1 2a–2d (V1_2 was not on GitHub then) | Values identical; Java stricter on negatives; fixture-size criterion of EE-P2d not met (A-23); GAP one-sided (A-28). |

---

## 7. Open questions for the owner (deduplicated)

1. **L2-0 / WA-1 grading design:** stock `cmd=new/reply` + wims4win JSON output hook (MW), or a new `job=` on `adm/raw`/sibling module (Validation Note), or HTML scraping? (A-03)
2. **Help link:** adopt `\text{algogebra_help=file.json}` + sidecar `<exo>.help.json`, native `\help{}` mapped to text? (A-04)
3. **Q-W6 vs MW-5:** accept exploration fallback as Phase 2, with an explicit "engine missing" error in the MVP? (A-07)
4. **GAP-6:** frozen variants at conversion (default N=20)? Accept answer keys shipped offline (WI-R10)? (A-06)
5. **yacas/m2/scilab exercises:** `gradable:false` offline, or plan engine slices? (A-24)
6. **EE-P2d fixture set F:** define it (≥20/engine) and accept "values match; rejections at least as strict" wording? (A-23)
7. **`giac` meaning:** GeoGebra CAS command language, or rename? (A-32)
8. Please **push** `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md` (`fbc`) so it can be audited directly.

## 8. Recommended next actions

| # | Action | Owner/agent | Depends on |
|---|---|---|---|
| 1 | Answer Q1–Q7 | Owner | — |
| 2 | Rewrite WI-20 (last ¶ + `adm/raw` exception), WI-21 L2-1, WI-22, WI-23 per Q1 (MW text as base) | Claude | Q1 |
| 3 | Rewrite WI-12 per Q2; add GAP-6 to WI-05; replace GAP-5 text and WI-31 enum; WI-24 phase per Q3; add WI-R7..R10; WI-40/41 nuances | Claude | Q2–Q4 |
| 4 | Course schema: extend `checkAction.type` (WA-2), `gradable` flag, `variants[]`; engine enum per Q5; define `giac` | Claude | Q4, Q5, Q7 |
| 5 | EE-11 Maxima full `illegal[]/illpart[]`; EE-P2b/P2c acceptance text; EE-P2d wording; GAP Windows note | Claude | Q6 |
| 6 | Push Windows-passing EE-P1 hardening on #60 | Codex | — |
| 7 | Rerun EE-P2 Linux on #60's new head once Windows checks pass; build fixture set F if defined | Grok G1 | 6, Q6 |
| 8 | Converter: `\text{algogebra_help}`, variants, new check types; rerun suite 19 + GAP-5 breakdown | Grok G1 / Migration_Wims | 3, 4 |
| 9 | Prototype the chosen L2-1 on wims4win r19040 (JSON hook or `adm/raw` job), with `.connections` config | Migration_Wims | Q1 |
| 10 | Supersede `Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1 (OD-2); rename #41 Q-W IDs to Q-GC (when unparked) | Grok | — |
| 11 | Rebase #40–#42 mock on chosen protocol + per-answer `answers[]` | Grok | Q1, S-01/S-02 hold lifted |

---

*End of `Audit_Specs_Wims_GBOT_v1.md`. Audit only — no spec or schema edited.*
