# GeoGebraPlus Architecture and Scenario Validation Plan

**Version:** GROK V1  
**Status:** Architecture baseline for feasibility work; not implementation approval  
**Date:** 28 October 2026  
**Language:** English  
**Project root:** `D:\ALF_Agents\G1_Geogebra_Migration`  
**GeoGebra reference checkout:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Provisional source baseline:** upstream `main`, commit `375db7faf54`  
**Intended readers:** project owner, architecture/development team, WIMS/XWims integrators

## 1. Purpose

This document consolidates the architecture decisions and requirements currently present in **all eleven files found recursively in `02-Cdc`**, including the archived decision drafts, and checks the resulting design against the source-tree evidence and the two research documents in `01-Recherche`.

It is both:

1. a proposed target architecture for GeoGebraPlus; and
2. a scenario-by-scenario validation plan showing what must be proved, how to test it, what constitutes a pass, and what must happen on failure.

It is not a claim that the RCP conversion, web replacement, or plugin loading has already been tested. Previously completed Gradle desktop/web builds prove that the **reference checkout** builds; they do not prove that it can run inside Equinox or that a replacement web client can match it feature-for-feature.

### 1.1 Normative language

- **MUST / MUST NOT:** requirement for a release candidate.
- **SHOULD:** recommended unless an accepted ADR documents a reason not to.
- **MAY:** optional capability.
- **PASS / FAIL / NOT RUN:** test execution status. In this version, the scenarios are specified but not executed; results must be filled during spikes.

## 2. Source-of-truth hierarchy and document reconciliation

The project folder contains drafts that intentionally conflict. To prevent stale language from becoming implementation requirements, apply this precedence:

1. `Decisions_Architecture_ALF_GROK_V1_3.md` — closes four decisions: Eclipse IDE is the workbench, desktop product is RCP/Equinox, teachers select prebuilt features, and upstream `common` remains intact and unsplit.
2. `Decisions_Architecture_ALF_GROK_V1.2.md` — expands the product requirements: desktop + web parity, all native GeoGebra surfaces, host-level extension hooks, separate algorithms, and startup discovery.
3. `Q&A_Architecture_ALF_v1.1.md` and `Q&A_Architecture_ALF_v1.md` — decision history and copied Gemini hypotheses, not authoritative technical evidence.
4. `GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md` and `Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md` — technical analysis; retain useful source findings but supersede earlier recommendations where the later owner decisions differ.
5. `Cdc_Evolution_GeoGebra_GROK_V1.md` and `Cahier_des_charges_outil_eleve_GROK_V1.md` — original student-tool drafts. Their notebook-only algebra/CAS split is withdrawn by later decisions.
6. Gemini's study and `Cdc_GeoPlus.txt` — source context, not license authority or verified implementation design.
7. `00-00_archives\...` — retained history only; not active requirements.

If any future file conflicts with this document, record an ADR and update the source-of-truth hierarchy. Do not silently merge incompatible statements.

### 2.1 Reviewed-file inventory

All eleven files found recursively in `02-Cdc` were reviewed for requirements or historical conflicts:

| File | Active use in this architecture |
|---|---|
| `Cdc_Evolution_GeoGebra_GROK_V1.md` | Initial GeoGebraPlus/Jupyter/WIMS split; superseded regarding Algebra/CAS relocation. |
| `Cdc_GeoPlus.txt` | Original user objective and ecosystem context. |
| `Decisions_Architecture_ALF_GROK_V1_3.md` | Primary current decisions. |
| `Decisions_Architecture_ALF_GROK_V1.2.md` | Current detailed decisions and requirement rationale. |
| `GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md` | Repository analysis plus prior addenda; this document turns those into a validation plan. |
| `Noms.md` | Future Algo* subject/module names; names do not imply they are GeoGebra kernel algorithms. |
| `Q&A_Architecture_ALF_v1.1.md` | Owner answers and Gemini technical assertions, some of which are corrected below. |
| `Q&A_Architecture_ALF_v1.md` | Earlier answers, including superseded/inconsistent statements. |
| `Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md` | Source-based comparison of Gemini's build/runtime proposals. |
| `00-00_archives\Decisions_Architecture_ALF_GROK_V1.1.md` | Historical decision; no longer authoritative where GWT or split-package statements conflict. |
| `00-00_archives\Decisions_Architecture_ALF_GROK_V1.md` | Historical decision; do not implement from this alone. |

