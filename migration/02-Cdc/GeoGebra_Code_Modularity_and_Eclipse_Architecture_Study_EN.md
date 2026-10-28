# GeoGebra Code Modularity and Eclipse Architecture Study

**Status:** Initial technical assessment and decision brief  
**Prepared:** 28 October 2026  
**Code reviewed:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Git revision:** `375db7faf54` (`main`, as reported by the local checkout)  
**Source proposal reviewed:** `01-Recherche\synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md`  
**Project target:** a highly extensible student geometry/3D tool, eventually integrated with notebooks, Wims, and the teacher's VS Code/LLM workflow.

## Executive recommendation

The requirement “as flexible as Eclipse” has two materially different meanings:

1. **Use Eclipse as the development IDE.** This is low-risk. Keep GeoGebra's existing Gradle build and import/configure it in Eclipse as a Gradle workspace. This changes the developer environment, not the product architecture.
2. **Turn GeoGebra into an Eclipse/Equinox (OSGi) application or migrate its code into Eclipse plug-ins.** This is a major re-platforming effort. The desktop Java modules are conceivable candidates for gradual OSGi boundaries; the web application is a separate GWT build with browser-specific code generation and cannot become an Eclipse plug-in merely by adding OSGi manifests.

**Recommended direction:** do not migrate upstream GeoGebra wholesale into Eclipse RCP now. Preserve the upstream Gradle build as the source of truth, use Eclipse for development if desired, and build GeoGebraPlus as a separately versioned integration shell around the supported web applet API. Add an explicit, versioned extension contract at the wrapper boundary. If in-process, third-party plug-ins later become a proven requirement, run a bounded architecture spike against the desktop Java core and compare OSGi/Equinox with a deliberately small host API before committing to a kernel refactor.

Gemini's study correctly identifies that the public tree already has some Gradle module boundaries and that a web wrapper is the least invasive path. It overstates the absence of modularity (the source is not one Gradle project), understates the GWT/web limitation, and its license summary is materially stale: GeoGebra's current official legal material identifies the source code as EUPL 1.2, while the overall product, installers/services, and language/UI materials have distinct terms. Obtain a project-specific legal review before redistributing a modified product or embedding product assets.

## 1. Scope and evidence

This is a repository-level architectural assessment, not a complete class-by-class audit. I reviewed the root Gradle settings/build, the `source/shared`, `source/desktop`, and `source/web` composite-build settings, the desktop launcher module's dependencies, shared `common` module's declared API/dependencies, and the README build instructions. The working tree contains local build outputs and an untracked launcher script; these do not appear to be upstream source changes, but should be kept out of architectural commits unless intentionally needed.

The checkout is the GeoGebra GitHub mirror at the recorded revision above. The upstream README says the repository contains GeoGebra math-app source and documents distinct desktop and web launch tasks. Desktop Classic 5 runs via `:desktop:run`; web development runs via `:web:run` under `source/web`.

## 2. What the code actually looks like

### 2.1 Existing module/build topology

The root `settings.gradle.kts` includes three separate Gradle builds: `source/shared`, `source/desktop`, and `source/web`; it also includes `source/build-logic` for convention plugins. Desktop and web each include the shared build. Shared itself includes `source/openrewrite`. Therefore this is a **Gradle composite of independently configured builds**, not a single flat multi-project build and not a single undifferentiated Java monolith.

