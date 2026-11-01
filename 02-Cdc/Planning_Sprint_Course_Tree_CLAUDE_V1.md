<!-- CLAUDE_V1_1 -->
# Sprint Planning — Course Tree Feature (All Three Agents)

| Field | Value |
|---|---|
| Document | `02-Cdc/Planning_Sprint_Course_Tree_CLAUDE_V1.md` |
| Version | CLAUDE_V1_1 |
| Date | 2026-11-01 |
| Status | Active |
| Source of truth | `Workload_Course_Tree_CLAUDE_V1_1.md` + errata `V1_2.md` |
| Specs ready | Study V1_2, Security Spec V1, JSON Schema V1, Bug Handoff V1 |

---

## 0. Overall timeline

```
Week 1 (Nov 1–7)     Week 2 (Nov 8–14)    Week 3 (Nov 15–21)   Week 4 (Nov 22–28)
─────────────────     ─────────────────    ─────────────────    ─────────────────
SPRINT 1              SPRINT 2             SPRINT 3             SPRINT 4
Specs + scaffolding   Implementation       Integration          Acceptance
All 3 agents          All 3 agents         All 3 agents         Grok + Owner
```

---

## 1. CLAUDE — Specifications, web assets, scenario scripts (~30h)

### Sprint 1 — Week 1: Specs and web foundation

| # | Task | WP | Effort | Input | Deliverable | Status |
|---|---|---|---|---|---|---|
| C-01 | JSON Schema | WP1-01 | 1.5h | Study V1_2 | `Schema_Course_JSON_CLAUDE_V1.json` | **DONE** |
| C-02 | Security spec | WP9-01 | 2h | Study V1_2 §6, Commands.java | `Spec_Course_Security_CLAUDE_V1.md` | **DONE** |
| C-03 | Study V1_2 (blocking fixes) | — | 2h | Grok review | `Study_Course_Tree_RCP_and_Web_CLAUDE_V1_2.md` | **DONE** |
| C-04 | Bug handoff (BUG-014/015/016/017) | — | 2h | states.yaml, source analysis | `Handoff_Bug_Fixes_BUG-014_015_016_017_CLAUDE_V1.md` | **DONE** |
| C-05 | Sample course: Trigonometry (2D, avoids BUG-014) | WP1-02 | 2h | Schema | `courses/trigonometry_intro.json` | **NEXT** |
| C-06 | Validate sample against schema | WP1-04 | 0.5h | Schema + sample | Commit message | After C-05 |
| C-07 | `course-tree.css` | WP3-02 | 1h | Study V1_2 §3 | `web-host/course-tree.css` | **NEXT** |
| C-08 | T1 Cheat Sheets reconciliation | WP4-00 | 1h | `D:\ALF_ZGit\T1_Cheat_Sheets` | Gap analysis doc | **NEXT** |

**Sprint 1 total: ~12h (7.5h done, 4.5h remaining)**

### Sprint 2 — Week 2: Web controller and IDE tooling

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| C-09 | `course-tree.js` (controller with security checks) | WP3-01 | 3h | Study V1_2 §3.4, Security spec | `web-host/course-tree.js` | C-01 |
| C-10 | Accessibility (ARIA, keyboard nav) | WP3-04 | 1h | WAI-ARIA tree pattern | Updated `course-tree.js` | C-09 |
| C-11 | Mobile responsive sidebar | WP3-05 | 1h | CSS media queries | Updated `course-tree.css` | C-07 |
| C-12 | `course-host.html` (corrected embedding) | WP3-03 | 2h | Study V1_2 §3.3 | `web-host/course-host.html` | C-09, C-07 |
| C-13 | Cheat Sheet generator | WP4-01 | 2h | Migration guide, WP4-00 | `Generate_CheatSheets_CLAUDE_V1.ps1` | C-08 |
| C-14 | Generate 33 scenario XMLs | WP4-02 | 1h | Run C-13 | `cheatsheets/scenarios/*.xml` | C-13 |
| C-15 | Generate 5 gate XMLs | WP4-03 | 1h | Gate definitions | `cheatsheets/gates/*.xml` | C-14 |

**Sprint 2 total: ~11h**