The two `01-Recherche` documents reviewed are `Cahier_des_charges_outil_eleve_GROK_V1.md` and `synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md`.

## 3. Resolved product decisions

1. **Two shipped clients:** standalone desktop application based on Eclipse RCP/Equinox and a browser client.
2. **Eclipse IDE 2026-09:** development workbench only. Its installed path is recorded in V1.3; the IDE itself is not the user product.
3. **Browser runtime:** target is to drop GWT. The replacement path is unresolved and must be evaluated against full feature parity before selection.
4. **Native feature preservation:** Algebra View, CAS, Spreadsheet, 2D Graphics, 3D Graphics, and standard GeoGebra tools must remain available with no accepted regression.
5. **Upstream constraint:** do not edit or split/move classes inside upstream `source/shared/common`; keep the upstream repository as a clean updateable dependency where feasible.
6. **Extension lifecycle:** developers/system administrators provide trusted extensions. Users do not author code. Desktop discovers/resolves extensions during startup; hot install/uninstall is not required.
7. **Teachers:** choose/configure prebuilt capabilities and evaluation schemas in activities.
8. **Extension boundary:** GeoGebraPlus host APIs, not new extension points inside `common`.
9. **Domain algorithms:** physics/discrete mathematics modules compute outside GeoGebra's `AlgoElement` hierarchy and exchange declared inputs/outputs via host APIs.
10. **External systems:** WIMS/XWims is the evaluation/submission backend; Lean 4 is a later optional proof integration; Jupyter is complementary and must not replace native algebra/CAS.
11. **Parity:** extension packaging differs by runtime, but students should get equivalent required capabilities on desktop and web.

### 3.1 Baseline interpretation

Until a named official stable release is selected, this architecture uses local commit `375db7faf54` as the **reproducible initial comparison baseline only**. The product's no-regression baseline must be replaced by an explicitly pinned upstream commit/tag before release acceptance. “Latest stable” is otherwise a moving target and cannot be used as a repeatable test oracle.

## 4. Architecture overview

```text
                         Teacher authoring / activity manifest
                   WIMS + XWims schemas + optional VS Code/LLM
                                     |
                          signed/pinned activity package
                                     |
                         GeoGebraPlus activity contract
               activity id | capabilities | policies | save/submit
                         /                       \
                        /                         \
      Desktop host: Equinox/RCP              Browser host: web runtime TBD
      trusted OSGi bundles                    trusted JS/TS or Java-to-web modules
      RCP workbench + GeoGebra adapter        GeoGebra client adapter
      Swing/SWT interoperability spike        modern web UI and lifecycle
                |                                      |
       intact upstream desktop artifacts       full-parity GeoGebra capability set
                \                                      /
                 \---- shared versioned contracts ---/
                    state | schema | events | errors
                             |
                External computation providers
          physics/discrete math | notebook | Lean 4 (later)
                             |
                    WIMS/XWims submission adapter
```

The desktop Equinox service registry and browser extension loader are **different runtime mechanisms**. They implement equivalent product-level capability contracts but do not share loadable binaries by default.

### 4.1 Core architectural layers

| Layer | Responsibility | Must not own |
|---|---|---|
| Activity format | Activity id, version, initial GeoGebra file(s), enabled capabilities, permissions, evaluation schema refs. | Executable arbitrary plugin code or secrets. |
| GeoGebraPlus host | Activity lifecycle, capability selection, session/save/restore, extension discovery policy, UI integration, telemetry/logging. | Reimplementation of GeoGebra math kernel or scoring authority. |
| GeoGebra adapter | Translate typed host requests into supported desktop/web GeoGebra calls and normalize results/events. | WIMS credentials or arbitrary external code. |
| Extension providers | WIMS backend, external math/physics algorithms, notebook/Lean adapters, optional UI contributions. | Direct modification of upstream internals. |
| GeoGebra kernel | Existing construction, Algebra/CAS, standard tools/views and `.ggb` semantics. | GeoGebraPlus-specific policy/backend logic. |
| WIMS/XWims | Assignment, roster, evaluation, grading and collection according to schema. | Desktop bundle lifecycle or browser module loading. |