The shared build already has modules such as `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, `keyboard-base`, `keyboard-scientific`, `ggbjdk`, and `giac-jni`. Desktop has `desktop`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, and `jogl2`. Web has `web`, `web-common`, `web-dev`, `canvas-web`, `renderer-web`, `editor-web`, keyboard modules, and GWT tooling/modules. That structure is evidence of platform/module separation, but Gradle project boundaries alone do **not** guarantee stable public APIs, runtime isolation, independently installable extensions, or safe third-party evolution.

For example, `source/shared/common/build.gradle.kts` exposes editor, renderer, and canvas modules as API dependencies and uses the keyboard module internally. The desktop application depends on shared `common`/`common-jre` plus desktop-specific canvas/editor/Jogl modules and native JOGL/Giac runtime artifacts. This suggests a useful existing seam—shared mathematical/domain code versus platform adapters—but also shows that desktop assembly brings in native/platform concerns. The web side has its own GWT and dev-mode modules; it is not just a browser skin over the desktop module.

### 2.2 Consequence for the flexibility goal

There are at least four separate kinds of modularity to design for:

| Modularity | Meaning | Present state / implication |
|---|---|---|
| Build-time | Can teams build/test subcomponents separately? | Partly present through Gradle composite builds and subprojects. |
| Source/API | Can implementation change behind stable contracts? | Must be audited; Gradle module names do not establish API discipline. |
| Runtime extension | Can an installed module add capabilities to a running product? | No evidence in the inspected build of an Eclipse-style extension registry or loader. |
| Product composition | Can different student/teacher deployments select features without forking GeoGebra? | Best started in the GeoGebraPlus shell, with feature/configuration contracts. |

The project should not equate “many Gradle modules” with “Eclipse-like extensibility.” Eclipse's important properties are explicit bundle dependencies, versioned exported APIs, extension points/registry, lifecycle and resolution, and tooling. Replicating all of this is a product/runtime decision, not an IDE import setting.

## 3. Assessment of Gemini's proposals

### 3.1 Web shell + official JavaScript API — recommended first

**What Gemini proposes:** keep the applet intact; develop a separate React/Vue/JavaScript host and communicate through the official API.

**Assessment:** This is the best first architecture for GeoGebraPlus, and it matches the already drafted evolution spec in `02-Cdc\Cdc_Evolution_GeoGebra_GROK_V1.md`. It avoids a kernel fork and preserves the browser runtime GeoGebra already builds. GeoGebra's official integration project documents embedding math apps and interacting with them through a JavaScript API. It gives a direct integration surface for the planned notebook bridge and does not require students to install a local JDK.

**Important limits:** this API is an *integration boundary*, not an internal plug-in system. It does not by itself allow arbitrary modules to inject new kernel algorithms, replace internal views, or extend the CAS. It also does not make the GeoGebra web applet's internals independently replaceable. The host should own student workflow, activity packaging, persistence, identity/session linkage, feature toggles, and Wims handoff; GeoGebra should own the geometry/3D figure. Define a narrow adapter with command allowlists, typed values, events, timeouts/errors, applet/API version compatibility, and a security policy. Avoid giving notebook code unrestricted execution against the page.

**Recommendation:** proceed with a 2D proof-of-concept wrapper first, then confirm the documented API can satisfy actual teacher/student workflows before adding a bridge or forking anything. Treat 3D parity, save/load behavior, offline behavior, accessibility, and browser compatibility as validation criteria, not assumptions.

### 3.2 Java SPI — useful for a narrow static extension contract, not Eclipse parity

Java `ServiceLoader` is a simple provider-discovery mechanism. It can be useful when a host explicitly enumerates implementations of a stable Java interface, especially for statically packaged providers or controlled deployments. It is not a full plug-in platform: it does not supply the Eclipse extension registry/UI, a dependency resolver, a feature/update mechanism, capability permissions, or lifecycle isolation.

**Recommendation:** use SPI only for a small, stable internal provider seam if requirements call for implementations chosen at startup and shipped together. Do not present it as “Eclipse-like” or use it as a reason to modularize the whole kernel prematurely.

### 3.3 PF4J — plausible alternative for a new Java host, not automatically for GeoGebra

PF4J offers a plug-in manager and classloader-based plug-in loading, so it is more than SPI. But inserting a plug-in framework into the existing desktop application does not automatically solve API stability, access control, dependency compatibility, kernel service boundaries, GWT sharing, or native library isolation. Classloader separation can itself be difficult when plug-ins exchange GeoGebra model objects and libraries.

**Recommendation:** consider PF4J only if a new Java-hosted GeoGebraPlus desktop product is selected and the extension requirements fit its runtime model. Test one harmless external extension and one dependency/version conflict first. It is not the appropriate first move for the web applet integration path.

### 3.4 OSGi/Bnd/Equinox — closest technical match to Eclipse bundles, highest migration burden

Eclipse plug-ins are OSGi bundles with manifests and explicit dependencies; Eclipse adds extension points/registry, features, and PDE tooling. OSGi/Equinox is thus the closest match to the request for Eclipse-like runtime extensibility. Bnd can help generate/verify OSGi metadata in builds, but it does not eliminate the underlying refactoring or resolve semantic boundaries automatically.

To move existing Java code into bundles, likely work includes: identify exported API packages; version API and implementation; eliminate or control cycles and split packages; declare imports/exports; handle reflection/resources/service loading; redesign static/global singleton assumptions; make startup/shutdown and service lifecycles explicit; integrate native libraries (Giac/Jogl); and validate class/resource loading in Equinox. Desktop's native and Java platform integration makes this especially nontrivial. The web/GWT tree is a separate problem: browser Java is compiled/linked into GWT modules, and an OSGi runtime does not execute in the browser. OSGi could at most host/build selected server or desktop-side components; the browser extension story still needs a web module system and API.

**Recommendation:** if the eventual non-negotiable requirement is independently installable Java extensions with Eclipse-style lifecycle/registry, run an OSGi spike on a *small non-kernel subsystem* first. Do not convert all source packages into bundles before defining the public extension contract and proving a build/release path. Do not confuse “use Eclipse IDE” with “adopt Equinox.”

### 3.5 JPMS — good encapsulation support, not an extension marketplace/runtime

JPMS modules help declare module dependencies and encapsulate packages at compile/runtime boundaries. They do not provide Eclipse extension points, plug-in installation/update, or a plug-in lifecycle. Existing dependencies, reflection, automatic modules, native libraries, and deployment packaging would require inspection. JPMS could complement a future architecture, but it does not replace OSGi for Eclipse-style dynamic plug-ins and is not needed for the web-shell MVP.

### 3.6 WebSocket/local bridge — defer until an actual notebook use case proves it

A local WebSocket bridge can connect a separately running notebook kernel to a browser/app process, but adds process startup, authentication, origin controls, transport errors, versioning, and lifecycle burden. The current student-tool draft already proposes beginning with the browser JavaScript API and delaying the bridge. Keep that sequencing. Start with a same-page, narrow, typed message adapter; use WebSocket only if notebook execution cannot reasonably communicate through the host page or a supported Jupyter extension mechanism.

### 3.7 Eclipse IDE import — feasible development workflow, separate from migration

The repository is Gradle-first and explicitly documents IntelliJ/command-line workflows. Importing the Gradle builds into Eclipse via Buildship is a developer-workspace experiment; it does not alter source architecture. However, this checkout's nested included builds/composite topology is more complex than a conventional single Gradle root. Validate how the installed Eclipse/Buildship version imports and synchronizes each included build and GWT task configuration. Even if import is imperfect, running Gradle tasks from Eclipse terminals/external tools remains possible while keeping Gradle authoritative.

Do not replace Gradle with PDE/PDE Build solely to get an Eclipse workspace. Doing so would duplicate build logic, native packaging, GWT compilation, generated sources, and CI configuration. A migration to Eclipse RCP should be justified by runtime extension/product-distribution requirements, not by editor preference.

## 4. Corrections and caveats in Gemini's note

1. **“Java/GWT monolith” is too broad.** The source has numerous Gradle subprojects and three included platform/shared builds. “No discovered plug-in platform” is the safer statement; internal componentization exists, while customer-facing runtime plug-ins are not demonstrated.
2. **Eclipse IDE and Eclipse application are different.** Gradle/Buildship import is not a migration. Equinox/PDE/RCP changes the runtime and product packaging.
3. **OSGi does not modularize GWT in the browser.** Web modules have GWT-specific compilation and linking. A desktop OSGi port and browser modularity require separate designs.
4. **License statement needs correction and legal review.** Gemini's GPLv3 statement conflicts with GeoGebra's current official licensing information, which states source code is EUPL 1.2 and identifies separate terms for product materials and language/UI files. Official license terms also distinguish commercial use based on the use and product components. Do not infer that “educational” automatically means non-commercial in every deployment; assess the intended Wims/institution/hosting/business model and included assets with counsel/GeoGebra. This report is not legal advice.
5. **Version claims are outside this code review.** Gemini's Classic/Android version-number assertions are not necessary to the architecture decision and should be verified independently before they enter a requirements baseline.
6. **PF4J/JPMS are options, not defaults.** Their selection depends on runtime requirements and API boundaries, not only Gradle usage or Java version.

## 5. Proposed target architecture (phased, reversible)

### Phase A — retain upstream source and establish constraints

- Keep the clone as a read-mostly upstream reference and use a small, clearly separated integration repository/project for GeoGebraPlus unless a specific source patch is proven necessary.
- Track upstream revision, patch set, provenance, licenses, and asset origins.
- Confirm whether “Eclipse-like” means IDE tooling, extensible authoring environment, installable runtime plug-ins, or all three.
- Test Eclipse/Buildship import without changing Gradle build files; record which composite projects and tasks resolve.

### Phase B — extension-ready GeoGebraPlus shell

Define a host core with a manifest/configuration model and a typed capability registry. Initial capabilities can be `GeometryApplet`, `ActivityStorage`, `NotebookLink`, and `SubmissionAdapter`; the initial applet adapter can be the official GeoGebra JavaScript API. Keep capabilities behind interfaces and versioned contracts, but avoid a general-purpose arbitrary-code plug-in loader in the first release.

The host should support selecting 2D vs 3D, activity modes (explore/construct/locked), a figure id, `.ggb` load/save, a safe subset of reads/writes/commands, reset, error/event reporting, and a replaceable persistence/submission adapter. Notebook and Wims integrations remain adapters rather than dependencies inside GeoGebra's kernel.

### Phase C — prove feature composition

Create two independently selectable extensions/configurations (for example, 2D and 3D applet adapters or one adapter with explicit configuration). Demonstrate that a test host can replace the storage/submission adapter without editing the applet adapter. This validates real modularity at the product boundary before taking on kernel modularization.

### Phase D — decision gate for internal runtime plug-ins

If and only if requirements show a need to add third-party in-process Java functionality to the desktop kernel, compare:

- **OSGi/Equinox:** best semantic fit for Eclipse-style extension points, but likely substantial refactoring and no direct browser solution.
- **PF4J:** simpler Java plug-in host candidate, but still requires explicit API design and classloader testing.
- **SPI:** simplest controlled/static provider mechanism.
- **JPMS:** encapsulation/dependency mechanism, not a dynamic extension system.

The spike must implement one extension end-to-end, prove dependency/version behavior, shutdown/restart, service replacement, native-library behavior, packaging, unit/integration tests, and an upgrade from one upstream revision. Estimate the cost of maintaining patches against upstream before greenlighting a core fork.

## 6. Decision matrix

| Option | Flexible student product | Eclipse-like dynamic runtime | Works with web/GWT | Migration risk | Recommendation |
|---|---:|---:|---:|---:|---|
| Eclipse IDE + existing Gradle build | Low by itself | No | Yes as development tooling | Low | Adopt/test now if preferred IDE. |
| GeoGebraPlus web shell + official API | High at product boundary | No, not internal kernel plugins | Yes | Low–medium | **Start here.** |
| Java SPI in desktop | Limited, controlled | No | No browser runtime | Low–medium | Only for a small stable seam. |
| PF4J desktop host | Medium | Partial | No browser runtime | Medium–high | Spike only if desktop plugins required. |
| OSGi/Equinox desktop re-platform | High for Java runtime bundles | Yes | No, separate web design needed | Very high | Conditional future option. |
| JPMS | Encapsulation, not product composition | No | No | Medium | Complementary, not a plugin answer. |

## 7. Questions to answer before freezing the requirements

1. By “migration into Eclipse,” do you mean **editing/building the current code in Eclipse IDE**, or shipping an **Eclipse RCP/Equinox application** that hosts GeoGebra?
2. Must third parties be able to install extensions **at runtime without rebuilding**? If so, for which users: developers/teachers, or students?
3. What may an extension add or replace: toolbar/tools, views, geometry algorithms, CAS commands, file formats, notebook adapters, submission backends, or arbitrary code? Rank these.
4. Is GeoGebraPlus primarily **web-only**, or must it also deliver a native desktop app? Are offline use and local deployment hard requirements?
5. Must the student-facing product embed the upstream applet/assets, or is it acceptable to use a separately hosted applet? What are the licensing/commercial distribution constraints for the actual Wims/organization deployment?
6. Are teachers expected to create/install extensions, or should they only select prebuilt modules/features in activity manifests?
7. What are the first two real use cases that would prove “Eclipse-level flexibility,” and what would count as success (e.g. new 3D tool without kernel fork, new notebook provider, custom toolbar, independently upgraded extension)?
8. Is maintaining a long-lived fork of upstream GeoGebra acceptable, including rebasing, testing, and licensing review, or is the preferred policy to keep upstream changes to zero unless API limitations are demonstrated?

## 8. Proposed next step

Answer questions 1, 2, 4, and 5 first; they decide whether this is an IDE setup, a modular web product, or a runtime re-platform. In parallel, perform a short Eclipse/Buildship import test without touching the source build, and a web-app API prototype for one 2D `.ggb` activity. Do not begin PF4J/OSGi conversion until those tests and the extension use cases are agreed.

## References

- Local code: root `settings.gradle.kts`; `source/shared/settings.gradle.kts`; `source/desktop/settings.gradle.kts`; `source/web/settings.gradle.kts`; `source/shared/common/build.gradle.kts`; `source/desktop/desktop/build.gradle.kts`; root `README.md`.
- GeoGebra official embedding/API integration: https://github.com/geogebra/integration and https://geogebra.github.io/docs/reference/en/GeoGebra_Apps_API/
- GeoGebra official licensing information: https://www.geogebra.org/license and https://github.com/geogebra/legal/blob/main/geogebra_license.md
- Gradle composite-build model and limitations: https://docs.gradle.org/current/userguide/composite_builds.html
- Eclipse plug-ins/OSGi and extension points: https://help.eclipse.org/latest/topic/org.eclipse.pde.doc.user/concepts/plugin.htm
- Eclipse PDE overview: https://help.eclipse.org/latest/topic/org.eclipse.pde.doc.user/guide/intro/pde_overview.htm

---

## Addendum: assessment of `Q&A_Architecture_ALF_v1.1.md`

**Reviewed:** 28 October 2026. This addendum records the owner's answers and updates the recommendation. It does not treat the technical assertions copied from Gemini as verified facts.

### A. Decisions now established

- The target is a **desktop Eclipse RCP/Equinox product**, not merely Eclipse IDE as the editor.
- A **web student version is also mandatory**; this is a dual-runtime product, not “RCP instead of GWT.”
- Runtime install/uninstall/hot-swap is not required. Developer/admin packaged extensions and restart/rebuild are acceptable.
- Teachers select prebuilt features/configurations; they do not develop plug-ins.
- Preserve all GeoGebra-native capabilities, including Algebra View and CAS. Jupyter is complementary and must not replace or disable those capabilities.
- Long-lived upstream source modifications are rejected.
- First extension use cases: (1) WIMS/XWims or JSON evaluation/submission adapter; (2) domain-specific algorithms such as physics/discrete mathematics.

This supersedes the earlier product split where Algebra/CAS and other non-graphical work were explicitly assigned to notebooks. Update `Cdc_Evolution_GeoGebra_GROK_V1.md` and the student-tool specification before treating either as a baseline.

### B. Main architectural contradiction to resolve

The requirements are coherent if separated into **extension planes**, but not if one assumes that a single OSGi bundle set can serve both desktop and browser unchanged:

1. **Desktop plane:** Equinox-hosted Java extensions can add views, UI integrations, backend adapters, and domain algorithms, subject to a stable GeoGebra-facing API.
2. **Web plane:** Browser extensions must be JavaScript/TypeScript modules or host-side web adapters. Browser apps cannot load desktop OSGi bundles as runtime plug-ins. “Web: only in Java” needs clarification: compiled Java via GWT, JavaScript generated from Java, or JavaScript/TypeScript web extensions are different constraints.
3. **Shared domain plane:** Pure mathematical/domain services can potentially be shared if they are compatible with both Java desktop and GeoGebra's web/GWT compilation constraints. The current `common` module is not automatically a clean, UI-free model layer merely because it is named `common`.
4. **Evaluation plane:** A WIMS/XWims JSON backend should be a transport/schema adapter around a stable activity/submission contract; it should not depend on or be allowed to alter GeoGebra's internal construction graph.

Therefore “all desktop extensions” and “the same extension works on web” should not be promised. Define separate extension packaging and API compatibility for desktop and web, and share only interfaces/data schemas where technically feasible.

### C. Corrections to the Gemini answers

#### C1. Official JavaScript API limitations are partly outdated or overstated

The listed limitations do not justify assuming that the official API is obsolete or cannot support the first web version. The current official API documentation includes an ES module injection example where `getAPI()` resolves as a Promise, and it shows an API object passed into `appletOnLoad`. It also documents explicit applet IDs for multiple instances, typed getters/setters, object events, state serialization (`getFileJSON`, `.ggb` Base64), and view/API control. The docs do confirm a global `ggbApplet` compatibility path and document imperative listeners, so a wrapper that avoids globals and turns callbacks into local reactive streams is sensible. [GeoGebra Apps API](https://geogebra.github.io/docs/reference/en/GeoGebra_Apps_API/)

Some concerns require reproducible tests against the **exact distribution/version and browsers** before acceptance: layout/responsive behavior, mutation ordering under rapid operations, command/event consistency, and memory/cleanup for multiple applets. “No official TypeScript types” may justify maintaining local typed definitions; it does not require changing GeoGebra internals. The report should not state Promise support or globals are universally absent: both module-style and callback/global-compatible integration modes exist in the current docs.

#### C2. `Algo*` is not the Jupyter notebook

GeoGebra's `AlgoElement` types are part of its construction dependency/evaluation machinery. Calling them the “notebook” confuses GeoGebra's mathematical kernel with Jupyter notebooks. Jupyter can provide a separate computation environment, but it does not become the GeoGebra kernel/model by naming or architecture. Any custom `Algo*` that is meant to behave as a native construction algorithm must participate in object creation, command parsing/dispatch, dependency updates, serialization/deserialization, undo/redo, and view/API exposure. An OSGi bundle cannot inject this behavior merely by being registered as an extension if core does not expose extension points at those seams.

That makes the “physics simulator or advanced discrete-math tool adds a new native `Algo*` without changing upstream” use case the **highest-risk requirement**. A desktop-only Java service that computes results and publishes them through a supported host API is much more feasible than a new kernel algorithm that acts exactly like a built-in GeoGebra algorithm. These must be treated as different acceptance levels.

#### C3. Wrapper bundles/fragments are not a no-change plug-in solution

Wrapping an existing JAR as an OSGi bundle can make it resolvable in Equinox, but it does not create good modular APIs or runtime extension points. It can leave the whole `common` module as one large, tightly coupled bundle. OSGi fragments are attached to a host bundle and are suited to host augmentation/resources/platform-specific content; they are not a general, upstream-safe mechanism for adding arbitrary new classes and making core discover or execute new algorithm types. New core extension hooks still need to exist somewhere, or the product must adapt externally through APIs already exposed by GeoGebra.

“No split package” is a valid OSGi concern, but wrapping `common` intact does not prove resolution is clean. Need inventory package ownership across every JAR on the proposed runtime classpath, dependencies, reflection/service loading, resources, native libraries, and GWT-only code. An actual Equinox launch and resolution test is required. Also distinguish **package split** (same Java package spread across bundles) from ordinary code dependencies between packages/bundles.

#### C4. Dropping GWT is not the selected strategy

The final answers explicitly retain a browser version. Therefore “drop GWT” cannot mean eliminating web support. A new JavaScript wrapper can improve the host integration, but it does not modernize the compiled GeoGebra application itself. Options are: (a) retain upstream GWT web app and improve host/API adapter; (b) rebuild/replace the web client while reusing only web-compatible core components; or (c) share backend/service schemas while treating desktop and web clients as separate implementations. Each has different fidelity, effort, and upstream-merge implications.

If the absolute requirement is that every GeoGebra-native feature remains fully functional on both clients, preserving the existing GWT app initially is the least risky baseline. A replacement web client would require a feature-by-feature parity specification and substantial validation.

#### C5. Eclipse/Java compatibility statement in Q&A is stale

The assertion that current Eclipse supports only Java 21 and Java 25 support is merely a future possibility is no longer accurate as of this report date. Eclipse's official 2026-09 release listing includes Java execution-environment metadata through JavaSE-25 (and later values). That does **not** automatically prove compatibility of this particular Gradle composite, Buildship, annotation processors, GWT, native JOGL/Giac, or the packaged RCP. Verify each matrix independently. [Eclipse 2026-09 release metadata](https://download.eclipse.org/releases/2026-09/202609091000/buildInfo/archive/download.eclipse.org/releases/2026-09/202609091000/)

### D. Revised recommendation

Adopt a **dual-host architecture** with one explicit product contract and separate runtime adapters:

```text
                   Activity / extension manifest
                       (versioned JSON schema)
                                 |
          +----------------------+----------------------+
          |                                             |
  GeoGebraPlus Desktop                         GeoGebraPlus Web
  Eclipse RCP / Equinox                         browser host + JS adapter
          |                                             |
  desktop extension APIs                       web extension APIs
          |                                             |
  GeoGebra desktop/common code                 GeoGebra GWT app/API initially
          +----------------------+----------------------+
                                 |
              shared activity / evaluation contracts
              (not shared OSGi bundles in the browser)
                                 |
                    WIMS / XWims backend
