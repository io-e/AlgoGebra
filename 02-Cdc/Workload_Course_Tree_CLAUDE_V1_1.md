<!-- CLAUDE_V1_1 -->
# Workload — Course Tree Feature: Agent Allocation (Revised)

| Field | Value |
|---|---|
| Document | `02-Cdc/Workload_Course_Tree_CLAUDE_V1_1.md` |
| Version | CLAUDE_V1_1 |
| Status | Active — revised after Codex + Grok Bot review |
| Date | 2026-11-01 |
| Supersedes | `Workload_Course_Tree_CLAUDE_V1.md` (preserved as history) |
| Reviews | Codex review 2026-10-31, Grok Bot review 2026-10-31 |

---

## 0. Review corrections applied (V1 → V1_1)

| # | Reviewer | Issue | Correction |
|---|---|---|---|
| W-01 | Both | BUG-014 described as blocking ALL Java work | Refined: BUG-014 blocks live `evalCommand` integration (WP2-06+), not model/parser/UI work |
| W-02 | Both | D-04 listed as prerequisite for all WP-2 | Refined: D-04 blocks host integration (WP2-06), not scaffolding |
| W-03 | Grok | P-09 is not in the 45-scenario inventory | New ID **D-11** (desktop course tree). Update scenario count to 47 |
| W-04 | Grok | W-05 already exists (web course tree scenario ID collision) | New ID **W-09** (web course tree). Update scenario count |
| W-05 | Grok | OEF converter blocked on WIMS template unnecessarily | WP7-02 now depends on schema + OEF fixtures only, not S-01/S-02 |
| W-06 | Grok | No WP to build/serve the GWT WAR | **New WP-3a** — WAR build/serve verification (+4–8h) |
| W-07 | Grok | Linux work should split: immediate baseline vs. later course-tree | WP-8 split into WP-8a (Debian baseline, unblocked) and WP-8b (course-tree rendering, after WP2-06) |
| W-08 | Both | 66h excludes blocker resolution and rework | Total relabeled as **initial estimate** with explicit exclusions |
| W-09 | Grok | Scripts named `_GROK_V1` but authored by Claude | Renamed to `_CLAUDE_V1` |
| W-10 | Grok | WP-4/WP-5 duplicate existing `T1_Cheat_Sheets` work | WP-4 updated: port or reconcile with `D:\ALF_ZGit\T1_Cheat_Sheets` first |
| W-11 | Grok | BUG-017 and evidence rule not scheduled | Added to WP-6 as WP6-08 |
| W-12 | Grok | D-01 (Eclipse import) not scheduled | Added note: D-01 requires owner approval before scheduling |
| W-13 | Both | Security model missing | Added WP-9 — security contract and tests |

---

## 1. Agent lanes (reminder)

| Agent | Scope | Platform |
|---|---|---|
| **Claude** | Specifications, schemas, web assets (HTML/CSS/JS), Cheat Sheet XMLs, VS Code config, handoff docs, scenario scripts, course content | Windows (authoring) |
| **Codex** | Java code (host, model, OSGi), PowerShell test scripts, build scripts, unit tests | Windows x86_64 |
| **Grok Bot** | Linux integration tests, Debian packaging, WIMS runtime, cross-platform validation, security tests | Debian Linux |

---

## 2. Work packages

### WP-1 — Course schema and sample content

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| JSON Schema for `course.json` (versioned, with `target` field, action allowlist) | WP1-01 | **Claude** | Study V1_1 §2.5 + §6 | `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` | 1.5h | — |
| Sample course: "Introduction to Trigonometry" (2D only, avoids BUG-014 commands) | WP1-02 | **Claude** | Schema | `courses/trigonometry_intro.json` | 2h | WP1-01 |
| Sample course: "Matrix Operations" (CAS-heavy — **deferred** until BUG-014 is fixed) | WP1-03 | **Claude** | Schema | `courses/matrix_operations.json` | 2h | WP1-01, BUG-014 |
| Validate sample courses against schema | WP1-04 | **Claude** | JSON Schema + samples | Validation report in commit message | 30min | WP1-01..02 |

**Total WP-1: Claude 6h** (WP1-03 deferred until BUG-014)

