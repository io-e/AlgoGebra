<!-- CLAUDE_V1 -->
# Development plan — Phase 1b / Phase 2 roadmap

| Field | Value |
|---|---|
| Document | `02-Cdc/Plan_Development_Phase2_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Status | **Draft** — for owner review |
| Baseline | `77c994e`..`8508d00` on `feat/grok-sprint3-plan-v1-1` |

---

## 1. Current state

### Gates

| Gate | Status | Blocking items |
|---|---|---|
| **A** | NOT MET | P-02–P-05 corpus (desktop + GWT war evidence) |
| **B** | IN PROGRESS | D-06 (extension mgmt — Codex handoff ready) |
| **C** | IN PROGRESS | W-01 PASS. W-02 met once Gate A corpus exists |
| **D** | NOT STARTED | X-01–06 + S-01–05 need running code on both hosts |
| **E** | NOT STARTED | Security, license, SBOM |

### Specs delivered (Claude)

All 5 contracts + W-01 study + WIMS message integration. No spec work blocks code.

### Open actions (from CDC V2 §13)

| # | Action | Who | Status |
|---|---|---|---|
| WA-3 | Help template skeleton generator | Grok | Open |
| WA-4 | Fixture corpus (20 exercises) | Grok | Open |
| WA-5 | Encoding normalization (UTF-8) | Grok | Open |
| WA-7 | GAP engine implementation | Codex | Open (optional) |
| WA-8 | L2-1 JSON output hook on wims4win | Grok | Open — **Phase 2 blocker** |
| WA-9 | Rebase #40–#42 on hook protocol | Grok | Blocked by WA-8 |
| WA-10 | Converter: help, variants, new check types | Grok | Open |

---

## 2. Priority tracks

### Track 1 — Close Gate B (highest priority)

**Goal:** D-06 PASS → Gate B MET.

| Step | Who | Handoff | Deliverable |
|---|---|---|---|
| 1.1 | **Codex** | `Handoff_Codex_D06_Extension_Mgmt_CLAUDE_V1.md` | Extension bundle manager: allowlist, load, reject bad bundle, log |
| 1.2 | **Codex** | `Handoff_Codex_C3_OSGi_Service_Registration_CLAUDE_V1.md` | `ExternalComputeService` interface + `EngineRegistry` DS tracker |
| 1.3 | **Claude** | — | Review D-06 evidence, update CLAUDE.md, close Gate B |

**Depends on:** nothing. Handoffs ready.

### Track 2 — Close Gate A (parallel with Track 1)

**Goal:** P-02–P-05 corpus on commit `375db7faf54`.

| Step | Who | Deliverable |
|---|---|---|
| 2.1 | **Codex** | P-02: Algebra, CAS, Spreadsheet, 2D, 3D automated screenshots on desktop build |
| 2.2 | **Codex** | P-03: Standard tools — verify no missing tool vs pin |
| 2.3 | **Grok** | P-02/P-03 on GWT war (Debian, `web3d` module in browser) |
| 2.4 | **Codex** | P-04: Open, save, reopen `.ggb` — no silent loss |
| 2.5 | **Codex** | P-05: Scripts, macros, images, export — gap list |

**Depends on:** nothing. Existing desktop build + GWT war.
**Unlocks:** Gate A → Gate C (W-02 met by GWT baseline).

### Track 3 — MVP offline exercises (Phase 1b)

**Goal:** Student can open a course, navigate the tree, check answers offline.

| Step | Who | Deliverable |
|---|---|---|
| 3.1 | **Codex** | `Handoff_Codex_CourseModel_V1_2_CLAUDE_V1.md`: CourseModel V1_2 loader (variants, gradable, engine field, help link) |
| 3.2 | **Codex** | `CheckEvaluator`: 8 check types from WI-31 (`value_equals`, `choice_equals`, `sequence_equals`, `set_equals`, `engine_check`, etc.) |
| 3.3 | **Codex** | Help template loader + display in course tree panel |
| 3.4 | **Grok** | WA-10: converter updates (`--variants`, new check types, `\text{algogebra_help}`) |
| 3.5 | **Grok** | WA-4: fixture corpus (20 exercises, converted from OEF) |
| 3.6 | **Claude** | Review integration, update scenario status |

**Depends on:** Track 1 (extension manager needed for engine bundles).
**Unlocks:** Gate D scenarios (X-01–06 on desktop, one schema + one algorithm).

### Track 4 — Connected mode grading (Phase 2)

**Goal:** Student submits answers, WIMS grades, per-answer results displayed.

| Step | Who | Deliverable |
|---|---|---|
| 4.1 | **Grok** | **WA-8: L2-1 JSON output hook** in `scripts/oef` on wims4win — **critical path** |
| 4.2 | **Grok** | WA-9: Rebase #40–#42 mocks on `cmd=new/reply` + JSON hook |
| 4.3 | **Codex** | `HttpWimsClient` from `Spec_WIMS_Message_Integration_CLAUDE_V1.md` |
| 4.4 | **Codex** | Session management: `WimsSession` in `SessionState`, retry policy |
| 4.5 | **Grok** | End-to-end test: Debian wims4win + AlgoGebra → JSON grade |
| 4.6 | **Claude** | S-01–S-05 scenario evidence review |

**Depends on:** WA-8 (Grok). Codex can build the client against a mock, but real integration waits.
**Unlocks:** Gate D scenarios (S-01–S-05).

### Track 5 — Security & license (Gate E)

**Goal:** O-02, O-03, D-09, W-04.

| Step | Who | Deliverable |
|---|---|---|
| 5.1 | **Claude** | SBOM / component provenance inventory (EUPL 1.2 + deps) |
| 5.2 | **Claude** | O-02 security review: XSS, `.ggb` injection, command injection |
| 5.3 | **Codex** | D-09 implementation: unsigned/unapproved jar rejection |
| 5.4 | **Claude** | GPL v2 analysis for WIMS hook material (WI-R7) |
| 5.5 | **Claude** | W-04 web security spec (extension sandbox) |

**Depends on:** Tracks 1 + 3 (code must exist before security review).

---

## 3. Timeline estimate

```
Week 1-2:  Track 1 (Gate B) + Track 2 (Gate A) — parallel
              Codex: D-06, C-3, P-02..P-05
              Grok: P-02/P-03 on GWT war (Debian)