```

Keep the upstream clone unchanged. First define shared contracts for activity configuration, evaluation payload, submission lifecycle, capability discovery, and error reporting. Then prototype a desktop RCP host around one **non-invasive** extension (for example, an XWims backend adapter) and a web host around the official GWT app/API. This provides useful extensibility without claiming that GeoGebra's internal kernel is already plug-in-ready.

Treat adding new native `Algo*` classes as a separate feasibility decision. The choices are: (1) implement domain algorithms outside GeoGebra and render/import their outputs through supported APIs; (2) maintain a small, explicit upstream extension hook (but this conflicts with the “no upstream changes” constraint); or (3) undertake a full kernel fork/rearchitecture (currently rejected). Do not claim the use case is met until a spike proves registration, persistence, dependency propagation, undo/redo, and web behavior end-to-end.

### E. Recommended next engineering deliverable

The previous Q&A suggested “package cut of `common`” as the first task. Given the new dual-runtime requirement and no-fork rule, make the next deliverable a **GeoGebra Extension Feasibility and Boundary Report**, not an OSGi package split alone. It should include:

1. Dependency/package map for `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, platform modules, GIAC/Jogl natives, and GWT-dependent classes.
2. Candidate public API boundary and package ownership/versioning plan for Equinox; classify internal vs exported APIs.
3. One thin RCP host prototype with wrapped upstream artifacts, bundle resolution report, `common` construction startup smoke test, and native/JNI smoke test.
4. One web prototype using the documented `mathApps`/`getAPI()` path, including two simultaneous applets, load/save, event cleanup, and responsive sizing.
5. WIMS/XWims JSON contract prototype independent of UI and kernel implementation.
6. Explicit verdict on custom native `Algo*` extensibility without source changes; no hand-waving through fragments.

