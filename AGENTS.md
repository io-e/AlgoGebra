<!-- CLAUDE_V5 -->
# AGENTS.md

This file provides guidance to Codex (claude.ai/code) when working with code in this repository.

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

**Phase 1a — RCP spike completed (2026-10-28/29).** The D-02/D-04/D-05 spike ran on Windows x86_64, Java 25, Equinox 3.24.300.

### Phase 0 audit (completed)

| Task | Result | File |
|---|---|---|
| E — Test baseline | common-jre: 6526 PASS. Desktop: 1089 PASS + 1 locale failure (English rerun PASS) | `Audit_E_Test_Baseline_CODEX_V1.md` |
| A — Package ownership | 5406 files, 385 packages, **1 split** (`desktop`+`jogl2` opengl, 8 classes) | `Audit_A_Package_Ownership_CODEX_V1.md` + `.tsv` |
| B — Dependencies | 12 production modules, 39 external coords (only 4 have OSGi BSN) | `Audit_B_Module_Dependencies_CODEX_V1.md` |
| C — OSGi wrapping | 14 Bnd recipe drafts → **50 bundles built and RESOLVED** in Equinox 3.24.300 | `Audit_C_OSGi_Wrapping_CODEX_V1.md` + `Bnd_Equinox_Resolution_Win64/` |
| D — Path comparison | **Path A (Eclipse RCP) recommended** at 3.55/5 vs Path B at 2.95/5 | `Audit_D_Path_Comparison_CODEX_V1.md` |
| Bnd + Equinox resolution | **50/50 RESOLVED** (12 GeoGebra + 34 wrapped + 4 existing OSGi). jogl2 fragment OK. 9 native jars on app-loader. `com.apple.eio` marked optional. | `Bnd_Equinox_Resolution_Win64/` |

**Correction:** The `org.geogebra.common` split package originally claimed does NOT exist. Only 2 classes declare that root package (both in `common`). The real split is `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` across `desktop` and `jogl2` — fixable via OSGi fragment.

### Phase 1a RCP spike results (2026-10-28/29)

Evidence: `03-RCP-Spike/D-02-D-04-D-05-VALIDATION-REPORT.md`.
Gate decision: `03-RCP-Spike/Gate_Decision_D-04_D-05_GROK_V1.md` (reviewed by Grok Bot).
Installed image: `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r3`.

| Scenario | Status | Key findings |
|---|---|---|
| D-02 | **PASS** | `IApplication.start()` runs; 50/50 bundles RESOLVED; headless and GUI confirmed. |
| D-03 | **PASS** | (unchanged from Phase 0) 50 bundles resolve, jogl2 fragment wired. |
| D-04 | **PARTIAL** | Core embedding PASS: SWT shell hosts `GeoGebraPanel`, Algebra View + toolbars visible, resize/redraw works, `C=5` accepted. Debian suite 09 found valid-input/focus and function-creation failures; clipboard copy/paste did not work. HiDPI at 200% starts. Windows suite 09 remains NOT RUN (attended UI). |
| D-05 | **PASS** (architecture accepted: `Gate_Decision_D-04_D-05_GROK_V1_1.md`, D-GIAC-01) | **Strict installed-image run (r3):** GIAC, GlueGen, and all 5 JOGL DLLs load from product classpath JARs — **no boot delegation, no `java.library.path`, no manual extraction.** CAS and 3D initialization pass. Also verified on Debian 13 (linux-gtk-x86_64 image, 2026-10-29); strict 3D screenshot captured under software OpenGL. Windows r9 suite 08 confirms GIAC CAS and JOGL 3D initialization. Real-GPU visual validation remains open. |
| P-08 | PARTIAL | Pin known (`375db7faf54`, `5.4.934.0`), acceptance tag not chosen. |

**D-05 native loading architecture (r3):** Three OSGi fragment bootstraps extract DLLs from classifier-JAR resources in the owning bundle's classloader and call `System.load` with absolute paths. This replaces the initial boot-delegation workaround:
- `GiacNativeBootstrap` (fragment of `giac.jni` bundle) — replaces upstream `NativeLibClassPathLoader`
- `GeoGebraPlusGlueGenNativeBootstrap` (fragment of GlueGen bundle) — loads `gluegen_rt.dll`
- `GeoGebraPlusJoglNativeBootstrap` (fragment of JOGL bundle) — loads 5 DLLs (nativewindow_awt, nativewindow_win32, newt_head, jogl_desktop, jogl_mobile)

**Owner review done:** The product-local GIAC loader replacement (not the upstream `NativeLibClassPathLoader`) is accepted as architecture (D-GIAC-01, `Gate_Decision_D-04_D-05_GROK_V1_1.md`).

### Scenario status summary (45 total)