### Sprint 3 — Week 3: Scenario scripts and remaining

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| C-16 | VS Code `tasks.json` + extensions + problem matcher | WP5-01..03 | 1.75h | Plan | `.vscode/tasks.json`, `.vscode/extensions.json` | — |
| C-17 | Course authoring Cheat Sheet | WP4-04 | 1h | Schema + Study | `cheatsheets/Course_Authoring.xml` | C-01 |
| C-18 | Evidence rule checklist in script headers | WP6-08 | 0.5h | `AGENTS.md` evidence rule | Checklist template | — |
| C-19 | `S_D-11_CourseTree_CLAUDE_V1.ps1` (desktop scenario) | WP6-01 | 2h | Scenario patterns | `scenarios/S_D-11_CourseTree_CLAUDE_V1.ps1` | Codex WP2-06 |
| C-20 | `S_W-09_CourseTreeWeb_CLAUDE_V1.ps1` (web scenario) | WP6-02 | 2h | Web patterns | `scenarios/S_W-09_CourseTreeWeb_CLAUDE_V1.ps1` | C-12 |
| C-21 | `course-host.html` adjust after WAR verification | WP3a-04 | 1h | Codex WP3a-02 results | Updated host page | Codex WP3a-02 |

**Sprint 3 total: ~8.25h**

### Sprint 4 — Week 4: Tracking and closure

| # | Task | WP | Effort | Depends on |
|---|---|---|---|---|
| C-22 | Update SCENARIOS_TRACKING (45 → 47, add D-11/W-09) | WP6-07 | 0.5h | All WP6 results |
| C-23 | Sample course: Matrix Operations (CAS) | WP1-03 | 2h | BUG-014 fix |

---

## 2. CODEX — Java code, build, Windows tests (~29h)

### Sprint 1 — Week 1: Model and parser (unblocked)

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| X-01 | `CourseNode.java` — data model | WP2-01 | 1h | `Schema_Course_JSON_CLAUDE_V1.json` | `host/src/.../course/CourseNode.java` | Schema (done) |
| X-02 | `CourseAction.java` — directive + target | WP2-02 | 0.5h | Schema | `host/src/.../course/CourseAction.java` | Schema (done) |
| X-03 | `CourseModel.java` — JSON parser | WP2-03 | 2h | Schema + model | `host/src/.../course/CourseModel.java` | X-01, X-02 |
| X-04 | Unit tests for parser (mock, no GeoGebra) | WP2-04 | 2h | Sample course | `host/test/.../course/CourseModelTest.java` | X-03, C-05 |
| X-05 | **BUG-014 investigation** (critical path) | — | 4h | Bug handoff V1 | Investigation report + fix if found | Bug handoff (done) |

**Sprint 1 total: ~9.5h**

**Priority:** X-05 (BUG-014) is the most important task. It unblocks WP2-06 and all downstream integration. Start the investigation in parallel with the model/parser work. See `Handoff_Bug_Fixes_BUG-014_015_016_017_CLAUDE_V1.md` for the full call-chain trace and investigation path.

### Sprint 2 — Week 2: SWT panel and executor

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| X-06 | `CourseTreePanel.java` — SWT Tree | WP2-05 | 4h | Study V1_2 §2.2–2.3 | `host/src/.../course/CourseTreePanel.java` | X-03 |
| X-07 | `DirectiveExecutor.java` — threading + allowlist | WP2-07 | 4h | Study V1_2 §2.4, Security spec §1.3 | `host/src/.../course/DirectiveExecutor.java` | X-06, Security spec (done) |
| X-08 | `StepValidator.java` — check return values | WP2-08 | 2h | Schema check actions | `host/src/.../course/StepValidator.java` | X-07 |
| X-09 | `GgbScriptScanner.java` — .ggb archive scan | WP9-04 | 2h | Security spec §3 | `host/src/.../course/GgbScriptScanner.java` | Security spec (done) |
| X-10 | `allowed-commands.json` generator | WP9-02 | 1h | Commands.java enum | Build script + JSON | Security spec (done) |

**Sprint 2 total: ~13h**

### Sprint 3 — Week 3: Integration and WAR (blocked on BUG-014)

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| X-11 | **BUG-014 fix** (if not done in Sprint 1) | — | variable | Investigation results | Code fix + evidence | X-05 |
| X-12 | Integrate panel into `GeoGebraPlusApplication.java` | WP2-06 | 2h | Study V1_2 §2.2 | Modified host app | X-06, **BUG-014 fix** |
| X-13 | `launch.ps1 -Course` flag | WP2-09 | 0.5h | Study V1_2 §2.7 | Modified `launch.ps1` | X-12 |
| X-14 | Build: compile course classes into host bundle | WP2-10 | 1h | build.ps1 patterns | Modified `build.ps1` | X-01..08 |
| X-15 | GWT WAR build (Windows) | WP3a-01 | 3h | GeoGebra source | WAR + log | — |
| X-16 | Serve WAR locally, verify `deployggb.js` | WP3a-02 | 1h | X-15 | Localhost test log | X-15 |

**Sprint 3 total: ~7.5h + BUG-014 variable**

### Sprint 4 — Week 4: Testing

