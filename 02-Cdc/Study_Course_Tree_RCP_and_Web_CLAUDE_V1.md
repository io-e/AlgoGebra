<!-- CLAUDE_V1 -->
# Study — Course Tree: RCP Desktop and Web Implementation

| Field | Value |
|---|---|
| Document | `02-Cdc/Study_Course_Tree_RCP_and_Web_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Study / Proposal |
| Date | 2026-10-30 |
| Depends on | `Study_Course_Tree_GeoGebraPlus_CLAUDE_V1.md`, V2 Architecture |
| Constraint | **`common` is untouchable.** No new GeoGebra view ID, no edits to upstream code. |

---

## 1. Shared contract — one course file, two clients

Both clients read the same `course.json`. Both use the same GgbAPI methods (`evalCommand`, `evalCommandCAS`, `getValue`, `setValue`). The course tree panel is **host-owned** on each platform — it never touches `common`.

```
                  course.json
                 (shared schema)
                /               \
    RCP Desktop                  Web Browser
    SWT Tree widget              HTML <details>/<ul> tree
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

### 2.2 Modified layout with course tree

```java
SashForm sash = new SashForm(shell, SWT.HORIZONTAL);

// NEW: course tree panel (SWT-native, no SWT_AWT bridge)
Composite courseComposite = new Composite(sash, SWT.NONE);
courseComposite.setLayout(new GridLayout(1, false));
CourseTreePanel coursePanel = new CourseTreePanel(courseComposite);

// Existing: GeoGebra 2D
Composite twoDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
// Existing: GeoGebra 3D
Composite threeDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);

// 20% tree | 50% 2D | 30% 3D
sash.setWeights(new int[] {20, 50, 30});

// Conditional: hide course panel if no -Dggbplus.course=<file>
String courseFile = System.getProperty("ggbplus.course");
if (courseFile == null) {
    courseComposite.setVisible(false);
    ((GridData) courseComposite.getLayoutData()).exclude = true;
    sash.setWeights(new int[] {58, 42});  // original weights
} else {
    coursePanel.loadCourse(Paths.get(courseFile));
}
```

### 2.3 CourseTreePanel implementation

