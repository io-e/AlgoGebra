<!-- CLAUDE_V1_2 -->
# Workload — Course Tree Feature: Errata and Updates (V1_2)

| Field | Value |
|---|---|
| Document | `02-Cdc/Workload_Course_Tree_CLAUDE_V1_2.md` |
| Version | CLAUDE_V1_2 |
| Status | Active — errata on V1_1 after Grok Bot V1_1 check |
| Date | 2026-11-01 |
| Applies to | `Workload_Course_Tree_CLAUDE_V1_1.md` (the WP tables remain authoritative; this document corrects specific items) |
| Review | Grok Bot 2026-11-01 (V1_1 check) |

---

## 0. Additional corrections (V1_1 → V1_2)

These correct items Grok Bot identified when reviewing the V1_1 documents.

| # | Issue | Correction |
|---|---|---|
| G-01 | D-04 still listed as gate for WP2-06 (Codex integration) | **Removed.** Course tree uses `GgbAPI.evalCommand`, not keyboard input. D-04 (focus/input) is a separate concern. WP2-06 depends on BUG-014 only. |
| G-02 | GWT WAR build (WP3a-03) counted in both WP-3a (3h) and WP-8a (3h, as WP8a-03) | **Deduplicated.** WP8a-03 is removed. Grok Bot's GWT build is WP3a-03 only (3h). WP-8a total becomes **1.5h**. |
| G-03 | D-11 and W-09 not registered in SCENARIOS_TRACKING or Run_All | **Added to WP6-07** scope: update SCENARIOS_TRACKING from 45 to 47, add D-11 and W-09 entries, update Run_All runner. |
| G-04 | V1_1 correction table uses labels W-01..W-13, clashing with scenario IDs W-01..W-08 | **Renamed** in Study V1_2: V1→V1_1 corrections keep prefix R-xx. V1_1→V1_2 corrections use prefix G-xx. No clash with scenario IDs. |
| G-05 | OEF converter (WP7-02) is unsuffixed Perl script with no `.ps1` test | **Clarified:** WP7-02 deliverable is `tools/oef2course.py` (Python, not Perl — Grok Bot's choice). A `.ps1` or `.sh` test wrapper is included in the deliverable. |
| G-06 | `launch.sh` (Linux) missing `-Course` flag | **Added** Study V1_2 §2.8. Implementation is Grok Bot's lane. |
| G-07 | Cheat Sheet plan (WP-4) says Eclipse is installed, but D-01 requires owner approval | **Clarified:** WP4-05 (Eclipse test) is gated on D-01 approval. WP4-00 through WP4-04 (generation) do not require Eclipse. |

---

## 1. Revised dependency graph for WP-2

```
WP1-01 Schema ──► WP2-01..04 (model, parser, tests) ◄── unblocked
                       │
                 WP2-05 SWT panel ◄── unblocked
                       │
                 WP2-07 Executor (with security allowlist) ◄── after WP9-01
                 WP2-08 Validator ◄── unblocked
                       │
                 ═══ BUG-014 GATE ONLY (D-04 removed) ═══
                       │
                 WP2-06 Host integration
                 WP2-09 launch.ps1 -Course
                 WP2-11 Smoke test
```

---

## 2. Revised totals

| Agent | V1_1 estimate | V1_2 correction | V1_2 estimate |
|---|---|---|---|
| Claude | ~30h | — | ~30h |
| Codex | ~29h | — | ~29h |
| Grok Bot | ~28.5h | -3h (WP8a-03 dedup) | **~25.5h** |
| Owner | ~1h | — | ~1h |
| **Total** | ~88.5h | -3h | **~85.5h** |

Still an initial estimate. Excludes BUG-014 resolution, W-01, S-01/S-02 authoring, and rework.

---

## 3. New deliverables in this cycle (produced with V1_2)

| Deliverable | WP | Status |
|---|---|---|
| `Study_Course_Tree_RCP_and_Web_CLAUDE_V1_2.md` | — | **Done** (three blocking fixes) |
| `Spec_Course_Security_CLAUDE_V1.md` | WP9-01 | **Done** (allowlist spec) |
| `Schema_Course_JSON_CLAUDE_V1.json` | WP1-01 | **Done** (JSON Schema) |
| `Handoff_Bug_Fixes_BUG-014_015_016_017_CLAUDE_V1.md` | — | **Done** (Codex/Grok handoff) |

---

## 4. What can start now (updated)

### Claude (done or in progress)

| Task | WP | Status |
|---|---|---|
| JSON Schema | WP1-01 | **DONE** |
| Security spec | WP9-01 | **DONE** |
| Study V1_2 (three blocking fixes) | — | **DONE** |
| Bug handoff | — | **DONE** |
| Sample course (trigonometry, 2D only) | WP1-02 | **NEXT** |
| course-tree.css | WP3-02 | NEXT |
| course-tree.js | WP3-01 | After WP1-01 (done) |
| T1 Cheat Sheets reconciliation | WP4-00 | NEXT |

### Codex (unblocked after schema)

| Task | WP | Status |
|---|---|---|
| CourseNode.java, CourseAction.java | WP2-01, WP2-02 | Unblocked (schema done) |
| CourseModel.java (parser) | WP2-03 | After WP2-01/02 |
| Unit tests | WP2-04 | After WP2-03 + sample course |
| CourseTreePanel.java | WP2-05 | After WP2-03 |
| DirectiveExecutor.java (with allowlist) | WP2-07 | After WP2-05 + security spec (done) |
| GgbScriptScanner.java | WP9-04 | After security spec (done) |
| GWT WAR build (Windows) | WP3a-01 | Unblocked |

### Grok Bot (unblocked)

| Task | WP | Status |
|---|---|---|
| Debian/Xvfb baseline | WP8a-01, WP8a-02 | Unblocked |
| GWT WAR build (Debian) | WP3a-03 | Unblocked |
| Malicious course file corpus | WP9-03 | After security spec (done) |
| OEF converter | WP7-02 | After schema (done) + OEF fixtures |
| BUG-017 fix (launch.sh) | — | Unblocked |
