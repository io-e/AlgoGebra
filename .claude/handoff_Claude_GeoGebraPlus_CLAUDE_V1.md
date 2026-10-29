<!-- CLAUDE_V1 -->
# Claude Self-Handoff — GeoGebraPlus Architecture Study

**Date:** 2026-10-29
**From:** Claude Opus 4.6 (session `e460cabc`)
**To:** Next Claude instance working on this project
**Purpose:** Complete state transfer so you can continue without re-reading the entire history.

---

## 1. Who you are working with

**User:** ALF Lefrancois (`alf.lefrancois@gmail.com`). University math/CS educator at WIMS Paris-Saclay. Manages a multi-agent AI workflow (Claude, Codex, Grok Bot, Gemini). Writes instructions in French; always reply in English per global CLAUDE.md.

**Technical profile:** Comfortable with C (oef2wims compiler), Go (xml2oef), Python (OEF interpreter, validators), PowerShell (launchers), Java/Gradle (GeoGebra builds), LaTeX/LaTeXML pipelines. Not a frontend/React specialist.

**Work style:** Expects structured handoff documents between agents. Sends Codex completion reports as pasted text and expects you to read, review, update docs, and commit. Gives concise instructions (often one line in French). Values reversible, risk-minimizing approaches.

---

## 2. What this project is

**GeoGebraPlus** is an architecture study for building a modular student-facing math tool ecosystem:

- **Desktop:** Eclipse RCP/Equinox product wrapping the upstream GeoGebra desktop (Swing)
- **Web:** Current GWT baseline stays until a scored replacement passes parity (Gate C)
- **Integration:** WIMS/XWims owns grading; GeoGebraPlus owns the interactive client

The study project at `D:\ALF_Agents\G1_Geogebra_Migration` contains **only specification documents** — no application code yet. The GeoGebra source checkout is at `D:\ALF_ZGit\G1_Geogebra_Migration` (pinned at commit `375db7faf54`, version `5.4.934.0`, EUPL 1.2).

### Three-project ecosystem

| Project | Location | Role |
|---|---|---|
| **GeoGebraPlus study** | `D:\ALF_Agents\G1_Geogebra_Migration` | Architecture specs, audit results, handoffs |
| **WIMS OEF toolchain** | `D:\ALF_Scripts\43-wims-paris-saclay_fr` | oef2wims C compiler, xml2oef Go, oef_validate Python, latex2wims C |
| **LaTeX pipeline + OEF interpreter** | `D:\ALF_Scripts\AH-Latex2LatexXML` | LaTeX textbook pipeline, Python OEF interpreter (bridge between WIMS and GeoGebraPlus) |

The OEF interpreter is the bridge: its `\draw` → Matplotlib is temporary; the real path is GeoGebraPlus for geometry. Jupyter complements but must **not** replace GeoGebra Algebra/CAS/2D/3D.

---

## 3. Agent roles

| Agent | Platform | Lane | Handoff style |
|---|---|---|---|
| **Claude (you)** | Windows (ShadowPC) | Architecture, code audit, specifications | Reads V2 + audit files, writes specs and handoffs |
| **Codex** | — | Code migration, unit tests, Bnd/Equinox | Receives detailed handoff `.md` with file paths, line numbers, acceptance criteria |
| **Grok Bot** | Debian/Linux | Integration tests (Maxima, PARI/GP, WIMS) | Receives test scenarios with fixture hashes and expected results |

**Your lane:** Don't write migration code that Codex should own. Don't run Linux integration tests that Grok Bot should own. Your deliverables are architecture documents, code audits, cross-project analysis, specifications, and handoff documents.

---

## 4. Current state — what has been done

### Git state

**Repo:** `D:\ALF_Agents\G1_Geogebra_Migration`
**Branch:** `feat/init-claude-md` (6 commits, never pushed)
**Not a remote-tracking branch.** No remote configured. Never push without explicit user request.

Commit log:
```
949558a Add Codex handoff for RCP product spike (D-02/D-04/D-05)
07d21c6 Add Bnd/Equinox resolution results — D-03 PASS, update CLAUDE.md V2→V3
efe7253 Mark Codex handoff as COMPLETED with audit output references
cd999c8 Update CLAUDE.md V1→V2: integrate Codex audit results and decisions
84d3441 Add Codex audit results: tests, packages, dependencies, OSGi, path comparison
ee16d1f Init repo with study docs + Codex audit handoff for GeoGebra/Eclipse integration
```

