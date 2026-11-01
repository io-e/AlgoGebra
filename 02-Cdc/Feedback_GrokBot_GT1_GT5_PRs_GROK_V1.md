<!-- GROK_V1 -->
# Feedback intake — Grok Bot G-T1 + G-T5 (`Feedback_GrokBot_GT1_GT5_PRs_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Feedback_GrokBot_GT1_GT5_PRs_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Tip referenced by Grok Bot | `6baf1d4` |
| Merge policy | **No merge** (owner Q7 still active) |

---

## 1. PRs (open, review-only)

| PR | Task | Result | URL |
|---|---|---|---|
| [#7](https://github.com/io-e/AlgoGebra/pull/7) | **G-T5** corpus re-verify | Suite 16: **71 PASS / 0 FAIL / 44 SKIP** (unchanged vs PR #3) | `feat/grok-gt5-corpus-reverify` |
| [#8](https://github.com/io-e/AlgoGebra/pull/8) | **G-T1** `launch.sh -Course` design + RQ-1 note | Design note + suite **18** plan (19 cases) | `feat/grok-gt1-launch-course-design` |

Nothing merged or force-pushed. G-T2..G-T4 still wait on Codex WAR (X-T8) and CourseTreePanel (X-T4 / WP2-06).

---

## 2. G-T5 — security corpus

- Fresh Debian run matches prior: **71/0/44**.
- 44 SKIPs remain until Codex delivers course validator / `.ggb` scanner (WP9-02/04).
- Evidence log + checksums are in PR #7.
- **Interpretation:** tip `6baf1d4` did not regress the corpus; SKIPs are still an implementation gap, not a flaky suite.

---

## 3. G-T1 — `launch.sh -Course` design (best practices locked for Codex twin)

From PR #8 (summary; full note lives in the PR):

| Rule | Detail |
|---|---|
| Flags | `-Course` / `--course`; env var fallback |
| Path safety | Resolve **symlinks** before JVM (`toRealPath` / realpath) — closes **SPEC-GAP-3 / SEC-G3** on the launcher side |
| Validation | Must be `.json`, size **&lt; 1 MB**, optional under a chosen course root |
| Fail-fast | Validate course file **before** Java discovery — bad path never starts the app |
| Exit codes | Distinct codes per failure class; **Codex should mirror on `launch.ps1`** |
| Tests | Planned **suite 18**, 19 cases |

---

## 4. RQ-1 — Grok Bot view (adopted as owner override)

- Prefer **Java 21 as default** for RCPTT on Debian, not fallback-only.
- RCPTT documents Java **17–22**; Java 25 is out of range.
- Product + SWTBot remain on **Java 25**.

Recorded in `Questions_RCP_Testing_Owner_GROK_V1_1.md`.

---

## 5. states.yaml

This intake **adds** G-T1 / G-T5 entries (Grok Bot asked). Agents should pull before editing `states.yaml`.

---

## 6. Agent next steps

| Agent | Action |
|---|---|
| **Codex** | Mirror launch.ps1 contract from PR #8; X-T8 WAR; WP2-06; validator to clear suite 16 SKIPs |
| **Claude** | Settle SEC-G1..G3; Playwright after WAR; RCPTT scripts assume **JAVA 21** default |
| **Grok Bot** | Hold G-T2..G-T4; keep #7/#8 open until merge allowed |
| **Owner** | Review #7/#8; merge still gated |
