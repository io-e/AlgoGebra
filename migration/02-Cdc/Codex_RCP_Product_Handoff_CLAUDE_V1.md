<!-- CLAUDE_V1 -->
# Codex Handoff — RCP Product Definition, IApplication, and D-02/D-04/D-05 Spike

**Date:** 2026-10-28
**From:** Claude Opus 4.6
**To:** Codex
**Purpose:** Implement the first GeoGebraPlus RCP product that starts Equinox, embeds `GeoGebraPanel` in an SWT shell, and proves GIAC/JOGL native loading under the Eclipse launcher.
**Prerequisite:** D-03 PASS — 50/50 bundles resolved in Equinox 3.24.300 (see `Bnd_Equinox_Resolution_Win64/`).
**Validation:** Claude reviews the product once Codex reports D-02 pass. Owner reviews after D-04/D-05.

---

## 0. Binding constraints (carry forward)

These are non-negotiable. If any step requires violating one, **stop and report the blocker**.

1. **Do NOT edit files under `source/shared/common/src`.** This is the upstream `common` module — must stay untouched.
2. **Do NOT modify the Eclipse IDE installation** at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse`.
3. **Do NOT push to any remote.** All work stays local.
4. **Do NOT delete or reset existing build outputs.**
5. **OSGi metadata goes in new files only**, never in upstream source JARs.
6. **Native classifier jars stay on the application loader** per Architecture V2. No `Bundle-NativeCode` on the first spike.
7. **No commit to `main`/`master`**. Create a feature branch.

---

## 1. What you are building

A **minimal Eclipse RCP product** — a standalone application (not the Eclipse IDE) that:

1. Launches Equinox with the 50-bundle set already validated in D-03
2. Opens an SWT shell window
3. Embeds `GeoGebraPanel` (Swing) inside that SWT shell via `SWT_AWT`
4. Triggers a CAS evaluation (GIAC) and a 3D render (JOGL) to prove native loading

This is NOT a full product. It is a proof-of-concept spike for scenarios D-02, D-04, and D-05.

### Where the new code lives

Create a new workspace directory:

```
D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike\
├── org.geogebra.plus.host/          ← the RCP host bundle (IApplication + SWT shell)
│   ├── src/
│   │   └── org/geogebra/plus/host/
│   │       ├── GeoGebraPlusApplication.java   ← IApplication
│   │       └── GeoGebraPlusAdvisor.java       ← optional WorkbenchAdvisor (if E4 needed)
│   ├── META-INF/
│   │   └── MANIFEST.MF
│   ├── plugin.xml                    ← extension point declarations
│   └── build.properties
├── org.geogebra.plus.product/        ← product configuration
│   ├── geogebraplus.product          ← .product file
│   └── geogebraplus.ini             ← launcher arguments
├── bundles/                          ← symlink or copy of resolved bundles
│   └── (50 jars from Bnd_Equinox_Resolution_Win64/bundles/)
├── natives/                          ← native classifier jars (app-loader)
│   └── (9 JOGL/GlueGen/GIAC native jars)
└── launch.ps1                        ← launch script for testing
```

**Do NOT create this inside the GeoGebra source checkout.** Keep it in the study project.

---

## 2. Technical specifications

### 2.1 Eclipse/Equinox versions (from the installed IDE)

| Component | Version | Location |
|---|---|---|
| Equinox OSGi framework | 3.24.300.v20260721-1251 | `plugins/org.eclipse.osgi_3.24.300.*.jar` |
| Equinox launcher | 1.8.0.v20260804-1928 | `plugins/org.eclipse.equinox.launcher_1.8.0.*.jar` |
| SWT (win32 x86_64) | 3.135.0.v20260819-1952 | `plugins/org.eclipse.swt.win32.win32.x86_64_3.135.0.*.jar` |
| SWT core | 3.135.0.v20260819-1952 | `plugins/org.eclipse.swt_3.135.0.*.jar` |
| Eclipse core runtime | 3.35.0.v20260623-1631 | `plugins/org.eclipse.core.runtime_3.35.0.*.jar` |
| Equinox app (IApplication) | 1.7.600.v20251211-1038 | `plugins/org.eclipse.equinox.app_1.7.600.*.jar` |
| JVM | Java 25.0.4 (JustJ) | `plugins/org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4.*/jre/` |
| Eclipse installation | `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` | Read-only reference |

### 2.2 The 12 GeoGebra production bundles (already built)

All at version `5.4.934.0`, in `02-Cdc/Bnd_Equinox_Resolution_Win64/bundles/`:

| BSN | Module | Notes |
|---|---|---|
| `org.geogebra.migration.shared.common` | common | 228 exports, JUNG/QuickHull3D private |
| `org.geogebra.migration.shared.common.jre` | common-jre | 12 exports |
| `org.geogebra.migration.shared.renderer.base` | renderer-base | |
| `org.geogebra.migration.shared.editor.base` | editor-base | |
| `org.geogebra.migration.shared.canvas.base` | canvas-base | |
| `org.geogebra.migration.shared.keyboard.base` | keyboard-base | |
| `org.geogebra.migration.shared.giac.jni` | giac-jni | Native bridge Java side |
| `org.geogebra.migration.desktop` | desktop | 61 exports, contains `GeoGebraPanel` |
| `org.geogebra.migration.desktop.canvas` | canvas-desktop | |
| `org.geogebra.migration.desktop.editor` | editor-desktop | |
| `org.geogebra.migration.desktop.renderer` | renderer-desktop | |
| `org.geogebra.migration.desktop.jogl2` | jogl2 | **Fragment** of `org.geogebra.migration.desktop` |

Plus 34 wrapped external bundles and 4 existing OSGi bundles = **50 total**.

### 2.3 Native classifier jars (application loader, NOT bundles)

These 9 jars remain **outside** the bundle set. They must be on the JVM classpath at launch, in a common directory so JOGL's native-JAR extractor finds them:

| Coordinate | Classifier | File |
|---|---|---|
| `org.jogamp.jogl:jogl-all:2.6.0` | `natives-windows-amd64` | `jogl-all-2.6.0-natives-windows-amd64.jar` |
| `org.jogamp.gluegen:gluegen-rt:2.6.0` | `natives-windows-amd64` | `gluegen-rt-2.6.0-natives-windows-amd64.jar` |
| `org.jogamp.jogl:jogl-all:2.6.0` | (Java API jar) | `jogl-all-2.6.0.jar` |
| `org.jogamp.gluegen:gluegen-rt:2.6.0` | (Java API jar) | `gluegen-rt-2.6.0.jar` |
| `fr.ujf-grenoble:javagiac:70501` | `natives-windows-amd64` | `javagiac-70501-natives-windows-amd64.jar` |

**Critical:** JOGL's `NativeLibLoader` requires that native JARs sit alongside their API JARs in the same directory. The Gradle build already does this (see `desktop/build.gradle.kts` lines 84–106). Replicate this layout in the `natives/` directory.

**Critical:** GIAC's `NativeLibClassPathLoader` (line 61 of `NativeLibClassPathLoader.java`) calls `ClassLoader.getSystemResourceAsStream(filename)`. The GIAC native JAR must be on the **system class loader's classpath**, not hidden inside a bundle.

### 2.4 JVM arguments

From the existing desktop `build.gradle.kts` (line 78–81) and `eclipse.ini`:

```
--add-exports java.base/java.lang=ALL-UNNAMED
--add-exports java.desktop/sun.awt=ALL-UNNAMED
--add-exports java.desktop/sun.java2d=ALL-UNNAMED
--enable-native-access=ALL-UNNAMED
--add-modules=ALL-SYSTEM
```

The first three are required for JOGL. `--enable-native-access=ALL-UNNAMED` is for JNI. `--add-modules=ALL-SYSTEM` is Eclipse standard.

---

## 3. Implementation guide

### 3.1 D-02 — RCP starts

**Goal:** An Equinox framework starts with all 50 bundles ACTIVE, the host bundle registers its `IApplication`, and the application prints confirmation to stdout.

#### Host bundle: `org.geogebra.plus.host`

Create a new OSGi bundle with this MANIFEST.MF:

```
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.geogebra.plus.host;singleton:=true
Bundle-Version: 0.1.0
Bundle-Name: GeoGebraPlus RCP Host
Bundle-Activator: org.geogebra.plus.host.Activator
Bundle-RequiredExecutionEnvironment: JavaSE-25
Import-Package: org.eclipse.equinox.app;version="[1.1,2.0)",
 org.eclipse.swt,
 org.eclipse.swt.awt,
 org.eclipse.swt.layout,
 org.eclipse.swt.widgets,
 org.osgi.framework;version="[1.10,2.0)",
 org.geogebra.desktop,
 javax.swing