- **PASS:** D-02, D-03, D-05 (3)
- **PARTIAL:** D-04, P-08 (2)
- **NOT RUN:** All remaining P (01–07, 09), D (01, 06–10), W (01–08), X (01–07), S (01–07), O (01–05) — 40 scenarios

### Gates

| Gate | Requirement | Status |
|---|---|---|
| A | P-02–P-05 exist for desktop build and GWT war | NOT MET |
| B | D-02–D-06 pass, natives load, no `common` diff | **IN PROGRESS** (D-02 + D-03 + D-05 PASS; D-04 PARTIAL; D-06 NOT RUN) |
| C | W-01 scored, GWT stays until W-02 passes | NOT STARTED |
| D | X-01–06 + S-01–05 on both hosts for 1 schema + 1 algorithm | NOT STARTED |
| E | O-02, O-03, D-09, W-04 pass (security, license, SBOM) | NOT STARTED |

### Next steps

1. **D-04 on Windows:** run attended suite 09 to investigate SWT↔AWT focus, valid input/function creation, clipboard, and localization/font findings (BUG-004, BUG-009..013). Do not interact with the PC during the run.
2. **D-05 visual closure:** run attended Windows suite 10 and capture strict-mode 3D output; Debian's software-OpenGL screenshot is not real-GPU evidence.
3. **Windows bundle/baseline checks:** suite 11 awaits a local/approved Bnd CLI; rerun suite 13 with common-jre forced to execute. Windows desktop baseline has the known locale-sensitive `CallJavaScriptTest.testEval` failure.
4. **D-06:** Extension bundle management (depends on D-02–D-05 closure).
5. **Parallel work (Codex):** W-01 (web technology scored study), 5 contract specs (activity, capability, compute, state, submission).

## Agent roles

| Agent | Lane |
|---|---|
| **Codex** | Architecture, code audit, specifications |
| **Codex** | Code migration, unit tests, Bnd/Equinox resolution |
| **Grok Bot** | Integration tests on Debian (Maxima, PARI/GP, WIMS runtime) |

Project state and bug tracker: `states.yaml` (see BUG-001..BUG-005, DOC-001).

## Key references outside this repo

| Resource | Location |
|---|---|
| GeoGebra source checkout | `D:\ALF_ZGit\G1_Geogebra_Migration` (commit `375db7faf54`) |
| Eclipse IDE 2026-09 | `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` (platform 4.41.0) |
| Desktop build output | `source/desktop/desktop/build/distributions` |
| GWT web output | `source/web/web/war` (`web3d`, `webSimple`, `web`, `tablet3d`) |
| Desktop launcher | `Launch_GeoGebra_GROK_V1.ps1` (in the source checkout) |
| RCP spike directory | `03-RCP-Spike/` (bundles, host, natives, logs, evidence) |
| RCP spike launcher | `03-RCP-Spike/launch.ps1` (flags: `-Headless`, `-NoBuild`, `-ManualNativeFallback`, `-BootDelegateJogAmp`) |
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

## Testing

Engine + RCP test pack (GROK_V1): `03-RCP-Spike/tests/` — read `03-RCP-Spike/tests/README_TESTS_GROK_V1.md` first.
Single runner on Windows and Linux: `pwsh -File 03-RCP-Spike/tests/Run_All_GROK_V1.ps1` (suites 01-13; bash twins of 01-08 are
reference only in `03-RCP-Spike/linux-tests/`). Codex handoff: `Handoff_Codex_from_GrokBot_GROK_V1.md` (repo root). Shared fixtures,
TAP + `PASS: n FAIL: n SKIP: n`, exit 0/1/2. Evidence rule below still applies (build success is not evidence).

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

## High-risk assumptions — status after spike

1. **RCP + Swing:** `GeoGebraPanel` embedding **works** (D-04 core PASS). `SWT_AWT.new_Frame(SWT.EMBEDDED)` hosted it. **Still open:** focus transfer (Enter triggered a GeoGebra warning), clipboard, high-DPI, menus.
2. **OSGi wrapping:** 50/50 bundles **RESOLVED** (D-03 PASS). The jogl2 fragment approach works. **Closed for resolution; open for runtime activation.**
3. **JOGL/GIAC natives — RISK REDUCED (r3):** Boot delegation is **eliminated**. Three product-local OSGi fragment bootstraps load OS-specific natives from classifier-JAR resources within their owning bundle classloaders. The fragment approach works on Windows x86_64 and Debian 13; strict 3D screenshot is software-OpenGL only. **Remaining risk:** real-GPU visual confirmation and macOS are untested. The product-local GIAC loader replacement is accepted as architecture (D-GIAC-01).
4. **Dropping GWT:** JS wrapper is not a replacement for four GWT modules. Full web parity is a release gate (Gate C). **Unchanged.**
5. **External algorithm semantics:** writing a result via API does not make it a native dependent construction object (X-04). **Unchanged.**
