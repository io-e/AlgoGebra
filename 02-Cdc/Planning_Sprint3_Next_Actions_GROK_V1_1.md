<!-- GROK_V1_1 -->
# Sprint 3 — next actions (Grok Bot / Codex) — V1_1

| Field | Value |
|---|---|
| Date | 2026-11-03 (Europe/Paris) |
| Tip | `feat/external-engines` @ `4e13b83` (includes #50 l10n, #55 focus evidence) |
| Supersedes | `Planning_Sprint3_Next_Actions_GROK_V1.md` active queue rows |
| Owner policy | Pause #48 / keep #33 open; WIMS skim only; no scanner |

## Recently closed / merged (do not reopen)

| Item | Result |
|---|---|
| #21 Q3b near-limit warning | Closed — PR #44 |
| #27 BUG-014 fonts | Closed — PR #43 |
| #28 BUG-010 logger | Closed — PR #45 |
| #39 / BUG-013 localization | Closed — PR #50 + evidence #52 |
| #55 Debian evidence for #48 @5e6322a | Merged — suite 10 fixed, #33 still fails on Xvfb |

## Open owner decisions (still)

| ID | Question | Status |
|---|---|---|
| **S-01 / S-02** | WIMS server contract / Lean batch | Decided earlier in docs — **implementation not started**; skim only until owner re-opens |
| **WIMS Q-W1…Q-W4** | Defaults in `WIMS_Open_Questions_GROK_V1.md` | Awaiting owner approve to post/settle |
| **#33 focus** | Product fix vs Windows-only / Xvfb limit | **Incubating** — #48 paused |
| **Course chrome i18n** | Run/Check/Next/Reset stay English in FR | Out of #39 — optional P2 later |
| **#53 null panel** | DockManagerD “Adding null panel” | P2 — not a merge gate |

---

## Grok Bot — ordered plan

### P0 — do now

| # | Action | Notes |
|---|---|---|
| G1 | **#49 hygiene** | Resolve mergeability with tip; keep **test-only**; wait for owner review of the diff; **no merge** until OK |
| G2 | **Gap-fill evidence PR** | If not opened yet: Options EN/FR + G-09/G-11 from commit `8deb5af` on `grok/verify-50-l10n` as a **new** PR ( #52 already merged) |
| G3 | **Cancel / idle the #48 watch** | No rebuild loops until owner un-pauses focus; draft-only if something appears |

### P1 — read-only / research

| # | Action | Notes |
|---|---|---|
| G4 | **WIMS skim** on #40 → #41 → #42 | Rebase onto tip if cheap; refresh suite 21/22/23 counts **only if needed for the skim**. **No implementation**, no S-01/S-02 settlement, **no merge** |
| G5 | Optional short note: Xvfb vs real-WM limits for focus (link #55) | Docs/evidence only |

### P2 — later (owner must ask)

| # | Action |
|---|---|
| G6 | Course-panel host i18n (Run/Check/Next/Reset) |
| G7 | Help with #53 null-panel investigation (evidence only) |
| G8 | Full Run_All snapshot after next product merge wave |

### Grok — do not

- Push or merge #48 / close #33  
- Start scanner / BUG-015  
- Settle WIMS protocol or start G-14…G-16 implementation beyond what’s already in open PRs  
- Blind focus iterations on Debian  

---

## Codex — ordered plan

### Paused

| # | Item | Rule |
|---|---|---|
| C0 | **#48 / #33 focus** | **Paused.** No further pushes or merges. Keep local experiments out of the PR until owner un-pauses. When resumed: target-pane **window** focus before text field; Windows suite 09+10 + Grok Debian; do not reintroduce suite 10 regression |

### P1 — when owner unblocks (pick one)

| # | Action | When |
|---|---|---|
| C1 | Resume #48 with a **design note** (window activation sequence + focusTrace acceptance) | Owner says “un-pause focus” |
| C2 | **#53** DockManagerD null panel (P2 packaging/host) | Owner asks; not blocking |
| C3 | Suite 09 **clipboard hygiene** (owned fixture / skip if contaminated) | Small test-only PR; can do anytime owner wants |

### Explicitly parked

| # | Item |
|---|---|
| C4 | Scanner / X-09 / BUG-015 |
| C5 | Scratch worktree cleanup PR (optional hygiene only) |

### Codex — do not

- Merge #48  
- Close #33  
- Start scanner  
- Parallel product features that need a green suite 09 focus path  

---

## Critical path (current)

```
[paused] #48 / #33 focus incubates
    │
    ├─ Grok: #49 mergeability + owner review
    ├─ Grok: gap-fill evidence PR (8deb5af)
    └─ Grok: WIMS skim only (#40–42)

Owner later: un-pause focus  OR  skim/merge WIMS stack  OR  #53
```

## Merge rule

Nothing merges without owner review. Evidence PRs are preferred over silent tip commits.
