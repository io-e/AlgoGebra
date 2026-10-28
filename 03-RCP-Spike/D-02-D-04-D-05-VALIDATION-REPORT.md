# GeoGebraPlus RCP Spike — D-02 / D-04 / D-05 Validation

**Validation date:** 2026-10-28–2026-10-29 (Europe/Paris)<br>
**Code commit:** `a821e589ca8a` on `feat/rcp-product-spike`<br>
**GeoGebra source pin:** `375db7faf540`<br>
**GeoGebra version string:** `5.4.934.0` (source tree; dated `20 October 2026`)<br>
**Host:** Windows 11 / amd64<br>
**Runtime:** Eclipse 2026-09 / Equinox 3.24.300, Java `25.0.4.1+1-LTS`<br>
**Compiler:** JDK `21.0.12.101`, `javac --release 21`<br>
**D-03 input set:** 50 installable bundles, SHA-256 `f5113da0e22d00c08c596793aacfb05aa1af05436e18f8b6ee62e3cf8a1750f4` (excludes the system `org.eclipse.osgi` framework bundle)

## Executive result

| Gate | Result | Scope of the result |
|---|---|---|
| D-02 — Equinox / `IApplication` startup | **PASS** | Headless and GUI launch; host `IApplication.start()` runs; the unchanged D-03 set resolves 50/50. |
| D-04 — GeoGebra Swing panel in SWT | **PASS — core embedding** | SWT shell, embedded `GeoGebraPanel`, visible algebra views and toolbars, input bar, and a basic resize/redraw were observed. Some optional interoperability checks remain untested/partial; see below. |
| D-05 — GIAC/CAS and JOGL/3D | **PARTIAL — functional proof with explicit workarounds** | CAS and a visible 3D point work in the successful run. The handoff's exact GIAC `NativeLibClassPathLoader` mechanism was not demonstrated; the default JOGL native-JAR extraction path and sibling-bundle classloader route did **not** pass. Success required a GIAC fragment bootstrap, manual extraction, and application-loader boot delegation. |

This is a spike result, **not** evidence that the final product's native loading architecture is resolved. In particular, the successful JOGL setup relaxes OSGi classloader isolation and needs owner/architecture review before it is treated as a product configuration.

## Evidence and reproducibility

### D-02 — headless startup

| Field | Value |
|---|---|
| Date / code commit | 2026-10-28 / `a821e589ca8a` |
| Version / OS / Java | GeoGebra `5.4.934.0`; Windows 11 amd64; Java `25.0.4.1+1-LTS` |
| Bundle set hash | `f5113da0e22d00c08c596793aacfb05aa1af05436e18f8b6ee62e3cf8a1750f4` |
| Command | `& .\03-RCP-Spike\launch.ps1 -Headless -NoBuild` |
| Expected | Equinox invokes `IApplication.start()` and all 50 D-03 installables are ACTIVE or RESOLVED, with no unresolved/other states. |
| Actual | **PASS.** Host bundle ACTIVE; `IApplication.start()` entered; `expected=50, found=50, ACTIVE=0, RESOLVED=50, unresolved/other=0, resolveBundles=true`; D-02 PASS; application exited 0. |
| Log | Headless: `logs/rcp-20261028-235642-12764-eca0bec6.log`; post-code-commit GUI confirmation: `logs/rcp-20261029-000134-9160-c931fe29.log` |

The GUI run repeated the same 50/50 resolution result. `com.sun.jna` briefly appeared in a lazy `STARTING` state and is normalized to `RESOLVED` for the D-02 gate; this is recorded in the log, not hidden as an unresolved bundle.

### D-04 — SWT_AWT embedding and UI smoke test