---

### WP-2 — RCP Desktop (Windows) — Java host code

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `CourseNode.java` — data model | WP2-01 | **Codex** | Schema WP1-01 | `host/src/.../host/course/CourseNode.java` | 1h | WP1-01 |
| `CourseAction.java` — directive data class (with `target` field) | WP2-02 | **Codex** | Schema | `host/src/.../host/course/CourseAction.java` | 30min | WP1-01 |
| `CourseModel.java` — JSON parser | WP2-03 | **Codex** | Schema + model | `host/src/.../host/course/CourseModel.java` | 2h | WP2-01, WP2-02 |
| Unit tests for CourseModel parser (mock-based, no GeoGebra) | WP2-04 | **Codex** | Sample courses | `host/test/.../course/CourseModelTest.java` | 2h | WP2-03, WP1-02 |
| `CourseTreePanel.java` — SWT Tree composite (conditional, see Study §2.2) | WP2-05 | **Codex** | Study V1_1 §2.2–2.3 | `host/src/.../host/course/CourseTreePanel.java` | 4h | WP2-03 |
| `DirectiveExecutor.java` — with threading policy (Study §2.4), 2D/3D routing (Study §2.5), deny list (Study §6.3) | WP2-07 | **Codex** | Study V1_1 §2.4–2.5 + §6 | `host/src/.../host/course/DirectiveExecutor.java` | 4h | WP2-05 |
| `StepValidator.java` — checks return values, not just "executed" | WP2-08 | **Codex** | Schema validation spec | `host/src/.../host/course/StepValidator.java` | 2h | WP2-07 |
| **Gate: BUG-014 fix + D-04 PASS** | — | — | — | — | — | — |
| Integrate panel into `GeoGebraPlusApplication.java` (conditional pane) | WP2-06 | **Codex** | Study V1_1 §2.2 | Modified `GeoGebraPlusApplication.java` | 2h | WP2-05, **BUG-014**, **D-04** |
| `launch.ps1 -Course` flag | WP2-09 | **Codex** | Study V1_1 §2.7 | Modified `launch.ps1` | 30min | WP2-06 |
| Build: compile course classes into host bundle | WP2-10 | **Codex** | build.ps1 patterns | Modified `build.ps1` | 1h | WP2-01..08 |
| Smoke test: load trigonometry course, run 3 steps (avoids BUG-014 commands) | WP2-11 | **Codex** | Sample course | Windows run log + screenshot | 1h | WP2-06, WP1-02 |

**Total WP-2: Codex 20h**

**Gate clarification (W-01, W-02):** WP2-01 through WP2-08 can proceed without BUG-014 or D-04. Only WP2-06 (live host integration) and downstream tasks (WP2-09, WP2-11) are blocked. Sample courses in WP1-02 should avoid functions, matrices, and 3D planes that trigger BUG-014.

---

### WP-3 — Web Browser (Windows authoring, both platforms testing)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| `course-tree.js` — tree controller (corrected: readiness gate, return-value checks) | WP3-01 | **Claude** | Study V1_1 §3.4–3.5 | `web-host/course-tree.js` | 3h | WP1-01 |
| `course-tree.css` — layout and theming | WP3-02 | **Claude** | Study V1_1 §3 | `web-host/course-tree.css` | 1h | — |
| `course-host.html` — corrected embedding (`deployggb.js`, `loadCourse` call) | WP3-03 | **Claude** | Study V1_1 §3.3 | `web-host/course-host.html` | 2h | WP3-01, WP3-02 |
| Accessibility: keyboard navigation, ARIA roles | WP3-04 | **Claude** | WAI-ARIA tree pattern | Updated WP3-01 | 1h | WP3-01 |
| Mobile responsive: tree as collapsible sidebar | WP3-05 | **Claude** | CSS media queries | Updated WP3-02 | 1h | WP3-02 |
| Manual test on Windows: Chrome + GWT applet + sample course | WP3-06 | **Owner** | All WP3-01..05 + GWT WAR | Test report | 30min | **W-01**, WP3a-02 |
| Manual test on Debian: Firefox + GWT applet | WP3-07 | **Grok Bot** | Same files | Debian test report | 30min | WP3-03, WP3a-02 |

