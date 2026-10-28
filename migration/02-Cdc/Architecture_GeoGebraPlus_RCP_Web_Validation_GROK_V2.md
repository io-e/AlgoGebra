# GROK_V2

# GeoGebraPlus architecture and scenario validation plan

**Status:** corrected baseline. Scenarios are specified, not executed.  
**Date:** 28 October 2026  
**Supersedes:** `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V1.md`  
**Project root:** `D:\ALF_Agents\G1_Geogebra_Migration`  
**GeoGebra checkout:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Reproducible source pin:** upstream `main`, commit `375db7faf54`  
**Version string in that checkout:** `5.4.934.0`, build date 20 October 2026 (`GeoGebraConstants.java`)

This document is a validation plan. It is not evidence that Equinox can host GeoGebra, and it is not approval to delete the GWT web app.

## 1. What V2 corrects in V1

Checked against `Decisions_Architecture_ALF_GROK_V1_3.md`, `Decisions_Architecture_ALF_GROK_V1.2.md`, and the checkout.

| V1 statement | Correction |
|---|---|
| "All scenario statuses are NOT RUN" while P-08 is PARTIAL | P-08 stays PARTIAL. Every other row is NOT RUN. |
| A single wrapper bundle around `common` | The desktop runtime is a set: `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, `keyboard-base`, `keyboard-scientific`, `ggbjdk`, `giac-jni`, plus `desktop`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, `jogl2`, and the JOGL/GIAC native jars. Wrapping `common` alone does not start the UI. |
| Gemini's "GPLv3" as the license to plan around | `GeoGebraConstants.java` in this checkout states EUPL 1.2 for that source, and states that the overall package is free for non-commercial use only. Release still needs a component inventory. Do not treat the Gemini brief as the license. |
| `5.4.x` read as an Android-only line | This desktop/shared tree itself reports `5.4.934.0`. That string is the comparison label for this pin. It is not yet an acceptance oracle. Acceptance still needs an explicitly chosen upstream tag. |
| "GWT removal is a decision", so the wrapper replaces the web app | GWT is the web app that already compiled (`SuperWeb`, `WebSimple`, `Web`, `Tablet3D`). Retiring it is a target. It stays until Gate C passes. |
| Eclipse 2024 / Java 21 as the RCP constraint | The installed workbench is Eclipse IDE 2026-09, platform 4.41.0, at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse`. `:desktop:run` uses a Java 25 toolchain. The RCP spike must use a Java that this desktop already runs on. |
| Eleven files in `02-Cdc` | Inventory in section 2.1 matches the folder after V2 was added. V1 remains history. |

Unchanged, and still binding:

- Shipped desktop product is RCP/Equinox. The Eclipse IDE is only the workbench.
- Teachers select prebuilt features. They do not install code.
- Upstream `common` is not edited and not split.
- Algebra View, CAS, spreadsheet, 2D, and 3D stay. Jupyter does not replace them.
- Domain algorithms are external services, not new `AlgoElement` classes.
- Hooks live in the GeoGebraPlus host.
- Desktop discovers allowlisted bundles at startup. No hot unload.
- A desktop bundle is not a browser module. Web mechanism (non-GWT Java-to-web, or JS/TS) is still a study.
- Students must see the same required features on both clients.

## 2. Source-of-truth order

1. This V2 file for the validation plan.
2. `Decisions_Architecture_ALF_GROK_V1_3.md`, then `Decisions_Architecture_ALF_GROK_V1.2.md`.
3. Code and build files in the pinned checkout, when a document disagrees with them.
4. Older Q&A, Gemini notes, and `Cdc_Evolution_GeoGebra_GROK_V1.md` only as history. Their "move algebra into the notebook" and "GPLv3" lines are withdrawn.

### 2.1 Folder inventory

| File | Role |
|---|---|
| `Decisions_Architecture_ALF_GROK_V1_3.md` | Closed product decisions. |
| `Decisions_Architecture_ALF_GROK_V1.2.md` | Owner answers that V1_3 records. |
| `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V1.md` | Superseded by this file. |
| `Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md` | Code comparison. Its "do not go Equinox" recommendation is superseded by the owner decision to ship RCP. The GWT and JOGL facts remain. |
| `GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md` | Earlier study. Use only where it matches the checkout. |
| `Cdc_Evolution_GeoGebra_GROK_V1.md` | Superseded on algebra/CAS and on "no RCP". |
| `Q&A_Architecture_ALF_v1.md`, `Q&A_Architecture_ALF_v1.1.md` | History. |
| `Cdc_GeoPlus.txt`, `Noms.md` | Context and subject names. Names are not kernel classes. |
| `00-00_archives\*` | History. |

`01-Recherche\Cahier_des_charges_outil_eleve_GROK_V1.md` still describes a notebook-first student page. It must be revised before anyone implements from it. `01-Recherche\synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md` is not evidence.