### 4.2 Proposed runtime packaging

**Desktop:** an Eclipse RCP product packages Equinox, GeoGebraPlus host bundles, a wrapper bundle around unchanged GeoGebra artifacts, and allowlisted extension bundles. Startup resolution is deterministic and logged. Native GIAC/JOGL artifacts must be handled by the product packaging and tested in the actual Equinox classloader/native-library environment.

**Web:** a browser shell loads the selected GeoGebra implementation and approved web add-ons. The API contract may match desktop semantically; a desktop OSGi bundle is not a browser module. Activity data selects a preinstalled/approved module id, not an untrusted script URL.

**GeoGebra artifact wrapper rule:** wrapping the intact `common` module is a packaging strategy, not an assumption that it is a stable extensibility API. It MUST NOT relocate/split upstream classes. Every dependency jar and package owner must be mapped; wrapper resolution, resource visibility, reflection, service loading, serialization, and native dependencies must be proven through Equinox tests.

## 5. Contracts that all scenarios depend on

Before building feature extensions, define these versioned interfaces/schemas:

### 5.1 Activity manifest

Minimum logical fields: `activityId`, `manifestVersion`, `geoGebraBaseline`, `figures[]`, `enabledCapabilities[]`, `permissions[]`, `evaluationSchemaRef`, and persistence/submission policy. A manifest is declarative; it cannot execute arbitrary code or grant itself permissions.

### 5.2 Capability descriptor

Each extension declares stable `capabilityId`, semantic version, compatible host API range, supported runtime (`desktop`, `web`, or both), required permissions, provided services, dependencies, and failure mode. Registry discovery must not imply automatic trust.

### 5.3 External computation request/result

Request fields: request id, algorithm id/version, typed inputs with units/coordinate frame, activity/figure id, revision/version of input state, cancellation token. Result fields: same request id and input revision, typed outputs, warnings/errors, computation version and timestamp. Stale or invalid results MUST NOT overwrite current construction state.

### 5.4 GeoGebra state adapter

Only named, allowlisted objects and typed values are exposed by default. API supports read, permitted write, save/restore, reset and event subscription. Raw command evaluation is privileged and opt-in. Adapter must normalize differences between desktop and web, including unavailable operation errors.

### 5.5 Submission/evaluation contract

The host packages notebook material (if enabled), `.ggb` files, declared responses, activity/schema versions, and a non-secret learner/session reference. WIMS remains scoring authority. Submission has idempotency key, status (`draft`, `submitted`, `accepted`, `rejected`, `returned`), retries, timeout handling, and auditable error response. `alphavalon-eval-v1` is a named schema candidate, not yet a frozen contract.

## 6. Scenario catalogue and validation matrix

Every row has to be run on both runtimes when marked **D+W**. At this stage all scenario statuses are **NOT RUN**. Do not mark an architecture “validated” until evidence (test log, build artifact, screenshots or automated report) is linked.

### 6.1 Product, shell and feature-parity scenarios

| ID | Scenario | Runtime | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|---|
| P-01 | Start clean product with no optional extension | D+W | Fresh profile; launch from packaged build. | App opens; baseline GeoGebra views/tools available; no missing-bundle/module errors. | Stop release; fix mandatory platform dependency. | NOT RUN |
| P-02 | Algebra View, CAS, Spreadsheet, 2D, 3D baseline | D+W | Run pinned test activity suite through all listed views and standard commands/tools. | All required views open and interact; results match baseline within defined tolerances. | Block chosen runtime; revise approach or scope explicitly. | NOT RUN |
| P-03 | Standard tool coverage | D+W | Enumerate standard tool ids/categories from pinned baseline; smoke each in representative geometry, measurement, transformation, function and 3D activities. | No missing tool or silent behavior drift. | Feature-specific blocker; no blanket parity claim. | NOT RUN |
| P-04 | Open/save/reopen `.ggb` | D+W | Open teacher file; modify; save; close; reload; compare geometry and metadata. | File opens and preserves supported state; no corruption/loss. | Block file workflow and identify unsupported elements. | NOT RUN |
| P-05 | Existing scripts/macros/import-export | D+W | Representative files with scripting, custom tools/macros, images, text, embedded content and supported exports. | Behavior matches declared baseline; unsupported cases listed. | Add exact gaps to parity matrix and decide baseline. | NOT RUN |
| P-06 | Offline use | Desktop mandatory; web documented | Disconnect network after installation; open local activity and save. | Desktop core and local extensions run; no hidden runtime fetch required. | Package missing runtime assets or classify feature as online-only. | NOT RUN |
| P-07 | Accessibility/layout/resizing | D+W | keyboard-only, zoom, high-DPI, narrow/mobile browser, resize, localization, screenreader spot tests. | No blocking clipping or unreachable controls; accepted standard. | Record WCAG target and fix/waive explicitly. | NOT RUN |
| P-08 | Baseline version lock | D+W | Pin exact upstream revision and artifact hashes; compare tests reproducibly. | Test reports identify commit and version. | No release parity sign-off without pin. | PARTIAL: source commit known, official stable target unresolved |