**Total WP-3: Claude 8h, Owner 30min, Grok Bot 30min**

---

### WP-3a — GWT WAR build and serve verification (NEW — W-06)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Build GWT WAR at pinned commit (Windows) | WP3a-01 | **Codex** | GeoGebra source, build commands | WAR in `source/web/web/war/` | 3h | — |
| Serve WAR locally, verify `deployggb.js` loads | WP3a-02 | **Codex** | WP3a-01 | Localhost test log | 1h | WP3a-01 |
| Attempt GWT WAR build on Debian | WP3a-03 | **Grok Bot** | GeoGebra source, JDK setup | Build log + WAR (or documented failure) | 3h | — |
| Verify self-hosted embedding: correct codebase config, `ggbOnInit` fires | WP3a-04 | **Claude** | WP3a-02 results | Updated `course-host.html` if needed | 1h | WP3a-02 |

**Total WP-3a: Codex 4h, Grok Bot 3h, Claude 1h**

---

### WP-4 — Eclipse Cheat Sheets (developer/teacher authoring)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Reconcile with existing `D:\ALF_ZGit\T1_Cheat_Sheets` (W-10) | WP4-00 | **Claude** | Existing Cheat Sheets | Gap analysis + reuse plan | 1h | — |
| `Generate_CheatSheets.ps1` — generator script (or port from T1) | WP4-01 | **Claude** | Migration guide §5.1 + WP4-00 | `03-RCP-Spike/Generate_CheatSheets_CLAUDE_V1.ps1` | 2h | WP4-00 |
| Generate 33 scenario Cheat Sheet XMLs | WP4-02 | **Claude** | Run WP4-01 | `03-RCP-Spike/cheatsheets/scenarios/*.xml` | 1h | WP4-01 |
| Generate 5 gate composite Cheat Sheet XMLs | WP4-03 | **Claude** | Gate definitions | `03-RCP-Spike/cheatsheets/gates/*.xml` | 1h | WP4-02 |
| Course authoring Cheat Sheet (teacher guide) | WP4-04 | **Claude** | Schema + Study | `03-RCP-Spike/cheatsheets/Course_Authoring.xml` | 1h | WP1-01 |
| Test: open in Eclipse 2026-09, run one scenario | WP4-05 | **Owner** | Eclipse IDE + XMLs (D-01 must be approved) | Validation in Eclipse | 15min | WP4-02, **D-01** |

**Total WP-4: Claude 6h, Owner 15min**

**Note (W-12):** WP4-05 requires D-01 (Eclipse project import). D-01 is waiting for owner approval.

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
| `S_D-11_CourseTree_CLAUDE_V1.ps1` — desktop scenario (W-03 fix) | WP6-01 | **Claude** | Scenario patterns | `scenarios/S_D-11_CourseTree_CLAUDE_V1.ps1` | 2h | WP2-06 |
| `S_W-09_CourseTreeWeb_CLAUDE_V1.ps1` — web scenario (W-04 fix) | WP6-02 | **Claude** | Web patterns | `scenarios/S_W-09_CourseTreeWeb_CLAUDE_V1.ps1` | 2h | WP3-03 |
| Run D-11 on Windows | WP6-03 | **Codex** | WP6-01 + product | Windows TAP result | 30min | WP6-01, WP2-11 |
| Run D-11 on Debian | WP6-04 | **Grok Bot** | WP6-01 + product | Debian TAP result | 30min | WP6-01, WP2-11, WP8b-01 |
| Run W-09 on Windows (Chrome) | WP6-05 | **Codex** | WP6-02 + WAR | Windows TAP result | 30min | WP6-02, WP3a-02 |
| Run W-09 on Debian (Firefox) | WP6-06 | **Grok Bot** | WP6-02 + WAR | Debian TAP result | 30min | WP6-02, WP3a-03 |
| Update SCENARIOS_TRACKING (new count: 47) | WP6-07 | **Claude** | All WP6 results | Updated tracking doc | 30min | WP6-03..06 |
| Schedule evidence rule + BUG-017 handling for each test (W-11) | WP6-08 | **Claude** | Evidence rule from CLAUDE.md | Checklist in each script header | 30min | — |

