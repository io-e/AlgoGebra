<!-- CLAUDE_V1 -->
# Study — Course Tree in GeoGebraPlus: Architecture and Display Options

| Field | Value |
|---|---|
| Document | `02-Cdc/Study_Course_Tree_GeoGebraPlus_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Study / Proposal |
| Date | 2026-10-30 |
| Depends on | V2 Architecture, `Plan_CheatSheets_Eclipse_VSCode_CLAUDE_V1.md` |

---

## 1. What the user asked

> How to set up a course as a tree of actions performed in Eclipse or VS Code,
> and how to display that tree in the GeoGebra application.

This connects three layers:

| Layer | Where | What |
|---|---|---|
| **Authoring** | Eclipse IDE or VS Code | Teacher/developer creates a course tree (steps, actions, expected outcomes) |
| **Data model** | JSON/XML course file | Hierarchical tree of nodes: sections → steps → actions |
| **Display** | GeoGebraPlus RCP product | Student sees the tree in a side panel, clicks a step, the construction updates |

---

## 2. What already exists in GeoGebra

### 2.1 Construction Protocol (built-in)

GeoGebra already has a **Construction Protocol** — a step-by-step table of every construction operation:

- `ConstructionProtocolView` (`common/gui/view/consprotocol/`) — the abstract model
- `ConstructionProtocolViewD` (`desktop/gui/view/consprotocol/`) — Swing JTable implementation
- `ConstructionProtocolDockPanel` — a dockable panel in the desktop layout (`VIEW_CONSTRUCTION_PROTOCOL = 32`)
- `ConstructionProtocolNavigation` — play/pause/step controls with a configurable delay

The Navigation Bar can step through the construction automatically (Play button). This is a **flat list**, not a tree — it replays every `evalCommand` in order.

### 2.2 Assignment / Exercise (built-in)

GeoGebra has a minimal exercise framework:

- `Assignment` / `GeoAssignment` (`common/util/`) — checks if a student's construction matches a macro's expected output
- `GgbAPI.getExerciseFraction()` — returns a `correct` score (0.0–1.0)
- Result enum: `CORRECT`, `WRONG`, `NOT_ENOUGH_INPUTS`, `WRONG_INPUT_TYPES`, etc.

This is **per-construction verification** — it can check one assignment but does not provide a course tree, navigation between exercises, or progress tracking.

### 2.3 SHOW_TUTORIALS action

`Action.SHOW_TUTORIALS` exists in the menu system, but it opens external browser URLs (geogebra.org tutorials). It does not display an in-app guided tree.

### 2.4 What does NOT exist

- No tree-structured course view
- No multi-exercise navigation or progress tracking
- No integration between Construction Protocol steps and a teacher-authored guide
- No Cheat Sheet engine in the product (that's Eclipse IDE only)

---

## 3. Architecture proposal: three levels

### Level 1 — IDE-only (developer/teacher authoring)

**Already proposed** in `Plan_CheatSheets_Eclipse_VSCode_CLAUDE_V1.md`:
- Eclipse Cheat Sheets for guided scenario testing
- VS Code Tasks for running scenario scripts

This is the **authoring and validation** layer. A teacher or developer walks through steps in Eclipse/VS Code, validates them, and produces a course definition file.

### Level 2 — Course file format (shared data)

A JSON course file that both the IDE tools and the GeoGebraPlus product can read:

```json
{
  "course": "Introduction to Trigonometry",
  "version": "1.0",
  "schema": "ggbplus-course-v1",
  "tree": [
    {
      "id": "ch1",
      "title": "Chapter 1 — Unit Circle",
      "children": [
        {
          "id": "ch1-s1",
          "title": "Draw the unit circle",
          "type": "construction",
          "actions": [
            { "directive": "CMD", "value": "c = Circle((0,0), 1)" },
            { "directive": "CMD", "value": "A = Point(c)" }
          ],
          "validation": {
            "check": "VAL",
            "object": "c",
            "expected": "x² + y² = 1"
          },
          "hint": "Use the Circle command with center at origin and radius 1"
        },
        {
          "id": "ch1-s2",
          "title": "Mark the angle",
          "type": "construction",
          "actions": [
            { "directive": "CMD", "value": "B = (1, 0)" },
            { "directive": "CMD", "value": "α = Angle(B, (0,0), A)" }
          ],
          "ggb_file": "ch1_s2_start.ggb"
        },
        {
          "id": "ch1-s3",
          "title": "Compute sin and cos",
          "type": "computation",
          "engine": "geogebra-cas",
          "actions": [
            { "directive": "CAS", "value": "sin(π/6)" },
            { "directive": "CAS", "value": "cos(π/6)" }
          ],
          "validation": {
            "check": "CAS",
            "expected": ["1/2", "sqrt(3)/2"]
          }
        }
      ]
    },
    {
      "id": "ch2",
      "title": "Chapter 2 — Trigonometric Functions",
      "children": [
        {
          "id": "ch2-s1",
          "title": "Plot sin(x)",
          "type": "construction",
          "actions": [
            { "directive": "CMD", "value": "f(x) = sin(x)" }
          ]
        }
      ]
    }
  ]
}
```

The `actions` array uses the **same directive vocabulary** as `ScenarioScript.java` (`CMD`, `VAL`, `CAS`, `SAVE`, `PNG`, `OPEN`, `EXIT`). This is not a coincidence — it means the course can be validated by the existing test infrastructure.

### Level 3 — Product-side course tree panel

A new SWT panel in the GeoGebraPlus host, **beside** the GeoGebra Swing panel, that displays the course tree and drives the construction.

---

## 4. How to display the tree in GeoGebraPlus

### 4.1 Current host layout

The host (`GeoGebraPlusApplication.java`) uses:

```
Shell (FillLayout)
  └── SashForm (HORIZONTAL)
        ├── Composite (SWT.EMBEDDED) → SWT_AWT Frame → GeoGebraPanel (2D)
        └── Composite (SWT.EMBEDDED) → SWT_AWT Frame → App3D panel (3D)
