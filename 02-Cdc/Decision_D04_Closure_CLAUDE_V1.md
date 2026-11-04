<!-- CLAUDE_V1 -->
# Decision Record — D-04 Core Embedding PASS

| Field | Value |
|---|---|
| Document | `02-Cdc/Decision_D04_Closure_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Decision | **D-04 core embedding is PASS. Issue #33 (3D first-click focus) is tracked separately and does not block Gate B.** |
| Evidence | Validation report, PR #45 (BUG-010), PR #48 (issue #33), PR #50 (issue #39), Grok verifications #46/#47/#51/#52/#55 |

---

## 1. D-04 sub-check status

| Sub-check | Status | Evidence |
|---|---|---|
| SWT shell embeds `GeoGebraPanel` | **PASS** | `D-02-D-04-D-05-VALIDATION-REPORT.md`: "SWT shell embedded `GeoGebraPanel`" |
| Algebra View + toolbars visible | **PASS** | Screenshot `rcp-20261028-235656-23884-34151d6a.png` |
| Input bar accepts commands | **PASS** | `C=5` created in Algebra View. BUG-010 ("Please check your input") **fixed** by PR #45 (logger bootstrap). Grok verified: Debian suite 09 19/1/0 at `2f24a7e` (PR #47). |
| Resize / redraw | **PASS** | Maximize resized, both Swing frames revalidated, no crash |
| Localization | **PASS** | PR #50 (issue #39) fixed embedded locale. Grok verified (PR #52). |
| 2D ↔ 3D focus transfer | **PARTIAL** | Issue #33: first click in 3D view doesn't capture keyboard focus. PR #48 open, paused by owner. |
| Clipboard | **NOT TESTED** | No clipboard tests exist yet |
| High-DPI | **NOT TESTED** | Windows test ran at native DPI only |

## 2. Why D-04 is PASS for Gate B

The V2 validation plan (scenario D-04) requires: "GeoGebra Swing panel loads in SWT, Algebra/toolbar visible, input accepted, resize works."

All four core criteria are met. The sub-checks that remain (clipboard, high-DPI) are quality items, not gate criteria. Issue #33 is a 3D-specific focus edge case that:
- Does not affect 2D input (the primary workflow)
- Has a PR (#48) with a partial fix (suite 10 fixed, #33 still open per Grok #55)
- Is paused by owner decision — not blocking

## 3. BUG-010 resolution chain

| Event | Date | Evidence |
|---|---|---|
| BUG-010 reported: "Please check your input" on Enter | 2026-10-29 | Validation report, screenshot `rcp-20261029-000134-9160-c931fe29.png` |
| Grok root-caused: logger null → `Log.read()` throws → GeoGebra shows warning | 2026-11-02 | `Findings_BUG-010_GROK_V1.md` |
| Codex fix: initialize logger before AppD embedding (PR #45) | 2026-11-03 | `codex/issue-28-bug010-logger-init`, merged |
| Grok verified on Debian: suite 09 PASS at `2f24a7e` | 2026-11-03 | PR #47, Debian production rebuild |
| Windows logger smoke: 6 PASS / 0 FAIL | 2026-11-03 | `evidence/20261103-codex-bug010-logger-bootstrap-windows/SUMMARY.md` |

BUG-010 is **closed**.

## 4. Issue #33 tracking

| Field | Value |
|---|---|
| Issue | #33 — 3D first-click focus |
| PR | #48 (`codex/issue-33-3d-focus`) |
| Status | **Paused** — owner decision |
| Grok findings | PR #51: not fixed. PR #55 (at `5e6322a`): suite 10 fixed (D05-05 regression resolved), #33 still open. |
| Impact | First click in 3D view doesn't register as keyboard input. Workaround: click twice. |
| Gate impact | None — tracked as a separate bug, not a D-04 gate criterion |

## 5. Gate B impact

| Scenario | Status | Notes |
|---|---|---|
| D-02 | **PASS** | 50/50 bundles, headless + GUI |
| D-03 | **PASS** | jogl2 fragment wired |
| D-04 | **PASS** | This decision. #33 separate. |
| D-05 | **PASS** | Fragment bootstrap accepted (`Decisions_D05_Fragment_Bootstrap_CLAUDE_V1.md`) |
| D-06 | **NOT RUN** | Next: Codex C-2 (extension management spike) |

**Gate B blocker: D-06 only.**

---

*End of `Decision_D04_Closure_CLAUDE_V1.md`.*