Git config (repo-local): `user.email=alf.lefrancois@gmail.com`, `user.name=ALF Lefrancois`.

### Phase 0 — COMPLETED

| Work item | Status | Evidence |
|---|---|---|
| CLAUDE.md created | V3 | In-file marker `<!-- CLAUDE_V3 -->` |
| Codex audit handoff (5 tasks) | COMPLETED | `02-Cdc/Codex_Audit_GeoGebra_Eclipse_Integration_CLAUDE_V1.md` |
| Task E — Test baseline | PASS | 6526 common-jre + 1089 desktop. `Audit_E_Test_Baseline_CODEX_V1.md` |
| Task A — Package ownership | PASS | 5406 files, 385 packages, 1 real split (desktop+jogl2). `Audit_A_Package_Ownership_CODEX_V1.md` + `.tsv` |
| Task B — Dependencies | PASS | 12 production modules, 39 external coords, 4 with OSGi BSN. `Audit_B_Module_Dependencies_CODEX_V1.md` |
| Task C — OSGi wrapping | PASS | 14 Bnd recipe drafts. `Audit_C_OSGi_Wrapping_CODEX_V1.md` + `osgi-manifest-drafts/` |
| Task D — Path comparison | PASS | Path A (Eclipse RCP) recommended at 3.55/5. `Audit_D_Path_Comparison_CODEX_V1.md` |
| D-03 — Equinox resolution | **PASS** | 50/50 bundles RESOLVED. `Bnd_Equinox_Resolution_Win64/equinox-resolution.log` |

### Key correction discovered during audit

My initial claim that `org.geogebra.common` was split between `common`, `common-jre`, and `canvas-base` was **WRONG**. Codex's source-level scan proved that only 2 classes declare the root `org.geogebra.common` package (both in `common`). The real split is `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` across `desktop` and `jogl2` (8 classes), fixable via OSGi fragment. **Do not repeat this incorrect claim.**

### Decisions taken after audit

1. **Integration path:** Path A (Eclipse RCP embedding GeoGebra) — binding V2 requirement
2. **First target:** Windows x86_64 only. Linux/macOS after Windows proof
3. **jogl2 fix:** Fragment of `desktop` first; merge as fallback
4. **Bundle versions:** Mirror `5.4.934.0` initially
5. **Aggregate core bundle:** Acceptable fallback if individual bundles cause `uses` constraint issues
6. **First RCP proof criterion:** Full D-02/D-04/D-05 slice (panel + CAS + 3D), not just panel alone

---

## 5. Current state — what is in progress

### Phase 1a — D-02/D-04/D-05 RCP spike (assigned to Codex)

**Handoff delivered:** `02-Cdc/Codex_RCP_Product_Handoff_CLAUDE_V1.md`

This document tells Codex to build `03-RCP-Spike/` with:
- A new `org.geogebra.plus.host` bundle implementing `IApplication`
- SWT shell + `SWT_AWT.new_Frame` embedding `GeoGebraPanel`
- GIAC CAS eval (`Expand[(x+1)^2]`) and JOGL 3D point creation as native-loading proof
- Launch via direct Equinox with 50 resolved bundles + 9 native JARs on app-loader

**Codex has NOT yet started this work.** The handoff was committed on 2026-10-28 and is waiting for the user to assign it to Codex.

### What is NOT started

| Item | Depends on | Agent |
|---|---|---|
| D-02 through D-05 implementation | Codex receives handoff | Codex |
| W-01 web technology scored study | Can start in parallel | Claude |
| 5 contracts (activity, capability, compute, state, submission) | Can start in parallel | Claude |
| D-06–D-09 extension management | Gate B (D-02–D-06 all pass) | Codex |
| Debian replication | Windows D-02/D-04/D-05 pass | Grok Bot |
| Phase 2 vertical slice | Gates B + C | All |

---

## 6. Document map

### Source-of-truth order (per V2 §2)

