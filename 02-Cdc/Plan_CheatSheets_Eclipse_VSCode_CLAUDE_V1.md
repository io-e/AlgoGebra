<!-- CLAUDE_V1 -->
# Plan — Eclipse Cheat Sheets and VS Code Tasks for Scenario Testing

| Field | Value |
|---|---|
| Document | `02-Cdc/Plan_CheatSheets_Eclipse_VSCode_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Proposal |
| Date | 2026-10-30 |
| Depends on | `SCENARIOS_TRACKING_GROK_V1.md`, `Synthesis_Automation_Tools_Eclipse_Equinox_GROK_V1.md` |

---

## 1. Goal

Provide **two independent, IDE-integrated** ways to run the 45 V2 validation scenarios interactively:
- **Eclipse Cheat Sheets** — XML-based step-by-step guides inside the Eclipse developer workbench
- **VS Code Tasks** — `tasks.json` + problem matchers for running the same PowerShell scripts

Both tools drive the same `03-RCP-Spike/tests/scenarios/S_*_GROK_V1.ps1` scripts. Neither tool replaces the headless `Run_All_GROK_V1.ps1` runner — they add a human-guided layer on top for attended testing, debugging, and teaching new team members the scenario flow.

---

## 2. Why two IDEs

| IDE | Role in the project | Cheat Sheet strength |
|---|---|---|
| **Eclipse** | Developer workbench (RCP, OSGi, Bnd, Equinox). Already at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` | Native Cheat Sheet engine (`org.eclipse.ui.cheatsheets`). Step-by-step guidance with checkboxes, sub-items, and command links. Can trigger Java actions inside the IDE. |
| **VS Code** | Specification editing, PowerShell debugging, Markdown preview, Git integration. Used daily for this repo. | Tasks + terminals. Problem matchers parse PASS/FAIL/SKIP. PowerShell debugging. Quick iteration on script fixes. |

Neither IDE depends on the other. A tester uses whichever is open.

---

## 3. Eclipse Cheat Sheets

### 3.1 What Eclipse Cheat Sheets are

An Eclipse Cheat Sheet is an XML file that the Eclipse help system renders as a side panel with:
- A title and introduction
- Numbered steps with descriptions
- Checkboxes (manual completion) or commands (auto-completion)
- Sub-items for optional branches
- Links between cheat sheets (composite cheat sheets for gates)

They are part of `org.eclipse.ui.cheatsheets` — already bundled in Eclipse 2026-09.

### 3.2 Structure

```
03-RCP-Spike/
  cheatsheets/
    gates/
      Gate_B_CheatSheet.xml          ← composite: D-02 → D-03 → D-04 → D-05 → D-06
      Gate_A_CheatSheet.xml          ← composite: P-02 → P-03 → P-04 → P-05
      Gate_E_CheatSheet.xml          ← composite: O-02 → O-03 → D-09 → W-04
    scenarios/
      P-01_CleanProduct.xml
      P-02_CoreFeatures.xml
      ...                            ← one XML per scenario (33 files)
      D-02_RCPStarts.xml
      ...
    README.md
```

### 3.3 Example — P-02 Core Features Cheat Sheet

```xml
<?xml version="1.0" encoding="UTF-8"?>
<cheatsheet title="P-02 — Algebra, CAS, Spreadsheet, 2D, 3D">
  <intro>
    <description>
      Gate A scenario. Verifies that the RCP product produces the same
      results as the pinned baseline for core GeoGebra features.
      Script: S_P-02_CoreFeatures_GROK_V1.ps1
    </description>
  </intro>

  <item title="1. Check prerequisites">
    <description>
      Verify IMAGE, JAVA_HOME, and GGB_SOURCE environment variables are set.
      IMAGE must point to a valid RCP installed image (r8+).
    </description>
    <subitem label="IMAGE set" skip="false"/>
    <subitem label="JAVA_HOME points to JDK 21+" skip="false"/>
    <subitem label="GGB_SOURCE points to the pinned checkout (375db7faf54)" skip="false"/>
  </item>

  <item title="2. Run the scenario script">
    <description>
      Open a PowerShell terminal and run:
      pwsh -File 03-RCP-Spike/tests/scenarios/S_P-02_CoreFeatures_GROK_V1.ps1
      Or use Run_All with: -Only P-02
    </description>
    <command serialization=
      "org.eclipse.debug.ui.commands.OpenRunConfigurations"/>
  </item>

  <item title="3. Check the 34 directives">
    <description>
      The script runs fixtures/p02_core_GROK_V1.tsv (34 directives)
      in both the product and the pinned baseline. Compare results.
    </description>
    <subitem label="evalCommand results match baseline" skip="false"/>
    <subitem label="CAS results match baseline" skip="false"/>
    <subitem label="3D Plane command works" skip="false"/>
  </item>

  <item title="4. Record BUG-014 status">
    <description>
      Known: f(x)=x^2-2x, m={{1,2},{3,4}}, 3D Plane(A,B,(1,0,0))
      fail in the product (evalCommand returns false + error dialog).
      If still failing: scenario stays FAIL, record the evidence path.
      If fixed: mark PASS and update SCENARIOS_TRACKING.
    </description>
  </item>

  <item title="5. Update tracking">
    <description>
      Update 03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1.md
      with the new status, run ID, and evidence path.
    </description>
  </item>
</cheatsheet>
```

