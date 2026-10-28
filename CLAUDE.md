<!-- CLAUDE_V2 -->
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
- Desktop RCP uses an OSGi wrapper/package set around intact upstream artifacts. The **production desktop runtime** is 12 modules (not 14): `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, `keyboard-base`, `giac-jni`, `desktop`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, `jogl2`, plus JOGL/GIAC native jars. (`keyboard-scientific`, `ggbjdk`, `xr-base` are test-only or unused in the desktop runtime graph.)
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

## Current phase and audit status

**Phase 0 — baseline partially established.** Codex completed a 5-task audit (2026-10-28):

| Task | Result | File |
|---|---|---|
| E — Test baseline | common-jre: 6526 PASS. Desktop: 1089 PASS + 1 locale failure (English rerun PASS) | `Audit_E_Test_Baseline_CODEX_V1.md` |
| A — Package ownership | 5406 files, 385 packages, **1 split** (`desktop`+`jogl2` opengl, 8 classes) | `Audit_A_Package_Ownership_CODEX_V1.md` + `.tsv` |
| B — Dependencies | 12 production modules, 39 external coords (only 4 have OSGi BSN) | `Audit_B_Module_Dependencies_CODEX_V1.md` |
| C — OSGi wrapping | 14 Bnd recipe drafts (inputs, not validated bundles) | `Audit_C_OSGi_Wrapping_CODEX_V1.md` + `osgi-manifest-drafts/` |
| D — Path comparison | **Path A (Eclipse RCP) recommended** at 3.55/5 vs Path B at 2.95/5 | `Audit_D_Path_Comparison_CODEX_V1.md` |

**Correction:** The `org.geogebra.common` split package originally claimed does NOT exist. Only 2 classes declare that root package (both in `common`). The real split is `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` across `desktop` and `jogl2` — fixable via OSGi fragment.

**Scenario status update:** P-08 PARTIAL. D-03 (package ownership) has source-level evidence but no OSGi resolver result. All other D/W/X/S/O scenarios remain NOT RUN.

**Next steps:** Run Bnd on 12 production jars → Equinox resolution test → D-02 (RCP starts) → D-04 (Swing in SWT) → D-05 (GIAC + JOGL under Equinox). Windows x86_64 first.

## Agent roles

| Agent | Lane |
|---|---|
| **Claude** | Architecture, code audit, specifications |
| **Codex** | Code migration, unit tests, Bnd/Equinox resolution |
| **Grok Bot** | Integration tests on Debian (Maxima, PARI/GP, WIMS runtime) |

## Key references outside this repo

| Resource | Location |
|---|---|
| GeoGebra source checkout | `D:\ALF_ZGit\G1_Geogebra_Migration` (commit `375db7faf54`) |
| Eclipse IDE 2026-09 | `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` (platform 4.41.0) |
| Desktop build output | `source/desktop/desktop/build/distributions` |
| GWT web output | `source/web/web/war` (`web3d`, `webSimple`, `web`, `tablet3d`) |
| Desktop launcher | `Launch_GeoGebra_GROK_V1.ps1` (in the source checkout) |
| wims4win repo | `D:\ALF_ZGit\02-wims4win` (private `io-e/wims4win`, 24/24 tests pass) |
| WIMS OEF toolchain | `D:\ALF_Scripts\43-wims-paris-saclay_fr` |
| OEF interpreter workspace | `D:\ALF_ZGit\WA-OEF2IPYNB` (conda `quiz_env`) |

## GeoGebra source build commands

All run from the source checkout (`D:\ALF_ZGit\G1_Geogebra_Migration`):

```powershell
# Set JAVA_HOME (required — no JDK on PATH by default)
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:Path="$env:JAVA_HOME\bin;$env:Path"

# Desktop assemble
./gradlew -p source/desktop assemble

# Web GWT compile + Sass
./gradlew -p source/web :web:gwtCompile :web:compileSass

# Run desktop (Java 25 toolchain)
./gradlew -p source/desktop :desktop:run

# Run web dev server (localhost:8888)
./gradlew -p source/web :web:run

# Run tests (baseline: 6526 + 1089 pass)
./gradlew -p source/shared :common-jre:test --no-daemon
./gradlew -p source/desktop :desktop:test --no-daemon
```

## Working conventions

- New study/spec documents go under `02-Cdc/`. Make supersession and status explicit in the document header.
- Prefer reversible experiments and external packaging metadata over upstream source edits.
- Do not claim the architecture works based only on Gradle build success — scenarios need linked evidence (date, commit, OS, Java/browser, fixture hash, command, expected vs actual, log path).
- The evidence rule: each executed scenario row records all of the above, or it stays NOT RUN.
- License is **EUPL 1.2** for the source (not GPLv3 as the Gemini brief stated). The overall package has non-commercial use terms. Complete component provenance needed before distribution.

## Codex audit: key decisions taken

1. **Integration path:** Path A (Eclipse RCP embedding GeoGebra) — confirmed by binding V2 requirement, not by lower technical risk.
2. **First target:** Windows x86_64 only. Linux/macOS after Windows proof.
3. **jogl2 split fix:** Fragment of `desktop` bundle first; merge as fallback if fragment resolution fails.
4. **Bundle versions:** Mirror `5.4.934.0` initially. Separate semantic API versions only if we reach a public extension API.
5. **Aggregate core bundle:** Acceptable fallback if 12 individual bundles create unmanageable `uses` constraints, provided RCP host and extension boundary remain modular.
6. **First RCP proof:** Full D-02/D-04/D-05 slice (panel + CAS + 3D + native load), not just panel alone.

## High-risk assumptions to verify

1. **RCP + Swing:** `GeoGebraPanel` (public `JPanel`, no-arg constructor) exists. `SWT_AWT.new_Frame` with `SWT.EMBEDDED` is the documented bridge. Focus, menus, clipboard, DPI untested (D-04).
2. **OSGi wrapping:** No existing OSGi metadata. 14 Bnd recipe drafts exist but are unvalidated. 35/39 external deps need wrapping. The 1 real split (desktop+jogl2) is fixable via fragment (D-02, D-03).
3. **JOGL/GIAC natives:** JogAmp has its own native-JAR extractor (doesn't need `java.library.path`), but Equinox classloader compatibility is unproven. GIAC uses `ClassLoader.getSystemResourceAsStream` — must stay on application loader (D-05).
4. **Dropping GWT:** JS wrapper is not a replacement for four GWT modules. Full web parity is a release gate (Gate C).
5. **External algorithm semantics:** writing a result via API does not make it a native dependent construction object (X-04).