Week 3-4:  Track 3 (MVP offline) — depends on Gate B
              Codex: CourseModel V1_2, CheckEvaluator, Help loader
              Grok: converter updates, fixture corpus

Week 4-6:  Track 4 (connected mode) — depends on WA-8
              Grok: L2-1 JSON hook (critical path)
              Codex: HttpWimsClient (can start with mock)

Week 5-7:  Track 5 (Gate E) — starts once Tracks 1+3 have code
              Claude: SBOM, security review, GPL analysis
              Codex: D-09 unsigned jar rejection

Week 8:    Integration & scenario sweep
              All remaining NOT RUN scenarios executed
              Gate review: A through E
```

---

## 4. Codex queue (priority order)

| Priority | Handoff | Track |
|---|---|---|
| **P0** | C-B1..C-B3 (existing #60 work: Gnuplot, Pari `read*`, fixture twin) | Ongoing |
| **P1** | D-06 extension management | Track 1 |
| **P2** | C-3 OSGi service registration | Track 1 |
| **P3** | C-4/C-5/C-6 CourseModel V1_2 + CheckEvaluator + Help loader | Track 3 |
| **P4** | P-02..P-05 corpus evidence | Track 2 |
| **P5** | `HttpWimsClient` (can start against mock server) | Track 4 |
| **P6** | D-09 unsigned jar rejection | Track 5 |
| **P7** | WA-7 GAP engine (optional) | Track 3 |

## 5. Grok queue (priority order)

| Priority | Action | Track |
|---|---|---|
| **P0** | G-B1..G-B7, G-C1..G-C4 (current queue from CDC V2 actions) | Ongoing |
| **P1** | P-02/P-03 on GWT war (Debian browser test) | Track 2 |
| **P2** | WA-10 converter updates (variants, new checks, help) | Track 3 |
| **P3** | WA-4 fixture corpus (20 exercises) | Track 3 |
| **P4** | **WA-8 L2-1 JSON output hook** — Phase 2 critical path | Track 4 |
| **P5** | WA-9 rebase #40–#42 mocks | Track 4 |
| **P6** | WA-3 help template skeleton generator | Track 3 |
| **P7** | WA-5 encoding normalization | Track 3 |

## 6. Claude queue (priority order)

| Priority | Action | Track |
|---|---|---|
| **P0** | Small errata: cite `Decisions_PARI_Forbidden_GROK_V1_1.md` in engines V1_3 | Housekeeping |
| **P1** | Review D-06 evidence when Codex delivers, close Gate B | Track 1 |
| **P2** | Review Gate A corpus evidence | Track 2 |
| **P3** | Review Track 3 integration, update scenarios | Track 3 |
| **P4** | SBOM / component provenance inventory | Track 5 |
| **P5** | O-02 security review | Track 5 |
| **P6** | GPL v2 analysis for WIMS hook material | Track 5 |
| **P7** | W-04 web security spec | Track 5 |

---

## 7. Risk summary

| Risk | Impact | Mitigation |
|---|---|---|
| **WA-8 (L2-1 hook) delayed** | Phase 2 connected mode blocked | MVP is offline; Codex builds client against mock. Hook is a small patch, not a module. |
| **D-06 harder than expected** | Gate B delayed → Track 3 blocked | Fallback: aggregate core bundle (Codex audit decision #5). Extension boundary stays modular. |
| **P-02/P-03 corpus reveals regressions** | Gate A blocked | Regressions are against pinned build, not new code. Fix is a bug report + scope cut, not a code change. |
| **GPL v2 conflict with EUPL 1.2** | Distribution blocked | Hook is WIMS-side (GPL server), not AlgoGebra-side (EUPL client). If conflict: JSON hook ships as WIMS patch, not as part of AlgoGebra. |

---

*End of `Plan_Development_Phase2_CLAUDE_V1.md`.*