| Check | Result / observed evidence |
|---|---|
| SWT shell opens and embeds upstream `GeoGebraPanel` | **PASS.** Log: `D-04 GeoGebraPanel embedded in SWT_AWT shell`. The left AWT frame contains the upstream 2D `GeoGebraPanel`; a second AWT frame contains the upstream 3D app used by the native proof. |
| Algebra View and toolbar visible | **PASS.** Both are visible in the saved screenshot. The GeoGebra toolbar was clicked during the UI smoke test and the selected tool changed. |
| Algebra input accepts keyboard input | **PARTIAL, manual UI smoke.** In run `20261029-000134-9160-c931fe29`, `C=5` was typed into the left GeoGebra input bar and Enter caused `C = 5` to appear in the left Algebra View. However, a modal GeoGebra warning (“Please check your input”) also appeared and had to be dismissed. The object remained after dismissing the dialog, so command processing occurred, but a clean interactive submission was not demonstrated. This was a transient in-memory test object, not a saved construction. See the input-test screenshot below. |
| Resize / redraw | **PASS for a basic maximize resize.** Maximizing the window triggered the SWT resize listener, the two Swing frames revalidated, the algebra-input rows became visible, and the 2D/3D content redrew without crashing. Arbitrary repeated drag-resize/minimum-size behavior was not exhaustively tested. |
| Focus | **Partial.** Keyboard focus reached the embedded GeoGebra input, and the expression was processed. The warning raised on Enter (above) leaves clean input/focus UX unresolved. Return focus to an independent SWT control was not tested: the spike shell has no SWT content control beyond the embedded AWT panes and native window chrome. |
| Clipboard | **Not tested.** No clipboard contents were read or changed. |
| High-DPI behavior | **Not tested.** The test establishes Windows amd64 UI rendering only; it does not establish behavior at a verified high-DPI scale factor. |

The startup code requests maximization so that the full GeoGebra UI, including the input rows, is initially available. The validated run displayed the input rows; the shell remains resizable.

The GUI log also contains a non-blocking Java `WindowsPreferences` warning: Windows denied creation/access to `Software\JavaSoft\Prefs` (registry error code 5). The RCP and GeoGebra views continued to run; preferences persistence was not tested.

**Clean UI screenshot:** `evidence/rcp-20261028-235656-23884-34151d6a.png`<br>
**Clean GUI log:** `logs/rcp-20261028-235656-23884-34151d6a.log`<br>
**Input-test screenshot (warning captured):** `evidence/rcp-20261029-000134-9160-c931fe29.png`<br>
**Input-test log:** `logs/rcp-20261029-000134-9160-c931fe29.log`

Two earlier Robot screenshots (`rcp-20261028-234616-37212-6a47ee6c.png` and `rcp-20261028-234928-22368-f5f609ee.png`) were retained locally but marked invalid: File Explorer obscured the RCP app at capture time. They are ignored by Git and are not cited as evidence. The valid screenshot above was captured after explicitly raising the RCP window and visually checked.

### D-05 — GIAC/CAS and JOGL/3D

| Field | Value |
|---|---|
| Date / code commit | 2026-10-28–2026-10-29 / `a821e589ca8a` |
| Version / OS / Java | GeoGebra `5.4.934.0`; Windows 11 amd64; Java `25.0.4.1+1-LTS` |
| Bundle set hash | `f5113da0e22d00c08c596793aacfb05aa1af05436e18f8b6ee62e3cf8a1750f4` |
| Command | `& .\03-RCP-Spike\launch.ps1 -NoBuild -ManualNativeFallback -BootDelegateJogAmp` |
| Expected | Evaluate `Expand[(x+1)^2]` through CAS/GIAC; create `A=(1,2,3)` and visibly render the 3D point; no `UnsatisfiedLinkError`. |
| Actual | **Functional subtests pass; strict handoff gate is PARTIAL.** CAS factory adapter is `CASFactoryD`; the fragment bootstrap calls `System.loadLibrary("javagiac64")` from the owning `org.geogebra.migration.shared.giac.jni` Equinox classloader; CAS result normalized to `x^2+2x+1`; direct GIAC smoke `1+1 -> 2`; the 3D point command was accepted and the view initialized; the clean screenshot from the same code revision shows `A` rendered. No `UnsatisfiedLinkError` occurred in the successful workaround runs. However, the handoff specifically asks that GIAC be shown loading via GeoGebra's `NativeLibClassPathLoader`; that mechanism was **not** used or proven here. |
| Log / screenshot | Latest run log `logs/rcp-20261029-000134-9160-c931fe29.log`; clean UI screenshot `evidence/rcp-20261028-235656-23884-34151d6a.png` |

