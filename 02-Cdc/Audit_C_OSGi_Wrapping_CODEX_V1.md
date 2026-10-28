# Task C — OSGi Wrapping Feasibility and Manifest Drafts

**Repository:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Revision:** `375db7faf54` (`main`)  
**Architecture authority:** `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`  
**Date:** 28 October 2026  
**Scope:** Source/build audit plus isolated Bnd bundle generation and Windows Equinox package-resolution test. No upstream source files or Eclipse installation files were changed; generated artifacts and logs are isolated under `02-Cdc`.

## Executive finding

**Wrapping is feasible as a staged Equinox experiment, but not yet proven as a working RCP.** The critical blocker Claude reported against `org.geogebra.common` is not present in the audited source package declarations. The actual package split is `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` across `desktop` and `jogl2` (5 + 3 classes). Draft `jogl2` as a fragment hosted by the `desktop` bundle, or merge its jar contents into that bundle. Do not install it as an ordinary peer exporter.

This report generated **14 Bnd recipes** under `02-Cdc\osgi-manifest-drafts\`. Bnd processed all **12 production recipes** into bundle JARs with generated `META-INF/MANIFEST.MF` files; the 2 non-production recipes remain drafts. `Import-Package: *` instructs Bnd to calculate imports from bytecode, not to write a literal wildcard import. Equinox successfully resolved the 50-bundle selected set with zero unresolved bundles. This validates package wiring for that provider set, but not bundle activation, reflective/resource lookups, application-loader behavior, or an RCP launch.

The V2 architecture is binding: this should be an Eclipse RCP/Equinox product, `common` must remain unmodified, and JOGL/GIAC native classifier jars stay on the application loader for the first spike. This native-loader boundary must be honored; do not “fix” it by guessing a `Bundle-NativeCode` header.

## Commands and evidence

Recipe generation:

```powershell
python D:\ALF_Agents\G1_Geogebra_Migration\.claude\generate_osgi_manifest_drafts.py
```

Package counts and split ownership are derived from:

```powershell
python D:\ALF_Agents\G1_Geogebra_Migration\.claude\audit_package_ownership.py D:\ALF_ZGit\G1_Geogebra_Migration D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc
```

The file inventory and actual Gradle desktop dependency graph were verified in Task B. Source/runtime checks made for this task:

```powershell
Get-ChildItem D:\ALF_ZGit\G1_Geogebra_Migration\source\shared -Recurse -File -Filter *.jar | Where-Object FullName -match '\\build\\libs\\'
Get-ChildItem D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop -Recurse -File -Filter *.jar | Where-Object FullName -match '\\build\\libs\\'
Get-Content D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop\desktop\src\main\java\org\geogebra\desktop\GeoGebraPanel.java
Get-Content D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop\desktop\src\main\java\org\geogebra\desktop\cas\giac\NativeLibClassPathLoader.java
Select-String -Path D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop\desktop\src\main\java\org\geogebra\desktop\cas\giac\CASgiacD.java -Pattern 'loadLibrary|NativeLib|javagiac'
Select-String -Path D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop\desktop\build.gradle.kts -Pattern 'implementation\(project\(":jogl2"\)\)|natives|Main-Class|Class-Path'
Get-ChildItem D:\ALF_ZGit\G2_Eclipse\01_src\eclipse\plugins -Filter 'org.eclipse.osgi_*.jar'
Get-ChildItem D:\ALF_ZGit\G2_Eclipse\01_src\eclipse\plugins -Filter 'org.eclipse.swt_*.jar'
Get-Content D:\ALF_ZGit\G2_Eclipse\01_src\eclipse\eclipse.ini
```

Official reference documents reviewed: [OSGi Core 8 Module Layer](https://docs.osgi.org/specification/osgi.core/8.0.0/framework.module.html), [Bnd library wrapping guide](https://bnd.bndtools.org/chapters/390-wrapping.html), [Eclipse `SWT_AWT` API](https://help.eclipse.org/latest/rtopic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/swt/awt/SWT_AWT.html), and [JogAmp JOGL user guide](https://github.com/sgothel/jogl/blob/master/doc/userguide/index.html).

## Corrected package-risk statement

The TSV scan covers **15 source modules** (10 shared + 5 desktop), **5,406 main Java files**, **385 unique packages**, and **one split package**. The source module count is 15, not 14. The observed built module-jar inventory contains 14 main jars because `xr-base` was not built in the inspected `build/libs` output; `xr-base` is also not in `:desktop:runtimeClasspath`.

Claude's claimed split `org.geogebra.common` is **not confirmed**:

| Module | Classes declaring the exact root package `org.geogebra.common` |
|---|---|
| `common` | 2: `GeoGebraConstants.java`, `SuiteSubApp.java` |
| `common-jre` | 0 |
| `canvas-base` | 0 |

Actual split:

| Package | `desktop` | `jogl2` | Proposed packaging fix |
|---|---|---|---|
| `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` | 5 classes: `JoglAndGluProvider`, `ManagerGLList`, `RendererCheckGLVersionD`, `RendererImplGL2`, `RendererImplShadersD` | 3 classes: `Animator`, `Component3D`, `RendererJogl` | Make `jogl2` a fragment of `desktop`, or merge both module jars into one bundle. The host exports this package once. |

OSGi does not categorically ban every duplicate package across every installed bundle. An importer gets a single package wiring; OSGi also permits split packages via `Require-Bundle` in limited cases. The spec prefers `Import-Package`/`Export-Package` because bundle-wide coupling and split-package ordering are error-prone. A fragment or merge is the clean fix here; `Require-Bundle` is not the recommended workaround.

The 69 third-party Java source files inside `common` are 10 QuickHull classes and 59 JUNG classes in 13 packages. Keep `com.github.quickhull3d` and `edu.uci.ics.jung.*` **private** in the `common` bundle; do not export them as GeoGebra extension APIs. `org.geogebra.regexp.*` is a GeoGebra-owned package used across modules and should be wired as an internal GeoGebra export/import, not hidden with JUNG.

The package map also shows private implementation/vendored namespaces inside `desktop` (17 packages, including `org.freehep.*`, `org.jfugue`, and `geogebra`). These are left out of the proposed exports. Bnd still needs to confirm no other module imports them.

## Proposed bundle/manifest matrix

All BSNs below use a proposed integration namespace, `org.geogebra.migration.*`, to avoid pretending the names are upstream-issued bundle identities. Bundle version `5.4.934.0` comes from `GeoGebraConstants.VERSION_STRING` at the pinned commit. Export versions are provisional and **not** a compatibility promise. The `.bnd` recipes propose exporting GeoGebra namespaces for the first resolver spike and keeping other in-jar namespaces private; narrow the export surface before release.

| Gradle jar/module | Proposed BSN | Owned packages in map | Proposed exported packages | Packaging notes |
|---|---|---:|---:|---|
| `common` | `org.geogebra.migration.shared.common` | 242 | 228 | Private 14 vendored packages (QuickHull/JUNG). |
| `common-jre` | `org.geogebra.migration.shared.common.jre` | 12 | 12 | Do not infer a root-package split from module name. |
| `renderer-base` | `org.geogebra.migration.shared.renderer.base` | 15 | 15 | Runtime dependency. |
| `editor-base` | `org.geogebra.migration.shared.editor.base` | 13 | 13 | Runtime dependency. |
| `canvas-base` | `org.geogebra.migration.shared.canvas.base` | 3 | 3 | Runtime dependency. |
| `keyboard-base` | `org.geogebra.migration.shared.keyboard.base` | 6 | 6 | Reached by common; validate exact runtime exports. |
| `keyboard-scientific` | `org.geogebra.migration.shared.keyboard.scientific` | 2 | 2 | Built module, not in desktop production runtime. |
| `ggbjdk` | `org.geogebra.migration.shared.ggbjdk` | 5 | 5 | Built/test module; test-only on the current desktop graph. |
| `giac-jni` | `org.geogebra.migration.shared.giac.jni` | 1 | 1 | Java-side/native integration; native classifier jars remain application-loader concern. |
| `desktop` | `org.geogebra.migration.desktop` | 78 | 61 | Bundle host/application code; 17 implementation/vendor packages private. RCP launches an Eclipse `IApplication`, not the jar `Main-Class`. |
| `canvas-desktop` | `org.geogebra.migration.desktop.canvas` | 1 | 1 | Runtime dependency. |
| `editor-desktop` | `org.geogebra.migration.desktop.editor` | 2 | 2 | Runtime dependency. |
| `renderer-desktop` | `org.geogebra.migration.desktop.renderer` | 3 | 3 | Runtime dependency. |
| `jogl2` | `org.geogebra.migration.desktop.jogl2` | 1 | 0 | Fragment hosted by `desktop`; its one package is private in the fragment and exported by the host. |

The current production desktop graph is **12 GeoGebra project outputs including `desktop` itself**. `keyboard-scientific` and `ggbjdk` are included in the 14-recipe set because their jars were built and requested for the audit, but they should not be added to the shipping product without a runtime need. `xr-base` is excluded from this recipe set for the inventory/runtime reasons above. The complete dependency edges are in `Audit_B_Module_Dependencies_CODEX_V1.md`.

### Required headers and recipe conventions

Each regular bundle needs at minimum `Bundle-ManifestVersion: 2`, a unique `Bundle-SymbolicName`, and a valid `Bundle-Version`. As a usable bundle, it also needs correct `Export-Package` for packages supplied to other bundles and `Import-Package` for packages required from others. The latter should be generated from bytecode by Bnd, then audited and versioned against the chosen provider set. Bnd's own guide warns that static scanning misses dynamic/reflection/resource-based dependencies; those require targeted review. The `jogl2` recipe adds `Fragment-Host`.

The draft directory contains 14 `.bnd` recipes with explicit BSNs, source version, package sets and local input jar paths. `Import-Package: *` is Bnd syntax; Bnd expands it to an analyzed import list rather than writing the literal asterisk as a final package. The 12 production recipes have now been processed and resolved by Equinox; see the addendum below. Package-version baselining, full RCP/system-package policy, bundle activation and native/UI tests remain open.

## Native-loading feasibility

### JOGL / GlueGen

The current `desktop/build.gradle.kts` places JOGL and GlueGen classifier jars in the runtime and copies the native jars into the directory containing the Java jars for the Gradle `run` path. The upstream JogAmp guide says its automatic native-JAR loader is enabled by default, can extract native libraries without relying on `java.library.path`, and requires JogAmp jars to remain unmodified in a common directory. That conflicts with Claude's unqualified statement that “Equinox's classloader will not do this automatically”: the supported JVMLoader behavior is more nuanced. **But it is not evidence of Equinox compatibility.** OSGi bundle/resource URLs and Eclipse launch classloaders must be tested with the exact jar layout.

For the first RCP spike, follow binding Architecture V2: leave the native classifier jars (and the JOGL/GlueGen runtime arrangement they require) on the application loader, in their common unmodified directory. If a launcher cannot expose the relevant JOGL packages to bundles, an explicit Equinox system-package/parent-loader design will be needed. Do not create a separate “native bundle” until D-05 proves the first approach insufficient.

`Bundle-NativeCode` is not a magic reader for sibling native jars: its listed native-library paths must be present in the bundle or an attached fragment and are resolved against OS/architecture attributes. It may be a later packaging option for an app-owned native payload, but it does not by itself reproduce JOGL's classpath/native-JAR resource lookup.

### GIAC / javagiac

`CASgiacD` tries `NativeLibClassPathLoader.loadLibrary(file)`. That implementation calls `ClassLoader.getSystemResourceAsStream(filename)`, writes the result to a temporary file and calls `System.load()`. If not found, `CASgiacD` falls back to `System.loadLibrary(file)`. A resource embedded only inside an arbitrary GeoGebra bundle is not automatically visible to the system class loader. Keep the existing GIAC native classifier jars on the application loader in the RCP spike, per V2. If that loader path changes, add a tested app-loader/bootstrap or bundle-aware extraction strategy outside `common`; do not assume a `Bundle-NativeCode` declaration alone fixes `getSystemResourceAsStream`.

### Eclipse/SWT/AWT entry point

The inspected Eclipse installation contains Equinox `3.24.300`, SWT `3.135.0`, and Equinox launcher `1.8.0`; its `eclipse.ini` requires Java 25. GeoGebra source uses Java 17 compilation conventions and its desktop `run` task launches with Java 25. Use the installed RCP's Java 25 baseline for the spike, without mistaking it for the source compile target.

`GeoGebraPanel` is a public `JPanel` with a public no-argument constructor; its documentation requires `buildGUI()` after construction. That makes it a realistic UI entry point. Eclipse's official `SWT_AWT.new_Frame` API confirms the SWT/AWT bridge, but requires the parent Composite to use `SWT.EMBEDDED`; its documentation also notes historical mouse/cursor caveats and recommends a heavyweight `Panel` as root. D-04 must still test focus, menu input, clipboard, DPI, resize, lifecycle, and platform behavior; class existence is not a successful embedding test.

## Risks, fixes, and decisions

1. **True split:** `jogl2` was packaged as a fragment of `desktop`, and the fragment/host plus complete selected package set resolved in Equinox. This confirms resolver feasibility, not runtime class/resource visibility after activation. Validate those points in the RCP launch before choosing whether to retain the fragment or fall back to merging. Do not move upstream classes.
2. **Huge export surface:** the 228 `common` packages and all other package exports in the drafts are a bootstrap resolver aid, not the extension API. Expose only narrow GeoGebraPlus contracts to extensions; preserve kernel internals behind the host.
3. **Generated imports:** Bnd analyzed the 12 production jars against the selected external provider set; Equinox resolved the resulting package constraints, including `uses`. That does not cover dynamic/reflection/resource dependencies or prove application behavior. Keep reviewing those and do not ship test-only bundles as dependencies.
4. **External OSGi wrappers:** Task B found `Bundle-SymbolicName` in only 4 of 39 exact external runtime coordinates. In the selected Windows set, 34 package-bearing external Java jars were wrapped, 4 existing OSGi bundles were reused, and 9 native classifiers were deliberately left on the application loader. The native/application-loader arrangement remains to be proven in the RCP runtime.
5. **Native loading:** JOGL and GIAC behavior under the Eclipse launcher is still a release-blocking POC. Use D-05 and a clean Windows product first; expand OS/architecture coverage only after loader behavior is demonstrated.
6. **RCP launch:** `desktop.jar` currently has `Main-Class` and `Class-Path` Gradle manifest attributes. Eclipse's product application does not launch that main class as its shell. A new RCP `IApplication` should create the SWT shell and embed `GeoGebraPanel`; keep source edits out of `common`.

## Validation status and remaining work

**Completed:** Bnd generated the 12 production GeoGebra bundles at `5.4.934.0`; the Windows x86_64 Equinox 3.24.300 resolver successfully resolved those bundles and the selected external providers (50 installed, zero unresolved). The `desktop` / `jogl2` fragment arrangement resolved. Exact output artifacts and run logs are in `Bnd_Equinox_Resolution_Win64\`.

**Still required before this can be called an RCP integration:**

1. Implement an isolated RCP product/`IApplication` and host, keeping the host and GeoGebraPlus extension/service boundary modular. Do not treat the resolver harness as an application host.
2. Launch the complete pinned product on Windows x86_64 with JOGL, GlueGen and GIAC native classifier jars on the agreed application loader and in their required common directory. Verify the reflective/system-resource paths and native extraction in the actual Eclipse launch.
3. Complete the owner-required D-02/D-04/D-05 proof: `GeoGebraPanel` opens through SWT_AWT, CAS works, and 3D works, with native load-once behavior and logs. Keep `source/shared/common/src` untouched.
4. Exercise fragment class/resource visibility during activation and fall back to merged `desktop+jogl2` packaging only if the fragment fails at runtime.
5. After Windows passes, decide and validate the Linux/macOS native and SWT_AWT matrix before broadening the supported platform set.

The current result is **successful Bnd generation and package-level Equinox resolution for the selected set**, not a started RCP application or proof of OSGi wrapping at runtime. Task A package facts and Task B external dependency facts remain linked above.

---

## Addendum — Bnd build and Windows Equinox package resolution

**Decision inputs accepted for this run:** Windows x86_64 first target; keep `desktop` + `jogl2` as a fragment/host pair; mirror `5.4.934.0`; keep application-loader native classifier jars out of OSGi; aggregate core is a fallback only if the modular resolver becomes unmanageable. The resolver test below is still not the complete D-02/D-04/D-05 UI/native proof.

### Tools and exact run

Bnd CLI 7.4.0 (`7.4.0.202608180709`) was downloaded from the official Bnd install page to `.claude\bnd-cli-7.4.0.jar`. The exact Bnd, Equinox and Java versions were recorded in the output folder.

```powershell
Invoke-WebRequest -Uri 'https://bndtools.jfrog.io/artifactory/update-latest/biz/aQute/bnd/biz.aQute.bnd/7.4.0/biz.aQute.bnd-7.4.0.jar' -OutFile D:\ALF_Agents\G1_Geogebra_Migration\.claude\bnd-cli-7.4.0.jar
java -jar D:\ALF_Agents\G1_Geogebra_Migration\.claude\bnd-cli-7.4.0.jar version
python D:\ALF_Agents\G1_Geogebra_Migration\.claude\generate_osgi_manifest_drafts.py
```

The 12 production `.bnd` recipes were processed with Bnd; each returned exit code 0. Bnd output bundles have real `META-INF/MANIFEST.MF` files and are in `Bnd_Equinox_Resolution_Win64\bundles\` as well as `osgi-manifest-drafts\`. The desktop recipe marks the macOS-only legacy `com.apple.eio` reflective fallback optional. This was added after the first real resolution exposed it as the sole unprovided package; source inspection found it under `if (AppD.MAC_OS)` in `BrowserLauncher.java`. No upstream code was edited.

External runtime artifacts were staged by:

```powershell
python D:\ALF_Agents\G1_Geogebra_Migration\.claude\prepare_bnd_resolution.py
```

The actual Windows x86_64 profile used the installed Eclipse Equinox framework JAR and the Eclipse-bundled Java 25.0.4 runtime. The index and `bndrun` are retained for inspection; the decisive resolution call is the reproducible Equinox Framework API harness:

```powershell
java -jar D:\ALF_Agents\G1_Geogebra_Migration\.claude\bnd-cli-7.4.0.jar index --verbose --name GeoGebraPlus-Windows-x86_64 --repositoryIndex index.xml bundles/*.jar
javac -cp "classes;bundles\org.eclipse.osgi_3.24.300.v20260721-1251.jar" -d classes EquinoxResolveHarness.java
java -cp "classes;bundles\org.eclipse.osgi_3.24.300.v20260721-1251.jar" EquinoxResolveHarness bundles framework-storage-win64-run2
```

The Java 21 JDK was used to compile the harness; it was run with the Java 25.0.4 runtime specified by the inspected Eclipse installation. Exact paths, output, staged jars and summary are under `Bnd_Equinox_Resolution_Win64\`.

### Result

| Result | Observed |
|---|---:|
| Production GeoGebra bundles built by Bnd | 12/12, exit code 0 |
| External Java artifacts with pre-existing BSN reused | 4 |
| External package-bearing Java jars wrapped by Bnd | 34 |
| Native classifier files deliberately left off the bundle set | 9 (JOGL 3, GlueGen 3, GIAC 3) |
| Equinox bundles installed in the resolver harness | 50 (12 GeoGebra + 34 wrappers + 4 existing OSGi) |
| Equinox framework used | 3.24.300.v20260721-1251 |
| Java runtime used by harness | 25.0.4 (installed Eclipse runtime) |
| All 50 installed bundles resolved | **Yes** (`allResolved=true`) |
| Unresolved bundles after the successful run | **0** |
| `jogl2` fragment attached/resolved with `desktop` | **Yes** |

One no-BSN external GAV, `fr.ujf-grenoble:javagiac:70501`, is represented in this runtime only by three native classifier jars and contains no ordinary Java class JAR to wrap. That explains why 35 external coordinates without BSN headers yielded 34 Bnd-wrapped Java JARs: the remaining item is native-only and stays on the application loader. The exact per-file disposition is in `artifact-disposition.tsv`.

Bnd-reported export/import package counts for the 12 production bundles are in `manifest-summary.tsv`. The counts show broad bootstrapping metadata (for example, `common` exports 228 packages and Bnd computes 261 imports); this proves resolver closure only, not that such broad exports are a suitable extension API. The package/import constraints including `uses` were checked by the Equinox resolver against the staged provider set.

### What this proves—and what it does not

It proves that the **12 production GeoGebra bundle manifests plus the selected non-native external Java dependency bundles can resolve in the specified Equinox 3.24.300 framework** on the Windows/Java 25 machine, using the generated fragment fix and optional Apple fallback. It also narrows the first package-resolution issue to a platform-specific reflective import, not a general `uses`-constraint failure. The resolution result is in `equinox-resolution.log`.

It does **not** start those 50 bundles, launch an Eclipse RCP `IApplication`, include a GeoGebraPlus RCP host or SWT/JFace product dependencies, prove class/resource lookup at runtime, open `GeoGebraPanel`, or load CAS/JOGL native code. The nine native classifier jars were deliberately not installed as bundles or on the harness classpath. Therefore D-02/D-04/D-05 remain **NOT RUN** and the owner’s first criterion (panel + CAS + 3D) is still outstanding. The result is an actual package resolver pass, not a product acceptance pass.

### New evidence files

- `Bnd_Equinox_Resolution_Win64\manifest-summary.tsv`
- `Bnd_Equinox_Resolution_Win64\artifact-disposition.tsv`
- `Bnd_Equinox_Resolution_Win64\index.xml`
- `Bnd_Equinox_Resolution_Win64\geogebra-desktop-win64.bndrun`
- `Bnd_Equinox_Resolution_Win64\EquinoxResolveHarness.java`
- `Bnd_Equinox_Resolution_Win64\equinox-resolution.log`
- `Bnd_Equinox_Resolution_Win64\bundles\` (12 generated GeoGebra bundles, 34 wrapped dependencies, 4 reused OSGi dependencies, plus the Equinox framework JAR used to run the harness)
- `bnd-build-logs\` (12 Bnd build logs) and `Bnd_Equinox_Resolution_Win64\wrap-logs\` (external wrapper logs)

**Tool reference:** [Official Bnd CLI installation guide](https://bnd.bndtools.org/chapters/120-install.html).
