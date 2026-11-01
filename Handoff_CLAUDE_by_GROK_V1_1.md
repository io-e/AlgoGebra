<!-- GROK_V1_1 -->
# Handoff to Claude — by Grok (`Handoff_CLAUDE_by_GROK_V1_1.md`)

| Field | Value |
|---|---|
| Document | **`Handoff_CLAUDE_by_GROK_V1_1.md`** |
| Supersedes | `Handoff_CLAUDE_by_GROK_V1.md` (archive) |
| Audience | **Claude** (new session); Codex / Grok Bot todo sections below |
| Author | Grok (xAI / Grok Build) |
| Date | 2026-11-01 |
| Repo | `D:\ALF_Agents\G1_Geogebra_Migration` |
| Branch | `feat/external-engines` |
| Architecture | **D-COURSE-01 ACCEPTED** — `02-Cdc/Decision_Course_Tree_Architecture_GROK_V1.md` |

Open this file first. Companion: `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md`. Tracking: `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` (47 scenarios).

---

## 1. Architecture validation (tree) — summary

**Verdict: accepted** as host-owned course tree (desktop SWT + web HTML), shared `course.json`, no `common` edits, GWT retained, formative checks only.

| Accepted | Open gap (code) |
|---|---|
| Conditional `-Dggbplus.course` pane | CT-DESK-01 — `CourseTreePanel` / executor missing |
| Shared schema + trig/matrix samples | CT-SEC-01 — web still **denylist**; need `allowed-commands.json` allowlist |
| Web outside GWT applet | CT-WAR-01 — self-hosted WAR |
| D-04 not a gate for WP2-06 | CT-BUG-014 — RCP `evalCommand` divergences |
| W-09 static PASS 15/0/4 | Browser half NOT RUN |

Full write-up: `02-Cdc/Decision_Course_Tree_Architecture_GROK_V1.md`.

---

## 2. Corrections already applied (this Grok pass)

| Fix | Where |
|---|---|
| C-22 / C-23 complete | Tracking V1_2, matrix course, runner scripts |
| W-09 false-positive comments | `web-host/course-*.js/html` |
| Scenario count 45 → 47 | `AGENTS.md`, `states.yaml` |
| Cheat sheet intros | `cheatsheets/scenarios/D-11.xml`, `W-09.xml` |
| Interim security marked CT-SEC-01 | `course-tree.js` header |
| Architecture decision filed | `Decision_Course_Tree_Architecture_GROK_V1.md` |

---

## 3. Proposed test actions — Playwright (web / W-09)

Goal: automated browser evidence for W-09 after a local GWT WAR is served next to `web-host/`.

### 3.1 Setup (once WAR exists)

```text
web-host/
  course-host.html
  course-tree.js
  course-tree.css
  GeoGebra/          ← copy or junction from GWT war (deployggb.js + HTML5/5.0/web3d/)
  courses/ → ../courses/trigonometry_intro.json (or HTTP path)
```

Serve with any static server (example):

```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration\web-host
npx --yes serve -p 4173
```

### 3.2 Suggested Playwright suite layout

```
03-RCP-Spike/tests/playwright/
  playwright.config.ts
  W09_CourseTree.spec.ts
  fixtures/courses.ts
```

### 3.3 Cases to implement

| Id | Action | Expect |
|---|---|---|
| PW-W09-01 | `page.goto('/course-host.html')` | Applet host `#applet1` visible; no console error matching `geogebra.org` load failure |
| PW-W09-02 | Wait for status Ready (CAS `1+1` → `2`) | Status bar Ready; no algebra object named `2` created by readiness |
| PW-W09-03 | Tree `#tree-root [role=treeitem]` count | ≥ 5 chapters for trigonometry course |
| PW-W09-04 | Select step 1.1 → `#btn-run` | Point `O` exists (`evalCommand` path); button re-enabled |
| PW-W09-05 | Step 1.2 Run | Circle created |
| PW-W09-06 | Check on CAS identity step | Pass feedback / green path |
| PW-W09-07 | `page.evaluate(() => courseTree.isCommandBlocked('Execute("Delete(A)")'))` | `true` |
| PW-W09-08 | `isOpenPathSafe('../../etc/passwd')` | `false` |
| PW-W09-09 | Keyboard: ArrowDown / Enter | Focus + run without freeze |
| PW-W09-10 | Viewport 375×667 | `#mobile-tree-toggle` visible; sidebar toggles |

Evidence: screenshot + Playwright trace + TAP or JSON summary under `03-RCP-Spike/evidence/<date>-windows-playwright-w09-<runid>/`. Update W-09 row only when browser cases pass.