1. `02-Cdc/Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` — 45 scenarios, 5 gates, 4 phases
2. `02-Cdc/Decisions_Architecture_ALF_GROK_V1_3.md` — closed primary decisions
3. `02-Cdc/Decisions_Architecture_ALF_GROK_V1.2.md` — expanded owner requirements
4. Code in pinned checkout when documents disagree with it

### Audit results (all under `02-Cdc/`)

| File | Content |
|---|---|
| `Audit_A_Package_Ownership_CODEX_V1.md` + `.tsv` | 385 packages, 1 real split |
| `Audit_B_Module_Dependencies_CODEX_V1.md` | 12 production modules, 39 external deps |
| `Audit_B_Desktop_Runtime_Gradle_Raw_CODEX_V1.txt` | Full Gradle dependency tree |
| `Audit_B_Runtime_Artifacts_CODEX_V1.txt` | Resolved artifact paths |
| `Audit_C_OSGi_Wrapping_CODEX_V1.md` | 14 Bnd recipes, wrapping analysis |
| `Audit_D_Path_Comparison_CODEX_V1.md` | Path A vs B scored matrix |
| `Audit_E_Test_Baseline_CODEX_V1.md` | 7615 tests pass |
| `Bnd_Equinox_Resolution_Win64/` | 50 bundle JARs, resolution log, manifest summary, artifact disposition |
| `osgi-manifest-drafts/` | 14 `.bnd` recipe files |

### Handoffs

| File | From → To | Status |
|---|---|---|
| `.claude/handoff_GGB_CODEX_v1.md` | Grok → Codex (via Claude) | Superseded by CLAUDE audit handoff |
| `02-Cdc/Codex_Audit_GeoGebra_Eclipse_Integration_CLAUDE_V1.md` | Claude → Codex | COMPLETED (V1_1) |
| `02-Cdc/Codex_RCP_Product_Handoff_CLAUDE_V1.md` | Claude → Codex | DELIVERED, awaiting execution |
| `.claude/handoff_Claude_GeoGebraPlus_CLAUDE_V1.md` | Claude → Claude | THIS FILE |

### Scripts (under `.claude/`)

| Script | Purpose |
|---|---|
| `audit_package_ownership.py` | Scans Java source tree for package declarations and splits |
| `dump_runtime_artifacts.init.gradle` | Gradle init script to dump resolved runtime artifact paths |
| `generate_osgi_manifest_drafts.py` | Generates `.bnd` recipes from package ownership scan |
| `prepare_bnd_resolution.py` | Builds bundle JARs with Bnd CLI and stages for resolution |
| `summarize_bnd_manifests.py` | Extracts export/import counts from generated manifests |

---

## 7. Binding constraints (NEVER violate)

