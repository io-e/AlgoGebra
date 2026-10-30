<!-- CLAUDE_V1 -->
# Guide — Migrating PS1 Scenarios to Eclipse Cheat Sheets and VS Code Tasks

| Field | Value |
|---|---|
| Document | `02-Cdc/Guide_Migration_PS1_to_CheatSheets_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Active |
| Date | 2026-10-30 |
| Parent | `Plan_CheatSheets_Eclipse_VSCode_CLAUDE_V1.md` |

---

## 1. Core principle — the scripts don't change

The 33 `S_*_GROK_V1.ps1` scripts are **not rewritten**. They stay exactly where they are:

```
03-RCP-Spike/tests/scenarios/S_<ID>_<Name>_GROK_V1.ps1
```

The Cheat Sheets and VS Code tasks are a **presentation layer** on top. They provide:
- Human-readable step descriptions (what the script does, what to check)
- Interactive checkboxes (Eclipse) or problem matchers (VS Code)
- Gate sequencing (run D-02 before D-03 before D-04...)

The scripts remain the single source of truth for test logic.

---

## 2. Extraction pattern — what comes from each script

Every script follows the same initialization pattern on line 1-3:

```powershell
# GROK_V1 - <ID> <title> (<scope>). Gate <gate>. Pass (spec): <criteria>.
# <additional detail lines>
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1')
Initialize-TestSuite 'S_<ID>'
Write-ScenarioHeader '<ID>' '<title>' '<gate>' '<scope>'
Test-ImagePresent    # (if the scenario needs the RCP image)
```

From this, the Cheat Sheet extracts:

| Script element | Maps to Cheat Sheet element |
|---|---|
| Line 1 comment: `<ID> <title>` | `<cheatsheet title="<ID> — <title>">` |
| Line 1: `Gate <gate>` | `<intro>` mentions the gate |
| Line 1: `Pass (spec): <criteria>` | Step "Verify results" → expected outcome description |
| Line 2-3: additional comments | `<intro><description>` detail |
| `Test-ImagePresent` | Step 1 prerequisite: "IMAGE must be set" |
| `Test-UiPrerequisites` | Step 1 prerequisite: "Display/Xvfb required" |
| `Invoke-ProductScenario` | Step 2: "Run the scenario" |
| `Invoke-BaselineScenario` | Step 2 note: "Also runs the pinned baseline for comparison" |
| `Invoke-ResolveProbe` | Step 2: "Runs an Equinox resolution probe (no UI)" |
| `Compare-Scn` | Step 3: "Compare product vs. baseline results" |
| Each `Test-Ok '<ID>-nn-<name>'` | Step 3 subitem: one check to verify |
| `Skip-Blocked '<label>' '<reason>'` | Step 4 note: "Known blocked — <reason>" |
| `Exit-Bail $why` | Prerequisite failure → Cheat Sheet says "stop if not met" |
| `Complete-TestSuite` | Step 5: "Update tracking" |

---

## 3. The three script categories and their Cheat Sheet shape

### Category A — Resolution / static analysis (no UI)

Scripts that use `Invoke-ResolveProbe` only. No product launch, no display needed.

**Scripts:** D-01, D-06, D-07, D-08, D-09, D-10, O-01, O-02, O-03, P-08, X-02, X-05

**Cheat Sheet shape:**
```xml
<cheatsheet title="<ID> — <title>">
  <intro><description>Gate <gate>. <pass criteria>. No UI — resolution/static only.
    Script: S_<ID>_<Name>_GROK_V1.ps1</description></intro>

  <item title="1. Prerequisites">
    <subitem label="IMAGE set to an RCP installed image (r8+)" skip="false"/>
    <subitem label="JAVA_HOME points to JDK 21+" skip="false"/>
  </item>

  <item title="2. Run the script">
    <description>pwsh -File 03-RCP-Spike/tests/scenarios/S_<ID>_<Name>_GROK_V1.ps1
    Or: Run_All_GROK_V1.ps1 -Scenarios -Only '<ID>'</description>
  </item>

  <item title="3. Verify checks">
    <!-- one subitem per Test-Ok in the script -->
    <subitem label="<ID>-01-<check-name>: <what it verifies>" skip="false"/>
    <subitem label="<ID>-02-<check-name>: <what it verifies>" skip="false"/>
  </item>

  <item title="4. Known gaps">
    <description><!-- from Skip-Blocked calls --></description>
  </item>

  <item title="5. Update SCENARIOS_TRACKING">
    <description>Record status, run ID, evidence path.</description>
  </item>
