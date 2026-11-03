<!-- CLAUDE_V1 -->
# CDC — GIAC/Xcas Integration in AlgoGebra RCP

| Field | Value |
|---|---|
| Document | `02-Cdc/Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Draft — needs owner review |
| Date | 2026-10-29 |
| Supersedes | None (first GIAC-specific spec) |
| Depends on | `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` (scenarios D-05, X-04) |
| Source pin | GeoGebra `375db7faf54`, `5.4.934.0` |
| License | EUPL 1.2 (source), non-commercial (overall package) |

---

## 1. Purpose

Define the target architecture for GIAC (Xcas CAS engine) integration in the AlgoGebra RCP product, from the current spike proof to a production-grade native loading mechanism. This document covers:

- How GIAC works in upstream GeoGebra (code-level anatomy)
- What the spike proved and what remains open
- MVP acceptance criteria
- Owner decisions required

---

## 2. GIAC in upstream GeoGebra — code-level anatomy

### 2.1 The four-layer stack

```
┌──────────────────────────────────────────────────────────┐
│  Layer 4: GeoGebra Kernel                                │
│  CASgiac (common) — command translation, caching,        │
│  Ggb2giac translation table (~450 command mappings)      │
│  CASgiac.evaluateRaw() → CASgiacB → CASgiacJre          │
│  Package: org.geogebra.common.cas.giac                   │
│  Module: common (UNTOUCHABLE)                            │
├──────────────────────────────────────────────────────────┤
│  Layer 3: Platform binding                               │
│  CASGiacBinding interface (common) + CASGiacBindingJre   │
│  CASFactory.setPrototype(CASFactoryD) in AppD            │
│  CASFactoryD.newGiac() → CASgiacD                        │
│  Package: org.geogebra.common.cas.giac.binding (common)  │
│           org.geogebra.desktop.cas.giac (desktop)        │
│  Modules: common (interface), common-jre (impl),         │
│           desktop (factory + loader)                     │
├──────────────────────────────────────────────────────────┤
│  Layer 2: JNI bridge (SWIG-generated)                    │
│  giacJNI — 6 native methods (context, gen, eval, print)  │
│  context.java, gen.java — SWIG wrappers for giac::context│
│  and giac::gen (C++ objects holding evaluation state)     │
│  Package: javagiac                                       │
│  Module: giac-jni                                        │
├──────────────────────────────────────────────────────────┤
│  Layer 1: Native DLL/SO                                  │
│  javagiac64.dll (Win), libjavagiac64.so (Linux),         │
│  libjavagiac.jnilib (macOS), libjavagiac-arm64.jnilib    │
│  Compiled from C++ GIAC source via SWIG 1.3.40           │
│  Deployed in platform-classifier JARs                    │
│  (javagiac-70501-natives-windows-amd64.jar, etc.)        │
└──────────────────────────────────────────────────────────┘
```

### 2.2 Evaluation flow (string-in / string-out)

```
User types: Expand[(x+1)^2]
     │
     ▼
CASgiac.evaluateGeoGebraCAS()
  ├─ Ggb2giac lookup: "Expand.1" → "expand(%0)"
  ├─ Build Giac command string: "expand((x+1)^2)"
  ├─ Cache check (MaxSizeHashMap, 1000 entries)
  │
  ▼
CASgiacB.evaluateRaw()
  ├─ Init: caseval("init geogebra") + custom functions
  │
  ▼
CASgiacJre.callEvaluateFunction()
  ├─ Thread wrapper (timeout, cancel support)
  │
  ▼
CASGiacBindingJre (implements CASGiacBinding)
  ├─ new context()          → giacJNI.new_context__SWIG_0()   [JNI]
  ├─ new gen(expr, ctx)     → giacJNI.new_gen__SWIG_25()      [JNI]
  ├─ gen.eval(1, ctx)       → giacJNI.gen_eval()              [JNI]
  ├─ gen.print(ctx)         → giacJNI.gen_print__SWIG_0()     [JNI]
  │
  ▼
C++ GIAC engine: parse → evaluate → serialize
  │
  ▼
Return string: "x^2+2*x+1"
  │
  ▼
