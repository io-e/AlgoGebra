# Task B — Desktop Module and External Dependency Graph

**Repository:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Revision:** `375db7faf54` (`main`)  
**Date:** 28 October 2026  
**Scope:** Gradle source modules in shared + desktop; actual `:desktop:runtimeClasspath`; resolved artifact manifest headers. Read-only.

## Commands and raw evidence

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
.\gradlew.bat -p source/desktop :desktop:dependencies --configuration runtimeClasspath --no-daemon --console=plain
```

Full Gradle dependency output is saved as `Audit_B_Desktop_Runtime_Gradle_Raw_CODEX_V1.txt`.

Resolved production artifact paths were captured with `.claude\dump_runtime_artifacts.init.gradle`:

```powershell
.\gradlew.bat -p source/desktop -I D:\ALF_Agents\G1_Geogebra_Migration\.claude\dump_runtime_artifacts.init.gradle :desktop:dumpRuntimeArtifacts --no-daemon --console=plain
```

Raw resolved artifacts are in `Audit_B_Runtime_Artifacts_CODEX_V1.txt`. Package ownership is independently recorded in `Audit_A_Package_Ownership_CODEX_V1.tsv`.

## 1. Desktop runtime project graph

The project `:desktop` has **11 resolved dependent GeoGebra Gradle project artifacts** plus its own application output (12 project outputs total):

```text
:desktop
  ├── :shared:common
  │     ├── :shared:editor-base
  │     │     └── :shared:renderer-base
  │     │            └── :shared:canvas-base
  │     ├── :shared:renderer-base
  │     ├── :shared:canvas-base
  │     └── :shared:keyboard-base
  ├── :shared:common-jre
  │     ├── :shared:common
  │     ├── :shared:giac-jni
  │     ├── :shared:renderer-base
  │     ├── :shared:editor-base
  │     └── external: org.mozilla:rhino:1.8.1
  ├── :canvas-desktop ─────────────── :shared:canvas-base
  ├── :editor-desktop ──┬──────────── :renderer-desktop
  │                     └──────────── :shared:editor-base
  ├── :renderer-desktop ┬──────────── :canvas-desktop
  │                     └──────────── :shared:renderer-base
  ├── :jogl2 ───────────┬──────────── external: org.jogamp.gluegen:gluegen-rt:2.6.0
  │                     └──────────── external: org.jogamp.jogl:jogl-all:2.6.0
  └── :shared:giac-jni