```

### 4.2 Proposed layout with course tree

```
Shell (FillLayout)
  └── SashForm (HORIZONTAL)
        ├── CourseTreeComposite (SWT)           ← NEW: 20% width
        │     ├── SWT Tree widget (course nodes)
        │     ├── Step description label
        │     └── Button bar [Run Step] [Reset] [Next] [Check]
        ├── Composite (SWT.EMBEDDED) → GeoGebraPanel (2D)   ← 50% width
        └── Composite (SWT.EMBEDDED) → App3D panel (3D)     ← 30% width
```

### 4.3 Why SWT Tree and not Swing JTree

| Consideration | SWT Tree | Swing JTree |
|---|---|---|
| Threading | Runs on the SWT/UI thread — no SWT_AWT bridge needed | Would need another SWT_AWT frame |
| Integration | Native widget, same as the shell | Foreign toolkit inside an embedded frame |
| Look & feel | Matches the OS (Windows native tree) | Java L&F, inconsistent with the host |
| Communication with GeoGebra | Calls GgbAPI via `SwingUtilities.invokeAndWait` | Direct but adds another bridge |
| Complexity | Low — standard SWT `Tree` + `TreeItem` | Medium — another AWT frame in the SashForm |

**Recommendation: SWT Tree.** The course tree is host-owned UI. The host is SWT. The GeoGebra panel stays Swing (untouchable `common`). Communication goes through the existing `GgbAPI` reflection bridge.

### 4.4 Implementation sketch

```java
// CourseTreePanel.java — SWT composite in the host bundle
public class CourseTreePanel extends Composite {

    private final Tree tree;
    private final Label stepDescription;
    private final Button runButton;
    private CourseModel model;
    private Object ggbApi;  // GgbAPI via reflection

    public CourseTreePanel(Composite parent, int style) {
        super(parent, style);
        setLayout(new GridLayout(1, false));

        tree = new Tree(this, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
        tree.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true));