| # | Task | WP | Effort | Depends on |
|---|---|---|---|---|
| X-17 | Smoke test: trigonometry course, 3 steps | WP2-11 | 1h | X-12, C-05 |
| X-18 | Run D-11 on Windows | WP6-03 | 0.5h | C-19, X-17 |
| X-19 | Run W-09 on Windows (Chrome) | WP6-05 | 0.5h | C-20, X-16 |
| X-20 | **BUG-015 fix** (PARI empty error) | — | 1.5h | Bug handoff V1 |
| X-21 | **BUG-016 fix** (reproducible builds) | — | 1.5h | Bug handoff V1 |
| X-22 | WIMS cross-validation (Windows) | WP7-05 | 1h | Grok WP7-04 |

**Sprint 4 total: ~6h**

---

## 3. GROK BOT — Debian tests, WIMS, cross-platform (~25.5h)

### Sprint 1 — Week 1: Debian baseline and GWT (unblocked)

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| G-01 | Debian/Xvfb environment prep | WP8a-01 | — | Current RCP product | Environment report | **DONE** |
| G-02 | Verify product starts on Debian (P-01 equiv) | WP8a-02 | — | G-01 | TAP 8/0/1 + screenshot | **DONE** (export evidence) |
| G-03 | GWT WAR build at pinned commit (Debian) | WP3a-03 | 3h | GeoGebra source | Build log + WAR | — |
| G-04 | **BUG-017 fix** (`launch.sh` JDK discovery) | — | 1h | Bug handoff V1 | Fixed `launch.sh` | — |
| G-05 | Malicious course file corpus (14 test cases) | WP9-03 | 2h | Security spec §6 | Test fixtures + `_GROK_V1.ps1` tests in `03-RCP-Spike/tests/` | Security spec (done) |

**Sprint 1 total: ~6h (G-01/G-02 done, export evidence only)**

**Parallel work:** G-03, G-04, and G-05 are independent — run simultaneously. G-05 can start immediately (security spec is done). G-04 is a quick fix. G-01/G-02 are already done — just need evidence export.

### Sprint 2 — Week 2: OEF converter and web test

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| G-06 | OEF→course.json converter (Python + `.ps1` test wrapper) | WP7-02 | 4h | Schema (done) + OEF fixtures | `tools/oef2course.py` + `S_WP7-02_OefConverter_GROK_V1.ps1` | Schema (done) |
| G-07 | Test `course-tree.js` on Firefox/Debian | WP3-07 | 0.5h | Claude web files | Debian test report | C-12, G-03 |
| G-08 | `launch.sh -Course` flag (Study V1_2 §2.8) | — | 0.5h | Study V1_2 | Updated `launch.sh` | G-04 |

**Sprint 2 total: ~5h**

### Sprint 3 — Week 3: Course-tree rendering (after Codex WP2-06)

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| G-09 | SWT Tree renders on GTK (Debian) | WP8b-01 | 1h | RCP product with course tree | Screenshot + report | Codex X-12 |
| G-10 | Xvfb headless course tree test | WP8b-03 | 1h | D-11 script + Xvfb | TAP result | C-19, G-09 |
| G-11 | Linux font/locale issues in course tree | WP8b-04 | 1h | G-09 report | Fix or documented gap | G-09 |
| G-12 | Run D-11 on Debian | WP6-04 | 0.5h | D-11 script + product | Debian TAP result | C-19, G-09 |
| G-13 | Run W-09 on Debian (Firefox) | WP6-06 | 0.5h | W-09 script + WAR | Debian TAP result | C-20, G-03 |

**Sprint 3 total: ~4h**

### Sprint 4 — Week 4: WIMS integration and reconciliation (blocked on S-01/S-02)

| # | Task | WP | Effort | Input | Deliverable | Depends on |
|---|---|---|---|---|---|---|
| G-14 | WIMS activity template | WP7-01 | 4h | Web files + WIMS knowledge | `wims/course-activity-template/` | C-12, **S-01** |
| G-15 | Grade callback (server-side only) | WP7-03 | 3h | WIMS API, Security spec §4 | Updated course-tree.js | C-09, **S-02** |
| G-16 | Integration test: full exercise cycle | WP7-04 | 2h | All WP7 | Debian test log | G-14, G-15 |
| G-17 | Reconciliation report: Windows ↔ Debian | WP8b-05 | 1h | All results | `Handoff_Course_Tree_Reconciliation_GROK_V1.md` | G-09..13 |

**Sprint 4 total: ~10h (G-14/G-15/G-16 blocked on S-01/S-02)**

---

## 4. Dependency gates — single view

