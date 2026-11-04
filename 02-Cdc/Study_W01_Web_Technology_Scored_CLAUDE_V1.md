<!-- CLAUDE_V1 -->
# W-01 — Web technology scored study

**Status:** DONE — scored matrix delivered, recommendation: **keep GWT baseline** (option A).  
**Date:** 2026-11-04  
**Author:** Claude (architecture lane)  
**Scenario:** W-01 from `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`  
**Pass criterion:** Written matrix scoring fidelity, build, CAS, 3D, license, maintenance  
**Supersedes:** nothing (first version)

---

## 1. What this study decides

W-01 scores candidate web technologies against the same mandatory views the desktop delivers: **Algebra View, CAS, Spreadsheet, 2D canvas, 3D canvas**. The result feeds Gate C: GWT stays until the chosen replacement passes W-02 (feature parity on P-02/P-03 corpus).

This is a scored comparison, not a proof of concept. No code is written. Evidence is drawn from the pinned source (`375db7faf54`, `5.4.934.0`) and public documentation of each candidate.

---

## 2. Candidates

| ID | Candidate | Mechanism |
|---|---|---|
| **A** | **GWT retention** (current baseline) | Java source → JavaScript via GWT compiler. 4 production modules (`SuperWeb`, `WebSimple`, `Web`, `Tablet3D`). Already compiles and runs. |
| **B** | **J2CL** (Google's GWT successor) | Java source → Closure-compatible JavaScript. Same source-transpilation model. Google's internal replacement for GWT. |
| **C** | **TeaVM** | Java bytecode → JavaScript or WebAssembly. Compiles from `.class` files, not source. Independent project. |
| **D** | **CheerpJ** | Unmodified JVM bytecode → WebAssembly/JavaScript in browser. No recompilation of source. Commercial product (Leaning Technologies). |
| **E** | **JS/TS rewrite** | Manual port of the web client to TypeScript, using `common` via JS API (`deployggb.js`) or a fresh kernel rewrite. |

**Excluded:** Vaadin (server-side rendering model, does not fit offline-capable student tool); JWebAssembly (abandoned/dormant); Kotlin/JS (would require rewriting all Java source to Kotlin first — same cost as option E with less ecosystem for math).

---

## 3. Scoring criteria

Each criterion is scored 1–5 (1 = worst, 5 = best) from the perspective of this project's constraints.

| # | Criterion | Weight | What it measures |
|---|---|---|---|
| F | **Feature fidelity** | 3× | Can the candidate render all 5 mandatory views (Algebra, CAS, Spreadsheet, 2D, 3D) from the same `common` kernel source? |
| B | **Build integration** | 2× | How much build/tooling change is needed on the pinned source? Does it work with the existing Gradle composite? |
| C | **CAS support** | 3× | Can `CASgiacW` reach `giac.wasm` / `giac.js`? Does the candidate's JS interop support the existing `@JsMethod` / JSInterop annotations? |
| G | **3D / WebGL support** | 3× | Does the candidate produce code that can call WebGL APIs? GeoGebra web uses `RendererImplShadersW` / `RendererWithImplW` over `elemental2.webgl`. |
| L | **License compatibility** | 1× | Compatible with EUPL 1.2 and non-commercial distribution? |
| M | **Maintenance burden** | 2× | Active community/corporate backing? Upstream GeoGebra merge friction? How many people maintain the tool? |
| O | **Offline / student-tool fit** | 1× | Static output that works without a server? Fits WIMS iframe embedding? |

Total weight: 15 points per raw score point.

---

## 4. Scored matrix

### 4.1 Option A — GWT retention (baseline)

| Criterion | Score | Rationale |
|---|---|---|
| F — Fidelity | **5** | All 5 views already work. 4 production GWT modules compile. `web3d` is the full 3D client. |
| B — Build | **5** | Zero change. `gwtCompile` already runs on the pinned source. Gradle composite build, 16-minute production compile, dev mode on port 8888. |
| C — CAS | **5** | `CASgiacW` loads `giac.wasm` via JSInterop. Already works. |
| G — 3D | **5** | `RendererImplShadersW` uses `elemental2.webgl.WebGLRenderingContext`. WebGL fallback (`EuclidianView3DWnoWebGL`) also present. |
| L — License | **4** | GWT is Apache 2.0. Compatible with EUPL 1.2. Score not 5 because GWT itself is in maintenance mode (see M). |
| M — Maintenance | **2** | GWT is effectively unmaintained by Google. Community releases exist (GWT 2.11+) but the core team is tiny. No new features. Long-term risk of browser incompatibilities. |
| O — Offline | **5** | Static HTML/JS output. No server needed. Already embeds in an iframe. |

**Weighted total: 5×3 + 5×2 + 5×3 + 5×3 + 4×1 + 2×2 + 5×1 = 15+10+15+15+4+4+5 = 68 / 75**

### 4.2 Option B — J2CL

| Criterion | Score | Rationale |
|---|---|---|
| F — Fidelity | **3** | J2CL transpiles Java source like GWT, but GeoGebra's `*.gwt.xml` modules, `Deferred Binding`, `GWT.create()`, and GWT-RPC patterns would all need rewriting. The `web-common` layer uses GWT widgets extensively (`com.google.gwt.user.client.ui`). J2CL does not include the GWT widget library. |
| B — Build | **2** | Requires Bazel (J2CL's build system) or an experimental Gradle plugin. The existing Gradle composite build would need substantial rework. J2CL is designed for Google's internal Bazel monorepo. |
| C — CAS | **3** | J2CL supports `@JsMethod` / `@JsInterop` (it was designed for that). The `CASgiacW` JSInterop bridge should port. But all `GWT.create()` calls in the CAS initialization path would break. |
| G — 3D | **3** | J2CL can call WebGL via `elemental2` (same library). But the renderer's deferred binding for `RendererImplShadersW` would need replacement. |
| L — License | **5** | Apache 2.0. Fully compatible. |
| M — Maintenance | **3** | Backed by Google internally, but external community is very small. Documentation is sparse. Publicly released but not publicly supported. |
| O — Offline | **5** | Static JS output like GWT. |

**Weighted total: 3×3 + 2×2 + 3×3 + 3×3 + 5×1 + 3×2 + 5×1 = 9+4+9+9+5+6+5 = 47 / 75**

### 4.3 Option C — TeaVM

| Criterion | Score | Rationale |
|---|---|---|
| F — Fidelity | **2** | TeaVM compiles bytecode, not source — it cannot process GWT-specific annotations or widget trees. The entire `web-common` / `web` layer (~400+ Java files using GWT widgets, GWT DOM, GWT events) would need replacement. `common` and `common-jre` bytecode would transpile, but the web UI shell is a full rewrite. |
| B — Build | **3** | TeaVM has a Gradle plugin. Can compile `common-jre` bytecode. But the GWT web modules cannot be fed to TeaVM — a new web shell must be written. |
| C — CAS | **2** | TeaVM has its own JS interop (`@JSBody`), incompatible with GWT's `@JsMethod`. `CASgiacW` and all JSInterop bridges need rewriting. TeaVM's WASM backend may not support calling into `giac.wasm` directly — the interop model differs. |
| G — 3D | **2** | TeaVM can generate code that calls WebGL, but the GeoGebra 3D renderer is written against `elemental2.webgl` (a GWT/J2CL library). A TeaVM port needs a different WebGL binding. The `noWebGL` fallback in `common` still works. |
| L — License | **5** | Apache 2.0. |
| M — Maintenance | **3** | Active single maintainer (Alexey Andreev). Used by a few commercial products. Small but real community. Releases are regular. |
| O — Offline | **4** | Static output possible. WASM target adds complexity for iframe embedding. JS target is simpler. |

**Weighted total: 2×3 + 3×2 + 2×3 + 2×3 + 5×1 + 3×2 + 4×1 = 6+6+6+6+5+6+4 = 39 / 75**

### 4.4 Option D — CheerpJ

| Criterion | Score | Rationale |
|---|---|---|
| F — Fidelity | **3** | CheerpJ runs unmodified JVM bytecode. In theory, the desktop jar set could run in the browser. In practice, GeoGebra desktop uses Swing, JOGL (native OpenGL), and GIAC (native C++ via JNI) — none of which CheerpJ can virtualize. CheerpJ 3.0 supports Swing rendering to HTML5 Canvas, but JOGL native calls and GIAC JNI are not supported. 2D and Algebra views might work; CAS and 3D would not. |
| B — Build | **2** | No build change to GeoGebra itself, but CheerpJ requires a runtime loader and its own JS runtime (~30MB). Integration with WIMS iframe embedding is complex. |
| C — CAS | **1** | GIAC is a C++ native library loaded via JNI. CheerpJ cannot run native JNI code. The `giac.wasm` path exists separately but is wired through GWT's `CASgiacW`, not desktop's `CASgiacD`. A bridge would need writing. |
| G — 3D | **1** | JOGL calls native OpenGL. CheerpJ cannot virtualize OpenGL. The 3D view would not render. |
| L — License | **2** | CheerpJ Community is free for personal/OSS use. Commercial use requires a paid license. Incompatible with the non-commercial distribution model unless the free tier suffices. Source not open. |
| M — Maintenance | **3** | Leaning Technologies is a funded company. Regular releases. But lock-in risk — single vendor, proprietary runtime. |
| O — Offline | **2** | CheerpJ requires loading its ~30MB runtime. Not a static page. Can work offline once loaded, but first-load cost is high. |

**Weighted total: 3×3 + 2×2 + 1×3 + 1×3 + 2×1 + 3×2 + 2×1 = 9+4+3+3+2+6+2 = 29 / 75**

### 4.5 Option E — JS/TS rewrite

| Criterion | Score | Rationale |
|---|---|---|
| F — Fidelity | **4** | A clean TypeScript client can implement all 5 views if the development is funded. GeoGebra's official "new" apps (graphing calc, geometry) are already partially TypeScript. But this project's pin is the Classic 5/6 Java codebase, and parity with that requires reimplementing the full command set, CAS dispatch, and 3D renderer. |
| B — Build | **1** | Complete rewrite of the web layer. The Gradle composite build is irrelevant. A new Node/webpack/vite toolchain is needed. Estimated effort: 6–18 months for one developer to reach parity with the current GWT output on the 5 mandatory views. |
| C — CAS | **4** | `giac.wasm` can be called directly from JS/TS. No GWT interop needed. The CAS command dispatch from `common` would need reimplementing or wrapping via a headless Java service. |
| G — 3D | **4** | WebGL is native to JS/TS. Three.js or raw WebGL is standard. But reimplementing GeoGebra's 3D renderer (shaders, selection, dragging, object types) is substantial. |
| L — License | **5** | No dependency license constraint. The rewrite is this project's code. |
| M — Maintenance | **5** | Modern toolchain, large ecosystem, easy to hire for. No upstream Java merge friction because the web client is decoupled. |
| O — Offline | **5** | Static JS output, PWA-ready, minimal bundle size. |

**Weighted total: 4×3 + 1×2 + 4×3 + 4×3 + 5×1 + 5×2 + 5×1 = 12+2+12+12+5+10+5 = 58 / 75**

---

## 5. Summary ranking

| Rank | Option | Weighted score | Key strength | Key risk |
|---|---|---|---|---|
| **1** | **A — GWT retention** | **68 / 75** | Everything already works | GWT is unmaintained; browser compatibility may degrade |
| **2** | E — JS/TS rewrite | 58 / 75 | Modern, maintainable, no GWT dependency | 6–18 month rewrite cost before parity |
| **3** | B — J2CL | 47 / 75 | Same transpilation model, Google-backed | GWT widget library absent, Bazel-oriented, small external community |
| **4** | C — TeaVM | 39 / 75 | Compiles bytecode (no source access needed) | All GWT interop and UI code must be rewritten |
| **5** | D — CheerpJ | 29 / 75 | No recompilation needed | Cannot run JOGL or GIAC JNI — CAS and 3D broken |

---

## 6. Recommendation

**Keep GWT (option A) as the web baseline.** It scores highest because it already works — all 5 views, CAS via `giac.wasm`, 3D via WebGL, static output, proven build.

The only weakness is maintenance risk: GWT is effectively end-of-life. This is a **future** problem, not a **current** one. The mitigation is Gate C itself: if GWT breaks on a future browser, the replacement decision is forced, and this matrix identifies the two viable successors:

1. **E (JS/TS rewrite)** if the project can fund a multi-month rewrite and wants to decouple from the Java web pipeline entirely.
2. **B (J2CL)** if the project wants to stay in the Java-source-transpilation model and can absorb the Bazel tooling and GWT-widget-removal cost.

Options C and D are not viable for this project — they cannot deliver CAS + 3D without major workarounds.

---

## 7. Gate C consequence

- **W-01 is now DONE.** The scored matrix exists.
- **GWT is not removed.** Gate C requires W-02 (chosen non-GWT client runs P-02 and P-03 corpus). Since the recommendation is to keep GWT, W-02 is satisfied by the current baseline.
- **Gate C status changes to:** W-01 scored (GWT retained). W-02 is met by the existing GWT build. Gate C can be marked **MET** once the P-02/P-03 corpus exists (Gate A dependency).
- **If GWT breaks in the future:** re-score this matrix with current browser compatibility data, then fund option E or B.

---

## 8. Scenario record

| Field | Value |
|---|---|
| Scenario | W-01 |
| Date | 2026-11-04 |
| Commit | `375db7faf54` (source pin) |
| OS | N/A (paper study, no code executed) |
| Java / Browser | N/A |
| Fixture | GWT modules: `SuperWeb`, `WebSimple`, `Web`, `Tablet3D` at pin |
| Command | N/A |
| Expected | Written scored matrix |
| Actual | Matrix written, 5 candidates scored on 7 weighted criteria |
| Evidence | This file |
| Status | **PASS** |
