<!-- GROK_V1 -->
# Decision — Course Tree architecture accepted (GROK_V1)

| Field | Value |
|---|---|
| Document | `02-Cdc/Decision_Course_Tree_Architecture_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Status | **ACCEPTED** (architecture). Implementation still incomplete. |
| Specs | `Study_Course_Tree_RCP_and_Web_CLAUDE_V1_2.md`, `Spec_Course_Security_CLAUDE_V1.md`, `Schema_Course_JSON_CLAUDE_V1.json` |
| Binding parents | `Decisions_Architecture_ALF_GROK_V1_3.md`, Architecture V2 |

---

## 1. Verdict

The course-tree design is **accepted as architecture** for GeoGebraPlus. It fits the closed decisions:

| Rule | Course-tree compliance |
|---|---|
| `common` untouchable | Host-owned SWT panel + host page JS only. No new GeoGebra view ID. |
| RCP desktop + web twin | Same `course.json` schema; desktop SWT Tree; web HTML tree outside GWT. |
| GWT stays until Gate C | Web tree does not require GWT retirement. |
| Teachers select prebuilt capabilities | Courses are JSON content; teachers do not ship OSGi code. |
| Host owns policy | Allowlist / error-dialog / OPEN path rules live in host code. |
| WIMS owns grade | Course checks are formative; authoritative grade remains WIMS. |

**D-GIAC-01 / Gate B** remain prerequisites for CAS steps on desktop. Course tree does **not** reopen D-04 as a gate for WP2-06 (Study G-08).

Decision id: **D-COURSE-01**.

---

## 2. Accepted shape

```
course.json (schema 1.0)
        |
   GeoGebraPlus host policy
   (allowlist, dialogs, OPEN paths, timeout)
      /                    \
 RCP host bundle              web-host/
 CourseTreePanel (SWT)        course-tree.js + course-host.html
 -Dggbplus.course=<file>      local html5codebase → GWT WAR
      \                    /
        GgbAPI evalCommand / evalCommandCAS / getValue*
```

Opt-in layout: without `-Dggbplus.course`, the two-pane RCP shell stays unchanged (suites 09/10/P-07 unchanged).

---

## 3. Corrections applied with this decision (docs / packaging)

| Id | Issue | Fix |
|---|---|---|
| CT-DOC-01 | Tracking still said 45 scenarios after D-11/W-09 | Canonical ledger `SCENARIOS_TRACKING_GROK_V1_2.md` (47). `states.yaml` + `AGENTS.md` updated. |
| CT-DOC-02 | Cheat sheets D-11/W-09 said scripts missing | Intros updated; scripts exist (CLAUDE authoring twins + GROK runner scripts). |
| CT-DOC-03 | Handoff for Claude resume was V1 only | Superseded by `Handoff_CLAUDE_by_GROK_V1_1.md`. |
| CT-WEB-01 | `course-tree.js` comment / host comment broke W-09 static regexes | Comment-only GROK_V1 tweaks; static W-09 **15/0/4 PASS**. |

---

## 4. Open architecture gaps (must close in code — not accepted as final)

| Id | Gap | Owner | Required outcome |
|---|---|---|---|
| **CT-SEC-01** | Web host still uses a **string denylist** (`BLOCKED_COMMANDS`). Spec §1.4 requires a generated **string allowlist** (`allowed-commands.json` from `Commands` enum). | Codex WP9-02 + Claude/web update | Ship JSON; switch `course-tree.js` to allowlist; keep fail-closed. |
| **CT-DESK-01** | Desktop `DirectiveExecutor` + `CourseTreePanel` not in host yet. | Codex WP2-01..WP2-06 | Classes in host bundle; no `common` edits. |
| **CT-LAUNCH-01** | `launch.ps1 -Course` / `launch.sh` course arg not verified on tip. | Codex (ps1) / Grok Bot (sh) | Match Study §2.7–2.8. |
| **CT-BUG-014** | CMD matrix / function / Plane divergences in RCP product. | Codex | Fix or document product-only skip; matrix course stays CAS/web-safe until fixed. |
| **CT-WAR-01** | Self-hosted GWT WAR not wired beside `web-host/`. | Codex X-15/16 / Grok G-03 | Browser half of W-09 runnable. |

Until CT-SEC-01 lands, web security is **interim denylist** — acceptable only as a temporary defense with WIMS as authoritative grader (spec limitation already noted).

---

## 5. What this decision does not approve

- Editing upstream `common`
- Retiring GWT
- Treating formative course checks as the WIMS grade
- Claiming D-11 or W-09 **PASS** at spec level (still NOT RUN / static-only)

---

## 6. Evidence anchors

- Schema: `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json`
- Samples: `courses/trigonometry_intro.json`, `courses/matrix_operations.json` (schema PASS)
- Web static: `03-RCP-Spike/tests/results/S_W-09_GROK_V1.csv` (2026-11-01)
- Tracking: `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md`
- Sprint status: `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md`