Only after this boundary report should the team decide whether to implement the WIMS backend adapter, browser wrapper, or kernel algorithm extension spike first. The package map is an input to the RCP spike, not proof that an RCP conversion is feasible.

### F. Questions still needing owner clarification

1. For “web extensions only in Java,” do you mean the web app must remain **GWT-compiled Java**, or can web-only add-ons be **JavaScript/TypeScript** while the underlying GeoGebra app remains GWT?
2. Do custom physics/discrete-math algorithms need to be true native `AlgoElement`s participating in the GeoGebra construction graph, serialization, undo/redo, and dependencies—or can they be separate services that publish results through the app's supported APIs?
3. Must the desktop RCP and web app have **feature parity**, or is the desktop allowed to have additional developer extensions while the web keeps the complete standard GeoGebra feature set plus only a smaller extension set?
4. Does “all native features remain available” mean feature parity with the existing desktop and web products, or specifically preserving every feature of the current Classic 5 checkout? Which baseline/version and automated acceptance suite should define “all”?
5. Can product-specific extension hooks live in a separate GeoGebraPlus host/API layer, or does “extensions” require adding new capabilities inside upstream `common` itself?
6. Is the runtime expected to load all extensions at startup from a prebuilt product, or can each product build be assembled from a selected set of bundles before distribution?