        stepDescription = new Label(this, SWT.WRAP);
        stepDescription.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));

        Composite buttons = new Composite(this, SWT.NONE);
        buttons.setLayout(new RowLayout());
        runButton = new Button(buttons, SWT.PUSH);
        runButton.setText("Run Step");
        Button nextButton = new Button(buttons, SWT.PUSH);
        nextButton.setText("Next");
        Button checkButton = new Button(buttons, SWT.PUSH);
        checkButton.setText("Check");

        tree.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onStepSelected((TreeItem) e.item)));
        runButton.addSelectionListener(SelectionListener.widgetSelectedAdapter(
            e -> onRunStep()));
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
        }
    }

    private void onStepSelected(TreeItem item) {
        CourseNode node = (CourseNode) item.getData();
        stepDescription.setText(node.getHint() != null ? node.getHint() : "");
        stepDescription.getParent().layout();
    }

    private void onRunStep() {
        TreeItem[] sel = tree.getSelection();
        if (sel.length == 0) return;
        CourseNode node = (CourseNode) sel[0].getData();
        // Execute actions on the Swing EDT via the existing bridge
        SwingUtilities.invokeLater(() -> {
            for (CourseAction action : node.getActions()) {
                // Reuse ScenarioScript directive vocabulary
                executeDirective(action.getDirective(), action.getValue());
            }
        });
    }
}
```

### 4.5 Communication flow

```
Student clicks step in SWT Tree
  │
  ▼
CourseTreePanel.onRunStep()         [SWT thread]
  │
  ├─ SwingUtilities.invokeLater()   [→ Swing EDT]
  │     │
  │     ▼
  │   GgbAPI.evalCommand("c = Circle((0,0), 1)")
  │   GgbAPI.evalCommandCAS("sin(π/6)")
  │     │
  │     ▼
  │   Construction updates, views refresh
  │
  ├─ Display.asyncExec()            [→ SWT thread]
  │     │
  │     ▼
  │   Update tree item icon: ✓/✗
  │   Show validation result in stepDescription
  │
  ▼
Student sees the construction and the step status
```

---

## 5. Authoring in Eclipse and VS Code

### 5.1 Eclipse — Cheat Sheet as authoring preview

The same Eclipse Cheat Sheet engine used for scenario testing (§3 of the Plan) can preview a course:

1. Teacher writes a `course.json` file in VS Code or Eclipse
2. A generated Cheat Sheet XML provides a step-by-step preview
3. Each step has a "Try it" button that runs the GeoGebraPlus product with `-Dggbplus.course=<file>`
4. The Cheat Sheet checkboxes track which steps the teacher has validated

The Cheat Sheet is the **IDE preview**. The product tree panel is the **student view**.

### 5.2 VS Code — course.json editing + preview

```json
// .vscode/tasks.json addition
{
  "label": "Preview course in GeoGebraPlus",
  "type": "shell",
  "command": "pwsh",
  "args": [
    "-NoProfile", "-File",
    "03-RCP-Spike/launch.ps1",
    "-Course", "${file}"
  ],
  "group": "test"
}
```

The teacher edits `course.json`, hits Ctrl+Shift+B, and the RCP product opens with the course tree panel loaded.

### 5.3 Course validation via existing test infrastructure

Since `course.json` actions use the same directive vocabulary as `ScenarioScript.java`, validation is straightforward:

```powershell
# Validate_Course_GROK_V1.ps1
# Reads a course.json → generates a .tsv → runs via ScenarioScript
param([string]$CourseFile)

