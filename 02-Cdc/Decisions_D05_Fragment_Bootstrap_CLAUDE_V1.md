<!-- CLAUDE_V1 -->
# Decision Record — D-05 Fragment Bootstrap Architecture

| Field | Value |
|---|---|
| Document | `02-Cdc/Decisions_D05_Fragment_Bootstrap_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Decision | **Accept the three product-local OSGi fragment bootstraps as the production native loading architecture** |
| Status | **CLOSED** — D-05 native loading is PASS |
| Evidence | Installed image `GeoGebraPlus-RCP-0.1.0-win32-x86_64-r3`, log `rcp-20261029-073727-5656-eee96ccd.log` |
| Prior gate | `Gate_Decision_D-04_D-05_GROK_V1_1.md` — Grok already accepted the fragment approach |

---

## 1. Decision

The GeoGebraPlus RCP product loads GIAC, GlueGen, and JOGL native libraries via **three product-local OSGi fragment bootstraps**:

| Fragment | Attaches to | Loads |
|---|---|---|
| `GiacNativeBootstrap` | `org.geogebra.migration.shared.giac.jni` | `javagiac64.dll` |
| `GeoGebraPlusGlueGenNativeBootstrap` | GlueGen bundle | `gluegen_rt.dll` |
| `GeoGebraPlusJoglNativeBootstrap` | JOGL bundle | 5 DLLs: `nativewindow_awt`, `nativewindow_win32`, `newt_head`, `jogl_desktop`, `jogl_mobile` |

Each fragment:
1. Reads the native DLL from the owning bundle's classifier-JAR resource
2. Extracts it to a unique temporary directory
3. Calls `System.load()` with the absolute path from the owning bundle's Equinox classloader

This replaces both:
- GeoGebra's upstream `NativeLibClassPathLoader` (which cannot work under Equinox classloader isolation)
- The earlier boot delegation workaround (`-Dorg.osgi.framework.bootdelegation=com.jogamp.*`)

## 2. Rationale

| Concern | Assessment |
|---|---|
| **Why not `NativeLibClassPathLoader`?** | It uses `ClassLoader.getSystemClassLoader()` which bypasses OSGi isolation. Forcing it would require editing `common` (forbidden) or adding classloader tricks with no functional gain. |
| **Why not boot delegation?** | Boot delegation puts JogAmp on the application loader, breaking OSGi isolation. The r3 strict run proved boot delegation is unnecessary. |
| **Why not JogAmp's own JAR extractor?** | It fails under Java 25 / Equinox (`JVMUtil.initialize(ByteBuffer)` error). The product-local fragments are the viable alternative. |
| **Is `common` modified?** | No. The fragments are product-local, not upstream patches. |
| **Is this a fork?** | No. It's new product code that loads the same DLLs. GeoGebra source is untouched. |

## 3. Evidence summary

**Strict installed-image run (r3, 2026-10-29):**
- Command: `.\launch.ps1 -NoBuild` — no `-ManualNativeFallback`, no `-BootDelegateJogAmp`
- Boot delegation reported: `null`
- GIAC: `javagiac64.dll` loaded; `1+1 → 2`; `Expand[(x+1)^2] → x^2+2x+1`
- GlueGen: `gluegen_rt.dll` loaded
- JOGL: 5 DLLs loaded, no `UnsatisfiedLinkError`
- 3D: App3D initialized, point command accepted

**Grok gate review (V1_1):** "Accept the three product-local fragments as the Equinox native architecture. Do not require `NativeLibClassPathLoader` to run under Equinox."

**Debian confirmation:** Suite 10 `D05_Strict3D` passes on Debian with Mesa llvmpipe (same fragment approach, Linux natives).

## 4. Remaining limits

| Item | Status | Impact |
|---|---|---|
| Windows x86_64 only | Linux passes on Debian (Grok). macOS untested. | macOS deferred per binding decision (Windows first). |
| Strict-mode 3D screenshot | Not captured on r3 strict run. Earlier screenshot under boot delegation. | Evidence hygiene — Grok V1_1 says "not a reason to reopen the loader decision". |
| CAS factory via reflection | Spike adapter, not public API | Production CAS init needs a proper seam (EE-P3 scope) |
| JOGL/GlueGen bootstraps use `ClassLoader.getSystemResource` | Falls back only to system classloader, not bundle classloader | Constraint documented. Works because classifier JARs are on app-loader classpath. |

## 5. Gate B impact

With this decision, D-05 is **PASS**. Gate B status:

| Scenario | Status |
|---|---|
| D-02 | **PASS** |
| D-03 | **PASS** |
| D-04 | **PASS** (core; issue #33 tracked separately) |
| D-05 | **PASS** (this decision) |
| D-06 | **NOT RUN** |

Gate B requires D-02..D-06. After D-06, Gate B can close.

---

*End of `Decisions_D05_Fragment_Bootstrap_CLAUDE_V1.md`.*