</cheatsheet>
```

### Category B — Product + baseline comparison (UI required)

Scripts that use `Invoke-ProductScenario` + `Invoke-BaselineScenario` + `Compare-Scn`.

**Scripts:** P-01, P-02, P-03, P-04, P-05, P-07, O-04, O-05, X-01, X-03, X-04, X-06, X-07

**Cheat Sheet shape:**
```xml
<cheatsheet title="<ID> — <title>">
  <intro><description>Gate <gate>. <pass criteria>. UI required — product vs. baseline.
    Script: S_<ID>_<Name>_GROK_V1.ps1</description></intro>

  <item title="1. Prerequisites">
    <subitem label="IMAGE set to an RCP installed image (r8+)" skip="false"/>
    <subitem label="JAVA_HOME points to JDK 21+" skip="false"/>
    <subitem label="GGB_BASELINE_LIB set (upstream desktop distribution)" skip="false"/>
    <subitem label="Display available (Windows desktop or Linux Xvfb)" skip="false"/>
    <subitem label="Close browsers/editors — AllowForegroundInput may be needed" skip="false"/>
  </item>

  <item title="2. Run the script">
    <description>pwsh -File 03-RCP-Spike/tests/scenarios/S_<ID>_<Name>_GROK_V1.ps1
    Or: Run_All_GROK_V1.ps1 -Scenarios -Only '<ID>' -AllowForegroundInput</description>
  </item>

  <item title="3. Check product results">
    <subitem label="Product scenario ran to _END" skip="false"/>
    <subitem label="No directive ERR in product output" skip="false"/>
  </item>

  <item title="4. Compare with baseline">
    <description>Compare-Scn runs automatically. Check each Test-Ok result.</description>
    <!-- one subitem per Test-Ok -->
  </item>

  <item title="5. Known bugs / blockers">
    <description><!-- BUG-014 etc. from the script or SCENARIOS_TRACKING --></description>
  </item>

  <item title="6. Update SCENARIOS_TRACKING">
    <description>Record status, run ID, evidence path.</description>
  </item>
</cheatsheet>
```

### Category C — Precheck / NOT RUN stubs

Scripts where the feature does not exist yet — they document the gap and exit NOT RUN.

**Scripts:** S-01 through S-07, P-06

**Cheat Sheet shape:**
```xml
<cheatsheet title="<ID> — <title>">
  <intro><description>Gate <gate>. <pass criteria>.
    Feature not implemented — script verifies the gap and exits NOT RUN.
    Script: S_<ID>_<Name>_GROK_V1.ps1</description></intro>

  <item title="1. Run the precheck">
    <description>pwsh -File 03-RCP-Spike/tests/scenarios/S_<ID>_<Name>_GROK_V1.ps1
    Expected: NOT RUN with documented reason.</description>
  </item>

  <item title="2. Confirm status unchanged">
    <subitem label="Feature still absent (no contract/API code found)" skip="false"/>
    <subitem label="Script exited NOT RUN, not FAIL" skip="false"/>
  </item>

  <item title="3. No tracking update needed">
    <description>Status stays NOT RUN until the feature is implemented.</description>
  </item>
