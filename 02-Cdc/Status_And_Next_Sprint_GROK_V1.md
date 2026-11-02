# Status and next sprint — course tree (GROK_V1)

| Field | Value |
|---|---|
| Date | 2026-11-02 (Europe/Paris) |
| Tip | `feat/external-engines` after the merge train (#9, #3, #7, #18, #5, #8, #10, #12, #13, #14, #16, #15, #19) |
| Inputs | `Planning_Sprint_Course_Tree_CLAUDE_V1.md`, `Actions_*_GROK_V1.md`, `states.yaml`, owner answers [issue #17](https://github.com/io-e/AlgoGebra/issues/17#issuecomment-6569788303) |
| Final Debian run | suites 267/17/61, scenarios 165/17/42, suite 16 with real validator 134/2/1, Codex Java 27/0 (evidence PR #19) |

## 1. Done
| Lane | Items (plan ids) | Evidence |
|---|---|---|
| Grok Sprint 1 | G-01 env, G-02 P-01 (8/0/1), G-03 GWT WAR on Debian, G-04 BUG-017 `launch.sh` JDK discovery (exit 69, Q1), G-05 malicious corpus (62 cases, suite 16) | #6→#15, #5, #9, #3/#7 |
| Grok Sprint 2 | G-06 OEF→course.json (suite 19, 300/300 real OEF schema-valid), G-07 course-tree.js on Firefox (W-09 PW 10/10), G-08 `launch.sh -Course` (suite 18 21/0/1) | #16, #13, #9 |
| Grok Sprint 3 (partial) | G-10 Xvfb course tree test, G-12 D-11 on Debian (mechanical, FAIL = BUG-014), G-13 W-09 Debian (Firefox) | #14, #13 |
| Grok extra | G-T1..G-T5, P0/P1, F-1 mise warning, test-side validator CLI over real `StepValidator` + headless `AppDNoGui`, final-tip Run_All | #8, #10, #12, #18, #19 |
| Codex | X-01..X-08 model/parser/panel/executor/validator, X-12 panel in host, X-13 `launch.ps1 -Course`, X-14 build, Q2–Q4 security (fail-closed OPEN, Sequence 1000/10000, ACCEPT_WITH_WARNING) | #11, #18 |
| Claude | C-01..C-04, C-05 trigonometry + C-23 matrix courses, C-07/C-09..C-12 web host, C-16 VS Code, C-17 authoring cheat sheet | repo |
| Owner | Q1–Q8 decided (issue #17) | states.yaml |

## 2. Remaining
| Item | Lane | Blocking? | Note |
|---|---|---|---|
| BUG-014 `evalCommand` false in the RCP product (D-11, P-02, P-04) | Codex | **yes** (D-11, X-17, C-23 smoke) | persists with #18 host on the rebuilt image |
| D-11 CAS result empty | Codex | yes (D-11) | probably the same root as BUG-014 / CAS init |
| WP9-04 `GgbScriptScanner` (X-09) | Codex | yes for untrusted OPEN (Q2) | then a clean in-course .ggb may ACCEPT |
| Near-limit Sequence warning (≥800) vs corpus ACCEPT (T-45/T-51) | Owner → Codex/Grok | no | keep (update corpus) or drop |
| Trusted-OPEN SWT dialog: attended check | Codex/Owner (Windows) | no | not visually tested |
| Spec: SPEC-GAP-1 `<ggbscript>`, SPEC-GAP-3 realpath, §5 Sequence 1000/10000 | Claude (Q5) | no | tests already match the decisions |
| BUG-015 PARI empty error (X-06), BUG-016 reproducible build (O-03), BUG-010 input dialog (P-07) | Codex | no | |
| Compute API result kind / revision (X-01, X-02) | Codex | no (gate D) | |
| Windows unified suite 18 + D-11/W-09 Windows (X-18, X-19) | Owner/Codex (Windows) | no | Q8: clean worktree |
| Cheat sheets C-08, C-13..C-15, C-18..C-22 | Claude | no | partly present (`cheatsheets/`) |
| G-09 SWT tree screenshot on GTK, G-11 Linux font/locale | Grok | no | tree loads under Xvfb; screenshot + locale pass pending |
| G-14..G-16 WIMS template, grade callback, full cycle | Grok | blocked on S-01/S-02 (server contract) | |
| G-17 Windows↔Debian reconciliation | Grok | after Windows runs | |
| Suite 09 Xvfb keyboard (17 known fails), P-08 acceptance tag, O-02 licence | Grok / Owner | no | |

## 3. Proposed Sprint 3
| # | Item | Lane | Est. h | Depends on |
|---|---|---|---|---|
| 1 | BUG-014 root cause + fix (evalCommand false in RCP) | Codex | 6 | — |
| 2 | D-11 CAS empty | Codex | 2 | 1 |
| 3 | `GgbScriptScanner` + suite 16 VAL-T-06/07/29–33 green | Codex | 4 | Claude #6 |
| 4 | Decide near-limit warning; align corpus or code | Owner + Grok/Codex | 0.5 | — |
| 5 | Attended Windows: trusted-OPEN dialog, D-11, W-09 Chrome, unified suite 18 | Owner/Codex | 2 | 1 |
| 6 | Spec V1_1: SPEC-GAP-1/3 + Sequence limits + result states | Claude | 2 | — |
| 7 | Rebuild Linux image, rerun D-11/LC-18/LC-19, G-09 screenshot, G-11 locale | Grok | 2 | 1, 2 |
| 8 | Suite 09 Xvfb keyboard focus investigation | Grok | 2 | — |
| 9 | App-backed Java test for localized command rejection (replace adapters in CI) | Grok | 2 | — |
| 10 | BUG-015 PARI empty error | Codex | 1.5 | — |
| 11 | G-17 reconciliation report | Grok | 1 | 5, 7 |
| 12 | WIMS S-01/S-02 contract decision → unblock G-14..G-16 | Owner | 0.5 | — |
| | **Total** | | **25.5** (Codex 13.5, Grok 7, Claude 2, Owner/mixed 3) | |

## 4. Verdict
**New planning needed: yes, a light one.** The original 4-week plan is still the right frame, and Grok's Sprint 1–2 items are all done. What it doesn't cover:
(a) owner decisions Q1–Q8 changed contracts the plan never mentions (exit 69, fail-closed OPEN, Sequence budget, ACCEPT_WITH_WARNING);
(b) the critical path now sits entirely on **BUG-014**, which has outlived its Sprint 1/3 slots;
(c) several Codex/Claude items are done out of order, and Grok Sprint 4 (WIMS) is blocked on the S-01/S-02 server decision.
The plan doesn't need rewriting: adopt the Sprint 3 table above as the planning update, and mark the done items in `Planning_Sprint_Course_Tree_CLAUDE_V1.md` (Claude) and `states.yaml`.