### 6.2 Desktop RCP/Equinox scenarios

| ID | Scenario | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|
| D-01 | Buildship/Eclipse workbench import | Import Gradle composite without changing source settings; sync root/shared/desktop/web builds; run documented tasks. | IDE recognizes source and can launch/debug supported tasks; Gradle remains authoritative. | Use terminal/external launch configs; do not change product architecture. | NOT RUN |
| D-02 | RCP host boots with intact upstream bundle | Wrap existing built artifacts; do not edit/split `common`; launch Equinox product. | Framework resolves and desktop UI starts with logs proving versions/package wires. | Stop RCP conversion; identify unsupported artifact/build assumptions. | NOT RUN |
| D-03 | Package/dependency collision audit | Analyze all runtime jars for duplicate package ownership; generate OSGi manifests/import/export reports. | No unresolved package wires or accidental split packages. | Change external packaging metadata or reconsider wrapper strategy; never move upstream source classes. | NOT RUN |
| D-04 | Swing/SWT compatibility | Run the existing Swing GeoGebra UI in a minimal RCP host; test focus, modality, menus, clipboard, input, resizing and DPI. | Stable integrated UI; no lost native features. | Compare Equinox-with-Swing host vs SWT rewrite; quantify scope. | NOT RUN |
| D-05 | Native GIAC/JNI and JOGL/3D | Run CAS commands and 3D OpenGL scenario from installed RCP product on each supported OS/architecture. | Correct native library load and behavior; no duplicate classloader/native load failures. | Fail platform/architecture package; no silent CAS/3D fallback. | NOT RUN |
| D-06 | Extension discovery at startup | Install one allowlisted WIMS service bundle and one missing/incompatible bundle; cold start. | Compatible extension is registered once; incompatible one is isolated/reported; host remains usable. | Fail safe; extension not loaded; clear diagnostic. | NOT RUN |
| D-07 | Restart/no hot-swap policy | Change extension set then restart product; keep an open activity during upgrade test. | Changes take effect after restart; no promise of live unload; user data preserved. | Treat data migration and restart messaging as release blocker. | NOT RUN |
| D-08 | Extension version/dependency conflict | Two modules require incompatible API ranges; run resolver. | Deterministic refusal for incompatible module, no partial feature state. | Pin versions and improve manifest/diagnostics. | NOT RUN |
| D-09 | Admin-managed trusted directory/product assembly | Add unsigned, tampered, unapproved and approved bundle samples. | Only approved/signed/pinned modules load; audit trail records set. | Block deployment until trust policy is enforced. | NOT RUN |
| D-10 | RCP packaging/updater | Install, upgrade, rollback and launch on clean Windows/macOS/Linux targets as supported. | Reproducible product with correct Java runtime, native files and extension manifests. | Restrict supported platforms until packaging validated. | NOT RUN |

### 6.3 Browser replacement and parity scenarios

