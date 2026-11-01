<!-- CLAUDE_V1_1 -->
# Study — Course Tree: RCP Desktop and Web Implementation

| Field | Value |
|---|---|
| Document | `02-Cdc/Study_Course_Tree_RCP_and_Web_CLAUDE_V1_1.md` |
| Version | CLAUDE_V1_1 |
| Status | Revised after Codex + Grok Bot review |
| Date | 2026-11-01 |
| Supersedes | `Study_Course_Tree_RCP_and_Web_CLAUDE_V1.md` (preserved as history) |
| Depends on | `Study_Course_Tree_GeoGebraPlus_CLAUDE_V1.md`, V2 Architecture |
| Constraint | **`common` is untouchable.** No new GeoGebra view ID, no edits to upstream code. |
| Reviews | Codex review 2026-10-31 (3m21s), Grok Bot review 2026-10-31 |

---

## 0. Review corrections applied (V1 → V1_1)

| # | Reviewer | Issue | Correction |
|---|---|---|---|
| R-01 | Both | RCP pane created unconditionally crashes when no course is loaded; GridData never assigned; two weights for three children | **Conditional creation:** only add the course pane when `-Dggbplus.course` is set. Otherwise create the original two-pane SashForm. |
| R-02 | Both | ScenarioScript.java is a test harness, not proof of production-safe threading | **New §2.4:** explicit SWT↔Swing dispatch policy, disposal checks, modal dialog handling, non-blocking contract. |
| R-03 | Both | No 3D targeting — CMD3/VAL3 missing | **New §2.5:** course schema gains `target: "2d"` or `"3d"` per action. Executor routes to the correct GgbAPI instance. |
| R-04 | Grok | Existing UI suites 09/10/P-07 assume two panes | Two-pane layout preserved when no course flag. Test guard: course pane must not appear during standard test runs. |
| R-05 | Both | Web loader uses wrong script (`web3d.nocache.js` instead of `deployggb.js`) | **Corrected §3.3:** use the documented embedding loader. |
| R-06 | Both | `courseTree.loadCourse()` never called in the HTML | **Corrected §3.3:** added `loadCourse` call in `appletOnLoad`. |
| R-07 | Grok | Web CAS check passes on `"?"` while CAS is still loading | **New §3.5:** API readiness gate — wait for `ggbOnInit` + verify CAS with a known expression before enabling course actions. |
| R-08 | Both | No security model — arbitrary `evalCommand` is dangerous | **New §6:** security contract — allowlisted action types, forbidden command list, `.ggb` script policy, server-side grading only. |
| R-09 | Codex | `evalCommandCAS` web signature differs from Java | **Corrected §3.4:** use the actual `DefaultExportedApi` signature `evalCommandCAS(cmdString, rounding)`. |
| R-10 | Both | No work package to build/serve the GWT WAR | **New WP-3bis** in the workload: WAR build/serve verification. |
| R-11 | Grok | WIMS same-origin assumption may not hold | **New §3.6:** cross-origin embedding constraints. WIMS page must proxy or co-host the applet, or use `postMessage` bridge. |

---

## 1. Shared contract — one course file, two clients

Both clients read the same `course.json`. Both use the same GgbAPI methods (`evalCommand`, `evalCommandCAS`, `getValue`, `setValue`). The course tree panel is **host-owned** on each platform — it never touches `common`.

```
                  course.json
                 (shared schema)
                /               \
    RCP Desktop                  Web Browser
    SWT Tree widget              HTML <ul> tree
    → GgbAPI via reflection      → GgbAPI via JS exported API
    host bundle (OSGi)           host page (outside GWT applet)
```

---

## 2. RCP Desktop — SWT Tree in the host bundle

### 2.1 Current host layout

`GeoGebraPlusApplication.java` lines 208–213:

```java
SashForm sash = new SashForm(shell, SWT.HORIZONTAL);
Composite twoDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
Composite threeDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
sash.setWeights(new int[] {58, 42});
```

### 2.2 Modified layout — conditional course pane (R-01, R-04 fix)

The course pane is **only created** when `-Dggbplus.course=<file>` is set. Without it, the original two-pane layout is preserved unchanged, so suites 09/10 and P-07 continue to see the expected UI.

