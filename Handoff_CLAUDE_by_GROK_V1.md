<!-- GROK_V1 — SUPERSEDED by Handoff_CLAUDE_by_GROK_V1_1.md -->
# Handoff to Claude — by Grok (GROK_V1) — ARCHIVE

| Field | Value |
|---|---|
| Document | `Handoff_CLAUDE_by_GROK_V1.md` |
| Status | **SUPERSEDED** — use **`Handoff_CLAUDE_by_GROK_V1_1.md`** |
| Audience | **Claude** (new session resume) |
| Author | Grok (xAI / Grok Build) |
| Date | 2026-11-01 |
| Repo root | `D:\ALF_Agents\G1_Geogebra_Migration` |
| Branch | `feat/external-engines` |
| Last committed tip | `867a62f` (Sprint 3) |
| Working tree | Dirty — Sprint 4 C-22/C-23 + W-09 comment fixes **uncommitted** |

Read this file first in a new Claude session. Then open the documents in §3 before editing. Do not treat older transcript summaries as live truth; verify with `git status`, `states.yaml`, and the tracking ledger.

---

## 1. Goal of the interrupted Claude session

Claude session `1531512a-e273-4830-83eb-9532355575d0` (title: *Décision gate D-04 D-05 GROK*) was driving the **course-tree Sprint 4** closure for the Claude lane:

1. Finish **C-22** — register D-11 / W-09 in scenario tracking (45 → 47).
2. Finish **C-23** — sample course `matrix_operations.json` (web-safe CAS).
3. Produce a **three-agent Sprint 4 status** report.

The user interrupted mid C-22 (header claimed 47 scenarios; table/details were incomplete). **Grok resumed via `/resume-claude` and completed C-22, C-23, and the Sprint 4 status file.**

Owner constraint from that session: **no merge** of waiting PRs until asked.

---

## 2. What Grok completed (do not redo)

| Item | Path / evidence | Status |
|---|---|---|
| C-22 tracking | `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` (canonical 47-row ledger) | **DONE** |
| C-22 working copy | `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1.md` (GROK_V1_3 marker) | **DONE** |
| D-11 runner script | `03-RCP-Spike/tests/scenarios/S_D-11_CourseTree_GROK_V1.ps1` | **DONE** |
| W-09 runner script | `03-RCP-Spike/tests/scenarios/S_W-09_CourseTreeWeb_GROK_V1.ps1` | **DONE** |
| C-23 matrix course | `courses/matrix_operations.json` (schema PASS) | **DONE** |
| Sprint 4 status | `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` | **DONE** |
| `states.yaml` | total 47; D-11 / W-09 entries; tracking → V1_2 | **DONE** |
| W-09 static false positives | Comment-only edits in `web-host/course-tree.js`, `web-host/course-host.html` | **DONE** |
| W-09 static re-run | **15 PASS / 0 FAIL / 4 SKIP**, exit 0; CSV `03-RCP-Spike/tests/results/S_W-09_GROK_V1.csv` | **DONE** |
| README pointer | `03-RCP-Spike/tests/README_TESTS_GROK_V1.md` → 35 scripts, tracking V1_2 | **DONE** |

Authoring twins from Claude Sprint 3 (keep; do not delete):

- `scenarios/S_D-11_CourseTree_CLAUDE_V1.ps1`
- `scenarios/S_W-09_CourseTreeWeb_CLAUDE_V1.ps1`
- `cheatsheets/scenarios/D-11.xml`, `W-09.xml`

`Run_All_GROK_V1.ps1 -Scenarios` only loads `03-RCP-Spike/tests/scenarios/S_*_GROK_V1.ps1`. The GROK runner scripts are the ones the aggregator sees.

---

## 3. Source-of-truth order (read these)

1. `AGENTS.md` / `CLAUDE.md` — binding architecture decisions (`common` untouchable, RCP path, gates).
2. `02-Cdc/Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` — 45-scenario validation plan.
3. `02-Cdc/Planning_Sprint_Course_Tree_CLAUDE_V1.md` — sprint task IDs (C/X/G).
4. `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` — **current Sprint 4 closure snapshot**.
5. `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` — **canonical 47-scenario ledger**.
6. `states.yaml` — bug + scenario machine state.
7. This handoff — resume instructions only.

Course-tree specs (already DONE in earlier sprints): Study V1_2, `Spec_Course_Security_CLAUDE_V1.md`, `Schema_Course_JSON_CLAUDE_V1.json`, `Handoff_Bug_Fixes_BUG-014_015_016_017_CLAUDE_V1.md`.

---

## 4. Current scenario counts

| Status | Count |
|---|---|
| PASS | 4 |
| PARTIAL | 12 |
| FAIL | 7 |
| NOT RUN | 24 |
| **Total** | **47** |

New rows:

- **D-11** — Course tree SWT — **NOT RUN** (blocked: Codex WP2-06 `CourseTreePanel`).
- **W-09** — Course tree HTML — **NOT RUN** at spec level; static half PASS; browser half SKIP until self-hosted GWT WAR.

---

## 5. Claude lane — what remains

