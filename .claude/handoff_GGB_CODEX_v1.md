# GeoGebraPlus Architecture Study — Codex Handoff V1

**Purpose:** Transfer the architecture study, decisions, and next actions to Codex.  
**Prepared:** 28 October 2026  
**Project workspace:** `D:\ALF_Agents\G1_Geogebra_Migration`  
**Primary architecture document:** `02-Cdc\Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`  
**GeoGebra source checkout:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Pinned revision:** `375db7faf54` (`main`), reported `VERSION_STRING` `5.4.934.0`  
**Eclipse development IDE:** `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` (Eclipse IDE 2026-09 / 4.41.0)

## 1. Current objective

Develop a modular GeoGebraPlus ecosystem with:

- A standalone **desktop Eclipse RCP / Equinox** client.
- A **browser client** with required student-facing feature parity.
- Unmodified upstream GeoGebra source, especially `source/shared/common`.
- Trusted extensions selected/configured by teachers as activity features; teachers do not author or install code.
- WIMS/XWims submission/evaluation integration and optional future Jupyter/Lean 4 integrations.

The current task is architectural feasibility and test planning. Do not start a kernel rewrite or mark scenarios passed without evidence.

## 2. Read these files first

Use this priority order:

1. `02-Cdc\Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` — current consolidated architecture and 45 scenario validation plan; supersedes V1.
2. `02-Cdc\Decisions_Architecture_ALF_GROK_V1_3.md` — closed primary decisions.
3. `02-Cdc\Decisions_Architecture_ALF_GROK_V1.2.md` — expanded owner requirements.
4. `02-Cdc\Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md` and `GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md` — repository and proposal analysis; follow only where consistent with the current decisions and pinned code.
5. `01-Recherche\Cahier_des_charges_outil_eleve_GROK_V1.md` — older student-tool draft; it must be revised because it sends Algebra/CAS to notebooks.

The older Q&A files, `Cdc_Evolution_GeoGebra_GROK_V1.md`, Gemini study and `00-00_archives` are decision history. Do not treat their conflicting statements as current requirements.

## 3. Binding decisions

- Eclipse IDE is the developer workbench; **the shipped desktop product is RCP/Equinox**.
- Both desktop and web are required. Students must retain Algebra View, CAS, Spreadsheet, 2D, 3D and standard GeoGebra tools.
- GWT retirement is a target, **not yet approved for execution**. Keep current GWT web output as baseline until the replacement passes parity gates W-01/W-02.
- Keep `common` intact: no edits, source package cuts, class relocations, or long-lived fork.
- Desktop RCP uses an OSGi wrapper/package set around intact upstream artifacts. `common` alone is not sufficient; platform, shared, renderer/editor/canvas, GIAC/JNI, JOGL/native runtime pieces must be assessed.
- Extension hooks belong in the GeoGebraPlus host. OSGi providers are trusted and discovered at desktop startup. No hot-swap is required. Web uses a separate, approved module mechanism; OSGi bundles do not run in the browser.
- Teachers select prebuilt capabilities; only developers/admins manage extension code.
- Physics/discrete-math algorithms are **external computation services**, not native GeoGebra `AlgoElement`s. Exchange typed inputs/results via host APIs and reject stale results.
- WIMS owns evaluation/grade; GeoGebraPlus owns the client integration. `alphavalon-eval-v1` is only a candidate schema name. Lean 4 is optional/future.
- Jupyter is complementary and must not replace GeoGebra Algebra/CAS or other native views.

## 4. Architecture in one view