---

## Addendum 2: formal decisions in `Decisions_Architecture_ALF_GROK_V1.2.md`

**Reviewed:** 28 October 2026. This decision note resolves the open questions above. The architecture direction is now clear enough to frame a feasibility study, but not yet to begin implementation of a new web engine or plugin API.

### G. Confirmed decisions

1. **Eclipse IDE 2026-09** is the development workbench. The shipped desktop client is a standalone **Eclipse RCP/Equinox** application.
2. **GWT is to be dropped** in the target web client. A dual study is required: Java-to-web alternatives and native JavaScript/TypeScript extensions.
3. Teachers only select/configure prebuilt features and evaluation schemas. They do not create, compile, or install code extensions.
4. The upstream `source/shared/common` source must not be modified or split/moved. The intended desktop approach is a wrapper bundle around the intact module.
5. Custom physics/discrete-math algorithms should compute outside GeoGebra's `AlgoElement` hierarchy and exchange results through supported APIs.
6. Desktop and browser must retain end-user feature parity for Algebra View, CAS, 3D, Spreadsheet, 2D, and the standard toolset.
7. Extension hooks belong in the separate GeoGebraPlus host, including controlled exchange with WIMS and Lean 4; no hook is to be added inside `common`.
8. Extensions should be discovered/resolved at application startup (e.g. OSGi service registry on desktop). This is consistent with no hot-swap requirement: it means startup composition, not runtime installation while an activity is open.

