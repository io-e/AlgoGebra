# Task D — Eclipse RCP (Path A) vs Embedded Equinox (Path B)

**Repository:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Revision:** `375db7faf54` (`main`)  
**Architecture authority:** `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`  
**Date:** 28 October 2026  
**Decision:** **Path A — build the shipped desktop product as an Eclipse RCP/Equinox application.** Treat Path B, if used at all, only as a short-lived technical probe, not the product architecture.

## Recommendation in one paragraph

Path A is the only option consistent with the closed owner decision: “Shipped desktop product is RCP/Equinox.” Its practical cost is real—Bnd metadata, package wiring, Swing/SWT embedding, and preserving JOGL/GIAC's application-loader arrangement. But those costs are on the product’s required path, so choosing Path B would create a technically easier prototype that still fails the shipping requirement. Keep the GeoGebra Gradle build as the canonical upstream build, put RCP/Bnd integration in a separate adapter/product workspace, expose a small GeoGebraPlus host API rather than exporting the whole kernel as an extension API, and validate D-02 through D-05 before committing to deeper bundle segmentation.

**This is a scored architecture recommendation, not a performance test.** Startup scores and bundle complexity are estimates; no RCP product launch, Equinox resolution or startup benchmark has yet passed. Task E is the only execution evidence so far: common-jre passes; desktop has one locale-sensitive failure on the captured local environment.

## Evidence used

- The V2 architecture explicitly binds the shipped desktop to RCP/Equinox, requires upstream `common` to remain unmodified, keeps JOGL/GIAC native classifier jars on the application loader, and marks D-01 through D-10 as **NOT RUN**.
- GeoGebra has 15 Gradle source modules. The audited built-jar inventory has 14 module jars (no built `xr-base` jar); the production desktop graph resolves 12 GeoGebra project outputs including `desktop` itself.
- There is no current OSGi metadata in module jar manifests. Task B found only 4 of 39 external runtime coordinates with a `Bundle-SymbolicName`; the remaining external jars need generated metadata, wrapping, or a deliberately supported app-loader path.
- Source package ownership found **one actual split**: `org.geogebra.desktop.geogebra3D.euclidian3D.opengl`, divided between `desktop` and `jogl2`. The claimed split of exact package `org.geogebra.common` across `common`, `common-jre`, and `canvas-base` is not present in the source scan.
- `GeoGebraPanel` is a public `JPanel` with a public no-argument constructor. Eclipse’s `SWT_AWT.new_Frame` API provides the bridge, but the Composite must use `SWT.EMBEDDED` and the API documents event/cursor caveats. No embedding test has run.
- Installed Eclipse at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` contains Equinox `3.24.300`, SWT `3.135.0`, launcher `1.8.0`; its `eclipse.ini` requires Java 25. GeoGebra compiles under Java 17 conventions; `:desktop:run` selects Java 25.
- The runtime graph and package evidence are in `Audit_A_Package_Ownership_CODEX_V1.md`, `Audit_B_Module_Dependencies_CODEX_V1.md`, and `Audit_C_OSGi_Wrapping_CODEX_V1.md`. Baseline results are in `Audit_E_Test_Baseline_CODEX_V1.md`.

## Weighted score

Scale: **1 = poor / high friction, 5 = strong / low friction**. Scores are expert judgement against this checkout and binding V2 decisions, not measured benchmark results. Weights put 30% on meeting the non-negotiable RCP outcome.

| Criterion | Weight | Path A: Eclipse → GeoGebra | Path B: GeoGebra → Equinox | Evidence / rationale |
|---|---:|---:|---:|---|
| Build/integration complexity | 15% | 2 | 4 | A needs bundle recipes/target platform/RCP launch; 14 GeoGebra jar recipes plus external dependencies. B can begin as a Gradle launcher and keep the existing app runtime, but if it modifies `GeoGebra3D.main()` it creates an upstream touch point. |
| Native-loading feasibility | 15% | 2 | 4 | B is closer to the current Gradle classpath and native-copy layout. A must prove that native classifier jars remain visible through the Eclipse/application loader boundary exactly as V2 requires; neither Equinox nor `Bundle-NativeCode` has been demonstrated here. |
| Swing/SWT coexistence | 10% | 2 | 5 | A must embed `GeoGebraPanel` in SWT with `SWT_AWT`, `SWT.EMBEDDED`, cross-toolkit event handling, focus and lifecycle. B keeps Swing and does not need SWT. |
| Upstream compatibility | 10% | 4 | 3 | A can keep wrappers, RCP host and adapters outside the GeoGebra checkout; regenerate/verify package metadata on each pin. B’s proposed change to `GeoGebra3D.main()` is closer to upstream code and the Gradle graph. A separate B launcher would improve B’s score but would not make it RCP. |
| Extension/service integration | 15% | 5 | 3 | A has the Eclipse RCP application/workbench model and OSGi service/extension integration at the host. B can start an Equinox framework and register services, but Swing remains the application shell and host-to-plugin API/classloader sharing must be designed explicitly. |
| Startup-time outlook | 5% | 2 | 4 | A likely starts more Eclipse platform/workbench bundles; B likely starts fewer pieces. There is no measurement, and lazy activation / bundle set could change this result. Low weight until benchmarked. |
| Mandatory RCP product fit | 30% | 5 | 1 | V2 makes RCP/Equinox the shipped desktop architecture. A directly satisfies it. B is an OSGi-enabled Swing program, not the required Eclipse RCP product. |
| **Weighted total** | **100%** | **3.55 / 5** | **2.95 / 5** | Calculation = sum(weight × score) / 100. |

### Sensitivity

If the product requirement were relaxed to “Swing desktop plus an OSGi service container,” Path B would likely win on native continuity, short-term build effort and startup. That is **not** the accepted requirement in V2. If D-02/D-04/D-05 shows that Path A cannot satisfy native/UI requirements without violating the no-`common`-edit rule, stop and return to the owner for a new architecture decision; do not silently ship Path B as “RCP.”

## Architecture comparison

### Path A — Eclipse RCP product embedding GeoGebra

**Recommended product shape**

```text
Eclipse RCP product / Equinox (Java 25 runtime)
  ├─ GeoGebraPlus RCP host (IApplication, policy, allowlist, services)
  ├─ SWT shell + SWT_AWT bridge
  │    └─ GeoGebraPanel (Swing; upstream desktop API)
  ├─ GeoGebra package bundles from current Gradle artifacts
  │    ├─ common, common-jre, canvas/renderer/editor/keyboard modules
  │    ├─ desktop bundle + jogl2 fragment (or merge)
  │    └─ GIAC Java bridge
  └─ JOGL/GlueGen/GIAC native classifier jars on the application loader
       per Architecture V2; validate exact Eclipse launch arrangement