```text
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

The host owns policy; GeoGebra owns construction/kernel behavior; WIMS owns grading. Desktop and web may use different binaries/loaders but must implement equivalent student-facing contracts.

## 5. Evidence from the source checkout

- Checkout HEAD verified as `375db7faf54` on `main`.
- Root Gradle settings include separate `shared`, `desktop`, `web`, and build-logic builds.
- Desktop is a Swing application (`org.geogebra.desktop.GeoGebra3D`) with Java 25 toolchain in its run task.
- Web is currently GWT-based and emits `SuperWeb`, `WebSimple`, `Web`, and `Tablet3D` modules.
- Desktop depends on shared GeoGebra artifacts plus desktop render/editor/canvas modules and native JOGL/GIAC components.
- Earlier handoff notes report that desktop `assemble`, web `gwtCompile`, and Sass compilation succeeded on this checkout. These builds do **not** validate Equinox/RCP or a replacement web runtime.
- Current Git status includes generated `.gradle`/`build` outputs and an untracked `Launch_GeoGebra_GROK_V1.ps1`. Do not clean/reset/delete them without a specific request; do not include generated artifacts in product commits.

## 6. Required next work

Follow V2's gates and preserve the evidence protocol:

### Phase 0 — lock acceptance baseline

The reproducible provisional baseline is `375db7faf54` / `5.4.934.0`. The owner has not pinned an official stable release tag as the acceptance oracle. Confirm and record this before claiming no-regression parity. Build fixtures and test coverage for P-02/P-03, then P-04/P-05.

### Phase 1 — parallel feasibility spikes

**Desktop (D-01–D-05):** test Eclipse/Buildship import; identify the complete Gradle artifact/runtime set; generate package ownership/OSGi metadata; run intact artifacts in a minimal Equinox/RCP shell; test Swing/SWT interaction, CAS/GIAC and 3D/JOGL on clean installations. Do not change `common`.

**Web (W-01):** compare Java-to-web alternatives against JS/TS host modules using the same algebra, CAS, spreadsheet, 2D and 3D fixtures. Score feature fidelity, build complexity, native/CAS support, accessibility, offline behavior, licensing, and upstream maintenance. Do not remove GWT until W-02 passes.

**Contracts:** specify activity manifest, capability descriptor, state adapter, external computation request/result, WIMS submission/idempotency, permissions, trusted-module policy and common error/status codes.

### Phase 2 — vertical slice

One activity on both clients, with an intact `.ggb`, Algebra/CAS available, one external computation writing one allowlisted result, one WIMS/XWims schema and idempotent submission. Desktop provider and web provider are separate artifacts implementing the same capability contract.

### Phase 3 — widen validation

Execute all V2 product, desktop, web, extension, submission and release scenarios. Every PASS needs a log/artifact link with source pin, runtime/OS/browser, test fixture hash, command, expected and actual result. Until then statuses remain NOT RUN.

## 7. High-risk assumptions to challenge

1. **RCP + Swing:** GeoGebra desktop is Swing, while RCP normally centers SWT/JFace. Prove the integration/UX seam before assuming an RCP shell can host all desktop views reliably.
2. **Wrapping `common`:** A wrapper does not automatically create a stable plugin API or resolve package/resource/JNI conflicts. Test actual artifact boundaries and class loading.
3. **Native libraries:** JOGL and GIAC have explicit runtime/native packaging needs. Test on the final Equinox product, not only Gradle `run`.
4. **Dropping GWT:** A JS wrapper is not a replacement for GeoGebra's current web client. Full web parity is a release gate; if impossible, keep GWT temporarily or explicitly revise the decision.
5. **External algorithm semantics:** Writing a result through an API does not make it a native dependent construction object. Do not promise native dependency/undo/serialization semantics unless separately implemented and tested.
6. **Startup extension trust:** Activity manifests must not load arbitrary URLs/code. Use admin-controlled allowlists, pinned versions/integrity and declared permissions.
7. **Licensing:** Do not rely on Gemini's GPLv3 summary. Current GeoGebra materials distinguish source licensing (EUPL 1.2 in the checkout/legal notice) from terms for the complete product and assets. Complete component provenance and deployment-specific legal review before distribution.

## 8. Current scenario status

The V2 plan has 45 scenarios. No scenario is marked PASS. P-08 is PARTIAL: the local source pin and version string are known, but official acceptance tag remains unselected. All other scenarios are NOT RUN. Prior successful Gradle compilation is build evidence only, not RCP/web replacement validation.

## 9. Folder inventory caution

At the time this handoff was written, `02-Cdc` contains 13 files recursively, including V1, V2, the 2 archived decision files, and the other current documents. V2's section 2.1 does not enumerate itself and summarizes the archive directory as a wildcard; treat its source-of-truth hierarchy as meaningful, not its historical file count.

## 10. Expected Codex behavior

- Continue in English.
- Treat V2 and V1.3/V1.2 decisions as current, but verify claims against the pinned code and primary sources.
- Prefer reversible experiments and external packaging metadata over upstream source edits.
- Do not claim the whole architecture works based only on Gradle build success.
- Ask the owner only for decisions that block the next phase; otherwise proceed with the documented provisional baseline and label assumptions.
- When writing or editing a study, place it under `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc` and make supersession/status explicit.