```java
String courseFile = System.getProperty("ggbplus.course");

SashForm sash = new SashForm(shell, SWT.HORIZONTAL);

CourseTreePanel coursePanel = null;
if (courseFile != null && !courseFile.isEmpty()) {
    // Three-pane layout: course | 2D | 3D
    Composite courseComposite = new Composite(sash, SWT.NONE);
    coursePanel = new CourseTreePanel(courseComposite);
}

Composite twoDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
Composite threeDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);

if (courseFile != null && !courseFile.isEmpty()) {
    sash.setWeights(new int[] {20, 50, 30});
} else {
    sash.setWeights(new int[] {58, 42});  // original layout
}
```

After GeoGebra initialization:

```java
if (coursePanel != null) {
    coursePanel.setGgbApis(scenarioApi2d, scenarioApi3d);
    coursePanel.loadCourse(Paths.get(courseFile));
}
```

### 2.3 CourseTreePanel — SWT Tree composite

Same structure as V1, but with corrections:
- Receives **both** 2D and 3D API objects
- Directive executor routes to the correct API based on action target
- Error handling wraps each directive in try/catch and reports to status bar
- No hanging on modal dialogs (see §2.4)

### 2.4 Threading and error policy (R-02 fix — NEW)

`ScenarioScript.java` is a test harness running on a daemon thread with `SwingUtilities.invokeAndWait`. That is **not** the production threading model for the course tree.

**Production dispatch contract:**

```
SWT thread                           Swing EDT
──────────                           ─────────
  [Run Step] button clicked
       │
       ├─ Disable button (prevent double-click)
       ├─ SwingUtilities.invokeLater(──────────►)
       │                              try {
       │                                evalCommand(value)
       │                              } catch (Throwable t) {
       │                                errorMessage = t.getMessage()
       │                              }
       │                              Display.asyncExec(◄──────)
       │
       ├─ Re-enable button
       ├─ Update status bar (success or error)
       ├─ Update tree icon ✓/✗
       ▼
```

**Rules:**

1. **Never `invokeAndWait` from the SWT thread.** Use `invokeLater` + `Display.asyncExec` callback. `invokeAndWait` risks deadlock if Swing needs the SWT thread (e.g., for SWT_AWT resize events).
2. **Disposal check:** before every `Display.asyncExec` callback, check `!shell.isDisposed()` and `!display.isDisposed()`.
3. **Modal dialog suppression:** GeoGebra may open a modal Swing dialog (e.g., "Please check your input" from BUG-014). The course executor must set a GeoGebra error handler or suppress dialog display during automated step execution, same as `ScenarioScript` does via the `scenarioApp2d` reference. If a dialog escapes, the executor must not block the SWT thread.
4. **Timeout:** each directive has a 10-second timeout. If Swing EDT does not call back within that window, the status bar shows "Step timed out" and the button re-enables. A hung EDT is logged, not recovered.
5. **Single-step execution:** the executor runs one action at a time. A multi-action step chains via callbacks, not a blocking loop.

### 2.5 2D and 3D targeting (R-03 fix — NEW)

The current spike has two separate GeoGebra instances:
- `GeoGebraPanel` → 2D AppD → `scenarioApi2d`
- `App3D` → 3D → `scenarioApi3d`

The course schema supports an action-level `target` field:

```json
{
  "directive": "CMD",
  "value": "A = (1, 2, 3)",
  "target": "3d"
}
```

| Target | API | Default |
|---|---|---|
| `"2d"` or omitted | `scenarioApi2d` | Yes — most commands go to 2D |
| `"3d"` | `scenarioApi3d` | No — explicit for 3D commands |

The `ScenarioScript.java` test harness already distinguishes 2D/3D via `CMD3`/`VAL3` directives. The course schema uses a cleaner `target` field instead of encoding it in the directive name.

### 2.6 OSGi bundle structure

No change from V1. Course tree code lives in the existing host bundle.

### 2.7 Launcher integration

```powershell
# launch.ps1 addition
param(
    [string]$Course  # path to a course.json file
)
if ($Course) {
    $jvmArgs += "-Dggbplus.course=$Course"
}
```

---

## 3. Web Browser — HTML tree outside the GWT applet

### 3.1 Architecture constraint

GWT retirement is a target, not approved. The web tree lives **outside** the GWT applet in the host page.

### 3.2 JavaScript API (from `DefaultExportedApi.java`)