Export-Package: org.geogebra.plus.host
```

Create `plugin.xml` with the application extension:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?eclipse version="3.4"?>
<plugin>
   <extension id="geogebraplusApp"
              point="org.eclipse.core.runtime.applications">
      <application>
         <run class="org.geogebra.plus.host.GeoGebraPlusApplication"/>
      </application>
   </extension>
</plugin>
```

#### GeoGebraPlusApplication.java

```java
package org.geogebra.plus.host;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

/**
 * Minimal RCP application for GeoGebraPlus.
 * D-02: proves Equinox starts with the full bundle set.
 * D-04: embeds GeoGebraPanel in SWT via SWT_AWT bridge.
 */
public class GeoGebraPlusApplication implements IApplication {

    @Override
    public Object start(IApplicationContext context) throws Exception {
        System.out.println("[GeoGebraPlus] IApplication.start() — D-02 entry");
        
        // D-02 check: log all bundle states
        var bundleContext = org.osgi.framework.FrameworkUtil
            .getBundle(getClass()).getBundleContext();
        int active = 0, resolved = 0, other = 0;
        for (var bundle : bundleContext.getBundles()) {
            switch (bundle.getState()) {
                case org.osgi.framework.Bundle.ACTIVE -> active++;
                case org.osgi.framework.Bundle.RESOLVED -> resolved++;
                default -> other++;
            }
        }
        System.out.println("[GeoGebraPlus] Bundles: " + active + " ACTIVE, "
            + resolved + " RESOLVED (fragments), " + other + " other");
        
        // D-04: open the SWT shell with embedded GeoGebraPanel
        openSwtShell();
        
        return IApplication.EXIT_OK;
    }
    
    private void openSwtShell() {
        var display = new org.eclipse.swt.widgets.Display();
        var shell = new org.eclipse.swt.widgets.Shell(display);
        shell.setText("GeoGebraPlus — RCP Spike");
        shell.setSize(1024, 768);
        shell.setLayout(new org.eclipse.swt.layout.FillLayout());
        
        // SWT_AWT bridge: create embedded AWT frame inside SWT Composite
        var composite = new org.eclipse.swt.widgets.Composite(
            shell, org.eclipse.swt.SWT.EMBEDDED | org.eclipse.swt.SWT.NO_BACKGROUND);
        var awtFrame = org.eclipse.swt.awt.SWT_AWT.new_Frame(composite);
        
        // D-04: create and embed GeoGebraPanel (Swing)
        javax.swing.SwingUtilities.invokeLater(() -> {
            try {
                var ggbPanel = new org.geogebra.desktop.GeoGebraPanel();
                ggbPanel.setShowMenubar(true);
                ggbPanel.setShowToolbar(true);
                ggbPanel.setShowAlgebraInput(true);
                ggbPanel.buildGUI();
                
                awtFrame.add(ggbPanel);
                awtFrame.validate();
                System.out.println("[GeoGebraPlus] D-04: GeoGebraPanel embedded in SWT");
                
                // D-05: trigger CAS evaluation (proves GIAC native loaded)
                try {
                    String casResult = ggbPanel.getGeoGebraAPI()
                        .evalCommandCAS("Expand[(x+1)^2]");
                    System.out.println("[GeoGebraPlus] D-05 CAS: Expand[(x+1)^2] = "
                        + casResult);
                } catch (Exception e) {
                    System.err.println("[GeoGebraPlus] D-05 CAS FAILED: " + e);
                }
                
                // D-05: trigger 3D view (proves JOGL native loaded)
                try {
                    ggbPanel.getGeoGebraAPI().evalCommand("A = (1, 2, 3)");
                    System.out.println("[GeoGebraPlus] D-05 3D: Point A created at (1,2,3)");
                } catch (Exception e) {
                    System.err.println("[GeoGebraPlus] D-05 3D FAILED: " + e);
                }
                
            } catch (Exception e) {
                System.err.println("[GeoGebraPlus] D-04 EMBEDDING FAILED: " + e);
                e.printStackTrace();
            }
        });
        
        shell.open();
        while (!shell.isDisposed()) {
            if (!display.readAndDispatch()) {
                display.sleep();
            }
        }
        display.dispose();
    }

    @Override
    public void stop() {
        // cleanup if needed
    }
}
```