These choices confirm the **two-host model** proposed in Addendum 1: desktop Equinox host and separate browser host, with shared versioned activity/evaluation contracts rather than an assumption that OSGi bundles themselves run in browsers.

### H. Important feasibility findings implied by these decisions

#### H1. Replacing GWT while preserving every GeoGebra feature is the dominant risk

Dropping GWT removes the existing browser compilation/runtime path. It does **not** turn the Java core into a browser-ready library, nor does an OSGi wrapper solve browser execution. To keep full feature parity, the web study must compare at least:

- **Java-to-web continuation/replacement:** whether the required Java code can be compiled to a maintained browser runtime and what unsupported APIs, reflection, threading, GIAC/CAS, graphics, 3D, and native dependencies must be replaced.
- **Web client rewrite:** whether GeoGebra's current web app can be wrapped/reused as a component without retaining GWT internally, versus rewriting views and UI around an embeddable core.
- **Separate web implementation:** whether desktop and web hosts share only data, activity, and evaluation contracts while maintaining independent client implementations.

The browser's standard GeoGebra capabilities need a feature-by-feature parity matrix and automated regression corpus before selecting a direction. “A JavaScript wrapper” alone only modernizes the host integration; it cannot be claimed to replace the GWT client.

#### H2. Wrapper bundle strategy must be tested at artifact level

