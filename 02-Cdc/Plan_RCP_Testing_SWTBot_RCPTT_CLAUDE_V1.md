<!-- CLAUDE_V1 -->
# Plan — Hybrid RCP Testing Architecture: SWTBot + RCPTT

| Field | Value |
|---|---|
| Document | `02-Cdc/Plan_RCP_Testing_SWTBot_RCPTT_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-01 |
| Status | **DRAFT** — owner review required |
| Related | D-COURSE-01, Handoff V1_1 §4, D-04/D-05/D-11 scenarios |
| Product | GeoGebraPlus RCP (Equinox 3.24.300, SWT + embedded Swing) |

---

## 1. Rationale

The GeoGebraPlus RCP client embeds upstream GeoGebra Swing panels inside SWT shells via `SWT_AWT`. Testing needs span two levels:

- **Code-level** (SWTBot): bundle wiring, custom widget behavior, OSGi service contracts, `GgbAPI` calls — runs in the same JVM, sees internal classes.
- **Product-level** (RCPTT): end-to-end workflows against the packaged product — drives the UI externally, validates the assembled application as a user would.

Neither alone covers both levels. The hybrid avoids redundancy by enforcing a strict lane boundary.

---

## 2. Lane separation

| Concern | Framework | Why |
|---|---|---|
| OSGi bundle resolution / activation | SWTBot (JUnit) | Needs `BundleContext`, classloader introspection |
| `GgbAPI` command execution (evalCommand, evalCommandCAS) | SWTBot | Direct Java call, no UI required |
| Custom SWT widgets (`CourseTreePanel`, `StepValidator`) | SWTBot | Widget-level interaction, no product packaging |
| Equinox service wiring (`IApplication`, extension points) | SWTBot | Service registry assertions |
| Native loading (GIAC, JOGL, GlueGen) | SWTBot | `System.load` / classloader path verification |
| Full scenario D-04 (panel + resize + input) | RCPTT | End-to-end, compiled product, SWT+AWT bridge |
| Full scenario D-11 (course tree + step execution + CAS) | RCPTT | User workflow, `-Dggbplus.course` flag, tree navigation |
| Full scenario D-05 strict (3D + native visual) | RCPTT | Product assembly, screenshot evidence |
| Regression suite (focus transfer, clipboard, high-DPI) | RCPTT | Product-level, platform-specific |
| Smoke after product build | RCPTT | Black-box, no compile-time coupling |

**Rule:** Do not test in RCPTT what SWTBot already covers at the API level. Reserve RCPTT for user workflows and final assembly only.

---

## 3. Architecture

```
CI / PowerShell orchestrator (Run_RCP_Tests_CLAUDE_V1.ps1)
│
├─ Phase 1: SWTBot (JUnit via Tycho Surefire)
│   ├─ Bundle resolution tests
│   ├─ GgbAPI integration tests
│   ├─ Widget unit tests (CourseTreePanel, etc.)
│   └─ Native loading tests
│       → JUnit XML results → results/<runid>/swtbot/
│
├─ Phase 2: RCPTT (AUT CLI)
│   ├─ D-04 panel embedding scenario
│   ├─ D-11 course tree scenario
│   ├─ D-05 native/3D scenario
│   └─ Regression scenarios
│       → RCPTT report → results/<runid>/rcptt/
│
└─ Phase 3: Evidence export
    ├─ Merge JUnit + RCPTT results
    ├─ Screenshots / traces
    └─ MANIFEST with commit, date, OS, Java
```

### 3.1 SWTBot setup

SWTBot tests live in a Tycho test fragment or test bundle:

```
03-RCP-Spike/host/tests/
  org.geogebraplus.tests.swtbot/
    META-INF/MANIFEST.MF     (Fragment-Host or Require-Bundle)
    src/
      org/geogebraplus/tests/
        BundleResolutionTest.java
        GgbApiCommandTest.java
        CourseTreePanelTest.java
        NativeLoadingTest.java
    pom.xml                   (Tycho test packaging)
```

**Key constraint:** The SWT_AWT bridge means some GeoGebra Swing components need an AWT thread. SWTBot's `SWTBotShell` can host embedded AWT frames, but tests that call `GeoGebraPanel` must run with display access (Xvfb on Linux, real display on Windows).

**Dependencies:**
- `org.eclipse.swtbot.swt.finder` ≥ 4.2.0
- `org.eclipse.swtbot.eclipse.finder` ≥ 4.2.0
- JUnit 5 (or JUnit 4 via `SWTBotJunit4ClassRunner`)
- Tycho Surefire Plugin ≥ 4.0.0

### 3.2 RCPTT setup

RCPTT tests drive the compiled product externally via the AUT (Application Under Test) protocol:

```
03-RCP-Spike/tests/rcptt/
  D-04_PanelEmbedding.test       (ECL script)
  D-11_CourseTree.test            (ECL script)
  D-05_NativeStrict.test          (ECL script)
  Regression_FocusClipboard.test  (ECL script)
  contexts/
    GeoGebraPlusAUT.ctx           (AUT launch config)
    CourseData.ctx                 (test data / course JSON)
  rcptt.properties