#### Activator.java (minimal)

```java
package org.geogebra.plus.host;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

public class Activator implements BundleActivator {
    @Override
    public void start(BundleContext context) {
        System.out.println("[GeoGebraPlus] Host bundle activated, id="
            + context.getBundle().getBundleId());
    }
    @Override
    public void stop(BundleContext context) {}
}
```

### 3.2 Product configuration

#### geogebraplus.product

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?pde version="3.5"?>
<product name="GeoGebraPlus"
         uid="org.geogebra.plus.product"
         id="org.geogebra.plus.host.geogebraplusApp"
         application="org.geogebra.plus.host.geogebraplusApp"
         version="0.1.0"
         useFeatures="false"
         includeLaunchers="false">

   <configIni use="default"/>
   <launcherArgs>
      <vmArgsList>
         --add-exports java.base/java.lang=ALL-UNNAMED
         --add-exports java.desktop/sun.awt=ALL-UNNAMED
         --add-exports java.desktop/sun.java2d=ALL-UNNAMED
         --enable-native-access=ALL-UNNAMED
         --add-modules=ALL-SYSTEM
      </vmArgsList>
   </launcherArgs>

   <plugins>
      <!-- Eclipse platform minimum -->
      <plugin id="org.eclipse.osgi"/>
      <plugin id="org.eclipse.equinox.app"/>
      <plugin id="org.eclipse.equinox.common"/>
      <plugin id="org.eclipse.equinox.registry"/>
      <plugin id="org.eclipse.core.runtime"/>
      <plugin id="org.eclipse.swt"/>
      <plugin id="org.eclipse.swt.win32.win32.x86_64" fragment="true"/>
      
      <!-- GeoGebraPlus host -->
      <plugin id="org.geogebra.plus.host"/>
      
      <!-- 12 GeoGebra bundles -->
      <plugin id="org.geogebra.migration.shared.common"/>
      <plugin id="org.geogebra.migration.shared.common.jre"/>
      <plugin id="org.geogebra.migration.shared.renderer.base"/>
      <plugin id="org.geogebra.migration.shared.editor.base"/>
      <plugin id="org.geogebra.migration.shared.canvas.base"/>
      <plugin id="org.geogebra.migration.shared.keyboard.base"/>
      <plugin id="org.geogebra.migration.shared.giac.jni"/>
      <plugin id="org.geogebra.migration.desktop"/>
      <plugin id="org.geogebra.migration.desktop.canvas"/>
      <plugin id="org.geogebra.migration.desktop.editor"/>
      <plugin id="org.geogebra.migration.desktop.renderer"/>
      <plugin id="org.geogebra.migration.desktop.jogl2" fragment="true"/>
      
      <!-- 34 wrapped external + 4 existing OSGi (see artifact-disposition.tsv) -->
   </plugins>
