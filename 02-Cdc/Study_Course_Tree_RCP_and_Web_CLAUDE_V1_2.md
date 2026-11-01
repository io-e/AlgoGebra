<!-- CLAUDE_V1_2 -->
# Study — Course Tree: RCP Desktop and Web Implementation

| Field | Value |
|---|---|
| Document | `02-Cdc/Study_Course_Tree_RCP_and_Web_CLAUDE_V1_2.md` |
| Version | CLAUDE_V1_2 |
| Status | Ready for coding (three blocking fixes applied) |
| Date | 2026-11-01 |
| Supersedes | `Study_Course_Tree_RCP_and_Web_CLAUDE_V1_1.md` (preserved as history) |
| Depends on | `Study_Course_Tree_GeoGebraPlus_CLAUDE_V1.md`, V2 Architecture |
| Constraint | **`common` is untouchable.** No new GeoGebra view ID, no edits to upstream code. |
| Reviews | Codex 2026-10-31, Grok Bot 2026-10-31, Grok Bot 2026-11-01 (V1_1 check) |

---

## 0. Corrections applied

### V1 → V1_1 (Codex + Grok review)

See `Study_Course_Tree_RCP_and_Web_CLAUDE_V1_1.md` §0 for the full R-01..R-11 table.

### V1_1 → V1_2 (Grok V1_1 check — three blocking fixes + smaller fixes)

| # | Issue | Fix |
|---|---|---|
| G-01 | Threading rule "never invokeAndWait" contradicts working startup code | **Scoped:** rule applies to course-step execution only. Startup `invokeAndWait` in `GeoGebraPlusApplication` is unchanged. |
| G-02 | Error dialog suppression was vague | **Specified:** use `setErrorDialogsActive(false)` before each course step, restore to `true` after. Already used by `ScenarioScript.java:47`. |
| G-03 | Security deny-list is bypassable (localized names like "Exécute", nesting in Sequence) and lists non-existent commands | **Replaced with allowlist.** Post-parse check on the `Commands` enum value, not on string names. See `Spec_Course_Security_CLAUDE_V1.md`. |
| G-04 | .ggb check only looks at XML, misses `geogebra_javascript.js` and per-object scripts | **Expanded** in security spec §3. |
| G-05 | OPEN action doesn't reject `..`, absolute paths, or URLs | **Added** path traversal and URL rejection in security spec §2. |
| G-06 | Web page loads from geogebra.org (missing `setHTML5Codebase`), injects GeoGebra twice | **Fixed §3.3:** added `html5codebase` parameter, removed double injection. |
| G-07 | CAS readiness check `evalCommand("1+1")` creates object "2" in student construction | **Fixed §3.5:** use `evalCommandCAS("1+1","")` only (CAS doesn't create objects). Removed `evalCommand` readiness check. |
| G-08 | D-04 gates Codex integration work unnecessarily | **Removed from workload V1_2.** Course tree uses the GgbAPI command interface, not keystrokes. D-04 (focus/input) is tracked separately. |
| G-09 | Correction table labels W-01..W-13 clash with scenario IDs W-01..W-08 | **Renamed** to G-01..G-09 in this table. V1_1 table kept R-01..R-11 prefix. |
| G-10 | launch.sh (Linux) missing -Course flag | **Added §2.8.** |

---

## 1. Shared contract — one course file, two clients

Both clients read the same `course.json`. Both use the same GgbAPI methods (`evalCommand`, `evalCommandCAS`, `getValue`, `setValue`). The course tree panel is **host-owned** on each platform — it never touches `common`.

Security is defined in a separate spec: `Spec_Course_Security_CLAUDE_V1.md`. Commands are validated post-parse against an allowlist of `Commands` enum values, not a string deny-list.

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

`GeoGebraPlusApplication.java` lines 208–213 (unchanged):

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
    Composite courseComposite = new Composite(sash, SWT.NONE);
    coursePanel = new CourseTreePanel(courseComposite);
}

Composite twoDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
Composite threeDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);

