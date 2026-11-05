<!-- GROK_V1 -->
# Handoff — GBot tasks for AlgoGebra × WIMS integration (Debian)

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-05 |
| For | **Grok Bot** (Debian VM + WIMS HTTP / wims4win cross-check) |
| From | Grok Build (Windows) |
| Trigger | WA-8 Windows JSON hook prototype **done** (`wims4win` `bb929e3`) — Debian lane is now useful |
| Policy | Validation + packaging evidence — **no merges**, no force-push, no `common` edits |
| Canonical CDC | `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md` |
| Protocol | `Spec_WIMS_Message_Integration_GROK_V1_1.md` |
| WA-9 client brief | `Handoff_WA9_Mock_Rebase_GROK_V1.md` (Codex primary; GBot assists with live suites) |
| WIMS hook sources | `D:\ALF_ZGit\02-wims4win\AlgoGebra_Wims_Integration\` (or GitHub `io-e/wims4win` branch `feat/algogebra-wims-integration`) |

---

## 0. Context (read once)

| Already done (Windows) | Residual for Debian / GBot |
|---|---|
| Discovery 00006 + 00076 | Same exercises on Linux CGI |
| `answer.phtml` + `algogebra_json.phtml` hook | Install hook into Debian `wims-full` / runtime tree |
| Smoke test PASS | Cross-parity: same JSON schema, grades match |
| Docs CDC GROK_V2_2 + Spec GROK_V1_1 | Suites 21–23 vs **real** Debian WIMS (not only mocks) |

**Role split (Plan V2):** GBot = Debian verification, Linux parity, end-to-end on server. Do **not** re-implement the hook from scratch unless the Windows phtml fails under stock Linux WIMS.

**Wire rules (do not violate):**

1. Grade path = `cmd=new` → `cmd=reply` + `special_parm=algogebra_json` (**reply only**).
2. Form fields = `replyN` / `choiceN` (never invent `ansN`).
3. Extract `<!-- ALGOGEBRA_JSON_BEGIN … ALGOGEBRA_JSON_END -->`.
4. Primary grade is **not** `adm/raw` / `job=getresult`.

---

## 1. Priority board

### P0 — do now (unblock Debian parity)

| ID | Task | Done when | Est. |
|---|---|---|---|
| **GB-W1** | Checkout / pull `feat/algogebra-wims-integration` on the Debian box; confirm commit ≥ `bb929e3` and read `OEF_Variable_Map_GROK_V1.md` + `runtime_patch/` | Branch tip noted in report | 0.5 h |
| **GB-W2** | Install hook into the **live Debian WIMS** tree: copy `algogebra_json.phtml` → `public_html/scripts/oef/`; patch `answer.phtml` (same injection as Windows snippet). Keep a `.bak` | Files present; backup path recorded | 1 h |
| **GB-W3** | Live smoke on Debian HTTP (reuse GB-R5 URL pattern): `00006` wrong + right, `00076` wrong + right, with `special_parm=algogebra_json`; parse JSON; assert `grade` 0/1 and `id`=`reply1` | Evidence folder with raw HTML + extracted JSON + one-line PASS/FAIL table | 2 h |
| **GB-W4** | Negative test: same `cmd=reply` **without** `special_parm` → **no** `ALGOGEBRA_JSON_BEGIN` | Logged in same evidence pack | 0.5 h |

**Suggested evidence path:**  
`03-RCP-Spike/evidence/YYYYMMDD-gbot-algogebra-json-debian_GROK_V1/`

**Minimal commands (adapt paths):**

```bash
# After hook install — example using curl against local wims-full
# 1) cmd=new → capture session
# 2) cmd=reply&special_parm=algogebra_json&reply1=…
BASE='http://127.0.0.1:18431/wims/wims.cgi'   # replace with GB-R5 URL if different
# Prefer a small Python script mirroring wims4win tests/test_algogebra_json_GROK_V1.py
```

Port or run:

```text
AlgoGebra_Wims_Integration/tests/test_algogebra_json_GROK_V1.py
```

with `WIMS_HOME` / CGI pointing at the Debian tree (CGI may be `wims.cgi` without `.exe`; use `--cgi-prefix` only if wine).

---

### P1 — packaging + suite alignment

| ID | Task | Done when | Est. |
|---|---|---|---|
| **GB-W5** | Patch `tools/build-runtime-tree.sh` (wims4win) so a rebuilt runtime **always** includes `algogebra_json.phtml` + `answer.phtml` injection; dry-run or document the exact `cp`/`patch` lines | PR or branch commit on wims4win (draft OK); no merge required | 2–3 h |
| **GB-W6** | Linux object / template hygiene: confirm non-`_WIN32` C objects unchanged if any C was touched (hook is phtml-only → expect **N/A**); run `tools/check-linux-identical.sh` only if C changed | Note in report: “phtml-only, check skipped” or check PASS | 0.5 h |
| **GB-W7** | Re-run AlgoGebra suites **21–23** against **Debian WIMS + hook** (not mock). Keep mocks green separately. Record TAP + which cases need WA-9 client updates (`replyN`, JSON extract) | TAP paths + short gap list for Codex | 3 h |
| **GB-W8** | Encoding spot-check: page `charset=windows-1252` (or server default); JSON block ASCII-parseable; one exercise with accented feedback/name if available | Note charset + any `\u` / mojibake | 1 h |

---

### P2 — end-to-end / optional

| ID | Task | Done when | Est. |
|---|---|---|---|
| **GB-W9** | Track E twin: full student path on Debian (new → answer → reply+hook → extract → display grade in a tiny script or existing JS harness) | Short demo script + screenshot or log | 1 d |
| **GB-W10** | True `\choice` exercise (`choicecnt>0`) if present in corpus — confirm `choiceN` appears in JSON | One PASS case or “none in corpus” | 2 h |
| **GB-W11** | Assist Codex WA-9: provide mock fixtures recorded from **real** Debian JSON blocks (wrong/right × 00006/00076) for CI | Fixture files under agreed `03-RCP-Spike/…/fixtures/` | 2 h |
| **GB-W12** | Optional: refresh older **G-A6 / GB-R5** URL note if port/path changed after hook install | One paragraph in residual report | 0.5 h |

---

## 2. Explicit non-goals (do not do)

| ID | Rule |
|---|---|
| **GB-X1** | Do not merge PRs (#40–#42, #60, #61, wims4win) without owner OK |
| **GB-X2** | Do not redesign the hook as `adm/raw` / new `cmd=` |
| **GB-X3** | Do not send `special_parm=algogebra_json` on `cmd=new` |
| **GB-X4** | Do not edit GeoGebra `common` |
| **GB-X5** | Do not block on Gate E / EUPL counsel — file provenance notes only if easy |
| **GB-X6** | Do not replace Codex WA-9 product rebase — GBot supplies **live evidence + fixtures** |

---

## 3. Deliverable — report template

Create:

`02-Cdc/02-01_Wims_Integration/Report_GBot_AlgoGebra_JSON_Debian_GROK_V1.md`

Suggested sections:

1. Environment (Debian image, WIMS version, HTTP URL, hook install paths)  
2. GB-W1…W4 results table (exercise / given / grade / JSON ok)  
3. Diffs vs Windows smoke (`bb929e3` expectations)  
4. GB-W5…W8 status  
5. Blockers for Codex WA-9  
6. Commands to reproduce  

---

## 4. Paste brief — Grok Bot

> **P0:** Install AlgoGebra JSON hook (`algogebra_json.phtml` + `answer.phtml` injection) on Debian WIMS; smoke 00006/00076 wrong+right with `cmd=reply&special_parm=algogebra_json`; prove no leak without `special_parm`. Evidence under `03-RCP-Spike/evidence/…-gbot-algogebra-json-debian_GROK_V1/`.  
> **P1:** Wire hook into `build-runtime-tree.sh`; run suites 21–23 vs live Debian+hook; charset note.  
> **P2:** E2E demo script; optional `\choice` case; export real JSON fixtures for Codex WA-9.  
> **Read:** `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md`, `Spec_WIMS_Message_Integration_GROK_V1_1.md`, `Handoff_WA9_Mock_Rebase_GROK_V1.md`, wims4win `AlgoGebra_Wims_Integration/`. **No merges.**

---

## 5. Charge estimate (Plan V2 alignment)

| Bucket | Plan V2 | This handoff |
|---|---|---|
| Track C Debian cross-check | ~1 j/h | **GB-W1…W4, W8** |
| Track E Debian E2E | ~2 j/h | **GB-W7, W9** |
| Packaging assist | (was Claude B3/D2) | **GB-W5** if Windows packaging deferred |
| **Total useful now** | ~3 j/h deferred | **~1.5–2.5 j/h P0+P1** to first green Debian report |

---

*End of `Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md`.*