</product>
```

### 3.3 Launch script

For testing outside PDE, use a direct Equinox launch. Create `launch.ps1`:

```powershell
# GeoGebraPlus RCP Spike — direct Equinox launch
# Assumes: bundles/ has the 50 resolved bundles + host bundle
#          natives/ has JOGL/GlueGen/GIAC native + API jars in same directory

$ECLIPSE_HOME = 'D:\ALF_ZGit\G2_Eclipse\01_src\eclipse'
$JAVA = "$ECLIPSE_HOME\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4.v20260826-0822\jre\bin\java.exe"
$EQUINOX = "$ECLIPSE_HOME\plugins\org.eclipse.osgi_3.24.300.v20260721-1251.jar"
$SPIKE = 'D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike'
$NATIVES = "$SPIKE\natives"
$BUNDLES = "$SPIKE\bundles"
$STORAGE = "$SPIKE\framework-storage"

# Clean framework storage
if (Test-Path $STORAGE) { Remove-Item -Recurse -Force $STORAGE }

# Build classpath: Equinox framework + native jars on app loader
$nativeJars = (Get-ChildItem -Path $NATIVES -Filter '*.jar').FullName -join ';'
$classpath = "$EQUINOX;$nativeJars"

& $JAVA `
    --add-exports java.base/java.lang=ALL-UNNAMED `
    --add-exports java.desktop/sun.awt=ALL-UNNAMED `
    --add-exports java.desktop/sun.java2d=ALL-UNNAMED `
    --enable-native-access=ALL-UNNAMED `
    --add-modules=ALL-SYSTEM `
    -cp $classpath `
    -Dosgi.noShutdown=true `
    -Dosgi.framework.extensions= `
    -Dosgi.bundles.defaultStartLevel=4 `
    -Declipse.application=org.geogebra.plus.host.geogebraplusApp `
    -Dosgi.install.area="$BUNDLES" `
    -Dosgi.configuration.area="$SPIKE\configuration" `
    -Dorg.osgi.framework.storage="$STORAGE" `
    -Dorg.osgi.framework.storage.clean=onFirstInit `
    org.eclipse.equinox.launcher.Main `
    -configuration "$SPIKE\configuration" `
    -data "$SPIKE\workspace"
```