```java
package org.geogebra.plus.host;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.*;
import javax.swing.SwingUtilities;
import java.nio.file.Path;

public class CourseTreePanel {

    private final Tree tree;
    private final Text stepDescription;
    private final Button runButton;
    private final Button checkButton;
    private final Label statusLabel;
    private CourseModel model;

    // Set by GeoGebraPlusApplication after GeoGebra init
    private Object ggbApi2d;
    private Object ggbApi3d;

    public CourseTreePanel(Composite parent) {
        parent.setLayout(new GridLayout(1, false));

        // Course title
        Label titleLabel = new Label(parent, SWT.NONE);
        titleLabel.setLayoutData(new GridData(SWT.FILL, SWT.TOP, true, false));

        // SWT Tree widget — OS-native tree with expand/collapse
        tree = new Tree(parent, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL | SWT.H_SCROLL);
        tree.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true));

        // Step description area (read-only text)
        stepDescription = new Text(parent, SWT.MULTI | SWT.WRAP | SWT.READ_ONLY | SWT.BORDER);
        GridData descGd = new GridData(SWT.FILL, SWT.BOTTOM, true, false);
        descGd.heightHint = 80;
        stepDescription.setLayoutData(descGd);

        // Button bar
        Composite buttons = new Composite(parent, SWT.NONE);
        buttons.setLayout(new RowLayout(SWT.HORIZONTAL));
        buttons.setLayoutData(new GridData(SWT.FILL, SWT.BOTTOM, true, false));

        runButton = new Button(buttons, SWT.PUSH);
        runButton.setText("Run Step");
        checkButton = new Button(buttons, SWT.PUSH);
        checkButton.setText("Check");
        Button nextButton = new Button(buttons, SWT.PUSH);
        nextButton.setText("Next ▶");
        Button resetButton = new Button(buttons, SWT.PUSH);
        resetButton.setText("Reset");

        statusLabel = new Label(parent, SWT.NONE);
        statusLabel.setLayoutData(new GridData(SWT.FILL, SWT.BOTTOM, true, false));

        // Listeners
        tree.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onStepSelected((TreeItem) e.item)));
        runButton.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onRunStep()));
        checkButton.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onCheckStep()));
        nextButton.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onNextStep()));
        resetButton.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onReset()));
    }

    public void setGgbApis(Object api2d, Object api3d) {
        this.ggbApi2d = api2d;
        this.ggbApi3d = api3d;
    }

    public void loadCourse(Path courseJson) {
        model = CourseModel.parse(courseJson);
        tree.removeAll();
        for (CourseNode chapter : model.getRoot().getChildren()) {
            TreeItem chapterItem = new TreeItem(tree, SWT.NONE);
            chapterItem.setText(chapter.getTitle());
            chapterItem.setData(chapter);
            for (CourseNode step : chapter.getChildren()) {
                TreeItem stepItem = new TreeItem(chapterItem, SWT.NONE);
                stepItem.setText(step.getTitle());
                stepItem.setData(step);
            }
            chapterItem.setExpanded(true);
        }
        statusLabel.setText("Course loaded: " + model.getRoot().getTitle());
    }

    private void onStepSelected(TreeItem item) {
        CourseNode node = (CourseNode) item.getData();
        String desc = node.getHint() != null ? node.getHint() : node.getTitle();
        stepDescription.setText(desc);
    }

    private void onRunStep() {
        TreeItem[] sel = tree.getSelection();
        if (sel.length == 0 || ggbApi2d == null) return;
        CourseNode node = (CourseNode) sel[0].getData();

        // Execute on the Swing EDT — same pattern as ScenarioScript
        SwingUtilities.invokeLater(() -> {
            for (CourseAction action : node.getActions()) {
                try {
                    executeDirective(action.getDirective(), action.getValue());
                } catch (Exception ex) {
                    updateStatus("ERROR: " + action.getDirective() + " — " + ex.getMessage());
                }
            }
            updateStatus("Step executed: " + node.getId());
        });
    }

    private void executeDirective(String directive, String value) throws Exception {
        // Reuses the ScenarioScript directive vocabulary
        switch (directive) {
            case "CMD":
                ggbApi2d.getClass().getMethod("evalCommand", String.class)
                    .invoke(ggbApi2d, value);
                break;
            case "CAS":
                ggbApi2d.getClass().getMethod("evalCommandCAS", String.class, String.class)
                    .invoke(ggbApi2d, value, null);
                break;
            case "VAL":
                // value = "objectName" → returns current value
                String result = (String) ggbApi2d.getClass()
                    .getMethod("getValueString", String.class)
                    .invoke(ggbApi2d, value);
                updateStatus(value + " = " + result);
                break;
            // OPEN, SAVE, PNG handled same as ScenarioScript.java
        }
    }

    private void onCheckStep() {
        TreeItem[] sel = tree.getSelection();
        if (sel.length == 0) return;
        CourseNode node = (CourseNode) sel[0].getData();
        if (node.getValidation() == null) {
            updateStatus("No validation defined for this step.");
            return;
        }
        // Run validation on EDT, report back on SWT thread
        SwingUtilities.invokeLater(() -> {
            boolean pass = runValidation(node);
            Display.getDefault().asyncExec(() -> {
                sel[0].setImage(pass ? getCheckIcon() : getCrossIcon());
                updateStatus(pass ? "✓ Check passed" : "✗ Check failed");
            });
        });
    }

    private void updateStatus(String msg) {
        Display.getDefault().asyncExec(() -> statusLabel.setText(msg));
    }
    // ... nextStep, reset, icon helpers omitted for brevity
}
```

### 2.4 Threading model

```
SWT thread (UI)                  Swing EDT (GeoGebra)
─────────────                    ────────────────────
  User clicks [Run Step]
       │
       ├─ SwingUtilities.invokeLater(─────────►)
       │                              evalCommand("c = Circle((0,0), 1)")
       │                              construction updates
       │                              views repaint
       │                              (◄──────── Display.asyncExec)
       │
       ├─ Update TreeItem icon ✓/✗
       ├─ Update statusLabel
       ▼
```

This is the **same threading bridge** already proven in `ScenarioScript.java` lines 246-279. No new threading pattern.

### 2.5 OSGi bundle structure

The course tree panel lives in the **existing host bundle** (`org.geogebra.plus.host`). No new bundle needed for Phase 1.

New files in `03-RCP-Spike/host/src/org/geogebra/plus/host/`:

| File | Purpose |
|---|---|
| `CourseTreePanel.java` | SWT Tree composite (above) |
| `CourseModel.java` | Parses `course.json` → tree of `CourseNode` |
| `CourseNode.java` | Data class: id, title, type, actions[], validation, hint |
| `CourseAction.java` | Data class: directive, value |

Dependencies: only `org.eclipse.swt`, `javax.swing` (for `SwingUtilities`), and `org.json` or hand-written JSON parser. No `common` dependency beyond the GgbAPI reflection already in use.

### 2.6 Launcher integration