### 3.4 Gate composite Cheat Sheet (example: Gate B)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<compositeCheatsheet name="Gate B — Desktop RCP Validation">
  <taskGroup name="Gate B scenarios" kind="sequence">
    <task name="D-02" kind="cheatsheet">
      <param name="id" value="D-02"/>
      <param name="path" value="../scenarios/D-02_RCPStarts.xml"/>
    </task>
    <task name="D-03" kind="cheatsheet">
      <param name="id" value="D-03"/>
      <param name="path" value="../scenarios/D-03_PackageOwnership.xml"/>
    </task>
    <task name="D-04" kind="cheatsheet">
      <param name="id" value="D-04"/>
      <param name="path" value="../scenarios/D-04_SwingEmbedding.xml"/>
    </task>
    <task name="D-05" kind="cheatsheet">
      <param name="id" value="D-05"/>
      <param name="path" value="../scenarios/D-05_CAS3D.xml"/>
    </task>
    <task name="D-06" kind="cheatsheet">
      <param name="id" value="D-06"/>
      <param name="path" value="../scenarios/D-06_ExtensionBundle.xml"/>
    </task>
  </taskGroup>
</compositeCheatsheet>
```

### 3.5 Eclipse setup steps

1. Copy `03-RCP-Spike/cheatsheets/` into the Eclipse workspace or reference it via a linked resource.
2. **Help > Cheat Sheets > Open from file** — browse to any `.xml` file.
3. Or register them via a plug-in `plugin.xml` extension point `org.eclipse.ui.cheatsheets.cheatSheetContent` for the workspace.
4. The Cheat Sheet panel opens in the right sidebar. Step through each item, checking off as you go.

No product code changes. No `common` edits. This is developer-workbench tooling only.

---

## 4. VS Code Tasks

### 4.1 Structure

```
.vscode/
  tasks.json              ← scenario tasks + gate tasks
  settings.json           ← PowerShell terminal profile
  extensions.json         ← recommended extensions
