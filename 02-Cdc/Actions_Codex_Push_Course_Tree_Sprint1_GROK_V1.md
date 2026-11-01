<!-- GROK_V1 -->
# Codex — push course-tree sprint1 PR (`Actions_Codex_Push_Course_Tree_Sprint1_GROK_V1.md`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_Codex_Push_Course_Tree_Sprint1_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Audience | **Codex** (Windows) |
| Owner decision | Commit + push `feat/course-tree-sprint1` and open a **review-only** PR into `feat/external-engines` |
| Constraints | No merge, no force-push, no edits to upstream `common` |

---

## Why

Local Codex work (X-T8 WAR evidence, `launch.ps1 -Course` + suite 18, WP2-06 headless) is still **uncommitted** in the worktree. Until it is on GitHub, Grok Bot stays blocked on G-T2/G-T3 and cannot twin suite 18 / Playwright against the WAR.

Worktree (verified 2026-11-01):

`D:\ALF_Agents\_worktrees\course-tree-codex-sprint1-20261101`

Branch tip on remote today: `04b0c15` (model/parser + BUG-014 triage only). Working tree still holds the sprint1 deliverables.

---

## Do this (in order)

### 1. Commit in the worktree

From the worktree above, on `feat/course-tree-sprint1`:

**Include at least:**

| Path | Role |
|---|---|
| `03-RCP-Spike/host/src/org/geogebra/plus/course/CourseTreePanel.java` | WP2-06 panel |
| `03-RCP-Spike/host/src/org/geogebra/plus/course/DirectiveExecutor.java` | WP2-06 |
| `03-RCP-Spike/host/src/org/geogebra/plus/course/StepValidator.java` | WP2-06 |
| `03-RCP-Spike/host/test/org/geogebra/plus/course/StepValidatorPolicyTest.java` | policy 9/9 |
| `03-RCP-Spike/host/src/.../GeoGebraPlusApplication.java` | host integration |
| `03-RCP-Spike/host/META-INF/MANIFEST.MF` | exports |
| `03-RCP-Spike/configuration/config.ini` | course props if needed |
| `03-RCP-Spike/launch.ps1` | `-Course` twin of PR #8 |
| `03-RCP-Spike/tests/18_Test_LaunchCourse_GROK_V1.ps1` | suite 18 |
| `03-RCP-Spike/tests/fixtures/course-tree-trig-smoke.json` | fixture |
| `03-RCP-Spike/test-course-model.ps1` | model runner updates |
| `03-RCP-Spike/host/test/.../CourseModelTest.java` | model 9/9 |
| `03-RCP-Spike/evidence/20261101-windows-x-t8-gwt-war/` | X-T8 evidence (logs + sha256 + validation md) |

**Do not commit:** build outputs, `.class`, full WAR blobs if huge — prefer the evidence folder + sha256 manifest pointing at how to rebuild (`gwtCompile+copyHtml+mergeDeploy`). If a deployable WAR must land under `web-host/GeoGebra/`, say so in the PR body and keep size reasonable (or document junction/copy steps).

Suggested commit message style (one or two commits is fine):

```
feat: course-tree sprint1 — WP2-06 panel, launch.ps1 -Course, X-T8 WAR evidence

Co-Authored-By: Codex <noreply@openai.com>
```

### 2. Push the branch

```powershell
git push -u origin feat/course-tree-sprint1
```

Fast-forward / normal push only. **No `--force`.**

### 3. Open PR into `feat/external-engines`

```powershell
gh pr create --repo io-e/AlgoGebra `
  --base feat/external-engines `
  --head feat/course-tree-sprint1 `
  --title "Course-tree sprint1: WP2-06 + launch.ps1 -Course + X-T8 WAR evidence" `
  --body-file <path-to-body.md>
```

PR body must state:

- **Review-only** — do not merge (`merge_policy: no_merge_until_owner`).
- X-T8: Windows GWT WAR build succeeded; evidence path; Playwright **not** run.
- Suite 18: N pass / fail / skip (report actual counts; design target was 19; local report was 16).
- WP2-06: model 9/9, policy 9/9, headless course load OK; **attended UI still pending**.
- Align exit codes with PR #8 (`launch.sh`) where possible.
- No `common` edits.
- Unblocks Grok Bot: G-T2 (WAR consume), suite 18 twin, then Playwright / D-11 mechanical.

### 4. Report back

Paste the PR URL into a short note (comment on this Actions file via PR, or update `states.yaml` `codex_course_tree_sprint1.pr`).

---

## Out of scope for this push

- Merging the PR
- Attended D-11 / RCPTT UI (separate; after PR is up)
- BUG-014 product fix (triage docs OK; matrix CMD stays skipped)
- Playwright browser run (Grok Bot / Claude after WAR is consumable)
- Edits on `feat/external-engines` tip unrelated to this branch

---

## One-line brief to paste into Codex

> On worktree `D:\ALF_Agents\_worktrees\course-tree-codex-sprint1-20261101`, commit all WP2-06 / `launch.ps1 -Course` / suite 18 / X-T8 evidence, push `feat/course-tree-sprint1` (no force), open a **review-only** PR into `feat/external-engines`. Follow `02-Cdc/Actions_Codex_Push_Course_Tree_Sprint1_GROK_V1.md`. Do not merge. Do not touch `common`.
