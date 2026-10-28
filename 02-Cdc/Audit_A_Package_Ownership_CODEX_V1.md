# Task A — Java Package Ownership Audit

**Scope:** shared + desktop source modules in GeoGebra; read-only scan of `src/main/java`.
**Repository:** `D:\ALF_ZGit\G1_Geogebra_Migration`
**Command:** `python .claude/audit_package_ownership.py D:\ALF_ZGit\G1_Geogebra_Migration D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc`
**Modules scanned:** 15; **Java source files:** 5406; **unique packages:** 385; **split packages:** 1.
**Full raw map:** `Audit_A_Package_Ownership_CODEX_V1.tsv`.

## Source file counts by module

| Module | Java source files |
|---|---:|
| `common` | 3745 |
| `common-jre` | 48 |
| `renderer-base` | 522 |
| `editor-base` | 90 |
| `canvas-base` | 35 |
| `keyboard-base` | 38 |
| `keyboard-scientific` | 5 |
| `ggbjdk` | 41 |
| `giac-jni` | 6 |
| `xr-base` | 10 |
| `desktop` | 815 |
| `canvas-desktop` | 30 |
| `editor-desktop` | 4 |
| `renderer-desktop` | 14 |
| `jogl2` | 3 |

## Split package findings

| Package | Modules | Class files by module |
|---|---|---|
| `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` | `desktop`, `jogl2` | `desktop`: JoglAndGluProvider.java, ManagerGLList.java, RendererCheckGLVersionD.java, RendererImplGL2.java, RendererImplShadersD.java<br>`jogl2`: Animator.java, Component3D.java, RendererJogl.java |

## Vendored/non-GeoGebra packages in `common`

| Package | Classes |
|---|---:|
| `com.github.quickhull3d` | 10 |
| `edu.uci.ics.jung.algorithms.blockmodel` | 1 |
| `edu.uci.ics.jung.algorithms.cluster` | 1 |
| `edu.uci.ics.jung.algorithms.filters` | 1 |
| `edu.uci.ics.jung.algorithms.matrix` | 2 |
| `edu.uci.ics.jung.algorithms.metrics` | 1 |
| `edu.uci.ics.jung.algorithms.scoring` | 3 |
| `edu.uci.ics.jung.algorithms.scoring.util` | 1 |
| `edu.uci.ics.jung.algorithms.shortestpath` | 9 |
| `edu.uci.ics.jung.algorithms.util` | 7 |
| `edu.uci.ics.jung.collections` | 4 |
| `edu.uci.ics.jung.graph` | 18 |
| `edu.uci.ics.jung.graph.event` | 2 |
| `edu.uci.ics.jung.graph.util` | 9 |

## Root package class listings

Only files whose declared package is exactly `org.geogebra.common` are listed here.

- `common` (2): GeoGebraConstants.java, SuiteSubApp.java
- `common-jre` (0): none
- `canvas-base` (0): none

## Interpretation and limitations

- This is package ownership from source declarations, not a full OSGi resolver result.
- All packages shared by modules are flagged; confirm the exact emitted jars and runtime co-deployment before choosing a fix.
- A bundle wrapper does not by itself solve a true split package or define a stable plugin API.
- No source files were modified.