```

### 4.2 `tasks.json`

```json
{
  "version": "2.0.0",
  "inputs": [
    {
      "id": "scenarioId",
      "type": "pickString",
      "description": "Scenario to run",
      "options": [
        "P-01", "P-02", "P-03", "P-04", "P-05", "P-06", "P-07", "P-08",
        "D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-07", "D-08", "D-09", "D-10",
        "X-01", "X-02", "X-03", "X-04", "X-05", "X-06", "X-07",
        "S-01", "S-02", "S-03", "S-04", "S-05", "S-06", "S-07",
        "O-01", "O-02", "O-03", "O-04", "O-05"
      ]
    },
    {
      "id": "gateId",
      "type": "pickString",
      "description": "Gate to validate",
      "options": ["A", "B", "C", "D", "E"]
    }
  ],
  "tasks": [
    {
      "label": "Run single scenario",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/tests/Run_All_GROK_V1.ps1",
        "-Scenarios", "-Only", "${input:scenarioId}"
      ],
      "group": "test",
      "presentation": { "reveal": "always", "panel": "new" },
      "problemMatcher": {
        "owner": "geogebraplus-scenario",
        "pattern": {
          "regexp": "^not ok (\\d+) - \\[P(\\d)\\] (.+)$",
          "line": 1,
          "message": 3,
          "severity": 1
        }
      }
    },
    {
      "label": "Run gate",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/tests/Run_All_GROK_V1.ps1",
        "-Scenarios", "-Gate", "${input:gateId}"
      ],
      "group": "test",
      "presentation": { "reveal": "always", "panel": "new" },
      "problemMatcher": {
        "owner": "geogebraplus-gate",
        "pattern": {
          "regexp": "^not ok (\\d+) - \\[P(\\d)\\] (.+)$",
          "line": 1,
          "message": 3,
          "severity": 1
        }
      }
    },
    {
      "label": "Run all scenarios (non-UI)",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/tests/Run_All_GROK_V1.ps1",
        "-Scenarios", "-SkipUi"
      ],
      "group": "test",
      "presentation": { "reveal": "always", "panel": "new" }
    },
    {
      "label": "Run all scenarios (with UI, attended)",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/tests/Run_All_GROK_V1.ps1",
        "-Scenarios", "-AllowForegroundInput"
      ],
      "group": "test",
      "presentation": { "reveal": "always", "panel": "new" }
    },
    {
      "label": "Run engine tests",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/test-engines.ps1"
      ],
      "group": "test"
    },
    {
      "label": "Export evidence",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-NoProfile", "-File",
        "03-RCP-Spike/tests/Run_All_GROK_V1.ps1",
        "-Scenarios", "-ExportEvidence", "manual-review"
      ],
      "group": "test"
    }
  ]
}
```

### 4.3 Recommended VS Code extensions

```json
{
  "recommendations": [
    "ms-vscode.powershell",
    "hbenl.vscode-test-explorer",
    "DavidAnson.vscode-markdownlint",
    "redhat.vscode-yaml"
  ]
}
```

### 4.4 How to use

1. **Ctrl+Shift+P > Tasks: Run Task** → pick "Run single scenario" → pick "P-02" from the dropdown.
2. The terminal opens, runs the scenario script, and the problem matcher highlights failures in the Problems panel.
3. Click a failure to see the TAP output line.
4. For gate validation: "Run gate" → pick "B" → runs D-02 through D-06.
5. For evidence export after a successful run: "Export evidence".

### 4.5 PowerShell debugging

Set a breakpoint in any `S_*_GROK_V1.ps1` file. Use **Run > Start Debugging** with the PowerShell extension. The scenario script runs in the VS Code debugger — step through check_parm logic, output parsers, etc.

---

## 5. Comparison

| Feature | Eclipse Cheat Sheet | VS Code Task |
|---|---|---|
| Step-by-step guidance | Native — checkboxes, descriptions, sub-items | Manual — read the task output |
| Interactive checkoff | Yes — Eclipse tracks completion | No — use SCENARIOS_TRACKING.md |
| Gate sequencing | Composite cheat sheets chain scenarios | Run gate task (sequential in one terminal) |
| Script debugging | External terminal (PowerShell) | Integrated (PowerShell extension) |
| Problem highlighting | No — Eclipse Cheat Sheets are guides | Yes — problem matcher parses TAP failures |
| Best for | Onboarding, attended manual validation, teaching | Fast iteration, script debugging, CI integration |
| Requires | Eclipse 2026-09 (already installed) | VS Code + PowerShell extension |

**Use Eclipse Cheat Sheets** when walking through a gate validation manually, when onboarding a new contributor, or when the scenario needs human judgment (screenshots, focus transfer, visual checks).

**Use VS Code Tasks** for fast script iteration, debugging failures like BUG-014/015, and for scripted evidence capture.

---

## 6. Implementation plan

| Step | Deliverable | Who | Effort |
|---|---|---|---|
| 1 | Write 33 scenario Cheat Sheet XMLs (template-based, ~15 min each) | Claude | 1 session |
| 2 | Write 5 gate composite Cheat Sheet XMLs | Claude | 30 min |
| 3 | Create `.vscode/tasks.json` with all tasks and problem matchers | Claude | 30 min |
| 4 | Test: open one Cheat Sheet in Eclipse, run one scenario | Owner | 10 min |
| 5 | Test: run "Run single scenario" in VS Code, verify problem matcher | Owner | 10 min |
| 6 | Commit the cheatsheets/ and .vscode/ directories | Claude | 5 min |

No product code changes. No `common` edits. Both tools reference existing scripts.

---

## 7. Environment variables (shared by both tools)

Both Eclipse external tools and VS Code tasks need these set before running scenarios:

| Variable | Value | Required by |
|---|---|---|
| `IMAGE` | Path to the RCP installed image (e.g., `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12`) | All scenario scripts |
| `JAVA_HOME` | JDK 21 path (e.g., `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot`) | Build and run scripts |
| `GGB_SOURCE` | GeoGebra source pin (e.g., `D:\ALF_ZGit\G1_Geogebra_Migration`) | Baseline comparison |
| `GGB_BASELINE_LIB` | Upstream desktop distribution lib/ path | ScenarioBaseline comparison |