```powershell
# launch.ps1 addition
param(
    [string]$Course  # NEW: path to a course.json file
)
# ... existing flags ...
if ($Course) {
    $jvmArgs += "-Dggbplus.course=$Course"
}
```

---

## 3. Web Browser — HTML tree outside the GWT applet

### 3.1 The web architecture constraint

The V2 architecture says:
- **GWT retirement is a target, not approved for execution.**
- The web host technology is TBD (Gate C: W-01 scored study).
- The current GWT output produces four WAR variants (`web3d`, `webSimple`, `web`, `tablet3d`).

The GWT applet exposes a JavaScript API (`DefaultExportedApi`) via JsInterop. The key methods:

```javascript
// Available on the ggbApplet object after GWT init
ggbApplet.evalCommand("c = Circle((0,0), 1)")   // → boolean
ggbApplet.evalCommandCAS("sin(pi/6)", null)      // → string
ggbApplet.getValue("c")                           // → number
ggbApplet.getValueString("c")                     // → string
ggbApplet.setValue("a", 5.0)                      // → void
ggbApplet.getXML()                                // → string
ggbApplet.setXML(xml)                             // → void
```

### 3.2 Strategy: the course tree is a **host page** around the GWT applet

The course tree is **not inside** the GWT applet. It's pure HTML/CSS/JS in the **host page** that embeds the applet. This means:
- No GWT compilation needed
- No `common` edits
- Works with the current GWT applet AND with any future web replacement
- The same approach works for WIMS/XWims activity pages

```
┌──────────────────────────────────────────────┐
│  Host HTML page (GeoGebraPlus web host)      │
│  ┌───────────────┬──────────────────────────┐│
│  │ Course Tree   │  GeoGebra GWT Applet     ││
│  │ (HTML/CSS/JS) │  <article id="ggb">      ││
│  │               │    <div id="applet1"/>    ││
│  │ Chapter 1 ▼   │                          ││
│  │  ├ Step 1 ✓   │   [Algebra] [Graphics]   ││
│  │  ├ Step 2 ●   │   [CAS]     [3D]        ││
│  │  └ Step 3 ○   │                          ││
│  │ Chapter 2 ▶   │                          ││
│  │               │                          ││
│  │ [Run] [Check] │                          ││
│  │ [Next] [Reset]│                          ││
│  └───────────────┴──────────────────────────┘│
│  Status: Step 2 — Circle created             │
└──────────────────────────────────────────────┘
```

### 3.3 HTML structure

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

    <!-- Left: Course Tree -->
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

    <!-- Right: GeoGebra applet -->
    <article id="ggb-host">
      <div id="applet1"></div>
    </article>

  </div>

  <!-- GeoGebra GWT loader (current baseline) -->
  <script src="web3d/web3d.nocache.js"></script>
  <script>
    var ggbApp = new GGBApplet({
      "appName": "classic",
      "width": 900,
      "height": 600,
      "showToolBar": true,
      "showAlgebraInput": true,
      "showMenuBar": true,
      "appletOnLoad": function(api) {
        window.ggbApplet = api;
        courseTree.setApi(api);
        courseTree.enable();
      }
    }, true);
    ggbApp.inject('applet1');
  </script>

  <!-- Course tree controller -->
  <script src="course-tree.js"></script>
