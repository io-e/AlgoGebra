<!-- GROK_V1_1 -->
# Owner questions — Course Tree (`Questions_Course_Tree_Owner_GROK_V1_1.md`)

| Field | Value |
|---|---|
| Document | **`02-Cdc/Questions_Course_Tree_Owner_GROK_V1_1.md`** |
| Supersedes | `Questions_Course_Tree_Owner_GROK_V1.md` |
| Version | GROK_V1_1 |
| Date | 2026-11-01 |
| Status | **Answers recorded** (owner 2026-11-01) |
| Related | `Handoff_CLAUDE_by_GROK_V1_1.md`, `Decision_Course_Tree_Architecture_GROK_V1.md`, `Feedback_GrokBot_Sprint1_PRs_GROK_V1.md` |

---

## Answers recorded

| Id | Topic | Owner answer |
|---|---|---|
| Q1 / L1 | Push local Sprint 4 commits? | **Yes — push now** |
| Q2 / L2 | Interim web denylist? | **OK for internal demos**; no external cohort until allowlist |
| Q3 / L3 | Tree before BUG-014? | **Yes** — trig/CAS behind `-Dggbplus.course`; matrix CMD desktop skipped |
| Q4 / L4 | First WAR builder | **Codex (Windows)**; Grok Bot mirrors on Debian |
| Q5 / L5 | Playwright location | **In-repo** `03-RCP-Spike/tests/playwright/` |
| Q6 / L6 | T1 Cheat Sheets now? | **No** — XMLs stay in this repo until D-01 |
| Q7 / L7 | Merge open PRs? | **Keep no-merge** until further notice |
| Q8 / L8 | Next Claude focus | **Playwright W-09 scaffold + Eclipse RCP Testing Tool** (parallel) |

---

## Interaction with Grok Bot Sprint 1 PRs

Grok Bot reports #3–#6 ready for review (suite 15/16/17 + P-01 evidence). **Q7 still forbids merge.** Review-only until owner changes L7.

Recommended merge order **when** L7 flips: #3 → #4 (then rebuild images) → #5 → **#6 last**.

Details: `Feedback_GrokBot_Sprint1_PRs_GROK_V1.md`.

BUG-014: web matrices/functions work (PR #5) → treat as **desktop integration** bug (supports Q3).

---

## Agent locks after answers

| Agent | Authorized now | Still blocked |
|---|---|---|
| **Codex** | BUG-014 investigation; CourseTreePanel (trig/CAS); Windows WAR via `gwtCompile :copyHtml :mergeDeploy` (not broken standard deploy); validator/scanner for suite 16 SKIPs | Merging PRs |
| **Grok Bot** | Keep PRs green; Firefox when available; Mise Java path; mirror WAR after Codex | Merging PRs; WIMS without S-01/S-02 |
| **Claude** | Playwright under `tests/playwright/`; Eclipse RCP Testing Tool study/scaffold; settle SEC-G1..G3 (`Errata_Security_Spec_for_Claude_GROK_V1.md`) | Merging PRs; T1 plug-in update |

---

## Full question text

See archive `Questions_Course_Tree_Owner_GROK_V1.md` for the original wording and recommended defaults. Do not change answers here without a new owner line and date.