CASgiac: normalize, post-process, cache result
```

### 2.3 Native loading in upstream desktop

`CASgiacD` (desktop module) loads the native in a `static {}` block:

1. **Primary:** `NativeLibClassPathLoader.loadLibrary("javagiac64")`
   - Calls `ClassLoader.getSystemResourceAsStream("javagiac64.dll")`
   - Extracts to `java.io.tmpdir` with a random suffix
   - Calls `System.load(tmpFile.getAbsolutePath())`
   - Deletes temp file after load (load locks it on Windows, delete silently fails)
2. **Fallback:** `System.loadLibrary("javagiac64")` — for WebStart/`java.library.path`

**Key detail:** The upstream loader uses `ClassLoader.getSystemResourceAsStream()` — the **system/application classloader**, not the calling class's classloader. This works in a flat classpath but fails under OSGi because the system classloader doesn't see bundle-internal resources.

### 2.4 Web path (Emscripten/WASM)

`CASgiacW` uses `giac.wasm` compiled via Emscripten. The GWT transpiled Java calls into JavaScript via `JSInterop`. The WASM module exposes `__giac_eval()`. This path is completely separate from JNI and is **not affected** by the RCP native loading work.

### 2.5 The CASFactory abstraction

```java
// common (UNTOUCHABLE)
public abstract class CASFactory {
    private static volatile CASFactory prototype = new CASFactoryDummy();
    public static void setPrototype(CASFactory factory) { ... }
    public abstract CASGenericInterface newGiac(CASparser parser, Kernel kernel);
}

// desktop module
public class CASFactoryD extends CASFactory {
    public CASGenericInterface newGiac(CASparser p, Kernel k) {
        return new CASgiacD(p);  // triggers static {} native load
    }
}