```

**Advantages**

- Directly meets the RCP shipping decision and provides a real Eclipse product configuration, application entry point and product-level bundle set.
- Keeps the upstream Gradle composite as the canonical build and allows Bnd/RCP packaging artifacts to live outside the GeoGebra repository.
- Provides a natural place for the GeoGebraPlus host to enforce extension allowlisting and register approved extension services.
- Existing `GeoGebraPanel` avoids rewriting the desktop UI as SWT up front.

**Costs / risks**

- The core is not modularized for OSGi. Module Gradle edges are not package-level OSGi manifests; imports/exports and `uses` constraints still need Bnd and resolver analysis.
- The actual `desktop`/`jogl2` package split needs fragment/merge packaging.
- Only 4/39 external runtime coordinates had a BSN in the exact jars inspected; a complete product target requires a broader dependency and licensing inventory.
- Native loading is the gating risk under the accepted “application-loader” plan. The JOGL user guide documents native extraction without `java.library.path` when the JogAmp jars remain unmodified in a common directory; that is helpful evidence but does not prove Eclipse/Equinox classloader behavior. GIAC explicitly calls `ClassLoader.getSystemResourceAsStream`, which must still see the native resource.
- SWT_AWT event focus, clipboard, resize, DPI, shutdown and toolkit threading are untested. `GeoGebraPanel` itself does not prove the RCP bridge is robust.

### Path B — GeoGebra Swing main with embedded Equinox

**Possible shape**

```text
GeoGebra Gradle desktop runtime / Swing main
  ├─ existing GeoGebra app and current native loader setup
  ├─ new Equinox launcher/bootstrap
  └─ custom service bridge / extension API