```

Composite-build dependency substitution maps desktop coordinates like `org.geogebra:common` to the included source project `:shared:common` (and similar for canvas/editor/renderer artifacts).

### 1.1 Complete desktop/shared module edge list

The Gradle source trees contain **15 modules** (10 in shared, 5 in desktop), but not every module is on the production desktop classpath. The following direct project edges are declared in source `build.gradle.kts` files:

| Module | Direct project dependencies | Direct external/build dependencies (production unless marked) |
|---|---|---|
| `shared:common` | `keyboard-base`, `editor-base`, `renderer-base`, `canvas-base` | Apache `math-cross-platform`; SpotBugs annotations; JSpecify; J2ObjC annotations; JavaCC for generated source. |
| `shared:common-jre` | `common`, `giac-jni`, `renderer-base`, `editor-base` | Rhino 1.8.1; JUnit/Mockito/Hamcrest and `ggbjdk` are test-only. |
| `shared:renderer-base` | `canvas-base` | J2ObjC, JSpecify. |
| `shared:editor-base` | `renderer-base` | J2ObjC; JavaCC; JUnit test dependencies. |
| `shared:canvas-base` | — | SpotBugs annotations; JSpecify. |
| `shared:keyboard-base` | — | JUnit test dependencies only. |
| `shared:keyboard-scientific` | `keyboard-base` | JUnit test dependencies. Not in `:desktop:runtimeClasspath`. |
| `shared:ggbjdk` | `canvas-base` | SpotBugs and J2ObjC. Used by tests; not in production desktop runtime. |
| `shared:giac-jni` | — | Native extraction/test task references classified `javagiac` native runtime artifacts. |
| `shared:xr-base` | `common` | Not reached by the desktop runtime graph; no jar was present in the reviewed built-libs inventory. |
| `desktop:desktop` | `common`, `common-jre`, `canvas-desktop`, `editor-desktop`, `jogl2`, `giac-jni` | FlatLaf; JSObject shim; OpenGeoProver; JNA; EchoSVG; Rhino engine; JOGL, GlueGen and GIAC platform-specific native artifacts; JUnit/Mockito/Hamcrest test-only. |
| `desktop:canvas-desktop` | `canvas-base` | — |
| `desktop:editor-desktop` | `renderer-desktop`, `editor-base` | — |
| `desktop:renderer-desktop` | `canvas-desktop`, `renderer-base` | JUnit test dependencies. |
| `desktop:jogl2` | — | JOGL 2.6.0 and GlueGen RT 2.6.0. |

No cycle appears in the listed Gradle project edges. This is a source dependency-graph check; it is not a proof that bytecode has no reflective/service/resource dependency or that OSGi package wiring will resolve.

### 1.2 External runtime artifacts

`runtimeClasspath` resolved **50 distinct coordinates** and 58 files, including OS classifier variants. Of those, 11 are dependent GeoGebra project artifacts; 39 are external coordinates (some have multiple native classifier jars). Main families include:

- Apache math-cross-platform; J2ObjC annotations; SpotBugs annotations; JSpecify; JSR-305.
- Mozilla Rhino and Rhino engine.
- JOGL + GlueGen Java jars and Windows/Linux/macOS native classifier jars.
- `javagiac` JNI native classifier jars.
- FlatLaf, OpenGeoProver, JNA, JSObject compatibility jar, EchoSVG and its `io.sf.carte`, `io.sf.jclf`, and `io.sf.w3` transitive graph, plus ANTLR.

The direct/transitive exact coordinates and local cache paths are in `Audit_B_Runtime_Artifacts_CODEX_V1.txt`; Gradle's full dependency tree is in the raw file above. This avoids treating a dependency version written in a version catalog as proof of the selected runtime artifact.

### 1.3 OSGi readiness check of resolved jars

Read `META-INF/MANIFEST.MF` from every resolved external runtime jar file. Only the following four external coordinates had a `Bundle-SymbolicName` header in the inspected artifact:

| Coordinate | Observed BSN | Assessment |
|---|---|---|
| `com.github.spotbugs:spotbugs-annotations:4.10.2` | `spotbugs-annotations` | Header exists; validate package exports/imports. |
| `com.google.code.findbugs:jsr305:3.0.2` | `org.jsr-305` | Header exists; validate resolver. |
| `net.java.dev.jna:jna:5.18.1` | `com.sun.jna` | Header exists; native extraction/initialization remains a separate concern. |
| `org.jspecify:jspecify:1.0.0` | `org.jspecify.jspecify` | Header exists; validate resolver. |

The remaining 35 of 39 external coordinates did **not** have `Bundle-SymbolicName` in the exact cached runtime jar inspected. They need a tested wrapper/generated manifest or alternative supported packaging. Absence of a BSN does not itself prove a jar cannot be wrapped. Presence of a BSN does not prove the bundle is complete or compatible with this product. Native classifier jars are not ordinary Java API bundles.

JOGL/GlueGen and GIAC must be treated separately as native-enabled components. Do not build their metadata by assuming that `Bundle-NativeCode` alone fixes the code's actual resource/native lookup.

## 2. OSGi relevance and caveats

- The actual production runtime includes 12 internal Gradle outputs if `:desktop` is counted: `common`, `common-jre`, `renderer-base`, `editor-base`, `canvas-base`, `keyboard-base`, `giac-jni`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, `jogl2`, and `desktop`.
- `keyboard-scientific`, `ggbjdk`, and `xr-base` exist in the Gradle source build, but are not resolved by `:desktop:runtimeClasspath`; the first two are not desktop runtime dependencies in the graph and `xr-base` is unused by it.
- `:desktop:runtimeClasspath` does not make all declared test dependencies part of the shipped RCP.
- Native libraries are selected by Gradle variant dependencies; an OSGi RCP needs a product-level OS/architecture selection and a tested load policy.

## 3. Recommendation from this dependency audit

Use the resolved runtime graph, not the source-module inventory, to define the first Equinox target. Keep Gradle project boundaries untouched. Generate OSGi metadata externally, then resolve the exact runtime graph in Equinox. Before deciding between separate bundles and an aggregate core bundle, resolve the source package split found in Task A (`desktop` + `jogl2`) and prove GIAC/JOGL loading. Do not bundle test-only artifacts into the user product.

**Unresolved:** exact artifact/package graph after adding OSGi metadata; native/runtime behavior; whether `xr-base` should be included in any future desktop feature; the accepted target OS/architecture matrix.