$course = Get-Content $CourseFile | ConvertFrom-Json
$tsv = @()
foreach ($chapter in $course.tree) {
    foreach ($step in $chapter.children) {
        foreach ($action in $step.actions) {
            $tsv += "$($action.directive)`t$($step.id)_$($action.directive)`t$($action.value)"
        }
        if ($step.validation) {
            $tsv += "$($step.validation.check)`t$($step.id)_check`t$($step.validation.expected)"
        }
    }
}
$tsvPath = [IO.Path]::ChangeExtension($CourseFile, '.tsv')
$tsv | Set-Content $tsvPath -Encoding UTF8
# Run via existing ScenarioScript
Invoke-ProductScenario "course_$(Split-Path $CourseFile -LeafBase)" ($tsv -join "`n")
```

---

## 6. Displaying the tree — comparison of approaches

| Approach | Where | Pros | Cons |
|---|---|---|---|
| **A. SWT Tree in the host** | Product side panel | Native OS widget, host-owned, clean threading | New Java code in the host bundle |
| **B. GeoGebra Construction Protocol** | Inside GeoGebra panel | Already exists, no new code | Flat list only, no tree, no course metadata |
| **C. HTML tree in an SWT Browser** | Embedded `Browser` widget | Rich rendering, easy styling | Another widget type, offline HTML needed |
| **D. Eclipse Cheat Sheet viewer** | Eclipse IDE only | Zero product code | Only in the developer IDE, not in the student product |
| **E. Swing JTree** | Inside the GeoGebra AWT frame | Same toolkit as GeoGebra | Another SWT_AWT bridge, threading complexity |

**Recommended: Approach A (SWT Tree)** for the product, **Approach D** for teacher authoring in Eclipse.

### Why not the Construction Protocol?

The Construction Protocol is a **replay of commands** — every `evalCommand` is one row. A course tree is **pedagogical** — it groups steps into chapters, provides hints, has branching (prerequisites, optional sections), and doesn't show every atomic command. They serve different purposes.

However, the Construction Protocol Navigation Bar (Play/Pause/Step) is a good **model** for the course panel's Run/Next/Check buttons.

---

## 7. Relationship to WIMS activities

In the V2 architecture, WIMS owns the grade. The course tree is a **client-side navigation structure**:

```
WIMS / XWims activity (owns the grade)
       │
       ▼
GeoGebraPlus course file (owns the student navigation)
       │
       ├── Chapter 1 → steps → actions → GgbAPI
       ├── Chapter 2 → steps → actions → GgbAPI + external engine
       └── Submission step → activity contract → WIMS grading
```

The course tree panel **does not grade**. It navigates the student through the construction steps. When the student reaches a submission step, the existing activity/submission contract (S-01..S-07) sends the result to WIMS.

---

## 8. Implementation plan

| Phase | Deliverable | Who | Depends on |
|---|---|---|---|
| 0 | `course.json` schema (JSON Schema) | Claude | This document |
| 1 | `CourseModel.java` — parser for `course.json` | Codex | Schema |
| 2 | `CourseTreePanel.java` — SWT Tree composite | Codex | CourseModel + host SashForm |
| 3 | Host integration — add the panel to `GeoGebraPlusApplication` | Codex | CourseTreePanel |
| 4 | `Validate_Course.ps1` — course → ScenarioScript validation | Claude/Codex | course.json + existing ScenarioScript |
| 5 | Eclipse Cheat Sheet generator from `course.json` | Claude | Generator from migration guide |
| 6 | VS Code task: "Preview course" | Claude | launch.ps1 `-Course` flag |
| 7 | Sample course: "Introduction to Trigonometry" | Claude | All above |

### Constraints

- **No `common` edits.** The course tree is host-owned SWT, not a GeoGebra view.
- **No new GeoGebra view ID.** `VIEW_CONSTRUCTION_PROTOCOL = 32` is upstream. The course panel is an SWT composite in the host, not a GeoGebra `View`.
- **Communication via GgbAPI only.** `evalCommand`, `evalCommandCAS`, `getValue`, `setValue` — the same API already used by `ScenarioScript.java`.
- **Course files are data, not code.** They declare directives; the host executes them. No `eval()` or script injection.

### Gate dependency

This feature requires **D-04 PASS** (GeoGebraPanel embedding works, focus/input resolved). With D-04 still PARTIAL (BUG-014 blocks `evalCommand` for some expressions), the course tree panel can be built and tested with the commands that do work, but full validation waits for BUG-014 resolution.

---

## 9. Summary

| Question | Answer |
|---|---|
| How to author a course? | JSON file (`course.json`) edited in Eclipse or VS Code |
| How to preview in the IDE? | Eclipse Cheat Sheet (auto-generated) or VS Code task |
| How to display the tree in GeoGebraPlus? | **SWT Tree** in a new host panel, left of the GeoGebra construction |
| How to drive the construction? | Same `GgbAPI` directives as `ScenarioScript.java` |
| How to validate? | Convert course → TSV → run through existing ScenarioScript infrastructure |
| What about grading? | WIMS owns the grade; the course tree is navigation only |
| Does it touch `common`? | No — it's entirely in the host bundle |
