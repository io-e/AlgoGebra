<!-- CLAUDE_V1 -->
# Gate A — Reference corpus for P-02 through P-05

| Field | Value |
|---|---|
| Document | `02-Cdc/Corpus_Gate_A_Reference_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Status | **Reference** — agents run evidence against this |
| Source pin | `375db7faf54`, `VERSION_STRING` `5.4.934.0` |
| Source | `D:\ALF_ZGit\G1_Geogebra_Migration` |

---

## 1. Purpose

Gate A requires: "P-02 through P-05 exist for the current desktop build and the current GWT war, on commit `375db7faf54`."

This document provides the **reference data** — what tools, views, and features exist at the pin — so Codex (Windows desktop) and Grok (Debian GWT war) can run the scenarios and produce linked evidence.

---

## 2. P-02 — Mandatory views

### 2.1 Required views (binding decision)

Students must retain: **Algebra View, CAS, Spreadsheet, 2D canvas, 3D canvas**.

### 2.2 View inventory at pin (`App.java`)

| View | Constant | ID | Required for P-02 |
|---|---|---|---|
| 2D Graphics (EuclidianView) | `VIEW_EUCLIDIAN` | 1 | **Yes** |
| Algebra View | `VIEW_ALGEBRA` | 2 | **Yes** |
| Spreadsheet | `VIEW_SPREADSHEET` | 4 | **Yes** |
| CAS | `VIEW_CAS` | 8 | **Yes** |
| 2D Graphics 2 | `VIEW_EUCLIDIAN2` | 16 | No (secondary) |
| Construction Protocol | `VIEW_CONSTRUCTION_PROTOCOL` | 32 | No |
| Probability Calculator | `VIEW_PROBABILITY_CALCULATOR` | 64 | No |
| Data Analysis | `VIEW_DATA_ANALYSIS` | 70 | No |
| Function Inspector | `VIEW_FUNCTION_INSPECTOR` | 128 | No |
| 3D Graphics | `VIEW_EUCLIDIAN3D` | 512 | **Yes** |
| Properties | `VIEW_PROPERTIES` | 4097 | No |

### 2.3 Pass criterion

For each required view on each host (desktop + web):
1. View opens without error
2. A simple construction is visible (e.g., `f(x)=x^2` in Algebra, `Derivative(f)` in CAS, data in Spreadsheet, point in 2D, sphere in 3D)
3. Evidence: screenshot + command log

### 2.4 Test constructions

| View | Command sequence | Expected result |
|---|---|---|
| Algebra + 2D | `f(x) = x^2` then `g(x) = Derivative(f)` | `g(x) = 2x` in Algebra, parabola + line in 2D |
| CAS | In CAS cell: `Solve(x^2 - 4 = 0, x)` | `{x = -2, x = 2}` |
| Spreadsheet | A1=`1`, A2=`2`, A3=`=A1+A2` | A3 shows `3` |
| 3D | `Sphere((0,0,0), 2)` | Sphere centered at origin, radius 2 |
| Combined | `A = (1,2)`, `B = (3,4)`, `Segment(A, B)` | Segment in 2D, length in Algebra |

### 2.5 Tolerance

Numeric results: exact match for integers, ±10⁻⁸ for floating point. Symbolic results: CAS-equivalent (e.g., `2*x` = `2x`).

---

## 3. P-03 — Standard tools

### 3.1 Tool count at pin

`EuclidianConstants.java` defines **184 `MODE_*` constants** (tool IDs). These span:

| Range | Category | Count |
|---|---|---|
| 0–80 | 2D geometry tools | ~81 |
| 101–132 | Shape / MOW tools | ~18 |
| 501–570 | 3D tools | ~25 |
| 1001–1010 | CAS tools | 10 |
| 2001–2044 | Spreadsheet tools | 12 |
| Other | Special (macro, media, etc.) | ~38 |

### 3.2 Mandatory tool categories (from binding decisions)

The desktop Classic 5/6 app exposes the full toolbar. The requirement is "no missing tool against the pin" — meaning the RCP product and the GWT war must expose the same tools as the vanilla desktop/web builds.

| Category | Key tools to verify | Tool IDs |
|---|---|---|
| **Point** | Point, Point on Object, Intersect | 1, 501, 5 |
| **Line** | Line, Segment, Ray, Vector | 2, 15, 18, 7 |
| **Circle** | Circle (center+point), Circle (3pts), Compasses | 10, 11, 53 |
| **Polygon** | Polygon, Regular Polygon, Rigid Polygon | 16, 51, 64 |
| **Conic** | Ellipse, Hyperbola, Parabola, Conic (5pts) | 55, 56, 57, 12 |
| **Transform** | Reflect (point/line/circle), Translate, Rotate, Dilate | 29, 30, 54, 31, 32, 33 |
| **Measure** | Angle, Distance, Area, Slope | 36, 38, 49, 50 |
| **Construction** | Parallel, Perpendicular, Bisector, Angular Bisector, Tangent | 3, 4, 8, 9, 13 |
| **Special** | Slider, Text, Image, Checkbox, Button | 25, 17, 26, 52, 60 |
| **3D** | Plane (3pts), Prism, Pyramid, Sphere, Cone, Cylinder, Net | 510, 531, 533, 521, 522, 523, 535 |
| **CAS** | Evaluate, Numeric, Factor, Expand, Solve, Derivative, Integral | 1001–1009 |
| **Spreadsheet** | Create List, Stats (1var, 2var), Sum, Average, Count | 2001, 2020, 2021, 2040, 2041, 2042 |

### 3.3 Pass criterion

For each host:
1. Count available tools in toolbar
2. Compare against the 184 MODE_* constants
3. List any missing tools (expected: 0 for vanilla build)
4. Evidence: toolbar screenshot + tool count

### 3.4 Verification method

**Desktop:** programmatic — `App.getToolbarDefinition()` returns the toolbar string, parseable to tool IDs.

**Web:** inspect the toolbar DOM or use the JavaScript API: `ggbApplet.getToolbarDefinition()`.

---

## 4. P-04 — Open, save, reopen `.ggb`

### 4.1 Test files from the pin

The source tree contains `.ggb` files suitable for round-trip testing:

| File | Location | Content | Tests |
|---|---|---|---|
| `circles.ggb` | `desktop/src/e2eTest/resources/` | 2D circles | Basic 2D round-trip |
| `cube.ggb` | `desktop/src/.../geogebra3D/samples/` | 3D cube | 3D round-trip |
| `dandelin.ggb` | same | Dandelin spheres (complex 3D) | Complex 3D round-trip |
| `ziptest.ggb` | `common-jre/src/test/resources/.../io/` | I/O test file | Parser round-trip |
| `ggmexample.ggb` | `web/src/main/resources/.../war/` | Web example | Web round-trip |

### 4.2 Round-trip test procedure

For each test file on each host:

```
1. Open file:       api.openFile("path/to/file.ggb")
2. Record state:    objects_before = api.getAllObjectNames()
3. Save:            base64_saved = api.getBase64()
4. Close + reopen:  api.setBase64(base64_saved)
5. Record state:    objects_after = api.getAllObjectNames()
6. Compare:         objects_before == objects_after (same names, same count)
7. Spot check:      api.getValueString("objectName") matches before
```

### 4.3 Pass criterion

- Same object count before and after
- Same object names (order may differ)
- No "silent loss" (object present before, absent after)
- Tolerance: object values within ±10⁻⁸

### 4.4 Additional test: new construction round-trip

Create from scratch, save, reopen:

```
api.evalCommand("A = (1, 2)")
api.evalCommand("B = (3, 4)")
api.evalCommand("f(x) = x^2")
api.evalCommand("c = Circle(A, 3)")
base64 = api.getBase64()
# reopen
api.setBase64(base64)
# verify A, B, f, c all exist with correct values
```

---

## 5. P-05 — Scripts, macros, images, export

### 5.1 Feature inventory

| Feature | Desktop support at pin | Web support at pin | Test method |
|---|---|---|---|
| **GeoGebra scripts** (`OnClick`, `OnUpdate`) | Yes — `ScriptManager` | Yes — `ScriptManagerW` | Create object with `OnClick` script, click, verify execution |
| **JavaScript scripts** (`ggbOnInit`, `ggbApplet`) | Yes — Rhino engine | Yes — native JS | `api.registerObjectUpdateListener()` |
| **Macros** (custom tools) | Yes — `Macro` class, toolbar ID 48+ | Yes — same mechanism via GWT | Create macro, use it, save, reopen |
| **Images** (`GeoImage`) | Yes — `Image` tool (26) | Yes — same | Insert image, save, reopen, verify |
| **Export PNG** | Yes — `api.getPNGBase64()` | Yes — Canvas export | Call API, verify non-empty Base64 |
| **Export SVG** | Yes — `api.exportSVG()` | Yes — same API | Call API, verify valid SVG |
| **Export PDF** | Desktop only — `api.exportPDF()` | No (browser print) | Desktop: call API. Web: document gap |
| **Export `.ggb`** | Yes — `api.getBase64()` | Yes — same | Covered by P-04 |
| **Copy/paste** | Yes — clipboard | Yes — browser clipboard API | Manual test |

### 5.2 Known gaps to document (not fix)

| Gap | Host | Description |
|---|---|---|
| PDF export | Web | Not available via API — browser `print()` is the workaround |
| Copy/paste of constructions | Web | Browser clipboard restrictions may prevent cross-tab paste |
| Macro persistence across sessions | Both | Macros saved in `.ggb` may not survive toolbar reset |

### 5.3 Pass criterion

- Each feature in §5.1 tested on both hosts
- Working features: evidence (screenshot or API output)
- Non-working features: listed as gap, not silently ignored
- Evidence: test log with feature name, host, result, gap description

---

## 6. Evidence format

Each scenario produces an evidence directory:

```
03-RCP-Spike/evidence/YYYYMMDD-P0x-{host}/
├── P0x_{host}_Evidence_{agent}_V1.md    ← narrative + pass/fail
├── screenshots/                          ← PNG evidence
│   ├── algebra_view.png
│   ├── cas_solve.png
│   └── ...
├── api_log.txt                           ← command + result transcript
└── tool_inventory.tsv                    ← tool ID, name, present (P-03)
```

### Evidence record fields (per V2 evidence rule)

| Field | Value |
|---|---|
| Date | ISO 8601 |
| Commit | `375db7faf54` |
| OS | Windows x86_64 / Debian x86_64 |
| Java / Browser | Java 25 / Chromium version |
| Fixture | test file hash (SHA-256) |
| Command | exact API calls or shell commands |
| Expected | from this corpus document |
| Actual | observed result |
| Log path | relative to evidence directory |

---

## 7. Agent assignments

| Scenario | Host | Agent | Handoff |
|---|---|---|---|
| P-02 | Desktop | Codex | This document |
| P-02 | Web (GWT war) | Grok | This document |
| P-03 | Desktop | Codex | This document |
| P-03 | Web (GWT war) | Grok | This document |
| P-04 | Desktop | Codex | This document |
| P-04 | Web (GWT war) | Grok | This document |
| P-05 | Desktop | Codex | This document |
| P-05 | Web (GWT war) | Grok | This document |

**Desktop method:** Codex uses `api.*` calls from a headless or GUI test harness against the desktop build.

**Web method:** Grok uses `ggbApplet.*` JavaScript API calls from a browser (Playwright or manual) against the GWT war served on Debian.

---

*End of `Corpus_Gate_A_Reference_CLAUDE_V1.md`.*
