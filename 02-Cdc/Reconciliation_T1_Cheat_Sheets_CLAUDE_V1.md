<!-- CLAUDE_V1 -->
# Reconciliation — T1 Cheat Sheets vs Course Tree Scenarios

| Field | Value |
|---|---|
| Document | `02-Cdc/Reconciliation_T1_Cheat_Sheets_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Active |
| Date | 2026-11-01 |
| Task | C-08 (Sprint 1) |
| T1 repo | `D:\ALF_ZGit\T1_Cheat_Sheets` |
| T1 JAR | `build/org.geogebra.plus.cheatsheets_0.1.0.jar` |

---

## 0. Summary

The T1 Cheat Sheets Eclipse plugin currently ships **40 scenario XMLs** and **5 gate composites** covering the original 45-scenario validation plan. The course tree feature adds 2 new scenarios (**D-11** and **W-09**). This document reconciles the two sets and specifies the update work.

---

## 1. Current T1 coverage (40 XMLs)

### Present (40/45)

| Series | XMLs | Count |
|---|---|---|
| D (Desktop) | D-01 through D-10 | 10 |
| O (Operations) | O-01 through O-05 | 5 |
| P (Parity) | P-01 through P-08 | 8 |
| S (Submission) | S-01 through S-07 | 7 |
| W (Web) | W-01, W-02, W-04 | 3 |
| X (External) | X-01 through X-07 | 7 |

### Absent from T1 (5/45)

| Scenario | Reason |
|---|---|
| W-03 | Was removed from the 45-scenario plan (web parity merged into W-02) |
| W-05 | Was removed (web security folded into W-04) |
| W-06 | Was removed (web extension merged into W-02/W-04) |
| W-07 | Was removed (web offline folded into W-02) |
| W-08 | Was removed (web accessibility folded into W-02) |

These are correctly absent — the V2 Architecture document confirmed 45 scenarios, not 50, and W-03/W-05..W-08 are not in the scenario list.

### Gates (5 composites)

| Gate | XML | Scenarios referenced |
|---|---|---|
| Gate A | `Gate_A.xml` | P-02..P-05 |
| Gate B | `Gate_B.xml` | D-02..D-06 |
| Gate C | `Gate_C.xml` | W-01, W-02 |
| Gate D | `Gate_D.xml` | X-01..X-06, S-01..S-05 |
| Gate E | `Gate_E.xml` | O-02, O-03, D-09, W-04 |

---

## 2. New scenarios from course tree feature

| Scenario | Title | Series | Source |
|---|---|---|---|
| **D-11** | Course tree renders in SWT (desktop) | D | Study V1_2, Workload V1_2 |
| **W-09** | Course tree renders in HTML (web) | W | Study V1_2, Workload V1_2 |

These are not yet in T1. They need:
- 2 new scenario XMLs (`D-11.xml`, `W-09.xml`)
- Updated `plugin.xml` entries
- Updated `Generate_CheatSheets.ps1` if auto-generation covers new IDs
- The JAR rebuilt

### D-11 Cheat Sheet content (proposed)

```
Title: D-11 — Course tree renders in SWT Tree (desktop)

Intro: Validates the course tree panel in the RCP desktop product. Requires
-Dggbplus.course=<path> to be set. Checks tree rendering, step execution,
validation feedback, and error handling.

Items:
1. Launch with course file
   - launch.ps1 -Course courses/trigonometry_intro.json
   - Shell opens with three-pane layout (tree | 2D | 3D)

2. Tree rendering
   - Course title visible in tree panel header
   - 5 chapters visible with expand/collapse
   - Steps visible under each chapter

3. Step execution
   - Select step 1.1, click Run: point O appears at origin
   - Select step 1.2, click Run: unit circle drawn
   - Status bar shows success/failure

4. Validation (Check button)
   - After step 1.1, Check: "O exists" passes
   - After step 3.3, Check: CAS identity returns "1"

5. Error handling
   - Error dialogs suppressed during step execution
   - Timeout after 10s shown in status bar
   - Button re-enabled after error

6. Threading
   - No UI freeze during step execution
   - SWT and Swing remain responsive
```

### W-09 Cheat Sheet content (proposed)

```
Title: W-09 — Course tree renders in HTML tree (web)

Intro: Validates the course tree in the web browser host page. Requires
self-hosted GWT WAR and course-tree.js/css.

Items:
1. Page load
   - Open host page in Chrome/Firefox
   - GeoGebra applet loads (html5codebase points to local WAR)
   - CAS readiness check completes (evalCommandCAS "1+1" → "2")

2. Tree rendering
   - Course title in #course-title
   - 5 chapters with expand/collapse
   - Steps under each chapter

3. Step execution
   - Select step 1.1, click Run Step: point O appears
   - Select step 1.2, click Run Step: circle drawn
   - Status bar updates

4. Validation
   - After step 1.1, Check: "O exists" → pass icon
   - CAS check: Pythagorean identity → "1"

5. Error handling
   - setErrorDialogsActive(false) around each step
   - Failed command shows message in status bar
   - Buttons re-enable after completion

6. Security (subset of T-01..T-14)
   - Execute command rejected by allowlist
   - Path traversal in OPEN rejected
```

---

## 3. Gate impact

No gate change. D-11 and W-09 are not gate prerequisites — they are feature scenarios tracked in SCENARIOS_TRACKING but not blocking any gate. If a future gate F (course tree acceptance) is created, it would reference D-11 + W-09.

---

## 4. Generator compatibility

The `Generate_CheatSheets.ps1` reads scenario data from `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_1.md`. It will auto-generate D-11 and W-09 XMLs **only after** those IDs are added to SCENARIOS_TRACKING (Claude task C-22, Sprint 4).

### Interim option (Sprint 1)

Write D-11.xml and W-09.xml manually as placeholders. The generator will overwrite them once the tracking table is updated.

---

## 5. Action items

| # | Action | Agent | When | Depends on |
|---|---|---|---|---|
| 1 | Add D-11 and W-09 to `SCENARIOS_TRACKING` | Claude (C-22) | Sprint 4 | Course tree tested |
| 2 | Write `D-11.xml` and `W-09.xml` placeholder XMLs | Claude | Now (Sprint 1) | This document |
| 3 | Add entries to `plugin.xml` | Claude | After #2 | #2 |
| 4 | Rebuild JAR (`Generate_CheatSheets.ps1` + `Install_CheatSheets.ps1`) | Claude or owner | After #2 | #2, #3 |
| 5 | Verify Eclipse Cheat Sheets view shows D-11 and W-09 | Owner | After D-01 approval | #4, D-01 |

---

## 6. T1 version note

The current T1 JAR is `0.1.0`. Adding D-11/W-09 should bump to `0.2.0` since the scenario count changes. Update `build.properties` and MANIFEST.MF version.

---

## 7. Files in T1 repo needing changes

| File | Change |
|---|---|
| `cheatsheets/scenarios/D-11.xml` | **New** — desktop course tree scenario |
| `cheatsheets/scenarios/W-09.xml` | **New** — web course tree scenario |
| `eclipse-plugin/plugin.xml` | Add 2 `<cheatsheet>` entries |
| `eclipse-plugin/cheatsheets/scenarios/D-11.xml` | Copy for plugin |
| `eclipse-plugin/cheatsheets/scenarios/W-09.xml` | Copy for plugin |
| `eclipse-plugin/build.properties` | Bump version to 0.2.0 |