## 3. Target shape

```text
Teacher activity (Wims / XWims schema, optional VS Code LLM)
        |
        v
GeoGebraPlus host
  activity id, capability ids, permissions, save, submit
        |                         |
        v                         v
Desktop RCP / Equinox         Browser host (runtime not chosen)
allowlisted OSGi bundles      allowlisted web modules
Swing UI from upstream        current GWT applet until Gate C
        \                         /
         shared contracts only
         state, events, errors, submission
                 |
        external providers (not AlgoElement)
        physics / discrete math / notebook / Lean 4 later
                 |
              Wims grade
```

The host owns policy. The kernel owns constructions. Wims owns the grade.

**Desktop packaging.** An RCP product that resolves, at startup, the upstream jar set listed in section 1 plus the GeoGebraPlus host and allowlisted extension jars. Native JOGL and GIAC jars stay on the application loader. The desktop `run` task already copies JOGL natives beside the jars because JOGL does not honour a normal classpath. Equinox must be tested against that constraint, not assumed to fix it.

**Web packaging.** Until Gate C, the browser baseline is the GWT output already built under `source/web/web/war`. A replacement may be chosen only after W-01 and W-02. Activity files name a module id. They do not carry a script URL.

## 4. Contracts to freeze before extensions

- **Activity manifest:** `activityId`, `manifestVersion`, `geoGebraBaseline` (commit plus `VERSION_STRING`), `figures[]`, `enabledCapabilities[]`, `permissions[]`, `evaluationSchemaRef`. Declarative only.
- **Capability descriptor:** `capabilityId`, version, host API range, runtime `desktop` or `web` or `both`, permissions, failure mode. Discovery is not trust.
- **External computation:** request id, algorithm id, typed inputs, figure id, input revision. Result must echo the revision. A stale result must not write into the construction.
- **State adapter:** allowlisted names and typed values. `evalCommand` is privileged. Desktop and web errors use the same codes.
- **Submission:** notebook if present, `.ggb` files, declared answers, schema version, idempotency key, status `draft | submitted | accepted | rejected | returned`. `alphavalon-eval-v1` is a candidate name, not a frozen schema.

## 5. Scenarios

PASS requires a linked log or artifact. No row below is PASS.

### 5.1 Product

| ID | Scenario | Runtime | Pass | Status |
|---|---|---|---|---|
| P-01 | Clean product, no optional extension | D+W | Views open, no missing mandatory bundle | NOT RUN |
| P-02 | Algebra, CAS, spreadsheet, 2D, 3D | D+W | Same results as the pinned baseline, within a written tolerance | NOT RUN |
| P-03 | Standard tools | D+W | No missing tool against the pin | NOT RUN |
| P-04 | Open, save, reopen `.ggb` | D+W | No silent loss | NOT RUN |
| P-05 | Scripts, macros, images, export | D+W | Gaps listed, not ignored | NOT RUN |
| P-06 | Offline after install | Desktop required; web as documented | No hidden download for the core | NOT RUN |
| P-07 | Resize, DPI, keyboard, narrow browser | D+W | No blocked control | NOT RUN |
| P-08 | Pin recorded | D+W | Reports cite `375db7faf54` and `5.4.934.0` | PARTIAL: pin known, official acceptance tag not chosen |

### 5.2 Desktop

| ID | Scenario | Pass | Status |
|---|---|---|---|
| D-01 | Import the Gradle composite into Eclipse 2026-09 | IDE builds the existing tasks. Gradle stays the build. | NOT RUN |
| D-02 | RCP starts on the jar set in section 1, with no edit under `source/shared/common` | UI starts, logs show the jar set | NOT RUN |
| D-03 | Package-ownership report for that jar set | No accidental split packages. Fixes are metadata outside upstream source. | NOT RUN |
| D-04 | Swing GeoGebra inside an RCP shell | Focus, menus, clipboard, DPI work, or the SWT rewrite cost is written down | NOT RUN |
| D-05 | CAS and 3D from the RCP product | GIAC and JOGL load once | NOT RUN |
| D-06 | One good Wims bundle and one bad bundle at startup | Good one registered once; bad one reported; core stays up | NOT RUN |
| D-07 | Change the set, restart | New set after restart; open work kept | NOT RUN |
| D-08 | Incompatible version ranges | Resolver refuses; no half-loaded feature | NOT RUN |
| D-09 | Unsigned or unapproved jar in the extension directory | Not loaded | NOT RUN |
| D-10 | Install, upgrade, rollback on a clean Windows machine first | Java 25 and natives included | NOT RUN |

### 5.3 Web