1. **`source/shared/common/src` is untouchable.** No edits, no split, no fork. If a gate needs a change inside `common`, **stop** — the only allowed outcomes are: change the host, revise the no-fork rule in a new decision file, or cut scope.
2. **Never push to any remote** without explicit user request.
3. **Never commit to `main`/`master`** — create a feature branch.
4. **Never modify the Eclipse IDE installation** at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse`.
5. **OSGi metadata goes in new files only**, never in upstream source JARs.
6. **Native classifier jars stay on the application loader** per V2. No `Bundle-NativeCode` on the first spike.
7. **Each file you create/modify gets a `CLAUDE_V<x>` marker** per global CLAUDE.md §1.
8. **Commit after each coherent change** with clear message and `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` (or your model's attribution line).

---

## 8. V2 scenario status (45 total)

### Passed (2)

| Scenario | Evidence |
|---|---|
| D-03 | 50/50 Equinox resolution, `equinox-resolution.log` |
| (E/A/B/C/D audit tasks) | Not V2 scenarios per se, but Phase 0 audit tasks all completed |

### Partial (1)

| Scenario | Status |
|---|---|
| P-08 | Pin known (`375db7faf54`, `5.4.934.0`), official acceptance tag not chosen |

### Next up (3) — awaiting Codex D-02/D-04/D-05

| Scenario | What it proves |
|---|---|
| D-02 | RCP starts on jar set with no `common` edit |
| D-04 | Swing GeoGebra inside RCP shell (focus, menus, clipboard, DPI) |
| D-05 | CAS (GIAC) and 3D (JOGL) native loading under Equinox |

### Not run (39)

All remaining P, D (01, 06–10), W (01–08), X (01–07), S (01–07), O (01–05) scenarios.

### Gates

| Gate | Requirement | Status |
|---|---|---|
| A | P-02–P-05 exist for desktop build and GWT war | NOT MET |
| B | **D-02–D-06 pass, natives load, no `common` diff** | IN PROGRESS (D-03 done) |
| C | W-01 scored, GWT stays until W-02 passes | NOT STARTED |
| D | X-01–06 + S-01–05 on both hosts for 1 schema + 1 algorithm | NOT STARTED |
| E | O-02, O-03, D-09, W-04 pass (security, license, SBOM) | NOT STARTED |

---

## 9. Key technical facts to remember

### GeoGebra source (commit `375db7faf54`)

- **12 production desktop modules** (not 14): `common`, `common-jre`, `canvas-base`, `renderer-base`, `editor-base`, `keyboard-base`, `giac-jni`, `desktop`, `canvas-desktop`, `editor-desktop`, `renderer-desktop`, `jogl2`
- `keyboard-scientific`, `ggbjdk`, `xr-base` are test-only or unused
- **1 real split package:** `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` across `desktop` (5 classes) and `jogl2` (3 classes)
- **Vendored in `common`:** 69 files (JUNG + QuickHull3D) — keep private, never export as API
- **Entry point:** `GeoGebraPanel` is a public `JPanel` with public no-arg constructor, requires `buildGUI()` after construction
- **Main class:** `GeoGebra3D.main()` delegates to `GeoGebraFrame3D`
- **GIAC native loading:** `NativeLibClassPathLoader.loadLibrary()` uses `ClassLoader.getSystemResourceAsStream(filename)` → extract to temp → `System.load()`. Fallback: `System.loadLibrary(file)`
- **JOGL native loading:** `desktop/build.gradle.kts` lines 84–106 copy native JARs alongside API JARs; JogAmp's own extractor needs unmodified JARs in a common directory
- **License:** EUPL 1.2 for source, non-commercial for the overall package. NOT GPLv3 (Gemini's brief was wrong)
- **Build JDK:** Gradle uses JDK 21 (Adoptium), `:desktop:run` uses Java 25 toolchain
- **JVM args:** `--add-exports java.base/java.lang=ALL-UNNAMED`, `--add-exports java.desktop/sun.awt=ALL-UNNAMED`, `--add-exports java.desktop/sun.java2d=ALL-UNNAMED`, `--enable-native-access=ALL-UNNAMED`

### Eclipse installation (`D:\ALF_ZGit\G2_Eclipse\01_src\eclipse`)

- Eclipse IDE 2026-09, platform 4.41.0
- Equinox 3.24.300, SWT 3.135.0, Launcher 1.8.0
- JustJ Java 25.0.4
- Product: `org.eclipse.epp.package.java.product`
- **Read-only** — do not modify

### Resolved bundle set

- 50 bundles total: 12 GeoGebra + 34 Bnd-wrapped external + 4 existing OSGi (SpotBugs, JSR-305, JNA, JSpecify)
- 9 native JARs excluded from bundles (app-loader): 3 JOGL + 3 GlueGen + 3 GIAC per-platform
- `com.apple.eio` import marked optional on desktop bundle (macOS-only reflective fallback)
- jogl2 is a fragment of desktop: `Fragment-Host: org.geogebra.migration.desktop;bundle-version="[5.4.934,5.4.935)"`
- BSN namespace: `org.geogebra.migration.*` (not pretending to be upstream)

---

## 10. What you should do next (priority order)

### If Codex has NOT yet reported D-02/D-04/D-05 results:

1. **If the user asks you to start W-01 or contracts:** proceed — these are parallel work in Phase 1b
2. **If the user pastes Codex's D-02/D-04/D-05 report:** read all evidence files, update CLAUDE.md (V3→V4), update scenario statuses, update memory, commit

### If Codex reports D-02/D-04/D-05 results:

1. Read every evidence file Codex produced
2. Verify no `source/shared/common/src` diff: `git -C D:\ALF_ZGit\G1_Geogebra_Migration diff HEAD -- source/shared/common/src`
3. Check evidence completeness per V2 §9: date, commit, VERSION_STRING, OS, Java, bundle set hash, command, expected, actual, log path
4. If D-04 fails (SWT_AWT embedding): analyze whether it's a fixable integration issue or a gate failure requiring owner decision
5. If D-05 fails (native loading): check whether native JARs were correctly placed on the app-loader classpath, whether GIAC's `getSystemResourceAsStream` could see them
6. Update CLAUDE.md with new scenario statuses
7. If D-02 through D-05 all pass, prepare next handoffs:
   - D-06–D-09 (extension bundle management) for Codex
   - Grok Bot handoff for Debian D-02/D-04/D-05 replication
   - Begin W-01 (web technology scored study)
   - Begin contract specs

### Parallel work you can do anytime:

- **W-01:** Score Java-to-web (TeaVM, CheerpJ, GWT retention, JS/TS rewrite) against CAS, algebra, spreadsheet, 2D, 3D. Written matrix: fidelity, build, CAS support, 3D support, license, maintenance burden
- **5 contracts:** Activity manifest, capability descriptor, external computation, state adapter, submission. Declarative specs per V2 §4. These are your deliverables — don't delegate them

---

## 11. Files you should read first

When starting a new session on this project, read in this order:

1. `CLAUDE.md` (project root) — always loaded, but verify it's the latest version
2. This handoff file — for context beyond what CLAUDE.md covers
3. `02-Cdc/Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` — the 45 scenarios and gates
4. The most recent Codex delivery (whatever the user pastes or points to)

**Do NOT re-read** the full audit files (A through E) unless you need a specific fact. Their key findings are summarized in CLAUDE.md V3 and in this handoff.

---

## 12. Common pitfalls to avoid

1. **Don't claim `org.geogebra.common` is split.** It's not. Only `org.geogebra.desktop.geogebra3D.euclidian3D.opengl` is split. I made this mistake initially from directory-level `find` matching.
2. **Don't say 14 production modules.** It's 12. `keyboard-scientific`, `ggbjdk`, `xr-base` are not in the desktop runtime graph.
3. **Don't say the license is GPLv3.** It's EUPL 1.2 for the source. The Gemini brief was wrong.
4. **Don't claim scenarios PASS without linked evidence** per V2 §9.
5. **Don't write migration code yourself.** That's Codex's lane. Your job is specs and audit.
6. **Don't propose changes to `common`.** If something needs `common` to change, stop and escalate.
7. **Don't use PDE** (Plugin Development Environment) for the spike. Direct Equinox launch with explicit bundle installation.
8. **Don't create E4 workbench artifacts.** The spike uses a plain `IApplication` with a raw SWT shell.

---

## 13. Memory files

Persistent memory is at `C:\Users\Shadow\.claude\projects\D--ALF-Agents-43-wims-paris-saclay-fr--claude\memory\`. The index is `MEMORY.md` (9 entries). Key entries:

| File | What it remembers |
|---|---|
| `user_role.md` | User profile, technical skills, work style |
| `project_ecosystem.md` | Three-project pipeline and how they connect |
| `geogebraplus_architecture.md` | V2 plan summary, D-03 PASS, decisions |
| `tool_split.md` | Jupyter vs GeoGebraPlus vs WIMS boundaries |
| `dev_organization.md` | Agent roles and risk-minimizing principle |
| `codex_audit_results.md` | Full audit + resolution summary |
| `project_locations.md` | Workspace paths |
| `oef_interpreter.md` | Python OEF interpreter as the bridge |
| `wims4win.md` | Private repo reference, 24/24 tests |

Update these when facts change. Don't duplicate what's already in CLAUDE.md.

---

## 14. Published artifacts

| Artifact | URL | Content |
|---|---|---|
| GeoGebraPlus Planning | `https://claude.ai/artifact/GmZVX9sLcnTJ9Re3xmTSwL` | Interactive planning page — 45 scenarios, 4 phases, agent assignments, gate dependencies, current status |

This artifact should be updated when scenario statuses change.

---

## 15. Related project: wims4win

The user also works on `io-e/wims4win` (private GitHub), a WIMS Windows port at `D:\ALF_ZGit\02-wims4win`. Branch `feat/oef-python-fixes` has Claude edits to `tools/oef-validation/v2/oef2wims_v2.c`. 24/24 tests pass. GitHub issues #7 and #9 have Claude comments. This is a separate project but the same user — context for when they mention WIMS or oef2wims work.