#### Native loading findings

- **GIAC:** The spike-only `org.geogebra.plus.giac.native` fragment attaches a bootstrap class to the GIAC JNI bundle and preloads `javagiac64.dll` in the same Equinox classloader as `javagiac.giacJNI`. This fixes the native ownership mismatch seen when the desktop bundle's loader performs the load. The CAS factory installation/enablement uses reflection as a test adapter; it is **not** a proposed upstream/public API.
- **JOGL/GlueGen success mode:** Seven Windows DLLs were extracted into the unique per-run directory `natives/extract-20261029-000134-9160-c931fe29`; `java.library.path` points there and `-Djogamp.gluegen.UseTempJarCache=false` is set. JogAmp API/native JARs are also on the application classpath. `-Dorg.osgi.framework.bootdelegation=com.jogamp.*,jogamp.*` and `-Dosgi.parentClassloader=app` make the JogAmp classes use the shared application loader. The successful log explicitly reports this mode.
- **Default extractor is not validated as working here.** Earlier Java 25 runs failed in `jogamp.common.jvm.JVMUtil.initialize(ByteBuffer)` (`rcp-20261028-231711-25132-b9781aa2.log`, also `232239` and `232427`). With manual extraction but JogAmp classes remaining in sibling OSGi loaders, runs failed in `JAWTFactory.JAWT_GetAWT1` (`232608`, `233709`, `233915`, `234215`). A later resolution/ordering issue produced `toolbarPanel is null` (`234317`) and was fixed by building the App3D application panel before showing its 3D view.
- Therefore the answer to the handoff's extractor question is: **this passing Equinox configuration required manual extraction and `java.library.path`; the native-JAR extractor alone did not pass the Java 25/Equinox test.** The passing arrangement is platform-specific evidence, not yet a deployable cross-platform policy.

## Commands run

```powershell
& .\03-RCP-Spike\build.ps1
& .\03-RCP-Spike\launch.ps1 -Headless -NoBuild
& .\03-RCP-Spike\launch.ps1 -NoBuild -ManualNativeFallback -BootDelegateJogAmp
```

The launch script creates timestamped configuration, workspace, log, and native-extraction directories. Existing build outputs and failed-run evidence were retained; nothing was pushed to a remote.

## Scope, limitations, and next decision

1. `source/shared/common/src` was not edited; the separate GeoGebra source checkout remains at pin `375db7faf540`. No files were changed in the Eclipse installation.
2. The 50 D-03 input bundles are reused unchanged; host, resource, and native fragments live only under `03-RCP-Spike`.
3. The 3D view is a second upstream `App3D` instance hosted beside `GeoGebraPanel`; it does not prove that `GeoGebraPanel` itself exposes the full 3D desktop workbench.
4. The successful JOGL mode relies on boot delegation to the application classloader. Decide whether to accept that boundary, or investigate an application-level native bridge/packaging strategy, before calling native integration production-ready.
5. Full clipboard interoperability, high-DPI testing, Linux natives, and repeated freeform resize/focus testing remain open.
6. CAS initialization and GIAC/JOGL helper fragments are spike adapters; replace reflective initialization with a supported integration seam before productization.

**Recommendation:** accept D-02; accept D-04 for the core Swing-in-SWT proof while keeping focus/clipboard/DPI subchecks open; record D-05 as **PARTIAL**—the real CAS and 3D paths work in the tested Windows configuration, but the specified GIAC loader mechanism and a product-grade JOGL loading policy remain unproven. Proceed to owner/Claude review before treating D-02/D-04/D-05 as product gates fully closed.
