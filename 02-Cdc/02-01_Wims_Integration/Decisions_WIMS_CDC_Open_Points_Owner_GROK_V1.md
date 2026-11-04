<!-- GROK_V1 -->
# Owner decisions — WIMS CDC open points (Claude Q1–Q7)

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Status | **LOCKED** — owner validated Claude’s recommendations |
| Source session | Claude `52fc5689-54e8-4190-8248-047f8baac2d8` (`G1_Geogebra_Migration_CLAUDE_v02`) |
| Branch | `feat/grok-sprint3-plan-v1-1` |
| Related | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md`, `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md`, `QA_WIMS_Integration_Owner_ALF_V2.md`, `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` |

---

## How these were locked

Claude audited residual WIMS CDC / converter / engine gaps (labels A-01..A-32 in that session) and proposed seven answers. The owner validated those recommendations in the Grok resume session (2026-11-04). This file records them as binding for CDC fold-in.

**Not locked here:** push of local commit `47f6fbc` (`Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md`). That remains a separate owner action.

---

## Q1 — Grading design (A-01..A-03) → **D-WIMS-G01**

**Decision:** Stock OEF play path **`cmd=new` → `cmd=reply`**, plus a small WIMS-side **JSON output hook**.

| Item | Choice |
|---|---|
| Session create | `cmd=new` |
| Answer submit | `cmd=reply` |
| Machine-readable grade | JSON alongside HTML via a minimal patch, e.g. `special_parm=algogebra_json` in `scripts/oef` |
| Rejected for primary grade path | Relying on `adm/raw` alone for OEF evaluation context; `testexo` (compile-only); `getscore*` (aggregate stored scores only) |

**Rationale (Claude + Migration_Wims evidence):** `adm/raw` has no OEF evaluation context for a live student answer; `testexo` only compiles; `getscore*` only aggregates. The stock `new`/`reply` path is what WIMS uses for grading. A JSON hook is the least invasive way to feed AlgoGebra without inventing a new CGI `cmd=`.

**CDC fold-in:** Update WI-21 / WI-22 / WA-1 so the L2-1 adapter story is **OEF `new`/`reply` + JSON hook**, and reconcile with the validation note’s `adm/raw` findings (auth, JSON `!shortout`) as supporting machinery where useful, not as the primary OEF grade verb.

---

## Q2 — Help link (A-04) → **D-WIMS-H01**

**Decision:** Teacher links help with **`\text{algogebra_help=file.json}`** and a sidecar **`<exo>.help.json`**.

| Item | Choice |
|---|---|
| OEF marker | `\text{algogebra_help=<filename>.json}` |
| Artifact | Sidecar help JSON next to the exercise (schema: `Schema_Help_Template_JSON_CLAUDE_V1.json`) |
| Native `\help{}` | Maps to a **text** help node (no collision with the AlgoGebra JSON link) |

**CDC fold-in:** Converter emits the sidecar path into course/help linkage; document that stock `\help{}` stays text-only.

---

## Q3 — Exploration fallback (A-07) → **D-WIMS-E01**

**Decision:** **Phase 2** for remote exploration fallback. MVP shows an explicit **“engine missing — install guide”** error.

| Mode | Missing local engine |
|---|---|
| **MVP (offline)** | Hard error + install guide. No WIMS compute fallback. |
| **Phase 2 (connected)** | Exploration **may** call WIMS with UI label `remote computation` (existing Q-W6 intent). Grading still never falls back. |

**Note:** This **phases** Q-W6 / WI-24: the exploration exception is deferred until connected mode exists. MVP grading and exploration both fail closed when the binary is absent.

---

## Q4 — GAP-6 frozen variants (A-06) → **D-WIMS-C01**

**Decision:** **Yes.** Converter default **N=20** frozen variants with pre-evaluated `wims()` / `slib()` / `pari()` / `maxima()` parameters.

| Item | Choice |
|---|---|
| Default variant count | **20** |
| Parameter evaluation | At conversion time (deterministic seed), offline |
| Tradeoff | Answer keys ship in the offline package — accepted for offline-first MVP |

**CDC fold-in:** Document GAP-6 as accepted converter behavior; suite / fixture notes should expect frozen params, not live `wims()` at student runtime offline.

---

## Q5 — yacas / m2 / scilab (A-24) → **D-WIMS-E02**

**Decision:** Offline exercises that require these engines are **`gradable: false`** until an engine slice exists.

| Engines | Offline MVP |
|---|---|
| yacas, Macaulay2 (`m2`), scilab | No subprocess wrappers; mark non-gradable; do not block Pari/Maxima/Gnuplot/GAP path |

---

## Q6 — EE-P2d fixture acceptance (A-23) → **D-WIMS-T01**

**Decision:** Accept parity as **“values match, rejections at least as strict”** (not byte-identical stdout).

| Item | Choice |
|---|---|
| Fixture set F | Expand from the existing #61 cases toward **≥20 per engine** |
| Current thin spots | Maxima (~6), Gnuplot (~6), GAP (~3) need expansion; Pari (~12) needs more |
| Pass bar | Same numeric/symbolic values; illegal/rejected inputs rejected at least as strictly as WIMS C |

**CDC fold-in:** Soften EE-P2d “byte-identical” wording in the engines CDC to this acceptance bar when Claude revises V1_2 → next minor.

---

## Q7 — `giac` engine label (A-32) → **D-WIMS-L01**

**Decision:** Rename the course/help engine id **`giac` → `geogebra-cas`**.

| Item | Choice |
|---|---|
| Meaning | GeoGebra CAS syntax (e.g. `Derivative(...)`) routed through Ggb2giac |
| Not meaning | Raw GIAC CLI syntax (e.g. `diff(...)`) as if called outside GeoGebra |

**CDC fold-in:** Update `Schema_Course_JSON`, help schema engine enums, examples, and converter output to `geogebra-cas`. Keep GIAC as the native binary behind GeoGebra; the **label** is the student/teacher-facing engine id.

---

## Follow-ups (not decided in this file)

| ID | Action | Owner |
|---|---|---|
| F-1 | Fold Q1–Q7 into `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (WI-21/22/24, help link, converter) | Claude |
| F-2 | Soften EE-P2d byte-identical → D-WIMS-T01 bar in engines CDC | Claude |
| F-3 | Rename `giac` → `geogebra-cas` in schemas + example + converter | Claude / Grok |
| F-4 | Expand Maxima / Gnuplot / GAP fixtures toward ≥20 | Grok Bot / Codex |
| F-5 | Push `47f6fbc` validation note when owner asks | Owner / Grok |
| F-6 | Reconcile WA-1 options A–D in the validation note with **D-WIMS-G01** (new/reply + JSON hook) | Claude + Grok |

---

*End of `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`.*