| ID | Scenario | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|
| W-01 | Dual path feasibility comparison | Prototype Java-to-web alternatives and JS/TS host extensions against representative CAS, algebra, spreadsheet, 2D and 3D activities. | Scored matrix for fidelity, build, runtime, native/CAS, accessibility, offline, licensing, maintenance. | Keep current web implementation as temporary baseline; do not claim replacement parity. | NOT RUN |
| W-02 | Browser full-feature parity | Run same pinned scenario corpus as P-02/P-03 in chosen no-GWT client. | All mandatory features pass with no accepted regression. | Revisit no-GWT decision or resource a full replacement; no reduced feature release. | NOT RUN |
| W-03 | Web module discovery | Start with approved/disabled/missing/incompatible module sets from declarative activity config. | Only trusted preinstalled modules load; deterministic capability report. | Fail closed; never import arbitrary activity-supplied URL/code. | NOT RUN |
| W-04 | Browser security boundary | Attempt cross-origin script, command injection, oversized data, malicious `.ggb`, XSS in labels/text, unauthorized read/write. | Policy enforced; no untrusted module receives broad page/runtime access. | Block web extension API until sandbox/permission model is sound. | NOT RUN |
| W-05 | Multiple figures and deterministic identity | Open 2D and 3D figures simultaneously; reload and switch activities. | Stable figure ids; no cross-talk, overwritten state, or duplicate listeners. | Fix lifecycle and namespace before integration. | NOT RUN |
| W-06 | Responsive/device behavior | Exercise resize, device rotation, touch/pointer and low bandwidth on supported browsers. | No blocked interaction or persistent layout corruption. | Define supported browser/device minimums; block unsupported combinations. | NOT RUN |
| W-07 | Offline/cache behavior | Load app/activity then disconnect network; exercise core and extension capabilities. | Required student workflow operates offline to agreed level. | Identify dependencies requiring local packaging or state online-only. | NOT RUN |
| W-08 | Web-to-desktop shared contract | Feed same versioned activity and external algorithm request into both clients. | Equivalent typed inputs/outputs/errors/status and student-visible behavior. | Version contract separately or reject parity claim. | NOT RUN |

### 6.4 Extension and domain-computation scenarios

| ID | Scenario | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|
| X-01 | External algorithm computes independently | Physics/discrete-math provider receives typed input snapshot and returns typed output. | Runs outside `AlgoElement`; deterministic result and versioned errors. | Narrow scope; do not patch core under no-fork rule. | NOT RUN |
| X-02 | Live inputs and stale-result protection | Rapidly change figure input while async provider computes. | Old result rejected by input revision; latest result displayed, cancellation supported. | Use explicit submit/recompute action instead of live feedback. | NOT RUN |
| X-03 | Publish outputs through GeoGebra adapter | Write allowed named numeric/boolean/point outputs via supported operations. | GeoGebra views reflect outputs; no invalid/untyped writes. | Remove unsupported type from v1 contract. | NOT RUN |
| X-04 | No false native-algorithm semantics | Save/reopen activity with external output; inspect dependency/undo/redo behavior. | Documentation/UI distinguishes computed external output from native dependent `AlgoElement`. | Do not describe as “new GeoGebra Algo*”; use external result object/panel. | NOT RUN |
| X-05 | Same capability, different loaders | Desktop OSGi provider and web provider implement same capability descriptor/schema. | Product contract equivalent while artifacts remain runtime-specific. | Split capability IDs or block cross-runtime use. | NOT RUN |
| X-06 | Provider exception/timeout/cancel | Inject exceptions, slow response, malformed output, host shutdown. | Bounded timeout, user-safe message, no corrupted state; cancellation cleans listeners. | Disable failing extension and retain core app. | NOT RUN |
| X-07 | Lean 4 integration later | Mock or real service exchanges proof request/result without blocking app. | Lean service is optional and isolated; core remains usable offline/without it. | Defer integration; no dependency from core. | NOT RUN |

### 6.5 WIMS/XWims, activity and submission scenarios