**Important:** The `-cp` includes native jars so `ClassLoader.getSystemResourceAsStream` can find GIAC native libraries, and JOGL can find its API + native jars in the same directory.

### 3.4 Configuration area

Create `03-RCP-Spike/configuration/config.ini`:

```ini
osgi.framework=file\:../bundles/org.eclipse.osgi_3.24.300.v20260721-1251.jar
osgi.bundles.defaultStartLevel=4
eclipse.application=org.geogebra.plus.host.geogebraplusApp
osgi.bundles=\
  reference\:file\:org.geogebra.plus.host-0.1.0.jar@start,\
  reference\:file\:org.eclipse.equinox.common_3.21.0.*.jar@2\:start,\
  reference\:file\:org.eclipse.equinox.app_1.7.600.*.jar@start,\
  reference\:file\:org.eclipse.equinox.registry_3.12.600.*.jar@start,\
  reference\:file\:org.eclipse.core.runtime_3.35.0.*.jar@start
```

**Note:** This is a starting point. You will likely need to adjust the exact bundle start levels and the list of Eclipse platform bundles. The Equinox launcher can also auto-discover bundles from a `plugins/` directory.

---

## 4. Required Eclipse platform bundles

The host bundle needs SWT and the Eclipse application runtime. Copy these from the Eclipse installation's `plugins/` into your `bundles/` directory:

| Bundle | Why |
|---|---|
| `org.eclipse.osgi` | Framework itself (on classpath, not installed as bundle) |
| `org.eclipse.equinox.common` | `IStatus`, `IPath`, basic Equinox services |
| `org.eclipse.equinox.app` | `IApplication` extension point |
| `org.eclipse.equinox.registry` | Extension registry (needed by `equinox.app`) |
| `org.eclipse.core.runtime` | `Plugin`, `Platform` — ties the above together |
| `org.eclipse.swt` | SWT core |
| `org.eclipse.swt.win32.win32.x86_64` | SWT Windows implementation (fragment) |
| `org.eclipse.core.jobs` | Required by `core.runtime` |
| `org.eclipse.core.contenttype` | Required by `core.runtime` |
| `org.eclipse.equinox.preferences` | Required by `core.runtime` |

The exact transitive set may be larger. Start with these and add whatever the resolver or runtime reports missing.

---

## 5. Acceptance criteria

### D-02 — RCP starts
- [ ] Equinox starts with `eclipse.application=org.geogebra.plus.host.geogebraplusApp`
- [ ] `IApplication.start()` is called (stdout prints `[GeoGebraPlus] IApplication.start()`)
- [ ] All 50 GeoGebra/external bundles are ACTIVE or RESOLVED (fragments)
- [ ] No unresolved bundles in the log
- [ ] No edit under `source/shared/common/src`

### D-04 — Swing GeoGebra inside RCP shell
- [ ] SWT shell opens with embedded `GeoGebraPanel`
- [ ] Algebra View is visible
- [ ] Toolbar is visible and clickable
- [ ] Menu bar is visible
- [ ] Can type in the input bar and press Enter (construction updates)
- [ ] Window can be resized without crash
- [ ] Report focus behavior (click into GeoGebra area, then back to SWT — does focus transfer?)
- [ ] Report clipboard behavior (Ctrl+C/V between GeoGebra and external app)
- [ ] Report DPI behavior if on a high-DPI display

### D-05 — CAS and 3D from RCP
- [ ] `evalCommandCAS("Expand[(x+1)^2]")` returns `x^2 + 2*x + 1` (or equivalent)
- [ ] This proves GIAC native library loaded via `NativeLibClassPathLoader`
- [ ] `evalCommand("A = (1, 2, 3)")` creates a 3D point (proves JOGL loaded)
- [ ] 3D View opens and renders the point
- [ ] No `UnsatisfiedLinkError` in logs
- [ ] Report: did JOGL use its native-JAR extractor, or was `java.library.path` needed?

### Evidence rule (V2 §9)

Each pass records: **date, commit, `VERSION_STRING`, OS, Java version, bundle set hash, command, expected, actual, log path.** Capture these in the report.

---

## 6. Known risks and fallback strategies

| Risk | Mitigation |
|---|---|
| **SWT_AWT bridge doesn't render** | Try `awtFrame.setVisible(true)` explicitly. If the bridge itself fails, report the stack trace — this is a D-04 gate failure that goes back to the owner. |
| **GIAC native not found by system classloader** | Verify GIAC native JARs are on `-cp`. If the Equinox launcher doesn't expose them on the system classloader, try `-Djava.class.path` explicitly, or extract the DLL to a temp dir and use `-Djava.library.path`. Report what worked. |
| **JOGL fails to find native JARs** | Verify native JARs sit alongside API JARs in `natives/`. If JOGL's `NativeLibLoader` still fails, try `-Djogamp.gluegen.UseTempJarCache=false` and extract manually. Report. |
| **Eclipse platform bundle version mismatch** | Use the exact jars from the installed Eclipse 2026-09, not downloaded ones. Version strings matter for Equinox resolution. |
| **Host bundle can't import `org.geogebra.desktop`** | Check that the desktop bundle (`org.geogebra.migration.desktop`) exports `org.geogebra.desktop`. It should — 61 packages exported. Verify with `bnd print`. |
| **Fragment doesn't attach** | If `jogl2` fragment fails, fall back to merging it into the desktop bundle. |
| **AWT/SWT thread conflict** | The SWT event loop and AWT EventQueue run on different threads. Use `Display.asyncExec()` for SWT calls from AWT, and `SwingUtilities.invokeLater()` for AWT calls from SWT. The `GeoGebraPlusApplication` code above handles this. |

