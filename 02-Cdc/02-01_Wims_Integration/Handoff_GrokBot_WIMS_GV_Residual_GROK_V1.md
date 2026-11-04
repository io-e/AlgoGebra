<!-- GROK_V1 -->
# Handoff to Grok Bot — WIMS GV residual (Debian / live runtime)

| Field | Value |
|---|---|
| From | Grok (Windows / Grok Build) |
| To | **Grok Bot** (Debian VM + WIMS runtime lane) |
| Date | 2026-11-04 |
| Branch | `feat/grok-sprint3-plan-v1-1` @ `c90e7f4` |
| Already done (desktop) | `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` |
| CDC | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (`db5222f`) |
| Impl audit | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (`556749b`) |
| Policy | Validation only — **no merges**, no schema edits, no settle of S-01/S-02, leave #40–#42 parked |

---

## Why this handoff

Grok closed **GV-1..GV-7 from source inspection + Windows evidence + existing Debian TAP archives**. Several checks still need **your** lane: live Debian `wims-full` / CGI smoke, corpus fidelity metrics beyond schema-valid, and confirmation on tip.

Do **not** re-do the whole checklist. Confirm or refute the residuals below. Reply with a short Markdown report (suggested name at the end).

---

## Status already closed on desktop (read, do not redo)

| ID | Desktop result | Where |
|---|---|---|
| GV-1 (source) | Stock CGI = `module=` + **`cmd=`** (`intro/new/reply/hint/help/…`). **`job=getresult` absent** from `commands[]` | `Validation_…` §GV-1 |
| GV-2 | Suites 21–23 = **local mock** only; OK vs offline-first | same §GV-2 |
| GV-3 (partial) | Suite 19 fixtures PASS; archive corpus300 = 300/300 schema-valid; **GAP-5 ranked #1** | same §GV-3 + `evidence/20261102-054819-g06-oef-converter-debian/` |
| GV-4 / GV-6 (sample) | `\hint`, `\feedback`, `\help`, `\solution`, `\steps` exist; no stock `\help{*.json}` | same |
| GV-5 (Windows docs) | Laragon conf + Reprise `wims-runtime*` documented | same §GV-5 |
| GV-7 | No upstream resolution-process JSON | same §GV-7 |

---

## Residuals for Grok Bot (do these)

### GB-R1 — Live CGI probe (closes GV-1 runtime half) — **P0**

**Question:** On a real Debian WIMS tree (`wims-full` or institutional-equivalent), does anything accept D-S01’s shape?

```text
POST …/wims.cgi
  module=adm/class/sheet
  &job=getresult
  &exercise=<id>
  &ans1=<payload>
```

**Do:**

1. Confirm whether `public_html/modules/adm/class/sheet` (or sibling) exists in your `wims-full` / runtime.
2. Grep module sources for `getresult` / `job=` handling (expect: **none** or only AlgoGebra-invented).
3. Optional smoke: one POST to local `wims.cgi` with `cmd=intro` + a known `module=` (stock path) — expect **HTML**.
4. Optional negative: same POST with `job=getresult` — record status/body class (HTML error vs 400 vs ignore).

**Done when:** short table: path exists Y/N; `getresult` found Y/N; stock `cmd=intro` returns HTML Y/N; D-S01 POST behaviour one line.

**Expected (desktop hypothesis):** adapter still required; stock returns HTML; `job=getresult` not implemented.

---

### GB-R2 — Suite 19 on tip + fidelity metrics (closes GV-3 runtime half) — **P0**

Archive already has schema-valid 300/300 (2026-11-02). Need **tip** + **fidelity**, not only schema.

**Do:**

```powershell
# From AlgoGebra tip (feat/grok-sprint3-plan-v1-1 or main tip if instructed)
$env:OEF_CORPUS = '<path-to-corpus-list-or-dir>'   # reuse corpus_list_GROK_V1.txt if still valid
pwsh -File 03-RCP-Spike/tests/19_Test_OefConverter_GROK_V1.ps1
```

Then, on the 300 outputs (or a 50-file stratified sample if time-boxed), count:

| Metric | How |
|---|---|
| `check.type == value_equals` | numeric fidelity |
| `check.type == object_exists` | **GAP-5 degradation** |
| steps whose `description` contains `Hint:` | GAP-1 flat hint |
| steps with `"engine"` key present | GAP-2 (expect ~0 until converter emits V1_1) |
| convert failures / warnings mentioning `not numeric` | log scrape |

**Done when:** TAP + one TSV/CSV of the counts; state whether GAP-5 still #1 on tip.

---

### GB-R3 — GAP-2 engine signals in corpus — **P1**

Desktop did not quantify how many OEF files imply a named CAS.

**Do:** on the same corpus 300 (or Amato + certified banks if corpus paths broke):

```bash
# illustrative — adapt to your tree
rg -l 'wims\(|\\pari|\\maxima|gp -f|maxima|gap\.|octave' --glob '*.oef' | wc -l
```

Also note any OEF metadata / module `INDEX` that names an engine.

**Done when:** count of files with CAS/engine hints + 3 example paths; whether an `engine` field on steps is justified for MVP offline help.

---

### GB-R4 — Suites 21–23 still green on Debian mock — **P1**

Branches: `feat/grok-g14-wims-template`, `feat/grok-g15-wims-grade-client`, `feat/grok-g16-wims-full-cycle` (or cherry-pick onto tip if those branches are stale).

**Do:** run 21 + 22 (23 if Playwright/Firefox + `GGB_WAR_DIR` available). Keep using **mock** CGI — do not point at real WIMS until L2-1 exists.

**Done when:** TAP paths + PASS/FAIL/SKIP; note if tip drift broke templates.

---

### GB-R5 — Debian HTTP WIMS (GV-5 Linux twin) — **P1**

Windows Laragon path is documented. Confirm **your** Debian service:

1. URL that serves `wims.cgi` (e.g. `http://127.0.0.1/wims/wims.cgi` or container URL).
2. One-line start procedure you actually use (apache2 / docker / existing grok-bot-vm setup).
3. Whether scoring/`wimslogd` is healthy enough for a later adapter test (or still partial).

**Done when:** URL + start commands + “scoring usable Y/N”.

---

### GB-R6 — Schema / example spot-check (from Claude’s earlier handoff, still open) — **P2**

Only if time remains after P0/P1:

| Check | File |
|---|---|
| Help `engine` enum vs engines you install on Debian | `Schema_Help_Template_JSON_CLAUDE_V1.json` |
| Example `Derivative(…)` under GIAC on Debian GeoGebra/CAS | `Example_Help_Template_CLAUDE_V1.json` |
| Confirm `{{var}}` does not collide with OEF `\var` expansion in your oef2html path | practical note only |

---

## Out of scope

- Building the L2-1 JSON adapter (needs owner WA-1 first).
- Merging PRs #40–#42.
- Editing Claude schemas or the WIMS CDC (report only; Claude/owner apply).
- Claiming D-S01 works against stock CGI.

---

## Read first

1. `02-Cdc/02-01_Wims_Integration/Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` — desktop conclusions  
2. `02-Cdc/02-01_Wims_Integration/Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` — especially §5 WI-20..WI-24  
3. `02-Cdc/Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` — L1/L2 + filter notes  
4. Claude prior ask (context only): `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md`

---

## Expected deliverable

Create:

`02-Cdc/02-01_Wims_Integration/Validation_GrokBot_WIMS_GV_Residual_GROK_V1.md`

With:

1. Per residual **GB-R1..R6**: PASS / FAIL / PARTIAL / SKIP + evidence paths (date, host, command, log/TAP).  
2. Any **CDC correction** you recommend (especially `cmd=` vs `job=`).  
3. Whether desktop ranking “GAP-5 #1” still holds on tip.  
4. Blockers for L2-1 smoke on Debian (if any).

Reply channel: usual Grok Bot → owner / Grok session; no push to `main`.

---

*End of `Handoff_GrokBot_WIMS_GV_Residual_GROK_V1.md`.*