| ID | Scenario | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|
| S-01 | Teacher selects prebuilt schema/feature | Author activity manifest with approved WIMS schema and enabled capability. | Student client shows only configured capabilities and schema id. | Reject unknown/unauthorized manifest entries. | NOT RUN |
| S-02 | Submit valid activity package | Submit notebook if enabled, `.ggb` files, declared answers and schema version. | Backend receives reproducible complete package once. | Fix serializer or fail with actionable status; no partial success. | NOT RUN |
| S-03 | Duplicate submission/retry | Timeout after backend accepted; retry same idempotency key. | One logical submission/grade record. | Require idempotency at transport/backend or show duplicate warning. | NOT RUN |
| S-04 | Offline draft and later sync | Save locally, go offline, submit after reconnection. | No data loss; status clearly draft/pending/submitted. | Keep recoverable local file and explain sync failure. | NOT RUN |
| S-05 | Invalid schema / malformed response | Unknown schema version, invalid JSON, partial WIMS response. | Validate before use; retain student work; report failure safely. | No silent marking or destruction of work. | NOT RUN |
| S-06 | Auth/privacy separation | Attempt to expose learner token to extension or include secrets in `.ggb`/logs. | Least privilege; tokens held by host/backend channel; minimized data. | Block release; rotate exposed credentials. | NOT RUN |
| S-07 | XWims migration traceability | Convert representative OEF tasks to XML/JSON schema and compare expected grade. | Explicit mapping and equivalent evaluation on test fixtures. | Maintain OEF fallback until mapping proven. | NOT RUN |

### 6.6 Upstream, operations and governance scenarios

| ID | Scenario | Test/procedure | Pass criteria | Failure response | Status |
|---|---|---|---|---|---|
| O-01 | Upstream update without source delta | Update pinned upstream revision and rebuild wrapped desktop/web baselines. | No edits to `common`; changes limited to owned adapter/build metadata or documented incompatibility. | Reject update or create explicit upstream compatibility ADR; avoid hidden fork. | NOT RUN |
| O-02 | License/provenance audit | Inventory source, binaries, fonts, icons, language files, applet/materials, dependencies and trademarks. | Per-component license/provenance manifest approved for deployment model. | Stop distribution and seek rights review. | NOT RUN |
| O-03 | Reproducible build and SBOM | Clean build of RCP and web artifacts; produce dependency/SBOM and hashes. | CI can reproduce package and identify all included components. | Block external pilot. | NOT RUN |
| O-04 | Logs and diagnostics | Simulate missing bundle, failed service, malformed `.ggb`, backend outage. | User-facing safe error plus redacted diagnostic with correlation id. | Improve diagnostics before support pilot. | NOT RUN |
| O-05 | Data migration/backward compatibility | Upgrade activity, schemas, host and extension versions across one release. | Clear compatibility policy; recoverable conversion and rollback. | Keep old format reader or defer new format. | NOT RUN |

## 7. File-by-file traceability and conflict dispositions

| Source file(s) | Requirements carried forward | Conflict/disposition in this architecture |
|---|---|---|
| `Decisions_Architecture_ALF_GROK_V1_3.md` | RCP product; Eclipse IDE workbench; teachers configure; `common` intact wrapper; web path study. | Current decision source, but Java-to-web vs JS remains a study. |
| `Decisions_Architecture_ALF_GROK_V1.2.md` | Full feature parity; external computation; host-level hooks; startup extension discovery. | Current detailed requirements; startup resolver is not hot swap. |
| `Q&A_Architecture_ALF_v1.1.md` | Feature scope, proposed WIMS/Lean use cases. | Gemini API limitation claims are hypotheses; verify exact API/version. |
| `Q&A_Architecture_ALF_v1.md` | Historical preference and initial scenarios. | Earlier “Both/teachers extend”, GWT-tradeoff and notebook-core statements are superseded. |
| `00-00_archives\Decisions_Architecture_ALF_GROK_V1*.md` | Historical rationale. | Not active where they promise GWT retirement or extension behavior without parity proof. |
| `GeoGebra_Code_Modularity_and_Eclipse_Architecture_Study_EN.md` | Source topology, risk, legal correction, architecture analysis. | This document adds the scenario matrix and firm owner decisions. |
| `Report_Gemini_Proposals_vs_GeoGebra_Code_GROK_V1.md` | Detailed comparison of API/SPI/PF4J/OSGi/WebSocket. | Prior “GWT stays” product recommendation is superseded by V1.2; it remains useful as risk analysis. |
| `Cdc_Evolution_GeoGebra_GROK_V1.md` | GeoGebraPlus wrapper and activity configuration concepts. | Algebra/CAS are no longer moved out; desktop RCP is newly in scope. |
| `Cdc_GeoPlus.txt` | Overall target: modular student tool, GeoGebraPlus, Jupyter, WIMS, VS Code LLM. | Context only; not a detailed technical specification. |
| `Noms.md` | Candidate subject modules including AlgoPhy/AlgoGraphe/etc. | Names are product taxonomy, not promise of native GeoGebra algorithm injection. |
| `Cahier_des_charges_outil_eleve_GROK_V1.md` | Single student activity, notebook, figures, WIMS launch/submit. | Must be revised to preserve Algebra/CAS/Spreadsheet and desktop path. |
| `synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md` | Gemini architecture options to evaluate. | GPL/CC summary and version assertions not authoritative; verify before release. |