Keeping the source module untouched is a good upstream-maintenance constraint. However, “wrap the intact `common` module” is not yet a proof of an OSGi-clean system. Establish exactly which Gradle artifacts comprise the core at runtime, whether dependencies are embedded or separately wrapped as bundles, package ownership across artifacts, imports/exports, resources, reflection, service loading, and JNI/native loading. A single wrapper around one JAR can preserve its code but will not automatically resolve duplicated packages or create a stable API for external bundles.

Do not split or relocate upstream packages. Start with one OSGi bundle boundary around the intact core artifact(s), then report any package collision or dependency that blocks Equinox. Any proposed workaround must preserve upstream files and be tracked as build/packaging metadata outside the upstream source tree.

#### H3. “External algorithm” needs a precise data contract

The decision to keep custom algorithms outside `AlgoElement` is feasible in principle, but “exchange results through supported APIs” needs an explicit contract: input types, outputs, units/coordinate systems, precision, object identity, update triggers, errors, versioning, and persistence. The GeoGebra Apps API can set values, evaluate commands, read construction state, and listen for events; it does not thereby make an external algorithm a native dependent construction object. If a computed result must update continuously as a construction changes, define an adapter that listens to declared inputs and writes named outputs, including stale-result/error behavior. Avoid exposing unrestricted command execution to teacher-authored or remote modules.

