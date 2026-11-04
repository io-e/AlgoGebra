<!-- GROK_V1 -->
# Actions — Codex + Grok Bot after CDC V2 / Schema V1_2 (`09302b2`)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_Codex_GrokBot_After_CDC_V2_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Tip | `feat/grok-sprint3-plan-v1-1` @ **`09302b2`** |
| Trigger | Claude post-audit fold-in: WIMS CDC **V2**, Engines CDC **V1_3**, Course schema **V1_2**, help/example `giac`→`geogebra-cas` |
| Constraints | **No merge**, no force-push, no `common` edits, #48/#33 paused |
| Prior GBot queue | `Actions_GrokBot_After_EE_P2_GROK_V1.md` (G-B1..G-B7) — **still active**; this file **adds** unlocked work |

---

## Spec intake (agents: pull first)

| Artifact | Role |
|---|---|
| `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md` | Grading = `cmd=new`/`reply` + JSON hook; help = `\text{algogebra_help=…}`; exploration = Phase 2; GAP-6 frozen variants |
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` | Full Maxima illegal/illpart; **EE-P2d soft parity**; yacas/m2/scilab not planned; GAP Cygwin note |
| `Schema_Course_JSON_CLAUDE_V1_2.json` | 8 check types, `geogebra-cas`, `gradable`, `variants[]` |
| Help schema + example | `geogebra-cas` + help-link wording |
| Still authoritative | `Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`, `Decisions_PARI_Forbidden_GROK_V1_1.md` (**read***) |

### Known gap (do not wait on Claude to start)

Engines **V1_3** still cites BUG-006 **V1** only and lists `AGB_ILLEGAL` **without** `read` / `readvec` / `readstr`. Owner lock is **V1_1**. Codex implements V1_1; Claude can errata-cite later.

---

## Codex (Windows) — ordered

### P0 — continue / extend #60

| ID | Action | Done when |
|---|---|---|
| **C-B1** | Same as prior: **Gnuplot** multi-statement lines (`set grid; plot sin(x)`) | Fixture Gnuplot slice green on Windows |
| **C-B2** | Same as prior: add **`read`/`readvec`/`readstr`** to `AGB_ILLEGAL` per `Decisions_PARI_Forbidden_GROK_V1_1.md` | Unit + sandbox REJECT; #60 comment updated |
| **C-B3** | Twin Windows run of `ee_fixture_set_F_GROK_V1.json` (from #61) under **D-WIMS-T01 / EE-P2d V1_3** wording | Evidence path in #60 body |

### P1 — schema / converter consume (no merge)

| ID | Action | Done when |
|---|---|---|
| **C-B4** | Course / help fixtures: replace leftover `"giac"` with **`geogebra-cas`**; add at least one step using a new check type or `gradable:false` sample if cheap | Grep clean on Windows fixtures you own |
| **C-B5** | `oef2course_GROK_V1.py`: plan or small PR for Schema V1_2 emit (`variants[]`, `gradable`, engine id rename, `\text{algogebra_help=…}` → help link). Prefer **design note + failing tests** first if large | Note or draft PR; **no merge** |
| **C-B6** | Confirm Maxima filter in #60 already matches V1_3 full 16+6 lists (spec says yes) — one-line ack on #60 | Comment |

### Still paused

#48/#33, scanner beyond #60, WIMS L2-1 hook implementation, merges.

### Paste — Codex

> Pull `09302b2`. On #60: Gnuplot one-line fix + Pari `read*` (V1_1) + Windows twin of fixture F. Then schema consume: `geogebra-cas`, optional converter V1_2 plan. Engines V1_3 soft parity is the pass bar. **No merges.** See `Actions_Codex_GrokBot_After_CDC_V2_GROK_V1.md`.

---

## Grok Bot (Debian) — ordered

### P0 — keep G-B1..G-B3, plus newly unlocked

| ID | Action | Done when |
|---|---|---|
| **G-B1..G-B3** | Unchanged: watch #60 re-verify, open residual **review-only PR**, fixture inventory | As in After_EE_P2 brief |
| **G-C1** (**was G-A8**, now **owner-unlocked for design**) | Write a **design note only** (no code merge): rebase plan for #40–#42 mocks from fake `job=getresult` → CDC V2 **`cmd=new`/`reply` + `special_parm=algogebra_json`**. File under `02-Cdc/02-01_Wims_Integration/` as `Design_WIMS_Mock_Rebase_D_WIMS_G01_GROK_V1.md` on a docs branch or residual PR. **Do not change #40–#42 product code until owner says implement.** | Design MD + link on #34 / residual PR |
| **G-C2** (**was G-B8**) | Spot-check Debian GeoGebra CAS: `Derivative(...)` style command under label **`geogebra-cas`** (help example). Record PASS/FAIL + version | Note in residual report |

### P1

| ID | Action | Done when |
|---|---|---|
| **G-B4..G-B7** | Still valid (GAP blockers, `adm/raw` spot-check, suite 15, #49 ping) | As before |
| **G-C3** | Schema V1_2 dry-run: validate `courses/*.json` + one converted OEF against **new** schema (jsonschema). Expect additive OK; list any breaks | TSV of file → valid/invalid |
| **G-C4** | After Codex lands C-B2: confirm `read("/etc/hostname")` is **REJECT** on Debian Java (closes V1_1 loop) | Comment on #61 |

### Still idle / blocked

| Item | Wait for |
|---|---|
| Implement L2-1 JSON hook in wims4win / #40–#42 code | Owner “implement G-A8” |
| G-T2 / Playwright / D-11 / #48 | Prior gates |
| Merges | Owner |

### Paste — Grok Bot

> Pull `09302b2` (CDC V2 + Schema V1_2). Keep **G-B1..G-B3**. **New:** G-C1 design note for mock rebase to `cmd=new`/`reply`+JSON (no #40–#42 code yet); G-C2 `geogebra-cas` Derivative spot-check; G-C3 schema-validate courses. When #60 gets `read*`, G-C4 re-verify REJECT. **No merges.** Full list: `Actions_Codex_GrokBot_After_CDC_V2_GROK_V1.md`.

---

## Claude (not these agents — for #34 awareness)

| Item | Note |
|---|---|
| Cite `Decisions_PARI_Forbidden_GROK_V1_1.md` in Engines V1_3 `AGB_ILLEGAL` table | Small errata |
| Help schema header still says V1_1 in CDC Depends line | Cosmetic |
| Supersession banners on old V1 / V1_2 CDC files | If not already |

---

*End of `Actions_Codex_GrokBot_After_CDC_V2_GROK_V1.md`.*