## 8. Specific technical corrections that affect test design

1. **Eclipse IDE vs RCP:** importing the Gradle tree proves tooling only; it does not prove the user application runs in Equinox.
2. **RCP vs existing Swing UI:** the local desktop application is Swing-based; an RCP product commonly uses SWT/JFace. Do not assume the whole UI becomes RCP merely by placing jars in Equinox. Test a Swing host first and compare the effort of SWT integration/rewrite.
3. **`common` wrapper vs API modularity:** one intact bundle can satisfy “do not split upstream sources” but does not make internals an extensible API. External services can use host-defined contracts; native command/view/object injection remains out of scope.
4. **OSGi classloaders vs package conflicts:** classloader isolation does not magically remove duplicate package ownership or incompatible shared types. Resolve package and native loading empirically.
5. **Startup service registry:** OSGi can compose providers at startup. This does not mean activity manifests can load arbitrary plugins or that runtime add/remove is required.
6. **External algorithm:** output written to GeoGebra is not equivalent to an object with native construction dependencies, undo semantics, serialization and reactive recomputation. Use explicit external-result semantics.
7. **Web APIs:** the existing app API and a modern JS host can be useful during migration, but an outer wrapper is not a replacement for the internal GWT web app. Since GWT removal is a decision, web feature parity must be proved by the replacement, not assumed from wrapper work.
8. **Licensing:** older Gemini notes state GPLv3/CC BY-NC-SA broadly. Current GeoGebra legal text distinguishes source and product components; prepare a current component-level legal inventory and obtain deployment-specific review.

## 9. Test execution and evidence protocol

### 9.1 Required test dossier per scenario

For each test id, record: date; tester; exact source/build hash; runtime OS/Java/browser; extension set and versions; activity/test fixture hash; command/run procedure; expected result; actual result; pass/fail/not run; log/artifact path; issue link; remediation owner; retest result.

### 9.2 Exit gates

- **Gate A — Reference parity baseline:** source version pinned; P-02 to P-05 test corpus exists for current desktop and web builds.
- **Gate B — Desktop Equinox viability:** D-02 to D-06 pass for a representative RCP package; native 3D/CAS and no-source-change wrapper are demonstrated.
- **Gate C — Web replacement feasibility:** W-01 is complete and presents a costed path; do not retire GWT until W-02 passes.
- **Gate D — Extension contract:** X-01 to X-06 and S-01 to S-05 pass for WIMS plus one external computation provider on both hosts.
- **Gate E — Pilot readiness:** security, privacy, licensing, packaging, update/rollback, offline workflow and recovery scenarios pass or have explicit accepted exceptions.

### 9.3 Architecture decision rule

If a mandatory parity scenario cannot be met without editing upstream `common`, do not quietly patch it. Record a decision with exactly three choices: (a) change the host/adapter design; (b) explicitly revise the no-upstream-modification decision; or (c) revise product scope. If web parity fails after GWT retirement, the decision must explicitly restore a temporary GWT path or approve a fully resourced rewrite; no feature is silently dropped.

## 10. Phased implementation roadmap

### Phase 0 — baseline and requirements

- Pin the official/stable reference revision and archive build artifacts.
- Turn P-02/P-03 into a feature-by-feature parity inventory and executable test corpus.
- Correct prior student-spec documents to make notebooks complementary, not replacements for Algebra/CAS.

### Phase 1 — parallel feasibility spikes

- **Desktop:** run Eclipse/Buildship import; wrap intact core artifacts; Equinox package resolution; RCP Swing/SWT experiment; CAS/3D/native smoke test.
- **Web:** compare Java-to-web candidates vs JS/TS host modules; implement one same-activity feature under each path and estimate parity.
- **Contracts:** specify activity manifest, capability descriptor, external algorithm I/O, state adapter, WIMS schema and security policy.

