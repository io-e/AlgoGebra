<!-- GROK_V1 -->
# Sprint 4 status — Course Tree feature (all three agents)

| Field | Value |
|---|---|
| Document | `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Branch | `feat/external-engines` @ `867a62f` (+ local Sprint 4 edits) |
| Plan | `02-Cdc/Planning_Sprint_Course_Tree_CLAUDE_V1.md` |
| Tracking | `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` (47 scenarios) |

Resumed from Claude session `1531512a-e273-4830-83eb-9532355575d0` (interrupted mid C-22). This file closes Claude Sprint 4 tasks C-22/C-23 and records cross-agent status. No merges were requested.

---

## 1. Claude lane (specs, web assets, scenarios)

| Task | Deliverable | Status |
|---|---|---|
| C-01..C-15 | Schema, security, study V1_2, trig course, web CSS/JS/HTML, cheat sheets | **DONE** (Sprints 1–2 commits) |
| C-16 | `.vscode/tasks.json` + `extensions.json` | **DONE** (`867a62f`) |
| C-17 | `cheatsheets/Course_Authoring_CLAUDE_V1.xml` | **DONE** |
| C-18 | `03-RCP-Spike/tests/EVIDENCE_CHECKLIST_CLAUDE_V1.md` | **DONE** |
| C-19 | `scenarios/S_D-11_CourseTree_CLAUDE_V1.ps1` | **DONE** (authoring twin) |
| C-20 | `scenarios/S_W-09_CourseTreeWeb_CLAUDE_V1.ps1` | **DONE** (authoring twin) |
| C-21 | `course-host.html` after WAR verification | **PARTIAL** — host exists; WAR browser half still open |
| **C-22** | SCENARIOS_TRACKING 45 → 47 (D-11, W-09) | **DONE** (this session, GROK) |
| **C-23** | `courses/matrix_operations.json` | **DONE** (web-safe CAS course; schema PASS) |

### C-22 evidence

- Table rows and detail sections for D-11 / W-09 in `SCENARIOS_TRACKING_GROK_V1.md` and canonical `SCENARIOS_TRACKING_GROK_V1_2.md`.
- Counts: NOT RUN 24, PARTIAL 12, FAIL 7, PASS 4; clients desktop 17 / web 9 / both 20 / infra 1; total **47**.
- Runner-visible scripts: `03-RCP-Spike/tests/scenarios/S_D-11_CourseTree_GROK_V1.ps1`, `S_W-09_CourseTreeWeb_GROK_V1.ps1` (picked by `Run_All_GROK_V1.ps1 -Scenarios` / `-Only D-11,W-09`).

### C-23 evidence

- File: `courses/matrix_operations.json`.
- Schema validation against `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json`: **PASS**.
- Uses CAS directives only (create, Determinant, Transpose, product, Invert, Trace). Description states desktop CMD matrix literals remain unreliable under BUG-014.

### W-09 static run (this session)

Command: `pwsh -File 03-RCP-Spike/tests/scenarios/S_W-09_CourseTreeWeb_GROK_V1.ps1`

| Result | Detail |
|---|---|
| Before comment fix | 13 PASS / 2 FAIL / 4 SKIP — false positives from comments containing `evalCommand("1+1` and `geogebra.org` |
| After GROK_V1 comment tweaks in `web-host/course-tree.js` and `course-host.html` | **15 PASS / 0 FAIL / 4 SKIP** (exit 0). CSV: `03-RCP-Spike/tests/results/S_W-09_GROK_V1.csv` |

Browser checks W09-20..23 remain SKIP (need self-hosted WAR + HTTP server). Spec-level W-09 stays **NOT RUN** until the browser half runs.

---

## 2. Codex lane (Java, build, Windows)

| Task | Status | Notes |
|---|---|---|
| X-01..X-04 model/parser/tests | **Unknown / not in this tip** | No `CourseNode` / `CourseModel` under `03-RCP-Spike/host` confirmed in this handoff pass |
| X-05 / X-11 BUG-014 | **OPEN** | Blocks desktop WP2-06 and desktop matrix CMD path |
| X-06..X-10 panel, executor, validator, scanner | **Unknown** | Depends on model work |
| X-12 WP2-06 host integration | **BLOCKED** | Needs BUG-014 + panel; D-11 product half blocked |
| X-13 `launch.ps1 -Course` | **BLOCKED** | Depends on X-12 |
| X-14 build.ps1 course classes | **BLOCKED** | Depends on X-01..08 |
| X-15 / X-16 GWT WAR on Windows | **OPEN** | Blocks W-09 browser half and C-21 closure |
| X-17..X-22 Sprint 4 smoke / bugs | **NOT STARTED** here | Wait for D-11/W-09 product readiness |

Codex PRs mentioned in the Claude session (security corpus PR #3 and others) were reported as waiting for review with **no merge** per owner instruction.

---

## 3. Grok Bot lane (Debian, WIMS, security)

| Task | Status | Notes |
|---|---|---|
| Sprint 1 security corpus / suite 16 | Reported done on Debian in Claude session notes | Treat as stale until re-verified on current tip |
| G-03 GWT web build | OPEN / owner lane overlap | Needed for W-09 browser |
| G-04 BUG-017 `launch.sh` JDK discovery | OPEN | D-10 |
| G-05 malicious course corpus | Reported in Sprint 1 feedback | Re-verify after merges |
| G-14..G-16 WIMS | **BLOCKED** | S-01 / S-02 contracts missing |
| G-17 reconciliation | After D-11/W-09 runs on Debian | Not started |

---

## 4. Open blockers (unchanged critical path)

1. **BUG-014** — `evalCommand` divergences in RCP product (functions, matrix CMD literal, 3D Plane). Blocks Codex host integration and desktop matrix courses.
2. **S-01 / S-02** — no WIMS activity/submission contract. Blocks Grok Bot WIMS Sprint 4.
3. **Self-hosted GWT WAR** — blocks W-09 browser checks and full C-21.
4. **D-04 attended Windows suite 09** — still NOT RUN; separate from course-tree CMD path.
5. **No merge** — Sprint 1–3 Claude commits are on `feat/external-engines`; Codex/Grok PR merges still owner-gated.

---

## 5. Safest next actions

| Priority | Who | Action |
|---|---|---|
| P0 | Codex | BUG-014 investigation/fix evidence; then WP2-06 `CourseTreePanel` |
| P0 | Codex / Grok | Produce or document local GWT WAR path for `web-host/` |
| P1 | Grok / owner | `Run_All_GROK_V1.ps1 -Only W-09` after WAR; then D-11 when WP2-06 lands |
| P1 | Claude / owner | Keep contracts work for S-01/S-02 if WIMS Sprint 4 is required |
| P2 | Owner | Merge policy for open PRs; update `states.yaml` after reviewed runs |

---

## 6. Files touched in this Grok resume session

| Path | Change |
|---|---|
| `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1.md` | C-22 complete (GROK_V1_3 marker) |
| `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` | Canonical 47-scenario ledger |
| `03-RCP-Spike/tests/scenarios/S_D-11_CourseTree_GROK_V1.ps1` | New runner script |
| `03-RCP-Spike/tests/scenarios/S_W-09_CourseTreeWeb_GROK_V1.ps1` | New runner script |
| `courses/matrix_operations.json` | C-23 sample course |
| `web-host/course-tree.js` | Comment-only (W-09 false positive) |
| `web-host/course-host.html` | Comment-only (W-09 false positive) |
| `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` | This report |
| `states.yaml` | Scenario total / tracking pointer |

No commit was created in this session unless the owner asks for one.
