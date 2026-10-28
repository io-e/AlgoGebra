<!-- CLAUDE_V1_1 -->
# Codex Handoff — Code Audit: GeoGebra + Eclipse Equinox Integration

**Date:** 2026-10-28
**From:** Claude Opus 4.6
**To:** Codex
**Purpose:** Audit the GeoGebra source and Eclipse installation to determine the integration path for GeoGebraPlus RCP.
**Status:** **COMPLETED** — All 5 tasks delivered. See `Audit_{A,B,C,D,E}_*_CODEX_V1.md` and `osgi-manifest-drafts/`.

---

## 1. The question to answer

There are two possible integration paths for building the GeoGebraPlus desktop RCP product:

| Path | Start from | Add | Risk |
|---|---|---|---|
| **A. Eclipse → GeoGebra** | Eclipse RCP product (Equinox framework) | GeoGebra jars as OSGi bundles inside the RCP shell | Must wrap 14 jars with OSGi metadata, resolve split packages, handle JOGL/GIAC native loading under Equinox classloaders |
| **B. GeoGebra → Equinox** | GeoGebra Gradle build as-is | Embed Equinox as the OSGi framework, launched from the existing `GeoGebra3D` main class | Must add Equinox launcher dependency to Gradle, manage dual lifecycle (Swing app + OSGi container) |

**Codex must produce a recommendation with evidence.** The answer is not obvious: GeoGebra is a Swing application with JOGL native dependencies and no OSGi metadata whatsoever. Eclipse RCP normally centers SWT/JFace. Neither path is free.

---

## 2. Codebase locations

| Resource | Path | What it is |
|---|---|---|
| GeoGebra source | `D:\ALF_ZGit\G1_Geogebra_Migration` | Upstream clone, commit `375db7faf54`, `main` branch |
| Eclipse IDE 2026-09 | `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` | Installed IDE with Equinox 3.24.300 and Java 25 |
| Architecture spec | `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc\Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` | Binding decisions and 45 scenarios |
| This handoff | `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc\Codex_Audit_GeoGebra_Eclipse_Integration_CLAUDE_V1.md` | What you're reading |

---

## 3. What Claude already found

### 3.1 GeoGebra module inventory (Java file counts)

```
shared/common:              3745 files  (org.geogebra.common.* + 69 third-party files)
shared/common-jre:           775 files
shared/renderer-base:        522 files
shared/editor-base:           95 files
shared/canvas-base:           35 files
shared/keyboard-base:         40 files
shared/keyboard-scientific:    7 files
shared/ggbjdk:                41 files
shared/giac-jni:               6 files
shared/xr-base:               10 files
desktop/desktop:             876 files
desktop/canvas-desktop:       30 files
desktop/editor-desktop:        4 files
desktop/renderer-desktop:     16 files
desktop/jogl2:                 5 files
web/*:                      1234 files  (not needed for desktop RCP)
```

**Total desktop runtime: ~6207 Java source files across 14 modules.**

### 3.2 No OSGi metadata exists

- **No `module-info.java`** anywhere — GeoGebra does not use JPMS.
- **No `.bnd` files** — no bnd/bndtools configuration.
- **MANIFEST.MF files are build output only** — `build/tmp/jar/MANIFEST.MF` contains just `Manifest-Version: 1.0`, no `Bundle-SymbolicName`, no `Export-Package`, no OSGi headers.
- **No OSGi dependency** in `libs.versions.toml` or any `build.gradle.kts`.

This means: every jar needs OSGi metadata generated from scratch.

### 3.3 Split packages identified

OSGi forbids two bundles from exporting the same package. Current splits:

| Package | Appears in | Severity |
|---|---|---|
| `org.geogebra.common` | `common` + `common-jre` | **HIGH** — root package of both modules |
| `org.geogebra.common` | `common` + `canvas-base` | **HIGH** — same root package |

These are the root `org.geogebra.common` package only (likely interfaces/classes at that level). Sub-packages are cleanly separated. But OSGi package resolution is flat — any class in `org.geogebra.common` from two different bundles is a conflict.

### 3.4 Third-party code bundled inside `common`

The `common` jar bundles **69 Java files** that are NOT `org.geogebra`:

- `com.github.quickhull3d` — 3D convex hull algorithm
- `edu.uci.ics.jung.*` — JUNG graph library (algorithms, collections, graph)
- `org.geogebra.regexp` — regex (separate package, not a split)