```

**AUT configuration:**
- Product: `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8`
- JVM args: `-Dggbplus.course=courses/trigonometry_intro.json` (for D-11)
- VM: Java 25 (same as spike)
- RCPTT runner: `rcptt.runner-2.5.x` CLI (headless)

**Dependencies:**
- RCPTT Runner CLI ≥ 2.5.5
- ECL Core
- No compile-time coupling to the product

### 3.3 Evidence requirements

Per project conventions, each test run must record:

| Field | Source |
|---|---|
| Date | Orchestrator timestamp |
| Commit | `git rev-parse --short HEAD` |
| OS | `[Environment]::OSVersion` |
| Java | `java -version` |
| Image | Product path |
| Fixture hash | SHA-256 of course JSON |
| Command | Exact invocation |
| Expected vs actual | From JUnit XML / RCPTT report |
| Log path | Under `results/<runid>/` |
| Screenshot | SWTBot `SWTBotShell.bot().captureScreenshot()` / RCPTT `take-screenshot` |

---

## 4. Scenario mapping

| Scenario | SWTBot test | RCPTT test | PS1 runner |
|---|---|---|---|
| D-02 (bundle start) | `BundleResolutionTest` | — | `S_D-02` existing |
| D-03 (bundle resolve) | `BundleResolutionTest` | — | `S_D-03` existing |
| D-04 (panel embed) | `CourseTreePanelTest` (widget) | `D-04_PanelEmbedding.test` (E2E) | Orchestrator |
| D-05 (natives) | `NativeLoadingTest` | `D-05_NativeStrict.test` | Orchestrator |
| D-11 (course tree desktop) | `GgbApiCommandTest` (API) | `D-11_CourseTree.test` (workflow) | Orchestrator + `S_D-11` |
| D-06 (extension mgmt) | Future | Future | — |

---

## 5. Orchestration model

The PowerShell orchestrator (`Run_RCP_Tests_CLAUDE_V1.ps1`) integrates with `Run_All_GROK_V1.ps1`:

- **Standalone mode:** `Run_RCP_Tests_CLAUDE_V1.ps1 -Phase SWTBot` or `-Phase RCPTT` or `-Phase All`
- **Aggregated mode:** `Run_All_GROK_V1.ps1 -Scenarios -Only 'D-04','D-11' -WithRcpTests`

The orchestrator:
1. Validates prerequisites (Java, product image, RCPTT runner)
2. Runs SWTBot via Maven/Tycho (`mvn verify -pl org.geogebraplus.tests.swtbot`)
3. If SWTBot passes, launches RCPTT AUT and runs ECL scripts
4. Collects results into unified TAP + CSV output
5. Exports evidence with MANIFEST

---

## 6. Integration with existing test harness

The existing `Run_All_GROK_V1.ps1` uses TAP output, per-suite CSV, and evidence export with SHA-256 manifests. The RCP test orchestrator must:

- Emit TAP lines (`ok N - [P0] description` / `not ok N - ...`)
- Write `PASS: N FAIL: N SKIP: N` summary
- Exit 0 (pass), 1 (fail), 2 (bail)
- Support `$env:RESULTS_DIR` for result placement
- Support `-ExportEvidence` via the parent runner

JUnit XML from SWTBot is converted to TAP by the orchestrator. RCPTT report XML follows the same conversion.

---

## 7. Phased delivery

| Phase | Deliverable | Blocked by |
|---|---|---|
| **P1 (now)** | This spec + PS1 orchestrator skeleton | — |
| **P2** | SWTBot test bundle scaffold (MANIFEST.MF, pom.xml, empty test classes) | Codex WP2-06 (CourseTreePanel) |
| **P3** | RCPTT AUT context + D-11 ECL script | Product image with course tree |
| **P4** | CI wiring (GitHub Actions or local cron) | P2 + P3 passing |

---

## 8. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| SWT_AWT bridge instability in SWTBot | SWTBot tests hang on AWT thread | Xvfb on Linux; `-DforkCount=1` in Tycho; timeout per test |
| RCPTT version incompatibility with Equinox 3.24 | AUT fails to inject | Pin RCPTT 2.5.5+; test AUT handshake before writing ECL |
| Java 25 not supported by RCPTT | AUT launch failure | Fallback: Java 21 for RCPTT runs; keep Java 25 for SWTBot |
| Duplicate coverage wastes maintenance | Tests rot | Lane boundary enforced by code review; each test class documents its lane |
| GeoGebra Swing components block SWTBot event thread | Deadlock | Run Swing-touching tests in separate `@SWTBotTest` with `asyncExec` |

---

## 9. Open questions for owner

| # | Question |
|---|---|
| RQ-1 | Accept Java 21 fallback for RCPTT if Java 25 AUT injection fails? |
| RQ-2 | Should SWTBot tests live in `03-RCP-Spike/host/tests/` or a top-level `tests/` directory? |
| RQ-3 | RCPTT runner: download per-run (CI) or pre-installed (developer workstation)? |

---

*End of `Plan_RCP_Testing_SWTBot_RCPTT_CLAUDE_V1.md`.*