</body>
</html>
```

### 3.4 JavaScript course tree controller

```javascript
// course-tree.js — Course tree for the GeoGebraPlus web host
// No framework dependency. Uses the GeoGebra JS API (ggbApplet).
const courseTree = (function() {
    let api = null;       // GeoGebra API object (set on appletOnLoad)
    let model = null;     // Parsed course.json
    let currentNode = null;

    function setApi(ggbApi) { api = ggbApi; }
    function enable() {
        document.getElementById('btn-run').disabled = false;
        document.getElementById('btn-check').disabled = false;
    }

    async function loadCourse(url) {
        const resp = await fetch(url);
        model = await resp.json();
        document.getElementById('course-title').textContent = model.course;
        renderTree(model.tree, document.getElementById('tree-root'));
    }

    function renderTree(nodes, parentUl) {
        for (const node of nodes) {
            const li = document.createElement('li');
            li.setAttribute('role', 'treeitem');
            li.dataset.id = node.id;

            const span = document.createElement('span');
            span.className = 'tree-label';
            span.textContent = node.title;
            span.addEventListener('click', () => selectNode(node, li));
            li.appendChild(span);

            // Status icon
            const icon = document.createElement('span');
            icon.className = 'tree-icon';
            icon.textContent = '○';  // ○ not run, ● active, ✓ pass, ✗ fail
            li.appendChild(icon);

            if (node.children && node.children.length > 0) {
                li.setAttribute('aria-expanded', 'true');
                const childUl = document.createElement('ul');
                childUl.setAttribute('role', 'group');
                renderTree(node.children, childUl);
                li.appendChild(childUl);
            }
            parentUl.appendChild(li);
        }
    }

    function selectNode(node, li) {
        document.querySelectorAll('.tree-label.selected')
            .forEach(el => el.classList.remove('selected'));
        li.querySelector('.tree-label').classList.add('selected');
        currentNode = node;
        const desc = node.hint || node.title;
        document.getElementById('step-description').textContent = desc;
        setIcon(li, '●');
    }

    function setIcon(li, icon) {
        li.querySelector('.tree-icon').textContent = icon;
    }

    // Execute directives — same vocabulary as ScenarioScript.java
    function runStep() {
        if (!currentNode || !api) return;
        const actions = currentNode.actions || [];
        for (const action of actions) {
            executeDirective(action.directive, action.value);
        }
        setStatus('Step executed: ' + currentNode.id);
    }

    function executeDirective(directive, value) {
        switch (directive) {
            case 'CMD':
                api.evalCommand(value);
                break;
            case 'CAS':
                api.evalCommandCAS(value, null);
                break;
            case 'VAL':
                const result = api.getValueString(value);
                setStatus(value + ' = ' + result);
                break;
            case 'OPEN':
                api.setBase64(value);  // or fetch .ggb and load
                break;
        }
    }

    function checkStep() {
        if (!currentNode || !api || !currentNode.validation) {
            setStatus('No validation for this step.');
            return;
        }
        const v = currentNode.validation;
        let pass = false;
        switch (v.check) {
            case 'VAL':
                const actual = api.getValueString(v.object);
                pass = actual.trim() === v.expected.trim();
                break;
            case 'CAS':
                const casResult = api.evalCommandCAS(v.expected[0], null);
                pass = casResult != null && casResult.length > 0;
                break;
        }
        const li = document.querySelector(`[data-id="${currentNode.id}"]`);
        setIcon(li, pass ? '✓' : '✗');
        setStatus(pass ? '✓ Check passed' : '✗ Check failed');
    }

    function nextStep() {
        // Find next sibling or first child of next chapter
        // Implementation: flat walk of model.tree
    }

    function reset() {
        if (api) api.newConstruction();
        document.querySelectorAll('.tree-icon')
            .forEach(el => el.textContent = '○');
        setStatus('Construction reset.');
    }

    function setStatus(msg) {
        document.getElementById('status-bar').textContent = msg;
    }

    // Button bindings
    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('btn-run').addEventListener('click', runStep);
        document.getElementById('btn-check').addEventListener('click', checkStep);
        document.getElementById('btn-next').addEventListener('click', nextStep);
        document.getElementById('btn-reset').addEventListener('click', reset);
    });

    return { setApi, enable, loadCourse };
})();
```

### 3.5 CSS layout

```css
/* course-tree.css */
#app-container {
    display: flex;
    height: 100vh;
    overflow: hidden;
}
#course-tree {
    width: 280px;
    min-width: 200px;
    max-width: 400px;
    border-right: 1px solid #ccc;
    display: flex;
    flex-direction: column;
    padding: 12px;
    overflow-y: auto;
    resize: horizontal;
}
#ggb-host {
    flex: 1;
    min-width: 0;
}
#tree-root {
    list-style: none;
    padding: 0;
    flex: 1;
    overflow-y: auto;
}
#tree-root ul {
    list-style: none;
    padding-left: 20px;
}
.tree-label {
    cursor: pointer;
    padding: 4px 8px;
    border-radius: 4px;
    display: inline-block;
}
.tree-label:hover { background: #e8e8e8; }
.tree-label.selected { background: #d0e0f0; font-weight: bold; }
.tree-icon { margin-left: 6px; font-size: 14px; }
#step-description {
    min-height: 60px;
    padding: 8px;
    background: #f8f8f0;
    border: 1px solid #ddd;
    border-radius: 4px;
    margin: 8px 0;
    font-size: 13px;
}
#button-bar { display: flex; gap: 6px; }
#button-bar button {
    padding: 6px 14px;
    border: 1px solid #888;
    border-radius: 4px;
    cursor: pointer;
    background: #fff;
}
#button-bar button:hover { background: #e0e0e0; }
#status-bar {
    margin-top: 8px;
    font-size: 12px;
    color: #555;
}
```

---

## 4. Side-by-side comparison

| Aspect | RCP Desktop | Web Browser |
|---|---|---|
| **Tree widget** | SWT `Tree` (OS native) | HTML `<ul>` with CSS tree styling |
| **GgbAPI access** | Reflection (`Method.invoke`) | Direct JS (`ggbApplet.evalCommand`) |
| **Threading** | SWT thread → `SwingUtilities.invokeLater` → EDT → `Display.asyncExec` | Single JS event loop (no threading) |
| **Course file loading** | `Paths.get(file)` + JSON parser | `fetch(url)` + `JSON.parse` |
| **Host integration** | `GeoGebraPlusApplication.java` SashForm | Host HTML page around GWT applet |
| **New OSGi bundles** | None — code in existing host bundle | N/A |
| **GWT compilation** | N/A | **Not needed** — tree is pure JS outside the applet |
| **`common` edits** | None | None |
| **Launch flag** | `-Dggbplus.course=<file>` | URL param: `?course=trig_course.json` |

---

## 5. WIMS/XWims integration

The course tree is a natural integration point for WIMS activities:

```
WIMS/XWims activity page
  │
  ├── Loads course.json (defines the exercise tree)
  ├── Embeds GeoGebra GWT applet (existing WIMS applet integration)
  ├── Course tree panel (course-tree.js)
  │     └── Runs steps → GgbAPI → construction
  │
  └── Submission step
        ├── courseTree collects: construction XML, values, screenshots
        ├── Posts to WIMS grading endpoint
        └── WIMS returns grade → course tree shows ✓/✗ per step
