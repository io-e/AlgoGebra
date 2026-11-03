<!-- CLAUDE_V1 -->
# Consolidated Review — External Engines + GIAC CDCs

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Consolidated_Review_Grok_Codex_CLAUDE_V1.md` |
| Date | 2026-11-03 |
| Inputs | Grok Bot PR #59 (`Review_Cdc_External_Engines_V1_1_GROK_V1.md`), Codex review at `63f2190`, Owner Q&A ALF_V2_3 |
| Branch | `feat/grok-sprint3-plan-v1-1` |

---

## 1. Agreed verdicts

| Document | Grok Bot | Codex | Consolidated |
|---|---|---|---|
| `Cdc_External_Engines_V1_1` | Validated with reservations | Conditionally accepted for subprocess design | **Accepted for engine layer; corrections needed before implementation contract** |
| `Cdc_External_Engines_V1` | — | Archive only | **Archive** (already in `00-00_archives/`) |
| `Cdc_GIAC_Integration_V1` | Not in scope | Useful reference, not normative | **Needs status update** |
| Help template schema | OK (after `$comment` fix) | Not reviewed | **Accepted** (`$comment` fix done in `619ac5d`) |
| Example JSON | Fail → fix | Not reviewed | **Fixed** (`619ac5d`) |

---

## 2. Action items — no owner decision needed

These are factual corrections both reviewers agree on. Claude applies them.

| # | Finding | Grok | Codex | Fix |
|---|---|---|---|---|
| **F-01** | PARI security filter incomplete | M-2: missing `system`, `extern`, `install`, `eval` | Same: align with `Decisions_PARI_Forbidden_GROK_V1.md` | Update §5.1 with full AGB_ILLEGAL list + "not a sandbox" note |
| **F-02** | Perl wrongly listed as runtime dependency | M-5 | Same: Python is the OEF converter | Correct §2: Perl is optional conversion tooling, not an RCP engine prerequisite |
| **F-03** | Q-W6 exploration fallback not reflected | M-1 | — | Add exception to §4.1/§4.3: grading = error, exploration = WIMS fallback with UI label |
| **F-04** | Missing references in §9 | m-6 | — | Add `Decisions_PARI_Forbidden`, QA ALF_V2, schemas, `Decision_Open_Points_Sprint3` |
| **F-05** | Phase 4 contradicts offline-first | B-2 | Same: mark Phase 4 deferred | Rename scope to "engine layer (offline subprocess)" + mark Phase 4 explicitly deferred |
| **F-06** | No requirement IDs / acceptance criteria | M-6 | Same: add done-when | Add `EE-xx` IDs and acceptance column for all phases |
| **F-07** | API boundary wrong (host bundle vs compute.api) | — | `org.geogebra.plus.compute.api` OSGi bundle exists | Correct §4.1: `ExternalComputeService` is in `compute.api` bundle |
| **F-08** | Open contract defects not reflected | — | X-01 partial, X-02 fail, X-06 fail (BUG-015) | Add failure/empty-output acceptance criteria; note X-01/X-02/X-06 status |
| **F-09** | Gnuplot filter incomplete | m-2 | — | Block `set output`, `set print`, `load`, `call`, `save`, backticks |
| **F-10** | PARI test expects post-parser output | m-1 | Same: G-03 expected output | Pin gp version, say "after output parser", correct expected result format |
| **F-11** | No JVM stated | m-3 | — | State "Java 21 baseline (RQ-1); Java 25 tested on Windows" |
| **F-12** | Phase 2b provenance unspecified | m-4 | — | Name source (wims4win build or Debian package) and version |
| **F-13** | Q-W ID collision with #41 | m-5 | — | Rename #41 questions to `Q-GC1..4` before merge |
| **F-14** | GIAC CDC status outdated | — | D-GIAC-01 accepted, D-05 PASS | Update GIAC CDC status: loader accepted, D-05 native PASS |
| **F-15** | GIAC D-GIAC-02 alignment | — | Desktop-wrapper BundleActivator, not host reflection | Correct D-GIAC-02 description |
| **F-16** | GIAC loader explanation wrong | — | Native JARs on app classpath, not inside OSGi bundle | Correct §2.3 |
| **F-17** | GIAC G-03 expected output | — | `x^2+2x+1` not `x^2+2*x+1` | Fix expected output string |
| **F-18** | GIAC D-05 separation from open work | — | G-02, G-05, G-06 still open | Separate D-05 PASS from remaining production tasks |

---

## 3. Owner decisions needed

| # | Question | Grok | Codex | Options |
|---|---|---|---|---|
| **OD-1** | Scope: engine-only V1_1 + separate WIMS CDC, or fold Q-W into V1_2? | Q1: separate recommended | Same: do not treat as WIMS contract | **A.** Keep V1_1 as engine-only, write `Cdc_WIMS_Integration` separately (recommended) **B.** Fold into V1_2 |
| **OD-2** | Local engines supersede "engines only on WIMS server"? | M-3: Grok's own doc contradicts V1_1 | — | **A.** Confirm: local subprocess (Q-W2 offline-first) supersedes `Decisions_GIAC_Complet_WIMS §1` (recommended) **B.** Keep server-only |
| **OD-3** | PRs #40–#42: park as Phase 2, or reshape for per-answer results now? | M-4: single grade vs per-answer | Same: S-01/S-02 NOT RUN, WIMS parked | **A.** Park as Phase 2 (recommended) **B.** Reshape G-15 now |
| **OD-4** | GPL v2 obligations for WIMS-derived filter tables? | m-7: no risk row | Same: O-02 failed, license review pending | **A.** Accept GPL v2 for derived tables **B.** Rewrite filters from scratch **C.** Defer to O-02 Gate E (recommended) |

---

## 4. Owner decisions — CLOSED (2026-11-03)

| # | Decision | Owner answer |
|---|---|---|
| **OD-1** | Separate CDCs (engine-only V1_2 + WIMS CDC) | **Accepted.** Test files will be written manually. |
| **OD-2** | Local engines supersede server-only | **Yes.** Supersedes `Decisions_GIAC_Complet_WIMS §1`. |
| **OD-3** | Park PRs #40–#42 as Phase 2 | **Accepted.** Connected mode deferred. |
| **OD-4** | GPL v2 obligations for WIMS-derived filter tables | **Deferred to Gate E (O-02).** Do not distribute until license inventory is complete. |

## 5. Summary

- **18 factual fixes** (F-01..F-18): applied in `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` and `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` (bumped to V1_1)
- **4 owner decisions** (OD-1..OD-4): all closed (2026-11-03)
- **Both reviewers agree** the engine architecture is sound; the gaps are in WIMS integration scope, security filter completeness, and status accuracy

---

*End of `Consolidated_Review_Grok_Codex_CLAUDE_V1.md`.*