```
                 DONE (Nov 1)
    ┌─────────────────────────────────────────────┐
    │  Schema (C-01)    Security spec (C-02)      │
    │  Study V1_2 (C-03) Bug handoff (C-04)       │
    └──────────────┬──────────────────────────────┘
                   │
         ┌─────────┼──────────────────────┐
         ▼         ▼                      ▼
    Sprint 1      Sprint 1               Sprint 1
    CLAUDE        CODEX                   GROK BOT
    C-05 sample   X-01..04 model/parser   G-01..02 DONE ✓
    C-07 CSS      X-05 BUG-014 invest.    G-03 WAR build
    C-08 T1 rec.                          G-04 BUG-017
                                          G-05 security corpus (.ps1)
         │              │                      │
         ▼              ▼                      ▼
    Sprint 2      Sprint 2               Sprint 2
    C-09..12      X-06..10 panel/exec     G-06 OEF converter
    web assets    scanner/allowlist        G-07 Firefox test
    C-13..15                              G-08 launch.sh
    Cheat Sheets
         │              │                      │
         ▼              │                      │
    Sprint 3           ═══ BUG-014 GATE ═══    │
    C-16..18       X-12 host integration  Sprint 3
    VS Code        X-13..16 build/WAR     G-09..13 rendering
    C-19..20                              D-11/W-09 Debian
    scenarios
         │              │                      │
         ▼              ▼                      ▼
    Sprint 4      Sprint 4               Sprint 4
    C-22 tracking X-17..19 smoke/tests    G-14..16 WIMS
    C-23 matrix   X-20..21 BUG-015/016    G-17 reconciliation
                  X-22 WIMS Windows
                                ═══ S-01/S-02 GATE ═══
```

---

## 5. Blockers and risk register

| Blocker | Blocks | Owner | Mitigation |
|---|---|---|---|
| **BUG-014** | Codex X-12 (host integration), X-17 (smoke), all downstream | **Codex** | Investigation starts Sprint 1 (X-05). Sample courses avoid affected commands. |
| **S-01/S-02** | Grok G-14..16 (WIMS integration, ~9h) | **Claude** (spec authoring) | Not in this planning scope. Grok starts all non-WIMS work first. |
| **W-01** | Owner WP3-06 (Chrome acceptance) | **Claude** (web tech study) | Not in this planning scope. Web dev proceeds against mock/self-hosted WAR. |
| **D-01 approval** | WP4-05 (Eclipse Cheat Sheet test) | **Owner** | Cheat Sheet generation (WP4-01..04) proceeds without Eclipse. Test deferred. |
| **BUG-017** | D-10 on Linux | **Grok Bot** | Quick fix in Sprint 1 (G-04, ~1h). |

---

## 6. Daily handoff protocol

Each agent pushes commits to `feat/external-engines` as work completes. No branch conflicts expected because:

| Agent | Files touched | No overlap |
|---|---|---|
| Claude | `02-Cdc/*.md`, `02-Cdc/*.json`, `web-host/*`, `.vscode/*`, `cheatsheets/*`, `scenarios/S_D-11_*`, `scenarios/S_W-09_*` | ✓ |
| Codex | `host/src/**/*.java`, `host/test/**/*.java`, `build.ps1`, `launch.ps1` | ✓ |
| Grok Bot | `03-RCP-Spike/tests/scenarios/S_*_GROK_V1.ps1`, `tools/*`, `wims/*`, `launch.sh`, `Handoff_*_GROK_*` | ✓ |

Shared files requiring coordination:
- `states.yaml` — each agent updates their own bug/scenario entries. Pull before editing.
- `03-RCP-Spike/tests/Run_All_GROK_V1.ps1` — Grok's security tests plug into this runner. Claude updates scenario count in Sprint 4 (C-22).
- `SCENARIOS_TRACKING` — Claude updates after all agents report results (Sprint 4, C-22).

**Pre-condition:** PR #2 (Windows guard checks) should be merged into `feat/external-engines` before Codex starts Sprint 1, so Windows test runs use the guards.

---

## 7. Sprint 1 kickoff checklist

### Claude — ready now
- [ ] Write sample course `courses/trigonometry_intro.json` (C-05)
- [ ] Write `web-host/course-tree.css` (C-07)
- [ ] T1 Cheat Sheets reconciliation (C-08)

### Codex — ready now
- [ ] Start `CourseNode.java` and `CourseAction.java` from schema (X-01, X-02)
- [ ] **Start BUG-014 investigation** (X-05) — critical path
- [ ] Start `CourseModel.java` parser (X-03)

### Grok Bot — ready now
- [x] Debian/Xvfb baseline (G-01, G-02) — **DONE**, export evidence
- [ ] GWT WAR build on Debian (G-03)
- [ ] BUG-017 fix: `launch.sh` JDK discovery (G-04)
- [ ] Malicious course file corpus from security spec (G-05) — `.ps1` tests in `03-RCP-Spike/tests/`

### Owner — Sprint 1 decision needed
- [ ] Approve or defer D-01 (Eclipse project import)