These are **vendored dependencies** (source-copied, not external jars). Under OSGi, they'd be `Private-Package` in the bundle — but if another bundle tries to import them, there's no external provider.

### 3.5 Desktop entry points

```
org.geogebra.desktop.GeoGebra3D     — main class (3D, the default)
org.geogebra.desktop.GeoGebra       — main class (2D only)
org.geogebra.desktop.GeoGebraPanel   — embeddable JPanel (key for RCP hosting)
org.geogebra.desktop.spreadsheet.SpreadsheetDemo — demo
```

`GeoGebraPanel` is the most relevant for RCP integration: it's a `JPanel` that can be embedded in a Swing container, which can then be embedded in SWT via `SWT_AWT` bridge.

### 3.6 JOGL native loading problem

`desktop/build.gradle.kts` lines 84-106: JOGL cannot use `java.library.path` or classpath. The build **copies native jars beside the main jars** at runtime. Equinox's bundle classloader will NOT do this automatically. The native loading mechanism must be explicitly handled.

Libraries requiring native loading:
- JOGL 2.6.0: `jogl-all-2.6.0-natives-{linux-amd64,windows-amd64,macosx-universal}.jar`
- Gluegen RT 2.6.0: `gluegen-rt-2.6.0-natives-*.jar`
- GIAC (javagiac 70501): `javagiac-70501-natives-*.jar` (JNI)

### 3.7 Eclipse Equinox available

Eclipse IDE 2026-09 ships:
- `org.eclipse.osgi_3.24.300.v20260721-1251.jar` (Equinox framework)
- 53 Equinox plugins in `plugins/`
- Java 25 (JustJ OpenJDK HotSpot 25.0.4)
- `eclipse.ini` requires `-Dosgi.requiredJavaVersion=25`

### 3.8 Existing tests

- `common-jre`: **690 test files** + 37 test fixtures — this is the main test suite
- `desktop`: **55 test files**
- Tests use JUnit 5 (Jupiter + Vintage bridge for JUnit 4)

---

## 4. Audit tasks for Codex

### Task A: Package ownership report (V2 scenario D-03)

**Goal:** Produce a complete map of which Java packages belong to which module, and flag every conflict.

**Steps:**
1. For each of the 14 modules (10 shared + 4 desktop + jogl2), list all Java packages in `src/main/java`.
2. Find every package that appears in more than one module (split packages).
3. For each split, list the classes in each side. Determine if the split is: (a) identical interfaces, (b) platform-specific implementations, or (c) accidental duplication.
4. Flag the vendored third-party packages in `common` (`com.github.quickhull3d`, `edu.uci.ics.jung`).
5. Output: a TSV or JSON with columns `package | module | class_count | split_with | severity`.

