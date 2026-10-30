<!-- CLAUDE_V1 -->
# Workload — Course Tree Feature: Agent Allocation

| Field | Value |
|---|---|
| Document | `02-Cdc/Workload_Course_Tree_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Active |
| Date | 2026-10-30 |
| Depends on | `Study_Course_Tree_RCP_and_Web_CLAUDE_V1.md`, `Guide_Migration_PS1_to_CheatSheets_CLAUDE_V1.md` |

---

## 1. Agent lanes (reminder)

| Agent | Scope | Platform |
|---|---|---|
| **Claude** | Specifications, schemas, web assets (HTML/CSS/JS), Cheat Sheet XMLs, VS Code config, handoff docs, scenario scripts, course content | Windows (authoring) |
| **Codex** | Java code (host, model, OSGi), PowerShell test scripts, build scripts, unit tests | Windows x86_64 |
| **Grok Bot** | Linux integration tests, Debian packaging, WIMS runtime, cross-platform validation | Debian Linux |

---

## 2. Work packages

### WP-1 — Course schema and sample content

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| JSON Schema for `course.json` | WP1-01 | **Claude** | Study documents | `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` | 1h | — |
| Sample course: "Introduction to Trigonometry" | WP1-02 | **Claude** | Schema | `courses/trigonometry_intro.json` | 2h | WP1-01 |
| Sample course: "Matrix Operations" (CAS-heavy) | WP1-03 | **Claude** | Schema | `courses/matrix_operations.json` | 2h | WP1-01 |
| Validate sample courses against schema | WP1-04 | **Claude** | JSON Schema + samples | Validation report in commit message | 30min | WP1-01..03 |

**Total WP-1: Claude 5.5h**

---

### WP-2 — RCP Desktop (Windows) — Java host code

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `CourseNode.java` — data model | WP2-01 | **Codex** | Schema WP1-01 | `host/src/.../host/course/CourseNode.java` | 1h | WP1-01 |
| `CourseAction.java` — directive data class | WP2-02 | **Codex** | Schema | `host/src/.../host/course/CourseAction.java` | 30min | WP1-01 |
| `CourseModel.java` — JSON parser | WP2-03 | **Codex** | Schema + model | `host/src/.../host/course/CourseModel.java` | 2h | WP2-01, WP2-02 |
| Unit tests for CourseModel parser | WP2-04 | **Codex** | Sample courses | `host/test/.../course/CourseModelTest.java` | 2h | WP2-03, WP1-02 |
| `CourseTreePanel.java` — SWT Tree composite | WP2-05 | **Codex** | Study §2.3 | `host/src/.../host/course/CourseTreePanel.java` | 4h | WP2-03 |
| Integrate panel into `GeoGebraPlusApplication.java` SashForm | WP2-06 | **Codex** | Study §2.2 | Modified `GeoGebraPlusApplication.java` | 2h | WP2-05, D-04 |
| Directive executor (CMD, CAS, VAL, OPEN) | WP2-07 | **Codex** | ScenarioScript.java patterns | `host/src/.../host/course/DirectiveExecutor.java` | 3h | WP2-05 |
| Validation checker (step result → pass/fail) | WP2-08 | **Codex** | Schema validation spec | `host/src/.../host/course/StepValidator.java` | 2h | WP2-07 |
| `launch.ps1 -Course` flag | WP2-09 | **Codex** | Study §2.6 | Modified `launch.ps1` | 30min | WP2-06 |
| Build: compile course classes into host bundle | WP2-10 | **Codex** | build.ps1 patterns | Modified `build.ps1` | 1h | WP2-01..08 |
| Smoke test: load trigonometry course, run 3 steps | WP2-11 | **Codex** | Sample course | Windows run log + screenshot | 1h | WP2-06, WP1-02 |

**Total WP-2: Codex 19h**

**Blocking dependency:** WP2-06 requires **D-04 PASS** (GeoGebraPanel embedding with working `evalCommand`). BUG-014 must be resolved first.

---

### WP-3 — Web Browser (Windows authoring, both platforms testing)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `course-tree.js` — tree controller | WP3-01 | **Claude** | Study §3.4 | `web-host/course-tree.js` | 3h | WP1-01 |
| `course-tree.css` — layout and theming | WP3-02 | **Claude** | Study §3.5 | `web-host/course-tree.css` | 1h | — |
| `course-host.html` — host page with GWT applet embed | WP3-03 | **Claude** | Study §3.3 | `web-host/course-host.html` | 2h | WP3-01, WP3-02 |
| Accessibility: keyboard navigation, ARIA roles | WP3-04 | **Claude** | WAI-ARIA tree pattern | Updated WP3-01 | 1h | WP3-01 |
| Mobile responsive: tree as collapsible sidebar | WP3-05 | **Claude** | CSS media queries | Updated WP3-02 | 1h | WP3-02 |
| Manual test on Windows: Chrome + GWT applet + sample course | WP3-06 | **Owner** | All WP3-01..05 + GWT WAR | Test report | 30min | W-01 |
| Manual test on Debian: Firefox + GWT applet | WP3-07 | **Grok Bot** | Same files | Debian test report | 30min | WP3-03 |

**Total WP-3: Claude 8h, Owner 30min, Grok Bot 30min**

**Blocking dependency:** WP3-06 requires **W-01** (web technology scored study) — the GWT WAR must serve correctly.

---

### WP-4 — Eclipse Cheat Sheets (developer/teacher authoring)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `Generate_CheatSheets.ps1` — generator script | WP4-01 | **Claude** | Migration guide §5.1 | `03-RCP-Spike/Generate_CheatSheets_CLAUDE_V1.ps1` | 2h | — |
| Generate 33 scenario Cheat Sheet XMLs | WP4-02 | **Claude** | Run WP4-01 | `03-RCP-Spike/cheatsheets/scenarios/*.xml` | 1h | WP4-01 |
| Generate 5 gate composite Cheat Sheet XMLs | WP4-03 | **Claude** | Gate definitions | `03-RCP-Spike/cheatsheets/gates/*.xml` | 1h | WP4-02 |
| Course authoring Cheat Sheet (teacher guide) | WP4-04 | **Claude** | Schema + Study | `03-RCP-Spike/cheatsheets/Course_Authoring.xml` | 1h | WP1-01 |
| Test: open in Eclipse 2026-09, run one scenario | WP4-05 | **Owner** | Eclipse IDE + XMLs | Validation in Eclipse | 15min | WP4-02 |

**Total WP-4: Claude 5h, Owner 15min**

---

### WP-5 — VS Code Tasks

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `.vscode/tasks.json` — scenario + gate + course tasks | WP5-01 | **Claude** | Plan §4.2 | `.vscode/tasks.json` | 1h | — |
| `.vscode/extensions.json` — recommended extensions | WP5-02 | **Claude** | Plan §4.3 | `.vscode/extensions.json` | 15min | — |
| Problem matcher for TAP output (PASS/FAIL/SKIP) | WP5-03 | **Claude** | TAP format from TestFramework | Updated tasks.json | 30min | WP5-01 |
| Test: run single scenario via VS Code task picker | WP5-04 | **Owner** | VS Code + tasks.json | Validation | 10min | WP5-01 |

**Total WP-5: Claude 1.75h, Owner 10min**

---

### WP-6 — Scenario test scripts for the course tree

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `S_P-09_CourseTree_GROK_V1.ps1` — scenario script (desktop) | WP6-01 | **Claude** | Scenario patterns | `scenarios/S_P-09_CourseTree_GROK_V1.ps1` | 2h | WP2-06 |
| `S_W-05_CourseTreeWeb_GROK_V1.ps1` — scenario script (web) | WP6-02 | **Claude** | Web patterns | `scenarios/S_W-05_CourseTreeWeb_GROK_V1.ps1` | 2h | WP3-03 |
| Run P-09 on Windows | WP6-03 | **Codex** | WP6-01 + product | Windows TAP result | 30min | WP6-01, WP2-11 |
| Run P-09 on Debian | WP6-04 | **Grok Bot** | WP6-01 + product | Debian TAP result | 30min | WP6-01, WP2-11 |
| Run W-05 on Windows (Chrome) | WP6-05 | **Codex** | WP6-02 + WAR | Windows TAP result | 30min | WP6-02 |
| Run W-05 on Debian (Firefox) | WP6-06 | **Grok Bot** | WP6-02 + WAR | Debian TAP result | 30min | WP6-02 |
| Update SCENARIOS_TRACKING | WP6-07 | **Claude** | All WP6 results | Updated tracking doc | 30min | WP6-03..06 |

**Total WP-6: Claude 4.5h, Codex 1h, Grok Bot 1h**

---

### WP-7 — WIMS/XWims integration (Phase C)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| WIMS activity template with course tree embed | WP7-01 | **Grok Bot** | web-host files + WIMS knowledge | `wims/course-activity-template/` | 4h | WP3-03, S-01 |
| OEF↔course.json converter (Perl/Python) | WP7-02 | **Grok Bot** | OEF format + schema | `tools/oef2course.pl` | 4h | WP1-01, WP7-01 |
| Grade callback: course tree → WIMS grading | WP7-03 | **Grok Bot** | WIMS API, S-02 contract | Updated course-tree.js | 3h | WP3-01, S-02 |
| Integration test: full exercise cycle on Debian | WP7-04 | **Grok Bot** | All WP7 | Debian test log | 2h | WP7-01..03 |
| Cross-platform validation on Windows | WP7-05 | **Codex** | WP7-04 report | Windows test log | 1h | WP7-04 |

**Total WP-7: Grok Bot 13h, Codex 1h**

**Blocking dependency:** WP7-01..03 require **S-01 and S-02** (submission contracts). These are currently NOT RUN.

---

### WP-8 — Linux packaging and cross-platform validation

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Verify SWT Tree renders on GTK (Debian) | WP8-01 | **Grok Bot** | RCP product on Debian | Screenshot + report | 1h | WP2-06 |
| Verify course-tree.js on Firefox/Debian | WP8-02 | **Grok Bot** | web-host files | Test report | 30min | WP3-03 |
| Xvfb headless course tree test | WP8-03 | **Grok Bot** | WP6-01 + Xvfb | TAP result | 1h | WP6-01, WP8-01 |
| Linux font/locale issues in course tree | WP8-04 | **Grok Bot** | WP8-01 report | Fix or documented gap | 1h | WP8-01 |
| Reconciliation report: Windows ↔ Debian | WP8-05 | **Grok Bot** | All WP8 + WP6 results | `Handoff_Course_Tree_Reconciliation_GROK_V1.md` | 1h | WP8-01..04 |

**Total WP-8: Grok Bot 4.5h**

---

## 3. Summary per agent

### Claude (Windows — specifications, web assets, scenario scripts)

| WP | Description | Effort |
|---|---|---|
| WP-1 | Schema + sample courses | 5.5h |
| WP-3 | Web tree (HTML/CSS/JS) | 8h |
| WP-4 | Eclipse Cheat Sheets | 5h |
| WP-5 | VS Code Tasks | 1.75h |
| WP-6 | Scenario scripts + tracking | 4.5h |
| | **Total Claude** | **24.75h** |

### Codex (Windows — Java code, build, Windows tests)

| WP | Description | Effort |
|---|---|---|
| WP-2 | RCP host Java code (model, panel, executor, validator, build) | 19h |
| WP-6 | Run scenario tests on Windows | 1h |
| WP-7 | Windows cross-validation of WIMS integration | 1h |
| | **Total Codex** | **21h** |

### Grok Bot (Debian — Linux tests, WIMS, cross-platform)

| WP | Description | Effort |
|---|---|---|
| WP-3 | Test web on Debian Firefox | 0.5h |
| WP-6 | Run scenario tests on Debian | 1h |
| WP-7 | WIMS activity template, OEF converter, grade callback, Debian integration test | 13h |
| WP-8 | Linux packaging, GTK validation, Xvfb, reconciliation | 4.5h |
| | **Total Grok Bot** | **19h** |

### Owner (manual validation)

| WP | Description | Effort |
|---|---|---|
| WP-3 | Manual web test on Windows Chrome | 0.5h |
| WP-4 | Test Cheat Sheet in Eclipse | 0.25h |
| WP-5 | Test VS Code task | 0.15h |
| | **Total Owner** | **~1h** |

---

## 4. Grand total

| Agent | Effort | Platform |
|---|---|---|
| Claude | **25h** | Windows (specs + web + scripts) |
| Codex | **21h** | Windows (Java + build + tests) |
| Grok Bot | **19h** | Debian (Linux + WIMS + reconciliation) |
| Owner | **1h** | Windows (manual acceptance) |
| **Total** | **66h** | |

---

## 5. Critical path and dependencies

```
WP1-01 Schema ──────┬──► WP2-01..03 Java model ──► WP2-05 SWT panel ──► WP2-06 Host integration
  │                  │                                                          │
  │                  │         BUG-014 fix ─────────────────────────────────────►│
  │                  │                                                          │
  │                  └──► WP3-01 JS tree ──► WP3-03 Host page ──► WP3-07 Debian
  │                                                                    │
  ├──► WP1-02 Sample course ──────────────────► WP2-11 Smoke test      │
  │                                                    │               │
  │                                              WP6-03 Win test  WP6-04 Deb test
  │                                                    │               │
  │                                              WP6-07 Tracking update│
  │                                                                    │
  └──► WP4-01 Generator ──► WP4-02 XMLs ──► WP4-05 Eclipse test       │
                                                                       │
                          S-01 contract ──► WP7-01 WIMS template ──► WP7-04
                          S-02 contract ──► WP7-03 Grade callback      │
                                                                  WP8-05 Reconciliation
```

**Critical blockers:**
1. **BUG-014** — `evalCommand` failures block WP2-06 (host integration) and all downstream
2. **D-04 PASS** — required for WP2-06 (SWT/Swing embedding must be stable)
3. **S-01 / S-02 contracts** — required for WP-7 (WIMS integration). Currently NOT RUN.
4. **W-01** — required for WP3-06 (web testing needs the GWT WAR served)

**Unblocked start items (can begin now):**
- WP1-01 Schema (Claude)
- WP4-01 Cheat Sheet generator (Claude)
- WP5-01 VS Code tasks (Claude)
- WP3-01 course-tree.js (Claude)

---

## 6. Delivery order

| Sprint | Weeks | Agents | Deliverables |
|---|---|---|---|
| **S1** | 1 | Claude | Schema, sample courses, VS Code tasks, Cheat Sheet generator + XMLs |
| **S2** | 1 | Claude | course-tree.js/css/html, scenario scripts P-09 and W-05 |
| **S3** | 1–2 | Codex | Java model, parser, SWT panel, directive executor, validator |
| **S4** | 1 | Codex | Host integration, launch.ps1 -Course, Windows smoke test |
| **S5** | 1 | Grok Bot | Linux GTK validation, Xvfb test, web Firefox test |
| **S6** | 1 | All | Scenario tests (Windows + Debian), tracking update |
| **S7** | 2 | Grok Bot | WIMS template, OEF converter, grade callback |
| **S8** | 1 | Grok Bot + Codex | WIMS integration test (Debian + Windows), reconciliation |

S1 and S2 are unblocked and can start immediately. S3–S4 are blocked on BUG-014/D-04. S7–S8 are blocked on S-01/S-02 contracts.
