<!-- GROK_V1 -->
# Grok Bot — after Codex course-tree sprint1 PR lands

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_GrokBot_After_Codex_Sprint1_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Audience | **Grok Bot** (Debian) |
| Trigger | Codex opens review-only PR from `feat/course-tree-sprint1` → `feat/external-engines` |
| Constraints | No merge, no force-push, no `common` edits |

---

## Wait for

1. GitHub PR URL (Codex sprint1) exists and CI/checkout is possible.
2. Prefer checking out the **PR head** (or merging locally into a throwaway branch) — do **not** merge to `feat/external-engines` until owner says so.

Codex push brief (context): `02-Cdc/Actions_Codex_Push_Course_Tree_Sprint1_GROK_V1.md`.

---

## Priority after the PR is visible

### P0 — Twin suite 18 vs Windows

| | |
|---|---|
| **Do** | Fetch Codex PR head. Run suite 18 on Debian against `launch.sh` (already in PR #9) **and** compare exit-code / case matrix to Codex `launch.ps1` suite 18. |
| **Report** | PASS/FAIL/SKIP counts; list any Windows-only vs Linux-only gaps (symlink, path separators, exit codes). |
| **PR** | Comment on Codex sprint1 PR + optionally amend PR #9 if twin finds a real `launch.sh` bug. Do not merge. |

### P1 — G-T2 WAR consume

| | |
|---|---|
| **Do** | From Codex X-T8 evidence / rebuild recipe (`gwtCompile+copyHtml+mergeDeploy`), place WAR under `web-host/GeoGebra/` on Debian (or document identical Debian build). |
| **Done when** | `deployggb.js` loads locally; static W-09 half still green; note path + sha256. |
| **Unblocks** | G-T3 Playwright browser. |

### P2 — G-T3 Playwright W-09 browser

| | |
|---|---|
| **Do** | After WAR is local: run Playwright W-09 from `03-RCP-Spike/tests/playwright/` (Firefox if PR #10 smoke passed). |
| **Done when** | TAP + screenshots/evidence folder; no PASS claim on skipped matrix/CMD cases. |

### P3 — D-11 mechanical (not attended UI)

| | |
|---|---|
| **Do** | If WP2-06 classes are on the PR head and a product image can be rebuilt: run `Run_All -Only D-11` under Xvfb for file/JVM/panel-presence checks only. |
| **Skip** | Attended tree UI (owner/Codex Windows). Mark PARTIAL if panel loads but clicks not driven. |

---

## Still idle / forbidden

- Merging Codex sprint1 or PRs #3–#10
- Claiming W-09 / D-11 full PASS without WAR + panel evidence
- Editing upstream `common`
- Starting WIMS Sprint 4 without S-01/S-02

---

## One-line brief (paste when PR URL known)

> Codex sprint1 PR `<URL>` is up (review-only). Fetch head. Twin suite 18 vs Windows, consume/rebuild WAR for G-T2, then Playwright W-09 (G-T3). Optional Xvfb D-11 mechanical only. Follow `02-Cdc/Actions_GrokBot_After_Codex_Sprint1_GROK_V1.md`. Do not merge.