// App startup: CASFactory.setPrototype(new CASFactoryD())
```

This factory pattern is the **integration seam** — whoever calls `setPrototype` controls which CAS implementation runs. The spike uses reflection to call this from the host bundle without depending on `desktop` at compile time.

---

## 3. What the spike proved (r3 installed image)

### 3.1 Native loading — boot delegation eliminated

The r3 installed image (`GeoGebraPlus-RCP-0.1.0-win32-x86_64-r3`) loads GIAC without boot delegation, `java.library.path`, or manual DLL extraction:

| Component | Mechanism | Status |
|---|---|---|
| `javagiac64.dll` | `GiacNativeBootstrap` fragment extracts from classifier JAR resource, `System.load` in `giac-jni` bundle's classloader | **PASS** |
| CAS evaluation | `Expand[(x+1)^2]` → `x^2+2x+1`, direct GIAC `1+1 → 2` | **PASS** |
| Factory wiring | Reflection-based `CASFactory.setPrototype(new CASFactoryD())` from host bundle | **PASS (spike adapter)** |

### 3.2 What the spike does NOT prove

1. **Upstream `NativeLibClassPathLoader` was not used.** The spike's `GiacNativeBootstrap` is a functionally equivalent replacement, but it's new code.
2. **Thread safety under Equinox.** `CASgiacJre` spawns evaluation threads; the spike tested single-threaded only.
3. **`CASFactory.setPrototype` via reflection is a spike adapter**, not a production integration seam.
4. **Linux/macOS natives** were not loaded.
5. **Error paths:** What happens when the DLL is absent, corrupt, or already loaded by a different classloader? The bootstrap has no fallback.

---

## 4. MVP definition

### 4.1 Goal

A **production-grade GIAC native loading mechanism** for the AlgoGebra RCP product that:
- Loads `javagiac64.dll` from the product's native-classifier JAR
- Works under Equinox classloader isolation (no boot delegation)
- Supports the upstream CAS evaluation flow unchanged (Layer 4 / Layer 3 stay intact)
- Does not modify `common` or `common-jre` source

### 4.2 MVP acceptance criteria

| ID | Criterion | Evidence required |
|---|---|---|
| **G-01** | GIAC DLL loads in the `giac-jni` bundle's classloader without `java.library.path` or boot delegation | Log shows `System.load` with absolute path, no `-Djava.library.path`, no `-Dorg.osgi.framework.bootdelegation` |
| **G-02** | `CASFactory.setPrototype` is called through a **supported mechanism** (not reflection on a private field) | Code review: either OSGi Declarative Services, bundle activator in `desktop` scope, or a host-owned factory registration |
| **G-03** | CAS evaluation passes: `Expand[(x+1)^2]` → `x^2+2x+1` | Log assertion |
| **G-04** | Direct GIAC smoke: `1+1` → `2` via `gen(expr, ctx).eval().print()` | Log assertion |
| **G-05** | Thread-safe evaluation: two concurrent CAS requests return correct results | Test fixture with 2 threads, each evaluating a different expression |
| **G-06** | Error handling: missing DLL produces a clear log message and `CASFactory` falls back to `CASFactoryDummy` (returns `?`) | Test with DLL removed from classpath |
| **G-07** | No `common` source diff | `git diff HEAD -- source/shared/common/src` is empty |
| **G-08** | Evidence per V2 §9 | date, commit, OS, Java, bundle set hash, command, expected, actual, log path |

### 4.3 Non-goals for MVP

- Linux/macOS natives (separate criterion, after Windows proof)
- CAS View UI integration (that's D-04 scope, not D-05)
- Timeout handling tuning (upstream defaults are acceptable)
- Custom GIAC function registration (AlgoGebra-specific algebra)
- Web/WASM path (completely separate architecture)

---

## 5. Architecture decisions required

### D-GIAC-01: Accept product-local loader or require upstream path?

**Context:** The spike's `GiacNativeBootstrap` does exactly what upstream's `NativeLibClassPathLoader` does — `getSystemResource` → extract to temp → `System.load`. The difference: it lives in a fragment of `giac-jni`, not in `desktop`.

| Option | Pros | Cons |
|---|---|---|
| **A. Accept product-local loader** (recommended) | No `common`/`desktop` edit needed. Fragment is external packaging metadata. Functionally identical to upstream. | New code to maintain. Must track upstream if GeoGebra changes their loading. |
| **B. Require upstream `NativeLibClassPathLoader`** | Uses proven upstream code path. | Requires `NativeLibClassPathLoader` to be visible from `giac-jni`'s classloader. It lives in `desktop` module → either edit `common` (forbidden) or complex OSGi import gymnastics. `AppD.WINDOWS`/`AppD.MAC_OS` platform flags are `desktop`-internal. |
| **C. Copy `NativeLibClassPathLoader` into the fragment** | Uses upstream logic verbatim. | Needs `AppD` platform constants and `UtilD.delete` — deep `desktop` dependencies. Would need to strip or replace them. |

**Recommendation:** Option A. The fragment loader is simpler, has no `desktop` dependencies, and does the same I/O. The upstream loader's platform detection (`AppD.WINDOWS`) is replaced by a simpler filename convention.

### D-GIAC-02: How to wire CASFactory without reflection?

**Context:** The spike calls `CASFactory.setPrototype(new CASFactoryD())` via reflection from the host bundle. `setPrototype` is a public static method, but the host doesn't have a compile-time dependency on `CASFactoryD` (which is in the `desktop` bundle).

| Option | Pros | Cons |
|---|---|---|
| **A. Host bundle Activator imports `CASFactoryD`** | Simple, explicit. Activator in `org.geogebra.plus.host` calls `setPrototype` directly. | Host bundle must `Import-Package: org.geogebra.desktop.factories`. Couples host to desktop. |
| **B. OSGi Declarative Services** | Decoupled. Desktop bundle declares a component that calls `setPrototype` on activation. | Adds DS runtime dependency. Over-engineered for a one-line factory registration. |
| **C. Desktop bundle's own Activator** | No host involvement. Desktop bundle activator calls `setPrototype(new CASFactoryD())` on `start()`. | Desktop bundle doesn't currently have an activator. New code in the desktop bundle wrapper. |
| **D. Fragment of desktop with a `BundleActivator`** | Fragments can't have activators. | Not possible. |

**Recommendation:** Option C. The desktop OSGi bundle wrapper gets a `BundleActivator` that calls `CASFactory.setPrototype(new CASFactoryD())`. This is the natural OSGi pattern — each bundle registers its own services/factories. The host doesn't need to know about CAS at all.

### D-GIAC-03: Temp file cleanup on Windows

**Context:** `System.load()` locks the DLL file on Windows. The upstream loader calls `UtilD.delete(tmpFile)` which silently fails because the file is locked. Temp files accumulate in `%TEMP%`.

| Option | Pros | Cons |
|---|---|---|
| **A. Accept temp file accumulation** (current) | Simple. Files are small (~8 MB). | Temp directory pollution over many launches. |
| **B. Shutdown hook deletes temp dir** | Clean shutdown = clean temp. | JVM crash or kill leaves orphans. Shutdown hooks are unreliable. |
| **C. Extract to a deterministic product-local dir** | No temp pollution. DLL persists between runs. Re-extract only on version change. | Must handle version mismatch. Cannot delete while running. |

**Recommendation:** Option C for the product. Extract to `<product>/natives/cache/<version>/` and skip extraction if the file exists with the correct size. Shutdown hook as fallback for temp-based extraction.

---

## 6. Component map

### 6.1 What exists (upstream, untouched)

| File | Module | Layer | Role |
|---|---|---|---|
| `CASgiac.java` | common | 4 | Command translation, caching, 450+ `Ggb2giac` mappings |
| `CASgiacB.java` | common | 4 | Base evaluation with init sequence |
| `Ggb2giac.java` | common | 4 | GeoGebra → Giac syntax translation table |
| `CASGiacBinding.java` | common | 3 | Cross-platform interface (`createContext`, `createGen`) |
| `CASFactory.java` | common | 3 | Static prototype pattern for CAS factory |
| `CASgiacJre.java` | common-jre | 3 | Thread wrapper, timeout, JNI bridge |
| `CASGiacBindingJre.java` | common-jre | 3 | `CASGiacBinding` impl using `javagiac.*` classes |
| `giacJNI.java` | giac-jni | 2 | SWIG-generated JNI stubs (6 native methods) |
| `context.java`, `gen.java` | giac-jni | 2 | SWIG wrappers for C++ `giac::context`, `giac::gen` |
| `CASgiacD.java` | desktop | 3 | Desktop CAS impl, static native loader |
| `NativeLibClassPathLoader.java` | desktop | 1 | Upstream native extraction + `System.load` |
| `CASFactoryD.java` | desktop | 3 | Desktop factory: `newGiac` → `new CASgiacD` |

### 6.2 What AlgoGebra adds (new files, external to upstream)

| File | Bundle | Layer | Role |
|---|---|---|---|
| `GiacNativeBootstrap.java` | Fragment of `giac-jni` | 1 | Product-local native loader (replaces `NativeLibClassPathLoader` under Equinox) |
| Desktop bundle `Activator` | `desktop` wrapper | 3 | Calls `CASFactory.setPrototype(new CASFactoryD())` on bundle start |
| Native classifier JARs | App-loader classpath | 1 | `javagiac-70501-natives-windows-amd64.jar` (and per-platform equivalents) |

### 6.3 What is NOT modified

- `common` — all of Layer 4 and the `CASFactory`/`CASGiacBinding` interfaces
- `common-jre` — the binding implementation and thread wrapper
- `giac-jni` — the SWIG-generated JNI stubs
- `desktop` — the CAS implementation classes (`CASgiacD`, `CASFactoryD`, `NativeLibClassPathLoader`)
- The C++ GIAC source or the compiled native DLLs

---

## 7. MVP implementation plan

### Phase 1: Native loader production-grade (Codex)

| Step | Deliverable | Acceptance |
|---|---|---|
| 1a | Harden `GiacNativeBootstrap`: add version-based cache dir, size check, fallback log | G-01, G-06 |
| 1b | Desktop bundle `Activator` calls `setPrototype` | G-02 |
| 1c | Verify CAS evaluation + direct GIAC smoke | G-03, G-04 |
| 1d | Thread-safety test fixture | G-05 |
| 1e | Evidence capture per V2 §9 | G-08 |

### Phase 2: Close D-05 (Claude review + owner decision)

| Step | Deliverable |
|---|---|
| 2a | Owner accepts D-GIAC-01 (product-local loader) |
| 2b | Claude reviews all evidence against G-01 through G-08 |
| 2c | D-05 marked PASS in V2 plan (or rejected with next action) |

### Phase 3: Multi-platform (Codex + Grok Bot)

| Step | Deliverable |
|---|---|
| 3a | Linux x86_64 native loading (`libjavagiac64.so`) — Codex implementation, Grok Bot test |
| 3b | macOS aarch64 native loading (`libjavagiac-arm64.jnilib`) — if hardware available |
| 3c | Platform detection in `GiacNativeBootstrap` (filename and resource path per OS/arch) |

---

## 8. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `CASgiacD` static initializer runs before fragment bootstrap | Medium | DLL loads in wrong classloader → `UnsatisfiedLinkError` | Bundle start-level ordering: `giac-jni` (and fragment) before `desktop` |
| Thread-safety issue in GIAC C++ under concurrent JNI calls | Low | Crash or wrong result | GIAC uses per-context state; `CASgiacJre` already synchronizes. Test with concurrent fixture. |
| Temp dir DLL accumulation on Windows | Low | Disk usage over time | Version-based cache dir (D-GIAC-03 Option C) |
| Future GeoGebra upstream changes to `NativeLibClassPathLoader` | Low | Product loader diverges from upstream | Product loader is simpler (no `AppD` deps). Monitor upstream git log for `NativeLibClassPathLoader` changes. |
| `CASFactory.setPrototype` called too late (after first CAS use) | Medium | Dummy factory returns `?` | Desktop activator runs on bundle start; ensure start-level is before first `Kernel` construction |

---

## 9. Relation to other scenarios and documents

| Scenario/Document | Relation |
|---|---|
| **D-05** (V2) | This CDC specifies the full D-05 closure path for GIAC. JOGL native loading has its own parallel spec (to be written). |
| **D-04** (V2) | The "Please check your input" warning may be a CAS-related issue (parse error from GIAC) or a focus/keypress issue. Separate investigation. |
| **X-04** (V2) | External computation services. GIAC is the **internal** CAS — not an external service. X-04 is about connecting external algorithms (physics, discrete math) to the kernel. |
| **Gate B** | D-05 PASS (GIAC + JOGL natives load) is required for Gate B. This CDC covers the GIAC half. |
| `Gate_Decision_D-04_D-05_GROK_V1.md` | Validated 2026-10-29. States D-05 stays PARTIAL until owner reviews the loader replacement. This CDC provides the review framework. |