```javascript
// Available on the ggbApplet object after GWT init
ggbApplet.evalCommand("c = Circle((0,0), 1)")          // → boolean
ggbApplet.evalCommandCAS("sin(pi/6)", "")              // → string (R-09: 2nd arg is rounding, not null)
ggbApplet.getValue("c")                                 // → number
ggbApplet.getValueString("c")                           // → string
ggbApplet.setValue("a", 5.0)                             // → void
```

### 3.3 HTML host page (R-05, R-06 fix)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GeoGebraPlus — Course</title>
  <link rel="stylesheet" href="course-tree.css">
</head>
<body>
  <div id="app-container">
    <nav id="course-tree" aria-label="Course navigation">
      <h2 id="course-title"></h2>
      <ul id="tree-root" role="tree"></ul>
      <div id="step-description"></div>
      <div id="button-bar">
        <button id="btn-run" disabled>Run Step</button>
        <button id="btn-check" disabled>Check</button>
        <button id="btn-next">Next ▶</button>
        <button id="btn-reset">Reset</button>
      </div>
      <div id="status-bar"></div>
    </nav>
    <article id="ggb-host">
      <div id="applet1"></div>
    </article>
  </div>

  <!-- R-05 fix: use the documented embedding loader, not web3d.nocache.js -->
  <script src="GeoGebra/deployggb.js"></script>
  <script>
    var parameters = {
      "appName": "classic",
      "width": 900,
      "height": 600,
      "showToolBar": true,
      "showAlgebraInput": true,
      "showMenuBar": true,
      // Self-hosted: point to the WAR output directory
      "material_id": "",
      "ggbBase64": ""
    };
    var applet = new GGBApplet(parameters, '5.0', 'applet1');

    // R-06 fix: load course after applet is ready
    function ggbOnInit() {
      var api = applet.getAppletObject();
      courseTree.setApi(api);
      // R-07: verify CAS readiness before enabling
      courseTree.verifyCasReady(api, function() {
        courseTree.loadCourse('courses/trigonometry_intro.json');
        courseTree.enable();
      });
    }
    applet.setCustomization(function() { applet.inject('applet1'); });
    window.addEventListener('load', function() { applet.inject('applet1'); });
  </script>
  <script src="course-tree.js"></script>