**Owner for implementation:** Claude (spec + scaffold) or Grok Bot (Debian Firefox) / Codex (Windows Chrome) after WAR.

---

## 4. Proposed test actions — Eclipse Cheat Sheets (desktop / D-11)

Workbench: `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` (IDE only). Cheat sheets are **developer guidance**, not the student product.

### 4.1 Register content

1. Link or copy `cheatsheets/scenarios/D-11.xml` and `W-09.xml` into the T1 / workspace cheat-sheet plug-in (see `Reconciliation_T1_Cheat_Sheets_CLAUDE_V1.md`).
2. Ensure `plugin.xml` lists D-11 and W-09 (`org.eclipse.ui.cheatsheets.cheatSheetContent`).
3. Rebuild the cheat-sheet JAR if that is how T1 ships.

### 4.2 Manual / assisted run of D-11 sheet (attended)

| Step in sheet | Operator action | Pass criteria |
|---|---|---|
| Prerequisites | Image with WP2-06; `courses/trigonometry_intro.json` | Files present |
| Launch | `launch.ps1 -Course courses/trigonometry_intro.json` (or `-Dggbplus.course=…`) | Three-pane layout |
| Tree rendering | Expand chapters | Title + 5 chapters |
| Step execution | Run 1.1 then 1.2 | `O` and circle in 2D |
| Check | CAS identity step | Pass |
| Errors | No modal "Please check your input" during scripted steps | Dialogs suppressed |
| Evidence | Date, commit, OS, Java, image, log, screenshot | Tracking row updated |

Also run mechanical twin:

```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike\tests
pwsh -File .\Run_All_GROK_V1.ps1 -Only D-11 -ExportEvidence windows-d11
```

Cheat sheets guide humans; `S_D-11_*_GROK_V1.ps1` records TAP evidence.

### 4.3 Composite suggestion

Add a composite cheat sheet **Course Tree smoke**: D-11 → W-09 (open Playwright checklist) → update `SCENARIOS_TRACKING_GROK_V1_2.md`.

---

## 5. Todo list — Codex (Windows / Java / WAR)

Priority order:

| # | Todo | Depends | Done when |
|---|---|---|---|
| X-T1 | **BUG-014** investigate + fix or written product limitation | Bug handoff | Product `evalCommand` matches baseline on P-02 fixtures |
| X-T2 | `CourseNode` / `CourseAction` / `CourseModel` + unit tests | Schema | Tests green without GeoGebra |
| X-T3 | `CourseTreePanel` + `DirectiveExecutor` + `StepValidator` (allowlist post-parse) | X-T2, security spec | Host compiles into product bundle |
| X-T4 | Wire panel in `GeoGebraPlusApplication` when `-Dggbplus.course` set | X-T3, prefer X-T1 | D-11 product launch shows tree |
| X-T5 | `launch.ps1 -Course` | X-T4 | Flag documented + smoke |
| X-T6 | Generate **`allowed-commands.json`** from `Commands` enum (WP9-02) | Security spec | File committed; desktop + web consumers |
| X-T7 | Switch web `course-tree.js` denylist → allowlist (CT-SEC-01) with Claude | X-T6 | W09 security cases still pass; nesting tests added |
| X-T8 | GWT WAR build + copy/junction under `web-host/GeoGebra/` | — | `deployggb.js` loads locally |
| X-T9 | Run `Run_All -Only D-11` on Windows image; export evidence | X-T4 | Tracking + evidence folder |
| X-T10 | Do **not** merge PRs until owner says so | Owner | — |

Out of scope for Codex unless asked: WIMS contracts S-01/S-02; editing `common`.

---

## 6. Todo list — Grok Bot (Debian / WIMS / browser)

| # | Todo | Depends | Done when |
|---|---|---|---|
| G-T1 | `launch.sh` `-Course` / `-Dggbplus.course` (Study §2.8) | Spec | Linux launch smoke |
| G-T2 | GWT WAR on Debian (or consume Codex WAR artifact) | — | Local `web-host/GeoGebra` works |
| G-T3 | Run `S_W-09_*` static on Debian; then Playwright/Firefox browser half | G-T2 | Evidence under `evidence/…-linux-…` |
| G-T4 | When WP2-06 image exists: `Run_All -Only D-11` under Xvfb | Codex X-T4 | Debian D-11 verdict |
| G-T5 | Re-verify security corpus / suite 16 on current tip | Merges | Fresh TAP |
| G-T6 | BUG-017: bundled Java / `launch.sh` discovery | Owner | D-10 precheck improves |
| G-T7 | WIMS Sprint 4 (G-14..) | **Blocked** on S-01/S-02 | Stay parked |
| G-T8 | No merge / no force-push without owner | Owner | — |

