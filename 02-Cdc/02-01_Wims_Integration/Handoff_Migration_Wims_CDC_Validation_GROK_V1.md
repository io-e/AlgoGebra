<!-- GROK_V1 -->
# Handoff to Grok Bot Migration_Wims — WIMS CDC validation (Spec)

| Field | Value |
|---|---|
| From | Grok Bot G1_Geogebra_Migration (Debian lane) |
| To | **Grok Bot Migration_Wims** (WIMS domain lane) |
| Requested by | Owner (ALF), 2026-11-04 |
| Branch / base | `feat/grok-sprint3-plan-v1-1` @ `c5177f9` |
| Policy | **Validation only.** No merges, no schema/spec edits (report corrections; Claude or the owner applies them), no S-01/S-02 settlement, PRs #40–#42 stay parked, no GitHub comments/issues without owner approval |

---

## 1. What to validate

| # | File (in `02-Cdc/02-01_Wims_Integration/`) | Focus |
|---|---|---|
| 1 | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` | **Main target.** WI-01..WI-51, risk register §9, open actions WA-1..WA-7 |
| 2 | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` | EE-01..EE-13 and Phase 1–4, only where it touches WIMS (engine wrappers, filters, connected mode) |
| 3 | `QA_WIMS_Integration_Owner_ALF_V2.md` | Owner decisions Q-W1..Q-W9 = source of truth; check both CDCs reflect them |
| 4 | `Schema_Help_Template_JSON_CLAUDE_V1.json`, `Example_Help_Template_CLAUDE_V1.json` | WIMS/OEF compatibility of the help model |

