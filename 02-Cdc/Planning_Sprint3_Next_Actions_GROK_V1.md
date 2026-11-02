<!-- GROK_V1 -->
# Sprint 3 — next actions (Codex / Grok Bot)

| Field | Value |
|---|---|
| Date | 2026-11-02 (Europe/Paris) |
| Tip at planning | `feat/external-engines` `d835675` (after #32) |
| Owner | Q1–Q8 decided (#17); Q3b drop near-limit warning (#21) |
| Claude / WIMS / security spec | Owner handles with Claude offline — not assigned here |
| Supersedes sprint table rows in | `Status_And_Next_Sprint_GROK_V1.md` §3 for Codex/Grok lanes |

## Open owner questions (still open)

| ID | Question | Blocks | Who |
|---|---|---|---|
| **S-01 / S-02** | WIMS / XWims server contract (which server, grade callback shape) | G-14…G-16 | Owner + Claude |
| **P-08** | Acceptance git tag (keep pin `375db7faf54` only, or cut a tag) | Traceability hygiene | Owner |
| **Trusted OPEN UI** | Attended visual check of warning dialog before loading `trustedGgb` | Evidence only | Owner / attended Windows |
| **O-02 legal** | License inventory + EUPL/GPL packaging review before distribution | Gate E | Owner / legal |

**Closed (do not reopen):** Q1–Q8 (#17), Q3b drop `SEQUENCE_WARNING_THRESHOLD = 800` (#21).

## Evidence already in (do not redo)

| Item | Result |
|---|---|
| Debian final tip Run_All | 267 PASS / 17 FAIL (pre-existing: suite 09, BUG-014 family, etc.) |
| Suite 16 real validator | 134/2/1 — the 2 fails are T-45/T-51 at 1000 iters (near-limit warning) |
| Suite 18 Windows (Shadow, worktree) | **17 PASS / 0 FAIL / 5 SKIP** — matches Grok `0382388`; logs `D:\ALF_Agents\G1_wt_grok_suite18\03-RCP-Spike\evidence\20261102-suite18-windows-rerun` |
| BUG-010 cause | Proven (#28 / PR #32 evidence + patch for Codex) |
| D-11 mechanical | 8/8 on Debian after related work; product still needs #27 fonts for full P-02/P-04 |

## Codex — ordered backlog

| Priority | Issue | Action | Acceptance |
|---|---|---|---|
| **P0** | [#27](https://github.com/io-e/AlgoGebra/issues/27) | Package ReTeX fonts into Linux image (`build.sh` / renderer resources); same approach as Windows r12 fragment | P-02/P-04 font failures gone on rebuilt Linux image; D-11 product path green |
| **P0** | [#21](https://github.com/io-e/AlgoGebra/issues/21) | Remove near-limit warning (Q3b). ≤1000 → plain ACCEPT | Suite 16 → **136/0/1** (T-45/T-51 ACCEPT) |
| **P0** | [#28](https://github.com/io-e/AlgoGebra/issues/28) | Apply logger init fix cleanly in host product code | Suite 09: no dialog on valid 2D input |
| **P1** | [#33](https://github.com/io-e/AlgoGebra/issues/33) | 3D input focus after logger fix | `D04-FOCUS-01` PASS |
| **P1** | (no issue # yet) | `GgbScriptScanner` (X-09) for untrusted OPEN | Suite 16 VAL-T-06/07/29–33 per Q2 |
| **P2** | — | BUG-015 PARI empty error on malformed input | X-06 typed error |
| **P2** | — | Empty CAS result on D-11 if still open after #27 | D-11 CAS asserts |

Rules for Codex: branch from `feat/external-engines`; no `common` edits; open one PR per issue; wait for owner before merge; Grok verifies on Debian.

## Grok Bot — ordered backlog

| Priority | Action | Depends on |
|---|---|---|
| **P0** | Optional: ready-to-apply evidence diffs for #27 and #21 (same style as BUG-010), without rewriting Codex design | — |
| **P0** | After Codex PRs: Debian verify #27 (rebuild image + P-02/D-11), #21 (suite 16), #28/#33 (suite 09) | Codex PRs |
| **P1** | G-09 SWT tree screenshot under GTK/Xvfb; G-11 Linux font/locale | Image with #27 |
| **P1** | Close G-17 Windows↔Debian comparison using Suite 18 Windows evidence above; remove `G1_wt_grok_suite18` worktree when done | Suite 18 done |
| **P2** | Suite 09 remaining Xvfb keyboard items after #28/#33 | #28, #33 |
| **Blocked** | G-14…G-16 WIMS | Owner + Claude on S-01/S-02 — **do not start** |

Rules for Grok Bot: no merge / no PR comments that approve merge until owner has seen the update; push evidence branches as today.

## Claude (owner channel — not this lane)

Owner will handle with Claude: security spec V1_1 (SPEC-GAP-1/3, Sequence 1000/10000, result states) and WIMS S-01/S-02. Grok/Codex stay clear of that until posted on GitHub.

## Critical path

```
#27 fonts (Linux) ──► rebuild image ──► P-02/P-04/D-11 product green
#21 drop warning ──► suite 16 136/0/1
#28 logger ──► #33 3D focus ──► suite 09 cleanup
S-01/S-02 (owner+Claude) ──► G-14…G-16 (Grok later)
```