**Total WP-6: Claude 5h, Codex 1h, Grok Bot 1h**

**Scenario inventory update (W-03, W-04):** D-11 and W-09 are new scenarios. The 45-scenario count becomes **47**. The runner (`Run_All`) and tracking document must be updated.

---

### WP-7 — WIMS/XWims integration (Phase C)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| WIMS activity template with course tree embed (same-origin) | WP7-01 | **Grok Bot** | web-host files + WIMS knowledge | `wims/course-activity-template/` | 4h | WP3-03, **S-01** |
| OEF↔course.json converter (W-05 fix: unblocked from S-01) | WP7-02 | **Grok Bot** | Schema WP1-01 + representative OEF fixtures | `tools/oef2course.pl` | 4h | WP1-01 |
| Grade callback: course tree → WIMS grading (server-side only) | WP7-03 | **Grok Bot** | WIMS API, S-02 contract, Study §6.5 | Updated course-tree.js | 3h | WP3-01, **S-02** |
| Integration test: full exercise cycle on Debian | WP7-04 | **Grok Bot** | All WP7 | Debian test log | 2h | WP7-01..03 |
| Cross-platform validation on Windows | WP7-05 | **Codex** | WP7-04 report | Windows test log | 1h | WP7-04 |

**Total WP-7: Grok Bot 13h, Codex 1h**

**Dependency corrections (W-05):** WP7-02 (OEF converter) depends only on the schema and OEF fixtures, not on S-01/S-02. WP7-01 and WP7-03 remain blocked on S-01/S-02 respectively.

---

### WP-8a — Debian baseline (immediate — W-07 split)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Debian/Xvfb environment prep (Java, SWT GTK, display) | WP8a-01 | **Grok Bot** | Current RCP product | Environment report | 1h | — |
| Verify current product starts on Debian (P-01 equivalent) | WP8a-02 | **Grok Bot** | WP8a-01 | TAP result + screenshot | 30min | WP8a-01 |
| GWT WAR build attempt on Debian | WP8a-03 | **Grok Bot** | GeoGebra source | Build log | 3h | — |

**Total WP-8a: Grok Bot 4.5h — UNBLOCKED, can start now**

---

### WP-8b — Linux course-tree rendering (after host integration — W-07 split)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Verify SWT Tree renders on GTK (Debian) | WP8b-01 | **Grok Bot** | RCP product with course tree | Screenshot + report | 1h | WP2-06 |
| Verify course-tree.js on Firefox/Debian | WP8b-02 | **Grok Bot** | web-host files | Test report | 30min | WP3-03, WP3a-03 |
| Xvfb headless course tree test | WP8b-03 | **Grok Bot** | WP6-01 + Xvfb | TAP result | 1h | WP6-01, WP8b-01 |
| Linux font/locale issues in course tree | WP8b-04 | **Grok Bot** | WP8b-01 report | Fix or documented gap | 1h | WP8b-01 |
| Reconciliation report: Windows ↔ Debian | WP8b-05 | **Grok Bot** | All WP-8 + WP-6 results | `Handoff_Course_Tree_Reconciliation_GROK_V1.md` | 1h | WP8b-01..04 |

**Total WP-8b: Grok Bot 4.5h**

---

### WP-9 — Security contract and tests (NEW — R-08)

| Task | ID | Agent | Input | Deliverable | Effort | Depends on |
|---|---|---|---|---|---|---|
| Course file security spec (allowlist, deny list, .ggb policy) | WP9-01 | **Claude** | Study V1_1 §6 | `02-Cdc/Spec_Course_Security_CLAUDE_V1.md` | 2h | WP1-01 |
| Deny list implementation in DirectiveExecutor | WP9-02 | **Codex** | WP9-01 | Updated DirectiveExecutor.java | 1h | WP2-07, WP9-01 |
| Security test: malicious course file corpus | WP9-03 | **Grok Bot** | WP9-01 | Test fixtures + TAP results | 2h | WP9-01 |
| `.ggb` script scanner (Java, for OPEN actions) | WP9-04 | **Codex** | WP9-01 §6.4 | `host/src/.../host/course/GgbScriptScanner.java` | 2h | WP9-01 |

