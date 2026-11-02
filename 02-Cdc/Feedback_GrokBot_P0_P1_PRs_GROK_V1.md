<!-- GROK_V1 -->
# Feedback intake — Grok Bot P0/P1 (PRs #9 / #10)

| Field | Value |
|---|---|
| Document | `02-Cdc/Feedback_GrokBot_P0_P1_PRs_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Source | Grok Bot report (owner paste into Grok CLI) |
| Dispatch | `02-Cdc/Actions_GrokBot_Parallel_GROK_V1.md` + PR #8 comment |
| Constraints honored | No merge, no force-push, no unsolicited GitHub review posts |

---

## Summary

| Task | Result | PR |
|---|---|---|
| **P0** `launch.sh -Course` + suite 18 | **17 PASS / 0 FAIL / 2 SKIP** | [#9](https://github.com/io-e/AlgoGebra/pull/9) |
| **P0** suite 17 re-run | **13/13 PASS** | (evidence in #9) |
| **P1** Firefox headless Playwright smoke | **PASS** (Firefox 157) | [#10](https://github.com/io-e/AlgoGebra/pull/10) |
| **P1** Mise → Java discovery | **PASS** (M-01..05; PATH-off + Java 21 RCPTT pin) | #10 |
| **P2** Review drafts #3–#8 | Ready on Bot VM only | `/workspace/AlgoGebra/reviews/P2_Reviews_GROK_V1.md` (not in this repo yet) |
| **P3** G-T2..G-T4 | Idle (await Codex WAR + panel) | — |

Evidence folder (PR #9): `03-RCP-Spike/evidence/20261101-133332-p0-launch-course-debian/`.

---

## Details that matter

### PR #9 vs PR #4

- #9 **includes** PR #4’s JDK discovery fix.
- Merge **one** of #4 or #9, not both. If #9 merges, **close #4**.

### Suite 18 skips (LC-18 / LC-19)

- Two SKIPs start the real app with a course → need course panel in product image (**Codex WP2-06 / X-T4**).
- Aligns with Windows Codex suite 18 report (16 local checks earlier; twin after Codex sprint1 PR).

### PR #8

- Extra commit aligning exit codes with #4/#9: `adbfcff` (“no JDK = 4, no image = 3”).
- Draft acknowledgement ready (owner gate before post):

> Ack dispatch 6557930365 — P0 done in #9 (launch.sh -Course + suite 18: 17/0/2, LC-18/19 SKIP until X-T4; depends on #4), P1 in #10 (Firefox 157 headless smoke PASS, mise→Java M-01..05 PASS), P2 review drafts ready for owner approval; G-T2..G-T4 idle; no merge.

### PR #10 minor finding (no code change)

- If Mise pins a Java that is too old, the launcher **quietly picks another Java** instead of warning.

### PR #6

- Conflicts with tip on `states.yaml`.
- Needs a fresh branch with changes re-applied; still **merge last**.

### Suggested merge order (Grok Bot; owner has not approved merge)

`#4` **or** `#9` → `#3` → `#7` → `#5` → `#8` → `#10` → `#6` last.

Current policy remains **`no_merge_until_owner`**.

### Bot environment limits

- `apt` cannot install packages (unsigned package source).
- Bot deferred updating `states.yaml` for P0/P1 because of #6 conflict — **this intake updates states on `feat/external-engines` tip instead**.

---

## Owner decisions still open

1. Post the PR #8 acknowledgement comment? (yes / no)
2. Approve posting P2 self-review drafts to GitHub? (yes / no / edit first — need file copied into repo)
3. When merge opens: confirm `#9` supersedes `#4`, and `#6` last after rebase.
4. Codex sprint1: pushed `24f2d3a`; review-only **PR #11** opened. Attended SWT UI still pending.
5. PR #8 ack **posted** (comment `6558337305`) per owner.

---

## Next for Grok Bot (after Codex sprint1 PR)

Follow `02-Cdc/Actions_GrokBot_After_Codex_Sprint1_GROK_V1.md` (twin suite 18, WAR consume, Playwright W-09, optional Xvfb D-11).