</cheatsheet>
```

---

## 4. Complete script-to-Cheat-Sheet mapping (33 scripts)

| Script | ID | Title | Gate | Category | Key checks |
|---|---|---|---|---|---|
| `S_P-01_CleanProduct` | P-01 | Clean product, no optional extension | A | B | 8 checks: clean profile, resolved bundles, 2D/3D/CAS, screenshot |
| `S_P-02_CoreFeatures` | P-02 | Algebra, CAS, spreadsheet, 2D, 3D | A | B | 34-directive comparison vs baseline. BUG-014 blocker |
| `S_P-03_StandardTools` | P-03 | Standard tools | A | B | 2D toolbar mode comparison vs baseline |
| `S_P-04_SaveReopen` | P-04 | Open, save, reopen .ggb | A | B | Build → save → reopen → fresh session → baseline cross-check |
| `S_P-05_ScriptsMacrosExport` | P-05 | Scripts, macros, images, export | A | B | GgbScript, PNG/SVG export vs baseline |
| `S_P-06_Offline` | P-06 | Offline mode | — | C | Linux: unshare -rn. Windows: NOT RUN (firewall needed) |
| `S_P-07_ScreensInput` | P-07 | Screens and input | — | B | Resize, keyboard input, xdotool, object list via GgbAPI |
| `S_P-08_PinTraceability` | P-08 | Upstream version and pin | — | A | Git commit match, VERSION_STRING, dirty check |
| `S_D-01_EclipseImport` | D-01 | Eclipse import | — | A | Gradle composite/settings parseable for Buildship |
| `S_D-06_ExtensionRegistry` | D-06 | Extension registry | B | A | Good bundle resolves, bad isolated, core intact |
| `S_D-07_EnableDisable` | D-07 | Enable/disable extension | B | A | Add/remove bundle, .ggb work preserved |
| `S_D-08_IncompatibleExtension` | D-08 | Incompatible extension | B | A | Version-range refusal at resolver level |
| `S_D-09_SignatureChannel` | D-09 | Signature/channel policy | E | A | Currently no policy → gap documented |
| `S_D-10_InstallUpgrade` | D-10 | Install, upgrade, rollback | — | A | Self-contained image, bundled Java, no system deps |
| `S_O-01_UpstreamUpdate` | O-01 | Newer upstream, no common edit | — | A | No common copy/patch in product repo |
| `S_O-02_LicenseInventory` | O-02 | License inventory | E | A | TSV of all jars, natives, fonts, licenses |
| `S_O-03_CleanRebuildSbom` | O-03 | Clean rebuild and hashes | E | A | SBOM sha256 list. Windows: build.ps1 NOT RUN |
| `S_O-04_FailureMessages` | O-04 | Missing bundle, bad .ggb, WIMS down | — | B | Safe error messages, redacted logs |
| `S_O-05_ActivityUpgrade` | O-05 | Activity upgrade | — | B | Old XML format .ggb opens with correct values |
| `S_X-01_ComputeContract` | X-01 | Same compute contract | D | B | Typed result fields, deterministic engine calls |
| `S_X-02_StaleResult` | X-02 | Stale result rejected | D | A | API revision field, reject stale |
| `S_X-03_WriteBack` | X-03 | Write allowlisted number back | D | B | setValue on free/dependent/fixed objects |
| `S_X-04_SaveUndo` | X-04 | Save and undo | D | B | Undo removes exactly last command |
| `S_X-05_CapabilityArtifacts` | X-05 | Same capability, two artifacts | D | A | API ids, separate desktop jars |
| `S_X-06_TimeoutBadOutput` | X-06 | Timeout and bad output | D | A | Typed error within timeout, process killed |
| `S_X-07_LeanAbsent` | X-07 | Lean absent | — | B | App opens, feature unavailable |
| `S_S-01_SchemaCapability` | S-01 | Teacher picks schema + capability | D | C | No contract → NOT RUN |
| `S_S-02_SubmitOnce` | S-02 | Submit once | D | C | No contract → NOT RUN |
| `S_S-03_Idempotency` | S-03 | Retry same idempotency key | D | C | No contract → NOT RUN |
| `S_S-04_OfflineDraftSync` | S-04 | Offline draft, then sync | D | C | No contract → NOT RUN |
| `S_S-05_BadSchema` | S-05 | Bad schema | D | C | No contract → NOT RUN |
| `S_S-06_TokenHidden` | S-06 | Token not visible to extension | — | C | No contract → NOT RUN |
| `S_S-07_OefToXWims` | S-07 | Sample OEF to XWims | — | C | No contract → NOT RUN |

---

## 5. Step-by-step migration procedure

### Step 1 — Generate XML from script metadata (automated)

A PowerShell generator script reads each `S_*_GROK_V1.ps1`, extracts the metadata from the `Write-ScenarioHeader` call and comments, and produces the XML skeleton:

```powershell
# Generate_CheatSheets_CLAUDE_V1.ps1
# Reads scenario scripts → writes cheatsheet XML skeletons
param([string]$OutDir = '03-RCP-Spike/cheatsheets/scenarios')