---

## 7. What NOT to do

- Do not use PDE (Plugin Development Environment) to build. Compile the host bundle with `javac` or a minimal Gradle/Maven build. PDE adds complexity we don't need for a spike.
- Do not create a target platform definition file. Use the exact jars from the installed Eclipse and the Bnd output.
- Do not attempt to start the E4 workbench (`org.eclipse.e4.ui.workbench.swt.E4Application`). We want a plain `IApplication` with a raw SWT shell — no perspectives, no views, no parts.
- Do not wrap native jars as OSGi bundles. They stay on the app-loader.
- Do not modify the 50 bundles that already resolved. They are inputs, not editable artifacts.

---

## 8. File references

| File | What it contains |
|---|---|
| `02-Cdc/Bnd_Equinox_Resolution_Win64/bundles/` | The 50 resolved bundle JARs |
| `02-Cdc/Bnd_Equinox_Resolution_Win64/equinox-resolution.log` | Proof of 50/50 RESOLVED |
| `02-Cdc/Bnd_Equinox_Resolution_Win64/manifest-summary.tsv` | Export/import counts per bundle |
| `02-Cdc/Bnd_Equinox_Resolution_Win64/artifact-disposition.tsv` | Which jars are bundles vs app-loader |
| `02-Cdc/Bnd_Equinox_Resolution_Win64/EquinoxResolveHarness.java` | The resolve harness (reuse for testing) |
| `source/desktop/desktop/src/main/java/org/geogebra/desktop/GeoGebraPanel.java` | The embedding entry point |
| `source/desktop/desktop/src/main/java/org/geogebra/desktop/cas/giac/NativeLibClassPathLoader.java` | How GIAC loads native libs |
| `source/desktop/desktop/build.gradle.kts` lines 84–106 | How JOGL natives are placed |
| `CLAUDE.md` | Project guidance (V3, current) |

---

## 9. Deliverables

1. **Working `03-RCP-Spike/` directory** with the host bundle, product config, and launch script
2. **D-02 evidence:** log showing all bundles ACTIVE/RESOLVED, `IApplication.start()` called
3. **D-04 evidence:** screenshot of `GeoGebraPanel` inside SWT shell, focus/clipboard/resize notes
4. **D-05 evidence:** CAS evaluation result, 3D point creation, native loading logs
5. **Report:** one Markdown file summarizing pass/fail for each acceptance criterion, with evidence per V2 §9

---

## 10. Validation by Claude

After Codex delivers, Claude will:

1. Read the D-02/D-04/D-05 report
2. Verify no `source/shared/common/src` diff
3. Update scenario statuses in CLAUDE.md and V2
4. If D-04/D-05 fail, analyze the failure and determine if it's a fixable integration issue or a gate failure requiring an owner decision
5. If all pass, prepare the next handoff: D-06–D-09 (extension bundle management) and the first contract spec

---

## 11. Suggested evolution path (after this spike passes)

| Step | What | When |
|---|---|---|
| D-06–D-09 | Extension bundle management (allow/block/version) | After Gate B |
| D-10 | Clean install, upgrade, rollback on fresh Windows | After Gate B |
| W-01 | Web technology scored study | Parallel with D-06 |
| Contracts | 5 specs (activity, capability, compute, state, submission) | Parallel with D-06 |
| Grok Bot replication | D-02/D-04/D-05 on Debian with Linux natives | After Windows pass |
| Phase 2 | One activity on both clients, one WIMS submit | After Gates B + C |
