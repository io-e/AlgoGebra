<!-- GROK_V1 -->
# Grok Bot — parallel actions while Codex is busy (`Actions_GrokBot_Parallel_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_GrokBot_Parallel_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Audience | **Grok Bot** (Debian) |
| Constraints | No merge, no force-push; follow `Questions_Course_Tree_Owner_GROK_V1_1.md` + `Questions_RCP_Testing_Owner_GROK_V1_1.md` |
| Blocked forever until Codex | **G-T2** (WAR consume), **G-T3** (Playwright browser), **G-T4** (D-11 product) |

Yes — Grok Bot can do more. **Idle only for WAR/panel-dependent work.** Everything below is safe in parallel.

---

## Priority order (do in this sequence)

### P0 — Suite 18 for `launch.sh -Course` (from PR #8 design)

| | |
|---|---|
| **Why** | G-T1 design is done; cold evidence still missing. Unblocks Linux course launch before WP2-06 UI exists (file validation + JVM args only). |
| **Do** | Implement suite 18 (19 cases) on Debian: flags `-Course`/`--course`, env fallback, symlink resolve, `.json` + size + optional root, distinct exit codes, fail-before-Java. |
| **PR** | New PR into `feat/external-engines` (do not merge). |
| **Done when** | TAP + evidence folder; counts published vs design’s 19 cases. |

### P1 — Coverage gaps called out earlier

| Gap | Action |
|---|---|
| **Firefox** | Install Firefox ESR (or package used on Debian images). No full W-09 browser until WAR; smoke that Playwright can launch Firefox headed/headless. |
| **Mise → Java** | Retest BUG-017 / PR #4 discovery path when Java is provided only via Mise; add 1–2 suite 17 cases or a note if still untested. |

### P2 — Review-only on open PRs #3–#8

Leave structured review comments (tests, docs, exit codes, RQ-1 Java 21 default). **Do not merge.** Suggested focus:

| PR | Review angle |
|---|---|
| #3 / #7 | Suite 16 SKIP contract vs Codex validator delivery |
| #4 | Image rebuild note after merge; Mise path |
| #5 | Document `gwtCompile+copyHtml+mergeDeploy` for Codex Windows |
| #6 | Merge-last checklist when owner allows |
| #8 | Exit-code table for Codex `launch.ps1` twin; suite 18 scope |

### P3 — Idle (only these)

| Task | Wait for |
|---|---|
| G-T2 WAR under `web-host/GeoGebra/` | Codex X-T8 artifact or identical Debian build |
| G-T3 Playwright W-09 browser | G-T2 |
| G-T4 `Run_All -Only D-11` | Codex WP2-06 image |
| WIMS G-T7 | S-01/S-02 contracts |

---

## Optional extras (if P0–P2 finish early)

1. **RCPTT Java 21 smoke** — dry-run `Run_RCP_Tests_CLAUDE_V1.ps1 -Phase RCPTT -DryRun` with `RCPTT_JAVA_HOME` → 21; record versions (no PASS claim without AUT).
2. **Static W-09 on Debian** — `S_W-09_CourseTreeWeb_GROK_V1.ps1` (no WAR needed for static half); compare to Windows 15/0/4.
3. **SEC-G1..G3 comments** on Claude errata from Debian evidence (do not rewrite Claude’s spec unless asked).

---

## Still forbidden

- Merge or force-push
- Edits to upstream `common`
- Claiming W-09 / D-11 PASS without WAR / panel
- Starting WIMS Sprint 4 without S-01/S-02

---

## One-line brief to paste to Grok Bot

> Run **P0 suite 18** for `launch.sh -Course` (new PR, no merge). Then **Firefox install smoke + Mise Java retest**. Leave **review comments on #3–#8**. Stay **idle on G-T2..G-T4** until Codex WAR and CourseTreePanel land. RQ-1: RCPTT **Java 21 default**. Follow V1_1 owner Q&A files; do not touch merge policy.