**Total WP-9: Claude 2h, Codex 3h, Grok Bot 2h**

---

## 3. Summary per agent

### Claude (Windows — specifications, web assets, scenario scripts)

| WP | Description | Effort |
|---|---|---|
| WP-1 | Schema + sample courses | 6h |
| WP-3 | Web tree (HTML/CSS/JS) | 8h |
| WP-3a | WAR embed verification | 1h |
| WP-4 | Eclipse Cheat Sheets (incl. T1 reconciliation) | 6h |
| WP-5 | VS Code Tasks | 1.75h |
| WP-6 | Scenario scripts + tracking | 5h |
| WP-9 | Security spec | 2h |
| | **Total Claude** | **~30h** |

### Codex (Windows — Java code, build, Windows tests)

| WP | Description | Effort |
|---|---|---|
| WP-2 | RCP host Java code (model, panel, executor, validator, build) | 20h |
| WP-3a | WAR build + serve | 4h |
| WP-6 | Run scenario tests on Windows | 1h |
| WP-7 | Windows cross-validation of WIMS integration | 1h |
| WP-9 | Deny list + .ggb scanner | 3h |
| | **Total Codex** | **~29h** |

### Grok Bot (Debian — Linux tests, WIMS, cross-platform)

| WP | Description | Effort |
|---|---|---|
| WP-3 | Test web on Debian Firefox | 0.5h |
| WP-3a | WAR build attempt on Debian | 3h |
| WP-6 | Run scenario tests on Debian | 1h |
| WP-7 | WIMS activity template, OEF converter, grade callback, Debian integration test | 13h |
| WP-8a | Debian baseline (immediate) | 4.5h |
| WP-8b | Course-tree rendering validation | 4.5h |
| WP-9 | Security test corpus | 2h |
| | **Total Grok Bot** | **~28.5h** |

### Owner (manual validation)

| WP | Description | Effort |
|---|---|---|
| WP-3 | Manual web test on Windows Chrome | 0.5h |
| WP-4 | Test Cheat Sheet in Eclipse (requires D-01 approval) | 0.25h |
| WP-5 | Test VS Code task | 0.15h |
| | **Total Owner** | **~1h** |

---

## 4. Grand total

| Agent | Effort | Platform |
|---|---|---|
| Claude | **~30h** | Windows (specs + web + scripts) |
| Codex | **~29h** | Windows (Java + build + tests) |
| Grok Bot | **~28.5h** | Debian (Linux + WIMS + reconciliation) |
| Owner | **~1h** | Windows (manual acceptance) |
| **Total** | **~88.5h** | |

**This is an initial estimate (W-08).** It excludes:
- BUG-014 resolution effort
- D-04 input/focus investigation
- W-01 (web technology scored study)
- S-01/S-02 contract authoring
- Rework from cross-platform acceptance failures
- BUG-017 resolution on Linux

---

## 5. Critical path and dependencies