| ID | Scenario | Pass | Status |
|---|---|---|---|
| W-01 | Score Java-to-web and JS/TS against the same CAS, algebra, spreadsheet, 2D, and 3D files | Written matrix: fidelity, build, CAS, 3D, license, maintenance | NOT RUN |
| W-02 | Chosen non-GWT client runs P-02 and P-03 | No missing mandatory feature | NOT RUN |
| W-03 | Approved, missing, and incompatible web modules | Fail closed. No URL from the activity | NOT RUN |
| W-04 | XSS, malicious `.ggb`, command injection | Extension has no broad page access | NOT RUN |
| W-05 | 2D and 3D together, then reload | Stable figure ids, no shared listeners | NOT RUN |
| W-06 | Resize and touch on the supported browsers | Supported set written if one fails | NOT RUN |
| W-07 | Offline after first load | Agreed offline slice works | NOT RUN |
| W-08 | Same activity contract on both clients | Same status codes and student-visible result | NOT RUN |

The current GWT war remains the web baseline for P-02 until W-02 passes.

### 5.4 Extensions and Wims

| ID | Scenario | Pass | Status |
|---|---|---|---|
| X-01 | External algorithm, not an `AlgoElement` | Deterministic typed result | NOT RUN |
| X-02 | Input changes during compute | Stale revision dropped | NOT RUN |
| X-03 | Write an allowlisted number back | Views update | NOT RUN |
| X-04 | Save and undo | UI does not call the output a native dependent object | NOT RUN |
| X-05 | Same capability id, two artifacts | Desktop jar and web module stay distinct | NOT RUN |
| X-06 | Timeout and bad output | Core construction unchanged | NOT RUN |
| X-07 | Lean 4 absent | App still opens | NOT RUN |
| S-01 | Teacher picks a schema and a capability | Student sees only those | NOT RUN |
| S-02 | Submit once | One complete package | NOT RUN |
| S-03 | Retry the same idempotency key | One grade record | NOT RUN |
| S-04 | Offline draft, then sync | Work kept | NOT RUN |
| S-05 | Bad schema | Work kept, no silent grade | NOT RUN |
| S-06 | Token not visible to the extension | Confirmed in logs | NOT RUN |
| S-07 | Sample OEF to XWims | Same grade on fixtures, or OEF kept | NOT RUN |

### 5.5 Release gates

| ID | Scenario | Pass | Status |
|---|---|---|---|
| O-01 | Newer upstream commit, still no edit in `common` | Adapter-only diff, or a written refusal | NOT RUN |
| O-02 | License inventory including EUPL 1.2 sources, non-commercial package terms, natives, fonts, translations | Deployment review recorded | NOT RUN |
| O-03 | Clean rebuild and hashes | SBOM matches the package | NOT RUN |
| O-04 | Missing bundle, bad `.ggb`, Wims down | Safe message, redacted log | NOT RUN |
| O-05 | One activity upgrade | Old file still opens | NOT RUN |

## 6. Gates

- **A.** P-02 through P-05 exist for the current desktop build and the current GWT war, on commit `375db7faf54`.
- **B.** D-02 through D-06 pass. Natives load. `common` has no source diff.
- **C.** W-01 is a scored choice. GWT is not removed until W-02 passes. If W-02 fails, the decision is explicit: keep GWT, or fund a rewrite. Features are not dropped in silence.
- **D.** X-01 through X-06 and S-01 through S-05 pass on both hosts for one Wims schema and one external algorithm.
- **E.** O-02, O-03, D-09, and W-04 pass, or an exception is written.

If a gate needs a change inside `common`, stop. The only allowed outcomes are: change the host, revise the no-fork rule in a new decision file, or cut scope.

## 7. Order of work

1. Phase 0: freeze the acceptance tag, or keep `375db7faf54` and say so. Build the P-02/P-03 corpus on the builds that already exist.
2. Phase 1, in parallel: D-01 to D-05, and W-01. Write the five contracts in section 4.
3. Phase 2: one activity, both clients, one `.ggb`, Algebra and CAS still open, one external number written back, one idempotent Wims submit.
4. Phase 3: widen to the rest of the matrix. Ship only rows that passed.

## 8. Risks

| Risk | Why it is real here | Response |
|---|---|---|
| Non-GWT web cannot match the four GWT modules | Those modules are the current full client | Gate C before deletion |
| Swing inside SWT | Desktop UI is Swing (`org.geogebra.desktop.GeoGebra3D`) | D-04 before a rewrite |
| OSGi split packages | `common` exports a wide public surface and depends on editor, renderer, and canvas | D-03; do not move classes |
| JOGL / GIAC under Equinox | Natives are already a special case in `desktop/build.gradle.kts` | D-05 on a clean machine |
| External result mistaken for a kernel object | Owner rule forbids new `AlgoElement` subclasses | X-04 |
| Old CDC files used by mistake | They still sit beside this file | Section 2.1 |

## 9. Evidence rule

Each executed row records: date, commit, `VERSION_STRING`, OS, Java or browser, extension set, fixture hash, command, expected, actual, log path. A row without that record stays NOT RUN.
