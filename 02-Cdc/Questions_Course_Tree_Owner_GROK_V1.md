<!-- GROK_V1 -->
# Owner questions — Course Tree / Sprint 4 follow-up (`Questions_Course_Tree_Owner_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Questions_Course_Tree_Owner_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Related | `Handoff_CLAUDE_by_GROK_V1_1.md` §8, `Decision_Course_Tree_Architecture_GROK_V1.md` (D-COURSE-01) |
| Commit | `b626459` on `feat/external-engines` (ahead of origin by 1; not pushed) |

Fill the **Answer** lines. Agents must not invent owner decisions. Recommended defaults are optional hints only.

---

## Q1 — Git push

**Question:** Push commit `b626459` to `origin/feat/external-engines` so Claude / Codex / Grok Bot share D-COURSE-01 and the V1_1 handoff?

| | |
|---|---|
| **Recommended** | Push when the next agent session starts on another machine; keep local-only if only this PC works the branch. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q2 — Web security interim (CT-SEC-01)

**Question:** Block web student pilots until `allowed-commands.json` allowlist lands, or accept the interim **denylist** in `course-tree.js` with WIMS as the authoritative grader?

| | |
|---|---|
| **Recommended** | Accept interim denylist for internal demos only; no external student cohort until allowlist. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q3 — BUG-014 vs CourseTreePanel order

**Question:** Must BUG-014 be fixed before merging `CourseTreePanel` (WP2-06), or may the tree ship with trig/CAS-only courses while desktop matrix CMD stays skipped?

| | |
|---|---|
| **Recommended** | Ship tree behind `-Dggbplus.course` with trig + CAS courses; keep matrix CMD desktop skipped until BUG-014 closed. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q4 — Who builds the first self-hosted GWT WAR?

**Question:** Who produces `web-host/GeoGebra/` (`deployggb.js` + `HTML5/5.0/web3d/`) — Codex (Windows), Grok Bot (Debian), or an owner script?

| | |
|---|---|
| **Recommended** | Codex on Windows first (matches desktop spike machine); Grok Bot mirrors on Debian for W-09 browser. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q5 — Playwright location

**Question:** Add Playwright under `03-RCP-Spike/tests/playwright/` in this repo, or in a separate test repository?

| | |
|---|---|
| **Recommended** | `03-RCP-Spike/tests/playwright/` next to `S_W-09_*` so evidence export stays in one tree. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q6 — Eclipse Cheat Sheets / T1 plug-in

**Question:** Update the T1 plug-in at `D:\ALF_ZGit\T1_Cheat_Sheets` in this sprint (register D-11/W-09), or keep XMLs only in AlgoGebra until D-01 Eclipse import is approved?

| | |
|---|---|
| **Recommended** | Keep XMLs in AlgoGebra now; T1 plug-in update after D-01 approval. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q7 — Merge policy

**Question:** Still **no merge** of open PRs (security corpus and others) into `feat/external-engines` / default branch?

| | |
|---|---|
| **Recommended** | Keep no-merge until BUG-014 path and WAR ownership are chosen. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Q8 — Next Claude focus

**Question:** After this handoff, should Claude (a) scaffold Playwright W-09, (b) draft S-01/S-02 contracts, or (c) idle until Codex WP2-06 / WAR?

| | |
|---|---|
| **Recommended** | (c) idle on product code; optional (a) Playwright scaffold only if Q4/Q5 are answered. |
| **Answer** | _pending_ |
| **Date / by** | |

---

## Quick locks (optional one-liners)

Use this table for a fast owner pass:

| Id | Topic | Owner answer (yes / no / name) |
|---|---|---|
| L1 | Push `b626459` now? | |
| L2 | Interim web denylist OK for demos? | |
| L3 | Tree before BUG-014 fix OK? | |
| L4 | WAR builder (Codex / Grok / owner) | |
| L5 | Playwright in-repo? | |
| L6 | Update T1 Cheat Sheets now? | |
| L7 | Keep no-merge? | |
| L8 | Claude next: Playwright / S-01-02 / idle | |

---

## Agent todo pointers (do not start without answers where marked)

| Agent | Start now (safe) | Wait for answers |
|---|---|---|
| **Codex** | X-T1 BUG-014 investigation (read-only + report) | X-T4 merge/panel after Q3; WAR after Q4 |
| **Grok Bot** | G-T1 `launch.sh` design note; G-T5 tip re-verify if image stable | G-T2/G-T3 browser after Q4; WIMS after S-01/S-02 |
| **Claude** | Use `Handoff_CLAUDE_by_GROK_V1_1.md`; no redo C-22/C-23 | Playwright scaffold after Q5; contracts after Q8 |

Full todo tables: `Handoff_CLAUDE_by_GROK_V1_1.md` §§5–7. Test plans: §§3–4 (Playwright + Eclipse Cheat Sheets).

---

*When answers are filled, bump this file to `Questions_Course_Tree_Owner_GROK_V1_1.md` or append an “Answers recorded” section with date.*