**File to start:** `D:\ALF_ZGit\G1_Geogebra_Migration\source\shared\common\src\main\java\org\geogebra\common\` — inspect what classes live at the root `org.geogebra.common` level (not in sub-packages) in both `common` and `common-jre`.

### Task B: Dependency graph

**Goal:** Map which modules depend on which, and which external libraries each pulls.

**Steps:**
1. Parse `build.gradle.kts` for each of the 14 modules. Extract `implementation()`, `api()`, `runtimeOnly()` dependencies.
2. Build a directed graph: module → module and module → external library.
3. Identify circular dependencies (should be none, but verify).
4. For each external library, note if it has an OSGi-ready jar (many Maven Central jars include `Bundle-SymbolicName` in MANIFEST.MF already).
5. Output: a dependency graph (text or DOT format) and a list of external libs with OSGi status.

**Key files:**
- `D:\ALF_ZGit\G1_Geogebra_Migration\source\desktop\desktop\build.gradle.kts`
- `D:\ALF_ZGit\G1_Geogebra_Migration\source\shared\common\build.gradle.kts`
- `D:\ALF_ZGit\G1_Geogebra_Migration\source\shared\common-jre\build.gradle.kts`
- `D:\ALF_ZGit\G1_Geogebra_Migration\gradle\libs.versions.toml`

### Task C: OSGi wrapping feasibility

**Goal:** Determine the minimum set of `MANIFEST.MF` headers needed to make the 14 jars loadable by Equinox.

**Steps:**
1. For each module, draft `Bundle-SymbolicName`, `Bundle-Version`, `Export-Package`, `Import-Package`, `Bundle-NativeCode` (for JOGL/GIAC).
2. For the split packages found in Task A, propose one of:
   - Merge the two modules into one bundle (if they're always co-deployed)
   - Make one a fragment of the other (`Fragment-Host`)
   - Use `Require-Bundle` instead of `Import-Package` (less modular but avoids the split)
3. For JOGL native loading, research whether `Bundle-NativeCode` header can replace the current copy-beside-jar hack, or whether the bundle must use `System.loadLibrary()` with a native code path.
4. Output: a draft `MANIFEST.MF` per module and a list of unresolved issues.

### Task D: Integration path comparison

**Goal:** Produce a scored comparison of Path A (Eclipse → GeoGebra) vs Path B (GeoGebra → Equinox).

**Criteria to score (1-5 each):**

| Criterion | What to measure |
|---|---|
| **Build complexity** | How many files change? Does the existing Gradle build break? |
| **Native loading** | Can JOGL/GIAC natives load correctly? |
| **Swing/SWT coexistence** | Does `SWT_AWT` bridge work for `GeoGebraPanel`? Is it needed? |
| **Upstream compatibility** | Can the next GeoGebra commit be pulled without conflict? (V2 scenario O-01) |
| **Extension point** | Where does the GeoGebraPlus host bundle register its OSGi services? |
| **Startup time** | Does Equinox add measurable overhead to GeoGebra launch? |

**For Path A:**
- Start from the Eclipse RCP target platform definition.
- Add GeoGebra jars as bundles in the target platform.
- Create an RCP `Application` that opens a Swing `GeoGebraPanel` inside an SWT shell.
- The existing Eclipse at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` provides the Equinox runtime. Its `plugins/` directory has the framework jars.

**For Path B:**
- Start from the GeoGebra Gradle build.
- Add `org.eclipse.osgi` as a dependency.
- Modify `GeoGebra3D.main()` to start Equinox programmatically (`EclipseStarter.run()`).
- GeoGebra itself stays a plain Swing app; Equinox runs as an embedded container for discovering extension bundles.

### Task E: Run existing tests

**Goal:** Establish the test baseline on commit `375db7faf54`.

**Steps:**
1. Run `./gradlew -p source/shared :common-jre:test` — record pass/fail count and duration.
2. Run `./gradlew -p source/desktop :desktop:test` — record pass/fail count and duration.
3. Save the results as the P-02/P-03 baseline reference (V2 Phase 0).
4. Note any test that requires a display (headless vs headed), CAS (GIAC), or 3D (JOGL).

---

## 5. Binding constraints (do not violate)

1. **Do NOT edit files under `source/shared/common/src`.** This is the upstream `common` module and must stay untouched (V2 binding decision).
2. **Do NOT delete or reset the existing build outputs.** `build/` directories contain the successful compilation from the previous session.
3. **Do NOT push to any remote.** All work stays local.
4. **Do NOT modify the Eclipse installation.** It's a reference, not a workspace.
5. **OSGi metadata goes in new files** (Gradle plugin config, `.bnd` files, or separate manifest templates), never in upstream source.

---

## 6. Output format

For each task, produce a file under `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc\` named:

```
Audit_<TaskLetter>_<ShortName>_CODEX_V1.md
```

Example: `Audit_A_Package_Ownership_CODEX_V1.md`

Each file must include:
- The exact command(s) run
- Raw data (counts, package lists, dependency edges)
- Analysis and recommendation
- Unresolved questions for Claude (architecture) or Grok Bot (Debian testing)

---

## 7. Priority order

1. **Task E** first (run tests) — establishes the baseline. Fast, low risk.
2. **Task A** (package ownership) — the split package question blocks everything.
3. **Task B** (dependency graph) — needed for Task C.
4. **Task C** (OSGi wrapping) — the hard technical work.
5. **Task D** (path comparison) — the recommendation, informed by A-C.

---

## 8. What Codex does NOT do

- **Architecture decisions** — Claude owns those. Codex provides evidence.
- **Debian/Linux integration tests** — Grok Bot owns those. Codex works on Windows.
- **Web client analysis** — out of scope for this audit. The web side (GWT, W-01) is separate.
- **GeoGebraPlus host bundle implementation** — that's Phase 2. This audit is Phase 1 feasibility.