Context documents (read, do not redo): `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md`, `Handoff_GrokBot_WIMS_GV_Residual_GROK_V1.md`, `Consolidated_Review_Grok_Codex_CLAUDE_V1.md`, `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (if pushed), evidence `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/`.

## 2. Findings already established (confirm or refute, do not redo)

| Ref | Finding | Source |
|---|---|---|
| F-1 | Stock WIMS CGI returns HTML; `cmd=` is the core verb set (`new, renew, reply, help, hint, config, …`); `cmd=getresult` → 450; `job=` is module-local | GV-1 live probe (WIMS 4.33a) |
| F-2 | `module=adm/raw` (`ident, passwd, code, job`) **is** a stock machine JSON API (`job=getinfoserver` → `application/json`), with `getscore*` / `testexo` jobs, auth via `log/classes/.connections/` | Validation note WI-20/WI-22 adm/raw |
| F-3 | Therefore **WI-22 as written needs correction** (it says "adapter-defined `cmd=getresult`"; a module cannot add a `cmd=` verb) and **WI-23 Step 1 "no auth" is false** for any grade path through `adm/raw` | F-1 + F-2 |
| F-4 | OEF already has a **native `\help{}`** (inline popup text, `\help_subject` conditionals). `\help{file.json}` (WI-12) collides with it. Only 2/300 corpus files use `\help`, never with a file ref | GV-4/GV-6, `grok/gv-validation-wims-cdc` |
| F-5 | Corpus 300: suite 19 16/0/0, 300/300 schema-valid. GAP-5: 1,824/1,840 answers fall back to `object_exists`. Families: choice 459 ans/107 files, variable-typed (`\format`, `\atype`) 616/63, fill (clickfill/dragfill) 588/53, numeric needing WIMS 89/24, symbolic 38/17 | GV-3 addendum `bf0184b` |
| F-6 | 214/300 files compute parameters with `wims()`, `slib()`, `pari()`, `maxima()` — not covered by WI-05 GAP-1..GAP-5 (proposed **GAP-6**) | GV-3 |
| F-7 | wims4win engine set = pari, maxima, octave, yacas, gap, m2, scilab; GIAC is **not** a WIMS engine; gnuplot is plot-only | GV report, per-file |
| F-8 | Suites 21–23 (#40–#42) test only a local mock → Phase 2 assets, not offline MVP | GV-2 |
| F-9 | EE-P2 Linux: WIMS C vs Java subprocess identical on values (27/27); Java filter stricter (Pari `install`, gnuplot `system`/backtick) | PR #61 |

## 3. Checks for Migration_Wims (your WIMS expertise)

| ID | Check | Priority |
|---|---|---|
| **MW-1** | **WI-20/WI-22/WI-23 rewrite proposal:** propose the correct L2-1 design (new `job=` on `adm/raw` or a sibling module with `!shortout` JSON), required `.connections` declaration, and how `getscore*`/`testexo` map to the per-answer `answers[]` of Q-W4. Say whether `testexo` can grade an arbitrary OEF answer set server-side | P0 |
| **MW-2** | **`\help` collision (WI-12):** propose a non-colliding link from OEF to an external help template (e.g. a new directive, a `\help` subject convention, a comment pragma, or a sidecar file by naming convention) that stays valid OEF for stock WIMS | P0 |
| **MW-3** | **WI-31 check types vs real OEF answer types:** for each GAP-5 family in F-5, state what WIMS does to grade it and whether an offline evaluator is feasible (choice/fill: yes; `\format`/`\atype` runtime-typed: how to resolve at conversion) | P0 |
| **MW-4** | **WI-05 + GAP-6:** confirm or refute F-6; recommend: pre-evaluate parameters at conversion via a WIMS run, ship N frozen variants, or require a local engine | P1 |
| **MW-5** | **WI-24 exploration fallback (Q-W6):** is routing an exploration computation to WIMS CGI realistic given F-1 (HTML only, no compute endpoint)? Which module/job would serve it? | P1 |
| **MW-6** | **Engine list consistency:** WI-xx and EE-02/Phase 2+ vs F-7 (octave, yacas missing; GIAC role per D-ENG-05) | P1 |
| **MW-7** | **Q-W1..Q-W9 traceability:** one line per owner decision → CDC section(s), OK / missing / contradicts | P1 |
| **MW-8** | **WI-40/WI-41 teacher workflow:** does it match how teachers really author OEF in Createxo / Modtool? | P2 |
| **MW-9** | **Risk register §9:** missing risks (GPL v2 obligations for WIMS-derived filter tables, encoding windows-1252 vs UTF-8 — WA-5, WIMS version drift 4.31b Debian vs 4.33a wims4win) | P2 |

## 4. Expected output

A Markdown report `02-Cdc/02-01_Wims_Integration/Validation_CDC_WIMS_Integration_MIGRATION_WIMS_V1.md`:

1. Verdict per CDC: **Validated / Validated with reservations / Not validated**.
2. Findings table: ID, CDC section (WI-xx / EE-xx), severity (blocking / major / minor), evidence (file + line, probe, OEF example path), proposed correction text.
3. MW-1..MW-9 results: PASS / FAIL / PARTIAL with evidence.
4. Open questions for the owner (do not post them on GitHub without owner approval).

Push the report on a new branch `migration-wims/validate-cdc-wims-v1` based on `feat/grok-sprint3-plan-v1-1` (normal push, never force-push). **No PR, no merge** until the owner approves.

## 5. Useful sources

- Stock WIMS tree on the shared Debian box: `/workspace/wims-full` (4.31b); wims4win port clone: `/workspace/wims-port` (`src/wims.c` identical to `D:\ALF_ZGit\02-wims4win`).
- WIMS C engine interfaces built for EE-P2: `/workspace/scratch_ee_p2`.
- OEF corpus 300 + converter: `oef2course_GROK_V1.py`, suite `03-RCP-Spike/tests/19_Test_OefConverter_GROK_V1.ps1`.
- Do **not** touch the owner's checkout `D:\ALF_Agents\G1_Geogebra_Migration`.

---

*End of `Handoff_Migration_Wims_CDC_Validation_GROK_V1.md`.*