$scripts = Get-ChildItem '03-RCP-Spike/tests/scenarios' -Filter 'S_*_GROK_V1.ps1'
foreach ($s in $scripts) {
    $lines = Get-Content $s.FullName -TotalCount 5
    # Extract from comment line 1
    $comment = $lines[0] -replace '^#\s*GROK_V1\s*-\s*', ''
    if ($comment -match '^(\S+-\d+)\s+(.+?)(?:\.\s*Gate\s+(\S+))?\.\s*Pass \(spec\):\s*(.+)$') {
        $id    = $Matches[1]
        $title = $Matches[2].TrimEnd('. ')
        $gate  = if ($Matches[3]) { $Matches[3] } else { '—' }
        $pass  = $Matches[4]
    } else { Write-Warning "Cannot parse: $($s.Name)"; continue }

    # Detect category
    $body = Get-Content $s.FullName -Raw
    $hasUi    = $body -match 'Invoke-ProductScenario|Invoke-BaselineScenario|Test-UiPrerequisites'
    $isStub   = $body -match 'Exit-Bail.*not.*exist|stays NOT RUN'
    $cat = if ($isStub) { 'C' } elseif ($hasUi) { 'B' } else { 'A' }

    # Extract Test-Ok names
    $checks = [regex]::Matches($body, "Test-Ok\s+'([^']+)'") |
              ForEach-Object { $_.Groups[1].Value }

    # Extract Skip-Blocked
    $skips = [regex]::Matches($body, "Skip-Blocked\s+'([^']+)'\s+'([^']+)'") |
             ForEach-Object { "$($_.Groups[1].Value): $($_.Groups[2].Value)" }

    # Build XML
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<cheatsheet title="$id — $title">
  <intro>
    <description>
      Gate $gate. Pass criteria: $pass
      Category: $cat. Script: $($s.Name)
    </description>
  </intro>

  <item title="1. Prerequisites">
    <description>
      Verify environment variables are set before running.
    </description>
    <subitem label="IMAGE points to an RCP installed image (r8+)" skip="false"/>
    <subitem label="JAVA_HOME points to JDK 21+" skip="false"/>
$(if ($hasUi) { '    <subitem label="Display available (Windows desktop or Linux Xvfb)" skip="false"/>
    <subitem label="GGB_BASELINE_LIB set (if baseline comparison)" skip="false"/>' })
  </item>

  <item title="2. Run the scenario">
    <description>
      pwsh -File 03-RCP-Spike/tests/scenarios/$($s.Name)
      Or: Run_All_GROK_V1.ps1 -Scenarios -Only '$id'$(if ($hasUi) { ' -AllowForegroundInput' })
    </description>
  </item>

  <item title="3. Verify results">
    <description>Pass criteria: $pass</description>
$(foreach ($c in $checks) { "    <subitem label=`"$c`" skip=`"false`"/>`n" })  </item>
$(if ($skips.Count -gt 0) { @"

  <item title="4. Known gaps">
    <description>
$(foreach ($sk in $skips) { "      $sk`n" })    </description>
  </item>
"@ })

  <item title="$(if ($skips.Count -gt 0) { '5' } else { '4' }). Update tracking">
    <description>
      Update SCENARIOS_TRACKING_GROK_V1.md with status, run ID, evidence path.
    </description>
  </item>
</cheatsheet>
"@
    $safeName = $id -replace '-', '_'
    $xmlPath = Join-Path $OutDir "${safeName}_${title -replace '[^A-Za-z0-9]+', '_'}.xml"
    $xml | Set-Content $xmlPath -Encoding UTF8
    Write-Host "Generated: $xmlPath"
}
```

### Step 2 — Generate gate composite Cheat Sheets

One composite XML per gate, referencing the scenario XMLs in gate order:

| Gate | Scenarios (in order) |
|---|---|
| A | P-02, P-03, P-04, P-05 |
| B | D-02 (suite 08), D-03 (suite 11), D-04 (suite 09), D-05 (suite 10), D-06, D-07, D-08 |
| C | W-01, W-02 (no scripts yet — placeholder) |
| D | X-01, X-02, X-03, X-04, X-05, X-06, S-01, S-02, S-03, S-04, S-05 |
| E | O-02, O-03, D-09, W-04 (no W-04 script yet — placeholder) |

Note: D-02/D-03/D-04/D-05 are covered by suites 08/09/10/11, not by standalone scenario scripts. Their Cheat Sheet entries reference the suite scripts instead, with appropriate instructions.

### Step 3 — Generate VS Code tasks.json

`tasks.json` is generated from the same script inventory. One task per scenario (using `Run_All -Only '<ID>'`), plus one task per gate.

### Step 4 — Manual review pass

After generation, review each XML for:
1. **Known bugs** — add BUG-014, BUG-015, etc. as notes in the relevant steps
2. **Windows-only blockers** — P-06 (offline), O-03 (rebuild), suite 14 foreground guard
3. **Missing feature stubs** — S-01 through S-07 and any W-* scenarios

### Step 5 — Place files and commit

```
03-RCP-Spike/
  cheatsheets/
    scenarios/       ← 33 generated XMLs (one per script)
    gates/           ← 5 composite XMLs (one per gate)
    README.md        ← how to open in Eclipse, environment setup
  Generate_CheatSheets_CLAUDE_V1.ps1  ← the generator (re-runnable)
.vscode/
  tasks.json         ← scenario + gate + evidence tasks
  extensions.json    ← recommended extensions
```

---

## 6. Keeping them in sync

When a `.ps1` script changes (new checks, renamed Test-Ok, new Skip-Blocked):

1. **Re-run the generator** — it reads the scripts and overwrites the XMLs.
2. **Manual additions are lost** — if you added BUG notes or custom steps, keep them in a separate override file or add them to the script comments (preferred — then the generator can extract them too).
3. **VS Code tasks.json** does not change when scripts change — it calls `Run_All -Only '<ID>'` which finds scripts by filename pattern.

The rule: **script comments are the source of truth**. The generator extracts. The XMLs are derived artifacts.

---

## 7. What does NOT migrate

| Item | Stays where it is | Why |
|---|---|---|
| `lib/Scenario_GROK_V1.ps1` | Test library | Called by scripts, not by Cheat Sheets |
| `lib/TestFramework_GROK_V1.ps1` | Test framework | TAP output, Test-Ok, etc. |
| `lib/UiDriver_GROK_V1.ps1` | UI driver | Foreground guard, screenshots |
| `Run_All_GROK_V1.ps1` | Aggregator/runner | Both Cheat Sheets and tasks.json call it |
| `fixtures/` | Test data | Referenced by scripts |
| `results/` | Run output | Git-ignored, per-run |
| `evidence/` | Exported evidence | Immutable, committed |
| `SCENARIOS_TRACKING_GROK_V1.md` | Status matrix | Updated manually after each run |

Nothing moves. The Cheat Sheets and VS Code tasks are an **addition**, not a replacement.
