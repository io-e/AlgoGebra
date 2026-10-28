<!-- CLAUDE_V1 -->
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**GeoGebraPlus** is an architecture study and specification project (no application code yet) for building a modular ecosystem around the upstream GeoGebra source. The goal is a standalone **desktop Eclipse RCP/Equinox** client and a **browser client** with student-facing feature parity, integrated with WIMS/XWims for evaluation and grading.

This repository contains only study documents, specifications, and decision records. The GeoGebra source checkout lives separately at `D:\ALF_ZGit\G1_Geogebra_Migration` (pinned at commit `375db7faf54`, `VERSION_STRING` `5.4.934.0`).

## Document hierarchy and source-of-truth order

Read documents in this priority — later files are history only:

1. **`02-Cdc/Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`** — current consolidated architecture and 45-scenario validation plan. Supersedes V1.
2. **`02-Cdc/Decisions_Architecture_ALF_GROK_V1_3.md`** — closed primary decisions.
3. **`02-Cdc/Decisions_Architecture_ALF_GROK_V1.2.md`** — expanded owner requirements.
4. **`02-Cdc/Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md`** and **`GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md`** — code analysis. Follow only where consistent with current decisions and pinned code.
5. **`01-Recherche/Cahier_des_charges_outil_eleve_GROK_V1.md`** — older student-tool draft. **Must be revised** because it sends Algebra/CAS to notebooks (withdrawn decision).

The older Q&A files, `Cdc_Evolution_GeoGebra_GROK_V1.md`, Gemini study, and `00-00_archives/` are decision history. Their conflicting statements (e.g. "move algebra into the notebook", "GPLv3", "no RCP") are **withdrawn**.

## Binding decisions

- The shipped desktop product is **RCP/Equinox** (Eclipse IDE is only the developer workbench).
- Both desktop and web are required. Students must retain **Algebra View, CAS, Spreadsheet, 2D, 3D** and standard GeoGebra tools.
- **GWT retirement is a target, not approved for execution.** Keep GWT web output as baseline until replacement passes parity gates W-01/W-02.
- **`common` is untouchable:** no edits, source package cuts, class relocations, or long-lived fork to the upstream `source/shared/common`.
- Desktop RCP uses an OSGi wrapper/package set around intact upstream artifacts. `common` alone is insufficient — the full runtime set is: `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, `keyboard-base`, `keyboard-scientific`, `ggbjdk`, `giac-jni`, plus `desktop`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, `jogl2`, and JOGL/GIAC native jars.
- Teachers select prebuilt capabilities; only developers/admins manage extension code.
- Domain algorithms (physics, discrete math) are **external computation services**, not native `AlgoElement` subclasses.
- WIMS owns evaluation/grade; GeoGebraPlus owns the client integration.
- Jupyter is complementary and must **not** replace GeoGebra Algebra/CAS or other native views.
- If a gate needs a change inside `common`, **stop**. Allowed outcomes: change the host, revise the no-fork rule in a new decision file, or cut scope.

## Architecture shape

```
WIMS / XWims activity + optional teacher authoring tools
                       |
          GeoGebraPlus host and activity contracts
             /                              \
    Desktop RCP / Equinox              Browser host (TBD)
    allowlisted OSGi bundles           allowlisted web modules
    intact GeoGebra artifact set       current GWT until Gate C
             \                              /
              shared versioned contracts only
        activity | state | events | errors | submission
                       |
        external compute / notebook / Lean adapters
```

Host owns policy. Kernel owns constructions. WIMS owns the grade.

## Current phase

**Phase 0 — lock acceptance baseline.** No scenario is marked PASS. P-08 is PARTIAL (pin known, official acceptance tag not chosen). All 45 scenarios in V2 are NOT RUN. Prior Gradle compilation is build evidence only, not RCP/web replacement validation.

Next steps: Phase 0 (freeze baseline, build P-02/P-03 test corpus), then Phase 1 parallel spikes (D-01–D-05 desktop, W-01 web, contract specs).

## Key references outside this repo

| Resource | Location |
|---|---|
| GeoGebra source checkout | `D:\ALF_ZGit\G1_Geogebra_Migration` (commit `375db7faf54`) |
| Eclipse IDE 2026-09 | `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` (platform 4.41.0) |
| Desktop build output | `source/desktop/desktop/build/distributions` |
| GWT web output | `source/web/web/war` (`web3d`, `webSimple`, `web`, `tablet3d`) |
| Desktop launcher | `Launch_GeoGebra_GROK_V1.ps1` (in the source checkout) |

## GeoGebra source build commands

All run from the source checkout (`D:\ALF_ZGit\G1_Geogebra_Migration`):

```powershell
# Desktop assemble
./gradlew -p source/desktop assemble

# Web GWT compile + Sass
./gradlew -p source/web :web:gwtCompile :web:compileSass

# Run desktop (Java 25 toolchain)
./gradlew -p source/desktop :desktop:run

# Run web dev server (localhost:8888)
./gradlew -p source/web :web:run
```

## Working conventions

- New study/spec documents go under `02-Cdc/`. Make supersession and status explicit in the document header.
- Prefer reversible experiments and external packaging metadata over upstream source edits.
- Do not claim the architecture works based only on Gradle build success — scenarios need linked evidence (date, commit, OS, Java/browser, fixture hash, command, expected vs actual, log path).
- The evidence rule: each executed scenario row records all of the above, or it stays NOT RUN.
- License is **EUPL 1.2** for the source (not GPLv3 as the Gemini brief stated). The overall package has non-commercial use terms. Complete component provenance needed before distribution.

## High-risk assumptions to verify

1. **RCP + Swing:** GeoGebra desktop is Swing; RCP centers SWT. Prove the integration seam (D-04).
2. **Wrapping `common`:** does not automatically create a stable plugin API. Test artifact boundaries and class loading (D-02, D-03).
3. **JOGL/GIAC natives:** explicit runtime packaging needs under Equinox, not just Gradle `run` (D-05).
4. **Dropping GWT:** JS wrapper is not a replacement for four GWT modules. Full web parity is a release gate (Gate C).
5. **External algorithm semantics:** writing a result via API does not make it a native dependent construction object (X-04).