### Phase 2 — vertical slice

One student activity opens on desktop and browser; same initial `.ggb`; Algebra/CAS and a 2D/3D figure remain available; one external computation provider writes a declared output; one WIMS evaluation schema receives a secure, idempotent submission. Providers are selected by trusted host configuration, not by arbitrary teacher code.

### Phase 3 — feature parity and rollout

Expand scenario coverage to every mandatory view/tool/file path, supported OS/browser, offline workflow, error recovery, and upgrade. Release only the features with passing parity results and explicit legal/security approval.

## 11. Architecture risks and mitigations

| Risk | Probability / impact | Mitigation / trigger |
|---|---|---|
| Full browser parity after dropping GWT is infeasible at acceptable cost. | High / Critical | Complete W-01 before choosing web engine; preserve current browser build as temporary fallback. |
| Swing UI cannot be integrated cleanly into RCP/SWT. | Medium / High | Prototype D-04; compare bridge vs staged UI rewrite. |
| Intact `common` artifact is not OSGi-resolvable with transitive dependencies. | Medium / High | D-03 artifact/package analysis; keep build metadata external to upstream. |
| CAS/JNI or JOGL fails through Equinox classloading/native packaging. | Medium / High | Early D-05 on clean machines and all intended architectures. |
| External algorithms are mistaken for native GeoGebra algorithms. | High / Medium | Explicit external-result contract and X-04 product language/test. |
| Startup extension loading introduces untrusted executable code. | Medium / Critical | Pinned admin allowlist, signatures/integrity, capability permissions; W-04/D-09 security gate. |
| WIMS schema conversion loses grading semantics. | Medium / High | S-07 golden OEF fixtures and dual-run comparisons before migration. |
| Scope contradictions persist in old CDC drafts. | High / Medium | This traceability table; revise or mark old docs superseded. |
| Legal restrictions/assets misunderstood. | Medium / Critical | O-02 component inventory and formal deployment review. |

## 12. Deliverables and ownership placeholders

| Deliverable | Depends on | Owner | Acceptance |
|---|---|---|---|
| Pinned feature parity baseline + tests | Product owner | TBD | Gate A |
| Equinox package/native feasibility report | Desktop lead | TBD | Gate B evidence |
| Web runtime comparison and recommendation | Web lead | TBD | Gate C evidence |
| Activity/capability/API schemas | Architecture owner | TBD | Versioned documents + contract tests |
| WIMS/XWims vertical slice | WIMS integrator | TBD | S-01–S-07 pass |
| External algorithm sample | Domain-module lead | TBD | X-01–X-06 pass |
| Legal/SBOM/security dossier | Release owner | TBD | O-02/O-03 + security gates |

## 13. References and local evidence

### Local files

- GeoGebra root `settings.gradle.kts`, `source/shared/settings.gradle.kts`, `source/desktop/settings.gradle.kts`, `source/web/settings.gradle.kts`.
- `source/shared/common/build.gradle.kts`, `source/desktop/desktop/build.gradle.kts`, root `README.md`.
- Project decisions and prior reports listed in section 2.1.

### Primary external references

- GeoGebra Apps API and embedding docs: https://geogebra.github.io/docs/reference/en/GeoGebra_Apps_API/ and https://geogebra.github.io/docs/reference/en/GeoGebra_Apps_Embedding/
- GeoGebra legal information: https://www.geogebra.org/license and https://github.com/geogebra/legal/blob/main/geogebra_license.md
- Gradle composite builds: https://docs.gradle.org/current/userguide/composite_builds.html
- Eclipse PDE and plug-in/OSGi concepts: https://help.eclipse.org/latest/topic/org.eclipse.pde.doc.user/concepts/plugin.htm and https://help.eclipse.org/latest/topic/org.eclipse.pde.doc.user/guide/intro/pde_overview.htm
- Eclipse 2026-09 release metadata: https://download.eclipse.org/releases/2026-09/202609091000/buildInfo/archive/download.eclipse.org/releases/2026-09/202609091000/

---

**Owner action required before implementation:** confirm the provisional feature-parity baseline, then authorize Phase 0 and the parallel feasibility spikes. No scenario in section 6 is represented as passed until evidence is attached.