```

The `course-tree.js` module is **framework-free** — it works in any HTML page, including a WIMS activity page. The GeoGebra applet just needs to be injected and its API passed to `courseTree.setApi()`.

---

## 6. What the web approach does NOT require

| Not needed | Why |
|---|---|
| GWT code changes | Tree is outside the applet in the host page |
| New GeoGebra view type | No `VIEW_COURSE_TREE` constant in `common` |
| `common` edits | All host-side |
| Server-side rendering | Course file is static JSON, served as a file |
| Database | Progress can be stored in `localStorage` (per-student, per-browser) or posted to WIMS |
| Authentication | Inherited from the WIMS session if running inside XWims |

---

## 7. Phased implementation

### Phase A — RCP proof (depends on D-04 PASS)

| Step | Deliverable | Who | Gate |
|---|---|---|---|
| A.1 | `CourseModel.java` + `CourseNode.java` — parse `course.json` | Codex | — |
| A.2 | `CourseTreePanel.java` — SWT Tree composite | Codex | — |
| A.3 | Add panel to `GeoGebraPlusApplication` SashForm | Codex | D-04 |
| A.4 | `launch.ps1 -Course` flag | Codex | — |
| A.5 | Sample course file: `courses/trigonometry_intro.json` | Claude | — |
| A.6 | Scenario test: `S_P-09_CourseTree_GROK_V1.ps1` | Claude | D-04 |

### Phase B — Web proof (independent of Phase A)

| Step | Deliverable | Who | Gate |
|---|---|---|---|
| B.1 | `course-tree.js` + `course-tree.css` | Claude | — |
| B.2 | `course-host.html` — host page with GWT applet embed | Claude | W-01 |
| B.3 | Same sample course file as A.5 | — | — |
| B.4 | Manual test: open in browser, click steps, verify construction | Owner | W-01 |

### Phase C — WIMS integration (depends on S-01 contract)

| Step | Deliverable | Who | Gate |
|---|---|---|---|
| C.1 | WIMS activity template with embedded course tree | Grok Bot | D scenario |
| C.2 | Submission step → WIMS grading endpoint | Grok Bot | S-01 |
| C.3 | Grade display in course tree (✓/✗ per step) | Codex | S-02 |

### Constraints preserved

- **`common` untouched** throughout all phases
- **GWT stays as baseline** — the web tree wraps it from outside
- **No new GeoGebra View ID** — the course tree is host UI, not a kernel view
- **Same directive vocabulary** — `CMD`, `CAS`, `VAL` from `ScenarioScript.java`

---

## 8. Future: GWT replacement

When the web host technology changes (Gate C), the course tree survives because:

1. `course-tree.js` only depends on `ggbApplet.evalCommand()` — which any replacement must expose (it's the published GeoGebra Apps API).
2. The HTML/CSS tree panel is framework-free — it works in React, Vue, plain HTML, or a Web Component.
3. The `course.json` schema is client-agnostic.

The only change needed at GWT retirement: swap the GWT applet loader script for the replacement loader. The course tree code stays identical.