```

**Advantages**

- Preserves the existing Swing product shell and Gradle run/classpath behavior, so it is the more attractive way to test whether Equinox can discover a small allowlisted service bundle.
- Avoids embedding Swing in SWT, and is likely to offer a smaller initial runtime and lower startup cost.
- Can be isolated in a new launcher module rather than patching upstream `GeoGebra3D.main()`.

**Costs / risks**

- Does not produce an Eclipse RCP product or satisfy the V2 desktop requirement.
- Adding `org.eclipse.osgi` to Gradle does not automatically make the application’s classes visible to extension bundles. If extensions need GeoGebra classes, a package-export/System-Bundle/host-bundle strategy is still needed; otherwise a narrow service SPI can reduce coupling but may be a different extension model.
- The startup lifecycle now couples a Swing app and an Equinox framework: framework shutdown, error reporting, service registration and app shutdown must be owned by the new bootstrap.
- If implemented by changing `GeoGebra3D.main()` as proposed in the handoff, it creates a recurring upstream rebase point. A separate main/bootstrap module is safer but remains a Swing host, not RCP.

## Evidence-qualified recommendation

1. **Choose Path A as the target architecture.** The key reason is the binding RCP outcome, not a claim that A is technically lower risk.
2. **Keep a strict layering boundary:** a separate RCP/host integration project, metadata-only wrappers from the exact GeoGebra jars, and no change to `source/shared/common/src`. Gradle remains the authoritative source build. Use OSGi package wiring, not `Require-Bundle` as a general dependency strategy.
3. **Treat bundle granularity as a staged choice.** Start with only the production runtime package set and a resolver smoke test. If package-level `uses` constraints or resource assumptions make 12 project-output bundles unmanageable, prefer a smaller aggregate core bundle over exposing more internals. Keep `jogl2` as a `desktop` fragment or merge its classes into the desktop wrapper.
4. **Honor the native plan already recorded in V2.** For the first RCP spike, keep native classifier jars on the application loader and in the expected unmodified common directory. If that fails, document the smallest adapter/product change outside `common`; only then evaluate `Bundle-NativeCode` or native fragments.
5. **Implement the RCP host using `GeoGebraPanel` through `SWT_AWT`**, with a `Composite` created using `SWT.EMBEDDED`. Run D-04 and D-05 on a clean Windows x86_64 install before widening platforms or extension APIs.
6. **Do not implement broad direct GeoGebra kernel exports as the permanent extension API.** GeoGebraPlus algorithms remain external services, and activity/host contracts should be narrow, typed and allowlisted as V2 states.

## Executed/unexecuted scenario status

| Scenario | Status from this audit |
|---|---|
| P-02/P-03 test baseline | Executed by Task E, with one locale-sensitive desktop failure; detailed result in `Audit_E_Test_Baseline_CODEX_V1.md`. |
| D-01 import Gradle composite in Eclipse | NOT RUN. |
| D-02 start RCP on complete pinned jar set | NOT RUN. |
| D-03 package ownership | Package scan completed; one actual split found. OSGi resolver result is still NOT RUN. |
| D-04 Swing GeoGebra inside RCP | NOT RUN. |
| D-05 GIAC/JOGL under RCP | NOT RUN. |
| D-06 through D-10 | NOT RUN. |

## Next decision gate / questions for architecture owner

1. Confirm the first supported product target: Windows x86_64 only for D-02/D-05, or Windows/Linux/macOS immediately?
2. Confirm whether `desktop+jogl2` may be emitted as a merged OSGi bundle for the first spike, or whether preserving `jogl2` as a separate Gradle-derived fragment is mandatory.
3. Confirm the intended product/API version policy: mirror GeoGebra `5.4.934.0` for wrapper bundle/package versions, or maintain semantic OSGi API versions separately.
4. Confirm whether a small aggregate GeoGebra core bundle is acceptable if Bnd reveals unmanageable package constraints, provided the RCP host and external service boundary remain modular and `common` source is unchanged.
5. Confirm the first RCP proof criterion: a panel opens, or the full V2 D-02/D-04/D-05 acceptance slice (UI + CAS + 3D + native load-once + logs) before proceeding to extension development.

## Sources

- [GeoGebraPlus RCP/Web validation V2](Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md) — binding product decision and D-01…D-10 validation scenarios.
- [OSGi Core 8 Module Layer](https://docs.osgi.org/specification/osgi.core/8.0.0/framework.module.html) — package wiring, `uses`, `Require-Bundle`, fragments and native code.
- [Bnd wrapping guide](https://bnd.bndtools.org/chapters/390-wrapping.html) — bytecode-derived imports, manifest recipe generation and review of unresolved/optional imports.
- [Eclipse `SWT_AWT` API](https://help.eclipse.org/latest/rtopic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/swt/awt/SWT_AWT.html) — embedded-frame requirements and caveats.
- [JogAmp JOGL user guide](https://github.com/sgothel/jogl/blob/master/doc/userguide/index.html) — native JAR extraction behavior and common-directory constraint.