</body>
</html>
```

### 3.4 JavaScript controller (corrected)

Key corrections from V1:
- `evalCommandCAS(cmd, "")` not `evalCommandCAS(cmd, null)` (R-09)
- `verifyCasReady()` gate before enabling actions (R-07)
- `loadCourse()` is called (R-06)

```javascript
const courseTree = (function() {
    let api = null;
    let model = null;
    let currentNode = null;

    function setApi(ggbApi) { api = ggbApi; }

    function verifyCasReady(ggbApi, callback) {
        // R-07: CAS may not be initialized yet. Poll with a known expression.
        var attempts = 0;
        var check = setInterval(function() {
            attempts++;
            try {
                var result = ggbApi.evalCommandCAS("1+1", "");
                if (result === "2") {
                    clearInterval(check);
                    callback();
                    return;
                }
            } catch (e) { /* CAS not ready */ }
            if (attempts > 30) {  // 15 seconds
                clearInterval(check);
                setStatus("Warning: CAS not available. Some steps may fail.");
                callback();  // enable anyway, CAS steps will report errors
            }
        }, 500);
    }

    function enable() {
        document.getElementById('btn-run').disabled = false;
        document.getElementById('btn-check').disabled = false;
    }

    async function loadCourse(url) {
        var resp = await fetch(url);
        model = await resp.json();
        document.getElementById('course-title').textContent = model.course;
        renderTree(model.tree, document.getElementById('tree-root'));
    }

    function executeDirective(directive, value, target) {
        // target: "2d" (default) or "3d" (R-03)
        // In web, both 2D and 3D share the same applet API
        switch (directive) {
            case 'CMD':
                var ok = api.evalCommand(value);
                if (!ok) setStatus("Command failed: " + value);
                return ok;
            case 'CAS':
                var result = api.evalCommandCAS(value, "");  // R-09 fix
                if (!result || result === "?") {
                    setStatus("CAS returned no result for: " + value);
                    return false;
                }
                return true;
            case 'VAL':
                var val = api.getValueString(value);
                setStatus(value + " = " + val);
                return true;
        }
        return false;
    }
    // ... renderTree, selectNode, checkStep, nextStep, reset same as V1
    // but executeDirective checks return values (R-08)

    return { setApi, verifyCasReady, enable, loadCourse };
})();
```

### 3.5 API readiness gate (R-07 — NEW)

Before enabling the course tree buttons, the host page must verify:

1. `ggbOnInit` has fired (applet loaded)
2. `evalCommand("1+1")` returns `true` (algebra processor ready)
3. `evalCommandCAS("1+1", "")` returns `"2"` (CAS ready — may take 2–5s on first load)

Only after all three checks pass does `courseTree.enable()` run. A CAS timeout (15s) enables the tree with a warning — non-CAS steps still work.

### 3.6 Cross-origin embedding (R-11 — NEW)

If the GeoGebra applet and the course tree host page are served from different origins (e.g., WIMS on `wims.unice.fr` and the applet on a local server):

- **Same-origin (recommended):** serve the GWT WAR from the same domain as the WIMS page. WIMS can proxy `/GeoGebra/` to the applet server.
- **Cross-origin fallback:** embed the applet in an `<iframe>` and use `postMessage` to bridge API calls. This is heavier and loses direct API access.
- **Content-Security-Policy:** the host page must allow `script-src` for the GeoGebra scripts.

For Phase B (web proof), we test same-origin only. Cross-origin design is deferred to Phase C (WIMS integration).

---

## 4. Side-by-side comparison

Same as V1, with the addition of:

| Aspect | RCP Desktop | Web Browser |
|---|---|---|
| **3D targeting** | Separate API objects, routed by `target` field | Single applet API (3D commands work if 3D view is open) |
| **CAS readiness** | CAS factory set during `initializeGeoGebra` | Must wait for async CAS init after `ggbOnInit` |
| **Error handling** | Catch + status bar, no modal blocking | Catch + status bar, check return values |

---

## 5. WIMS/XWims integration

Same as V1, with added constraint:
- **Server-side grading only (R-08).** The course tree can show formative ✓/✗ in the browser, but the authoritative grade must be computed by WIMS on the server. A browser-side check can be faked.
- **Cross-origin policy (R-11):** WIMS page must co-host or proxy the applet.

---

## 6. Security contract (R-08 — NEW)

### 6.1 Course files are data, not code

A `course.json` file declares typed actions. The executor interprets them — it does not `eval()` arbitrary strings.

### 6.2 Allowlisted action types

| Action type | Allowed | Notes |
|---|---|---|
| `CMD` | GeoGebra construction commands | Subject to a deny list (see §6.3) |
| `CAS` | CAS evaluation expressions | Subject to the same deny list |
| `VAL` | Read a named object's value | Read-only, always safe |
| `OPEN` | Load a `.ggb` file | **Restricted:** only from the course's own directory; no arbitrary paths; `.ggb` must be pre-screened for embedded scripts |
| `SAVE` | Save current construction | To a temp directory only; never overwrites source |
| `PNG` | Export a screenshot | To a temp directory only |

### 6.3 Forbidden commands

Same principle as the external engine security (WIMS `pari.c` pattern — deny list on dangerous operations):

```
Forbidden in CMD/CAS:
  Execute, RunClickScript, RunUpdateScript, RunMacro (script execution)
  System, Shell, Exec (OS access — not GeoGebra commands, but defense-in-depth)
  ExportImage with arbitrary paths (file write)
  JavaScript, JsEval (web only — script injection)
```

The deny list is checked before passing the command to `evalCommand`. Violations are logged and the step fails with a clear error.

### 6.4 `.ggb` file policy

A `.ggb` file can contain JavaScript and GeoGebra scripts. Before accepting an `OPEN` action:
- The `.ggb` XML is scanned for `<javascript>` elements and `onUpdate`/`onClick` script attributes
- If scripts are found: reject the file and fail the step, unless the course is marked `"trustedGgb": true` by the teacher
- On web: `ggbApplet.enableRightClick(false)` and `ggbApplet.enableShiftDragZoom(false)` limit student-initiated script triggers

### 6.5 Grading trust boundary

```
Browser (untrusted)                    WIMS Server (trusted)
───────────────────                    ─────────────────────
  courseTree shows formative ✓/✗          Authoritative grade computation
  Student can inspect/modify JS           Server-side .ggb analysis
  Client check = hint only                Server check = the grade
```

**Rule:** never trust a grade computed in the browser. The submission step sends the construction XML/`.ggb` to WIMS, which recomputes the result independently.

---

## 7. Future: GWT replacement

Same as V1. The course tree survives GWT replacement because it depends only on the published GeoGebra Apps API.