if (courseFile != null && !courseFile.isEmpty()) {
    sash.setWeights(new int[] {20, 50, 30});
} else {
    sash.setWeights(new int[] {58, 42});
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

- Receives **both** 2D and 3D API objects
- Directive executor routes to the correct API based on action `target` field
- Error handling wraps each directive in try/catch and reports to status bar
- Error dialogs suppressed around each step (see §2.4)

### 2.4 Threading and error policy (G-01, G-02 fix)

#### Scope

This policy applies to **course step execution only**. The existing startup code in `GeoGebraPlusApplication` (which uses `SwingUtilities.invokeAndWait` for initialization) is **unchanged and proven**.

#### Production dispatch contract for course steps:

```
SWT thread                           Swing EDT
──────────                           ─────────
  [Run Step] button clicked
       │
       ├─ Disable button
       ├─ SwingUtilities.invokeLater(──────────►)
       │                              api.setErrorDialogsActive(false)  ← G-02
       │                              try {
       │                                result = evalCommand(value)
       │                              } catch (Throwable t) {
       │                                errorMessage = t.getMessage()
       │                              } finally {
       │                                api.setErrorDialogsActive(true)  ← G-02
       │                              }
       │                              Display.asyncExec(◄──────)
       │
       ├─ Re-enable button
       ├─ Update status bar (success or error)
       ├─ Update tree icon ✓/✗
       ▼
```

#### Rules:

1. **Never `invokeAndWait` from SWT for course steps.** Use `invokeLater` + `Display.asyncExec` callback. Startup code is exempt — it runs before the SWT event loop.
2. **Error dialog guard:** call `api.setErrorDialogsActive(false)` before each step, restore to `true` in a `finally` block. This is the same call `ScenarioScript.java:47` uses. It affects the entire app, so it must be restored promptly.
3. **Disposal check:** before every `Display.asyncExec` callback, check `!shell.isDisposed()` and `!display.isDisposed()`.
4. **Timeout:** 10-second timeout per directive. If Swing EDT does not call back, status bar shows "Step timed out" and button re-enables.
5. **Single-step execution:** one action at a time. Multi-action steps chain via callbacks.

### 2.5 2D and 3D targeting (R-03 fix)

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
| `"2d"` or omitted | `scenarioApi2d` | Yes |
| `"3d"` | `scenarioApi3d` | No — explicit for 3D commands |

### 2.6 OSGi bundle structure

No change. Course tree code lives in the existing host bundle.

### 2.7 Windows launcher

```powershell
# launch.ps1 addition
param(
    [string]$Course  # path to a course.json file
)
if ($Course) {
    $jvmArgs += "-Dggbplus.course=$Course"
}
```

### 2.8 Linux launcher (G-10 fix — NEW)

```bash
# launch.sh addition
COURSE_ARG=""
if [ -n "$1" ] && [ -f "$1" ]; then
    COURSE_ARG="-Dggbplus.course=$1"
fi
# Add $COURSE_ARG to the java command line
```

Grok Bot owns `launch.sh`. This section defines the interface; implementation is Grok Bot's lane.

---

## 3. Web Browser — HTML tree outside the GWT applet

### 3.1 Architecture constraint

GWT retirement is a target, not approved. The web tree lives **outside** the GWT applet in the host page.

### 3.2 JavaScript API (from `DefaultExportedApi.java`)

```javascript
ggbApplet.evalCommand("c = Circle((0,0), 1)")          // → boolean
ggbApplet.evalCommandCAS("sin(pi/6)", "")              // → string (2nd arg = rounding)
ggbApplet.getValue("c")                                 // → number
ggbApplet.getValueString("c")                           // → string
ggbApplet.setValue("a", 5.0)                             // → void
ggbApplet.setErrorDialogsActive(false)                  // → void (suppress error popups)
```

### 3.3 HTML host page (G-06 fix: self-hosted codebase, no double injection)

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

  <script src="GeoGebra/deployggb.js"></script>
  <script src="course-tree.js"></script>
  <script>
    // G-06 fix: point to our self-hosted WAR, not geogebra.org
    var parameters = {
      "appName": "classic",
      "width": 900,
      "height": 600,
      "showToolBar": true,
      "showAlgebraInput": true,
      "showMenuBar": true,
      "html5codebase": "GeoGebra/HTML5/5.0/web3d/"
    };

    var applet = new GGBApplet(parameters, '5.0', 'applet1');

    function ggbOnInit() {
      var api = document.ggbApplet || applet.getAppletObject();
      courseTree.setApi(api);
      courseTree.verifyCasReady(api, function() {
        courseTree.loadCourse('courses/trigonometry_intro.json');
        courseTree.enable();
      });
    }

    // Single injection point (G-06: removed duplicate)
    window.addEventListener('load', function() {
      applet.inject('applet1');
    });
  </script>
</body>
</html>
```

### 3.4 JavaScript controller

Key corrections from V1_1:
- CAS readiness check uses `evalCommandCAS` only (G-07: no `evalCommand("1+1")` — that would create an object "2" in the student's construction)
- `setErrorDialogsActive(false)` around each step execution

```javascript
const courseTree = (function() {
    let api = null;
    let model = null;
    let currentNode = null;

    function setApi(ggbApi) { api = ggbApi; }

    function verifyCasReady(ggbApi, callback) {
        // G-07 fix: CAS-only check (evalCommandCAS doesn't create objects)
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
            if (attempts > 30) {
                clearInterval(check);
                setStatus("Warning: CAS not available. Some steps may fail.");
                callback();
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
        api.setErrorDialogsActive(false);  // G-02
        try {
            switch (directive) {
                case 'CMD':
                    var ok = api.evalCommand(value);
                    if (!ok) setStatus("Command failed: " + value);
                    return ok;
                case 'CAS':
                    var result = api.evalCommandCAS(value, "");
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
        } finally {
            api.setErrorDialogsActive(true);  // G-02
        }
    }

    return { setApi, verifyCasReady, enable, loadCourse, executeDirective };
})();
```

### 3.5 API readiness gate (G-07 fix)

Before enabling the course tree buttons, the host page verifies:

1. `ggbOnInit` has fired (applet loaded)
2. `evalCommandCAS("1+1", "")` returns `"2"` (CAS ready)

**Removed:** the previous `evalCommand("1+1")` check, which would create an object named "2" in the student's construction. CAS evaluation does not create construction objects.

Timeout (15s) enables the tree with a warning — non-CAS steps still work.

### 3.6 Cross-origin embedding (R-11)

Same as V1_1. Same-origin for Phase B; cross-origin design deferred to Phase C.

---

## 4. Side-by-side comparison

| Aspect | RCP Desktop | Web Browser |
|---|---|---|
| **Tree widget** | SWT Tree (native OS) | HTML `<ul>` with ARIA roles |
| **GeoGebra API** | Reflection on `GgbAPID` | JS on `DefaultExportedApi` |
| **3D targeting** | Separate API objects, routed by `target` | Single applet API |
| **CAS readiness** | Sync — CAS factory set at startup | Async — must poll after `ggbOnInit` |
| **Error dialogs** | `setErrorDialogsActive(false/true)` around each step | Same API call |
| **Codebase** | Local JARs | Self-hosted WAR (`html5codebase` parameter) |

---

## 5. WIMS/XWims integration

Same as V1_1. Server-side grading only (security spec §4). Same-origin required.

---

## 6. Security

**Moved to a separate spec:** `Spec_Course_Security_CLAUDE_V1.md`.

Summary:
- **Allowlist-based** command validation, checked post-parse on `Commands` enum values (not string names — immune to localization bypass like "Exécute")
- **`.ggb` archive scanning:** checks XML, `geogebra_javascript.js`, and per-object script attributes
- **OPEN action:** rejects `..`, absolute paths, URLs; resolved paths must be under the course directory
- **Server-side grading only:** browser checks are formative hints

---

## 7. Future: GWT replacement

Same as V1. The course tree survives GWT replacement because it depends only on the published GeoGebra Apps API.