| Task | Status | Suggested next step |
|---|---|---|
| C-01..C-20, C-22, C-23 | DONE | Do not re-author unless specs change |
| **C-21** | PARTIAL | After WAR is available: adjust `web-host/course-host.html` paths if needed; re-run W-09 browser checks |
| Docs / planning status tables | Stale markers in `Planning_Sprint_Course_Tree_CLAUDE_V1.md` | Optional: bump planning statuses for C-22/C-23 DONE |
| Commit of Sprint 4 working tree | **Not done** | Ask owner before `git commit` / push |
| S-01 / S-02 contracts | Still missing | Only if owner prioritizes WIMS Sprint 4 unblocking |

Claude should **not** edit `source/shared/common` in the upstream GeoGebra checkout.

---

## 6. Blockers owned by other agents (do not pretend fixed)

| Blocker | Owner | Impact |
|---|---|---|
| **BUG-014** (`evalCommand` divergences: functions, matrix CMD, 3D Plane) | Codex | Blocks WP2-06, D-11 product half, desktop matrix CMD |
| **WP2-06** `CourseTreePanel` + `-Dggbplus.course` | Codex | D-11 |
| **GWT WAR** self-hosted next to `web-host/` | Codex X-15/16 / Grok G-03 | W-09 browser, C-21 closure |
| **S-01 / S-02** WIMS activity/submission contracts | Specs + product | Grok Bot WIMS Sprint 4 |
| **No merge** | Owner | PRs stay unmerged until explicit ask |
| D-04 Windows suite 09 attended | Codex / attended UI | Separate from course-tree CMD path |

---

## 7. Verify before changing anything

```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration
git status -sb
git log -5 --oneline
# Expect: branch feat/external-engines, tip 867a62f, dirty tree with Sprint 4 files

# W-09 static (should still be 15/0/4 after comment fixes)
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_W-09_CourseTreeWeb_GROK_V1.ps1

# Matrix course schema
python -I -c "import json; from jsonschema import validate; validate(json.load(open('courses/matrix_operations.json',encoding='utf-8')), json.load(open('02-Cdc/Schema_Course_JSON_CLAUDE_V1.json',encoding='utf-8'))); print('PASS')"
```

GeoGebra pin (unchanged): commit `375db7faf54`, `VERSION_STRING` `5.4.934.0` at `D:\ALF_ZGit\G1_Geogebra_Migration`.

---

## 8. Safest next actions for Claude (pick with owner)

1. **Commit Sprint 4 docs/scripts** (if owner approves) — one coherent commit on `feat/external-engines`, no push unless asked. Suggested message theme: complete C-22/C-23 course-tree tracking + matrix course + W-09 static comment fixes.
2. **Idle on C-21** until WAR path exists; then close W-09 browser half and mark C-21 DONE.
3. **Optional planning hygiene** — update `Planning_Sprint_Course_Tree_CLAUDE_V1.md` status column for C-22/C-23.
4. **If unblocking WIMS** — start activity/submission contract specs (S-01/S-02), only with owner priority.
5. **Do not** re-run full desktop UI suites or merge PRs without owner confirmation.

---

## 9. Uncommitted file set Grok left (Sprint 4 resume)

Expect at least these among dirty/untracked paths (confirm with `git status`):

**Modified / new from Sprint 4 resume**

- `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1.md`
- `03-RCP-Spike/tests/SCENARIOS_TRACKING_GROK_V1_2.md` (new)
- `03-RCP-Spike/tests/scenarios/S_D-11_CourseTree_GROK_V1.ps1` (new)
- `03-RCP-Spike/tests/scenarios/S_W-09_CourseTreeWeb_GROK_V1.ps1` (new)
- `courses/matrix_operations.json` (new)
- `web-host/course-tree.js` (comment-only)
- `web-host/course-host.html` (comment-only)
- `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md` (new)
- `states.yaml`
- `03-RCP-Spike/tests/README_TESTS_GROK_V1.md`
- `Handoff_CLAUDE_by_GROK_V1.md` (this file)

**Also dirty from earlier work (not from this Sprint 4 close)** — leave unless owner scopes them in: e.g. `03-RCP-Spike/build.ps1`, `bundles.info`, `geogebraplus.product`, other untracked docs under `02-Cdc/`, evidence folders, etc.

---

## 10. Authorship note for Claude

- Grok-authored files use **`GROK_V…`** markers and `*_GROK_V*` names.
- Keep Claude archives as `CLAUDE_V…`. When Claude edits a Grok file, prefer a new versioned sibling or an explicit dual note; do not relabel Grok work as Claude-only.
- User-facing replies: **English** unless the user asks otherwise in that message.

---

## 11. Reader warnings (from `/resume-claude`)

- Claude transcript was heavily compacted (`preserved_segment_unavailable`, many unknown records skipped). Prefer this handoff + repo files over any recovered assistant text.
- Prior agent claims about Codex/Grok Bot PR results are **stale** until re-verified on the current tip.
- Spec-level W-09 remains **NOT RUN** even though static checks PASS.

---

*End of handoff. Primary companion: `02-Cdc/Sprint4_Course_Tree_Status_GROK_V1.md`.*
