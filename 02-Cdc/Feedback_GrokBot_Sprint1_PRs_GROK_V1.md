<!-- GROK_V1 -->
# Feedback intake — Grok Bot Sprint 1 PRs (`Feedback_GrokBot_Sprint1_PRs_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Feedback_GrokBot_Sprint1_PRs_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Source | Grok Bot message (Debian Sprint 1 lane complete) |
| Base branch | `feat/external-engines` |
| Owner merge policy | **No merge** until further notice (`Questions_Course_Tree_Owner_GROK_V1.md` Q7) |

---

## 1. PR status (open, waiting for review)

| PR | Title / lane | Reported result | Merge order note |
|---|---|---|---|
| [#3](https://github.com/io-e/AlgoGebra/pull/3) | Security corpus (G-05 / WP9-03) | Suite 16: **71 PASS / 0 FAIL / 44 SKIP** | Merge before #6 |
| [#4](https://github.com/io-e/AlgoGebra/pull/4) | BUG-017 JDK discovery (G-04) | Suite 17: **13/0/0** | Rebuild product images after merge (`build.sh` copies `launch.sh`) |
| [#5](https://github.com/io-e/AlgoGebra/pull/5) | GWT web build (G-03 / WP3a-03) | Suite 15: **15/0/0** | Self-hosted WAR; no egress in headless Chrome |
| [#6](https://github.com/io-e/AlgoGebra/pull/6) | P-01 evidence + states/handoff | P-01: **8/0/1** + evidence manifest | **Merge last** (links the other three) |

Nothing is merged yet. Owner Q7: keep no-merge. Agents may review and leave comments; do not merge without a new owner answer.

---

## 2. Technical findings (verified by Grok Bot on Debian)

### 2.1 GWT / Gradle (PR #5)

- Pin builds and loads from a **local** copy in headless Chrome; no outbound requests.
- `evalCommand`, `getValueString`, and CAS return correct values — **including functions and matrices**.
- GeoGebra’s standard deploy step **fails under Gradle 9.4.1**.
- Working task set: `:web:gwtCompile :web:copyHtml :web:mergeDeploy`.
- **Codex on Windows will likely hit the same deploy failure** — use the same three tasks (owner Q4: Codex owns first Windows WAR).

### 2.2 BUG-014 scope (side note)

Functions and matrices work on the **web** build. BUG-014 therefore looks **specific to the desktop RCP / OSGi integration**, not to upstream GeoGebra itself. Aligns with owner Q3: ship course tree with trig/CAS courses; keep desktop matrix CMD skipped until BUG-014 is fixed.

### 2.3 Suite 16 skips (PR #3)

44 skips = validator + `.ggb` scanner checks. Expected verdicts are recorded, waiting on **Codex** validator / scanner delivery. Not treated as product FAIL.

### 2.4 Gaps in Grok Bot’s own coverage

| Gap | Impact |
|---|---|
| Firefox not installed | Browser evidence is Chrome-only |
| Mise → Java discovery path untested | BUG-017 suite may not cover Mise layouts |

---

## 3. Three security gaps — Claude to settle

Grok Bot asks Claude to settle these against `Spec_Course_Security_CLAUDE_V1.md` (file on tip is already marked CLAUDE_V1_1 with T-15/T-16/T-17 text). Claude must confirm whether the **spec is closed** and only **implementation** remains, or whether further spec edits are required.

| Id | Gap (Grok Bot wording) | Spec V1_1 text today | Likely residual |
|---|---|---|---|
| SEC-G1 | Scanner misses scripts in `<ggbscript val=…>` | T-15 / `containsScriptElements` mentions `<ggbscript` | Implementation SKIP in suite 16 until Codex scanner; Claude confirms reject policy (any ggbscript vs allowlisted commands only) |
| SEC-G2 | `Sequence` has no size limit | T-16 / max 10 000 iterations | Web JS has `MAX_SEQUENCE_ITER`; Claude confirms nesting `Sequence(Execute(…))` + end-bound checks are mandatory for **both** hosts |
| SEC-G3 | Symlink escapes course folder without real-path check | T-17 / `toRealPath()` | Desktop OPEN path; Claude must specify **web** equivalent (no Node `realpath` in browser — reject symlinks server-side or disallow OPEN to non-regular files) |

Errata / settlement sheet: `02-Cdc/Errata_Security_Spec_for_Claude_GROK_V1.md`.

---

## 4. Actions by agent (respecting owner answers)

| Agent | Do now | Do not |
|---|---|---|
| **Owner / Grok Build** | Push local commits (Q1 yes); leave PRs open | Merge #3–#6 |
| **Codex** | BUG-014 desktop investigation; Windows WAR via `gwtCompile+copyHtml+mergeDeploy`; validator/scanner for suite 16 skips; CourseTreePanel (tree before BUG-014 OK) | Merge PRs; edit `common` |
| **Grok Bot** | Keep PRs green; add Firefox when available; retest Mise Java path; mirror WAR after Codex | Merge without owner |
| **Claude** | Settle SEC-G1..G3; Playwright scaffold under `03-RCP-Spike/tests/playwright/`; Eclipse RCP Testing Tool track (Q8) | Redo C-22/C-23; merge |

---

## 5. Suggested review checklist (when merge is allowed)

1. Review #3, #4, #5 independently (tests + docs).
2. Rebuild Linux images after #4.
3. Point `web-host/GeoGebra` at PR #5 artifact; run W-09 browser / Playwright.
4. Merge #6 last (states.yaml + handoff + P-01 evidence).
5. Reconcile `states.yaml` with local Sprint 4 / D-COURSE-01 commits to avoid clobber.

---

*Intake by Grok Build from Grok Bot Sprint 1 feedback. Does not authorize merges.*