```
                          Unblocked NOW
                  ┌─────────────────────────────┐
                  │  WP1-01 Schema (Claude)      │
                  │  WP3-02 CSS (Claude)         │
                  │  WP4-00 T1 reconciliation    │
                  │  WP5-01 VS Code tasks        │
                  │  WP8a-01 Debian baseline      │
                  │  WP6-08 Evidence checklist    │
                  │  WP9-01 Security spec         │
                  └──────────┬──────────────────┘
                             │
                             ▼
WP1-01 Schema ──────┬──► WP2-01..04 Java model/parser/tests ◄── unblocked
  │                  │          │
  │                  │    WP2-05 SWT panel ◄── unblocked
  │                  │          │
  │                  │    WP2-07 Executor ◄── unblocked
  │                  │    WP2-08 Validator ◄── unblocked
  │                  │          │
  │                  │   ═══ BUG-014 + D-04 GATE ═══
  │                  │          │
  │                  │    WP2-06 Host integration ◄── BLOCKED
  │                  │    WP2-09 launch.ps1
  │                  │    WP2-11 Smoke test
  │                  │          │
  │                  └──► WP3-01 JS tree ──► WP3-03 Host page
  │                                                 │
  │                  WP3a-01 WAR build ──► WP3a-02 Serve + verify
  │                                                 │
  │                                    WP3-06 Chrome test (Owner)
  │                                    WP3-07 Firefox test (Grok)
  │
  ├──► WP7-02 OEF converter (Grok) ◄── depends on schema only
  │
  ├──► WP9-01 Security spec ──► WP9-02 Deny list (Codex)
  │                         ──► WP9-03 Security tests (Grok)
  │                         ──► WP9-04 .ggb scanner (Codex)
  │
  │              S-01 contract ──► WP7-01 WIMS template
  │              S-02 contract ──► WP7-03 Grade callback
  │                                      ──► WP7-04 Integration test
  │
  └──► WP6-01 D-11 script ──► WP6-03 Win (after WP2-11)
                           ──► WP6-04 Deb (after WP8b-01)
       WP6-02 W-09 script ──► WP6-05 Win (after WP3a-02)
                           ──► WP6-06 Deb (after WP3a-03)
```

---

## 6. What can start now

### Immediately unblocked

| Agent | Task | WP |
|---|---|---|
| **Claude** | JSON Schema (with `target`, allowlist, security fields) | WP1-01 |
| **Claude** | Sample course (2D only, avoids BUG-014 commands) | WP1-02 |
| **Claude** | CSS for course tree | WP3-02 |
| **Claude** | T1 Cheat Sheets reconciliation | WP4-00 |
| **Claude** | VS Code tasks.json | WP5-01 |
| **Claude** | Evidence rule checklist | WP6-08 |
| **Claude** | Security spec | WP9-01 |
| **Grok Bot** | Debian/Xvfb baseline | WP8a-01..02 |
| **Grok Bot** | GWT WAR build attempt on Debian | WP8a-03 |

### Unblocked after schema delivery (WP1-01)

| Agent | Task | WP |
|---|---|---|
| **Claude** | course-tree.js | WP3-01 |
| **Codex** | Java model + parser + unit tests | WP2-01..04 |
| **Codex** | SWT panel + executor + validator | WP2-05, WP2-07, WP2-08 |
| **Codex** | WAR build on Windows | WP3a-01 |
| **Grok Bot** | OEF converter | WP7-02 |
| **Grok Bot** | Security test corpus | WP9-03 |

### Blocked behind gates

| Gate | Blocks | Status |
|---|---|---|
| BUG-014 fix + D-04 | WP2-06 host integration, WP2-09, WP2-11, WP1-03 | OPEN |
| W-01 | WP3-06 Chrome acceptance | NOT STARTED |
| S-01 | WP7-01 WIMS template | NOT STARTED |
| S-02 | WP7-03 Grade callback | NOT STARTED |
| D-01 approval | WP4-05 Eclipse Cheat Sheet test | WAITING |

---

## 7. Delivery order

| Sprint | Weeks | Agents | Deliverables |
|---|---|---|---|
| **S1** | 1 | Claude, Grok Bot | Schema, sample course, VS Code tasks, security spec, Debian baseline, T1 reconciliation |
| **S2** | 1 | Claude, Grok Bot | course-tree.js/css/html, Cheat Sheets, OEF converter, security tests |
| **S3** | 1–2 | Codex | Java model, parser, SWT panel, executor, validator, WAR build |
| **S4** | 1 | Codex | Host integration (after BUG-014/D-04), launch.ps1 -Course, smoke test |
| **S5** | 1 | Grok Bot | Linux GTK rendering, Xvfb test, web Firefox test, reconciliation |
| **S6** | 1 | All | Scenario tests D-11 + W-09 (Windows + Debian), tracking update (47 scenarios) |
| **S7** | 2 | Grok Bot | WIMS template, grade callback (after S-01/S-02) |
| **S8** | 1 | Grok Bot + Codex | WIMS integration test (Debian + Windows), final reconciliation |

S1 and S2 are unblocked. S3 is partially unblocked (model/parser/panel); S4 waits on BUG-014/D-04. S7–S8 wait on S-01/S-02.