---

## 7. Todo list — Claude (this lane)

| # | Todo | Notes |
|---|---|---|
| C-T1 | Resume from this V1_1 handoff | Do not redo C-22/C-23 |
| C-T2 | After WAR: close **C-21** host path tweaks | Then Playwright cases |
| C-T3 | **Scaffold** `03-RCP-Spike/tests/playwright/W09_CourseTree.spec.ts` | Owner Q8 / Q5 — authorized now |
| C-T4 | Eclipse **RCP Testing Tool** track for desktop course tree | Owner Q8 — parallel with Playwright |
| C-T5 | Settle SEC-G1..G3 security errata | `Errata_Security_Spec_for_Claude_GROK_V1.md` |
| C-T6 | CT-SEC-01 web allowlist once `allowed-commands.json` exists | After Codex WP9-02; demos may use interim denylist |
| C-T7 | T1 plug-in D-11/W-09 | **Deferred** (owner Q6) until D-01 |

---

## 8. Questions for the owner

**Answer sheet (recorded):** `02-Cdc/Questions_Course_Tree_Owner_GROK_V1_1.md`  
**RCP testing RQ-1..3 (recorded):** `02-Cdc/Questions_RCP_Testing_Owner_GROK_V1.md`  
**Grok Bot Sprint 1 PRs:** `02-Cdc/Feedback_GrokBot_Sprint1_PRs_GROK_V1.md` (review only — owner no-merge)  
**Security settle for Claude:** `02-Cdc/Errata_Security_Spec_for_Claude_GROK_V1.md`  
**Claude delivery `6baf1d4`:** Playwright W-09 scaffold + RCPTT/SWTBot plan — **already on origin**; browser run blocked on Codex WAR (X-T8).

1. **Commit / push:** Sprint 4 + D-COURSE-01 are on `feat/external-engines`. Push to `origin` now, or local-only until Codex lands WP2?
2. **CT-SEC-01 priority:** Block web student pilots until `allowed-commands.json` allowlist, or accept interim denylist with WIMS as grade authority?
3. **BUG-014:** Fix before any `CourseTreePanel` merge, or ship tree with CAS/trig-only courses and skip matrix CMD on desktop?
4. **WAR ownership:** Who builds the first self-hosted GWT WAR for `web-host/` — Codex (Windows), Grok Bot (Debian), or owner script?
5. **Playwright location:** Add under `03-RCP-Spike/tests/playwright/` in this repo, or a separate test repo?
6. **Eclipse Cheat Sheets:** Update T1 plug-in at `D:\ALF_ZGit\T1_Cheat_Sheets` in the same sprint, or keep XMLs only in AlgoGebra until D-01 Eclipse import is approved?
7. **Merge policy:** Still **no merge** of open PRs (#3 security corpus, etc.)?
8. **Next Claude focus:** Playwright scaffold, S-01/S-02 contracts, or idle until Codex WP2-06?

---

## 9. Verify commands (Claude / any agent)

```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration
git status -sb
git log -3 --oneline

pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_W-09_CourseTreeWeb_GROK_V1.ps1
# expect PASS: 15 FAIL: 0 SKIP: 4

python -I -c "import json; from jsonschema import validate; validate(json.load(open('courses/matrix_operations.json',encoding='utf-8')), json.load(open('02-Cdc/Schema_Course_JSON_CLAUDE_V1.json',encoding='utf-8'))); print('PASS')"
```

Pin unchanged: upstream `375db7faf54` / `5.4.934.0` at `D:\ALF_ZGit\G1_Geogebra_Migration`.

---

## 10. File map (GROK_V… names)

| File | Role |
|---|---|
| **`Handoff_CLAUDE_by_GROK_V1_1.md`** | **This handoff (current)** |
| `Handoff_CLAUDE_by_GROK_V1.md` | Archive |
| `02-Cdc/Decision_Course_Tree_Architecture_GROK_V1.md` | D-COURSE-01 |
| `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` | Sprint 4 closure |
| `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` | 47-scenario ledger |
| `03-RCP-Spike/tests/scenarios/S_D-11_CourseTree_GROK_V1.ps1` | D-11 runner |
| `03-RCP-Spike/tests/scenarios/S_W-09_CourseTreeWeb_GROK_V1.ps1` | W-09 runner |
| `courses/matrix_operations.json` | C-23 sample |

---

*End of `Handoff_CLAUDE_by_GROK_V1_1.md`.*