#### H4. Startup discovery should be trusted and deterministic

Because teachers do not install code, discovery can be controlled by product manifests or administrator-managed extension directories. At startup, resolve only trusted, allowlisted extensions with pinned versions and declared capabilities; log the resolved set and fail safely on missing/incompatible modules. For web, load only approved same-origin or otherwise integrity-verified modules. Do not interpret a JSON activity manifest as permission to execute arbitrary remote JavaScript. OSGi service discovery and web module discovery are separate mechanisms and should expose equivalent product-level capabilities, not promise identical binaries.

#### H5. Feature parity is a baseline and scope problem

“All current features” changes as upstream evolves. Freeze a reference version/commit and enumerate acceptance criteria by view and interaction: Algebra, CAS, 2D Graphics, 3D Graphics, Spreadsheet, tool sets, file open/save (`.ggb`), scripts, import/export, undo/redo, accessibility, and offline operation. The current local checkout at `375db7faf54` is a reproducible initial baseline, but the owner must decide whether that exact checkout or a named official stable release defines parity. Pinning the baseline prevents a moving target and distinguishes preserving current behavior from adding future upstream features.

### I. Revised work order

The earlier proposed package-cut-only task is superseded. With GWT removal and full web parity now explicit, the work should be ordered by architectural risk:

1. **Freeze baseline and parity tests:** pin the GeoGebra reference revision and inventory existing desktop/web features, especially CAS, Spreadsheet, 3D, file I/O and scripting.
2. **Run the dual web feasibility study:** compare Java-to-web and JS/TS extension paths against that parity matrix. Include CAS/GIAC, renderer, 3D, and offline requirements; deliver a recommendation with a feature gap table and cost/risk estimates.
3. **Run an Equinox wrapping spike:** without moving/modifying `common`, wrap the intact artifacts, launch a minimal RCP, resolve all bundles, and smoke-test construction, CAS, 2D/3D, Spreadsheet, `.ggb`, GIAC/JNI, and JOGL where applicable.
4. **Specify host-level extension contracts:** activity manifest, capability metadata, extension discovery and trust policy, GeoGebra state adapter, external-algorithm input/output protocol, WIMS/XWims submission, and Lean 4 adapter.
5. **Implement one vertical slice on both clients:** one prebuilt feature selected by an activity manifest; one external computation round-trip; one WIMS JSON submission; identical observable student behavior on desktop and web.
6. **Only then decide productization:** if full parity cannot be achieved on the chosen replacement web stack, retain the existing GWT app temporarily or revisit the no-GWT decision explicitly rather than quietly shipping a reduced product.

### J. Remaining decision to lock

The document states full parity against “the official stable release” but does not name a version. Please select one of these as the acceptance baseline: **(a)** the local source revision `375db7faf54`, **(b)** a named GeoGebra Classic stable release, or **(c)** a later pinned upstream commit. Until pinned, feature-parity estimates and test acceptance are not reproducible.
