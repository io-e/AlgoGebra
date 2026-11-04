<!-- MIGRATION_WIMS_V1 -->
# Validation — WIMS Integration CDC (Migration_Wims lane)

| Field | Value |
|---|---|
| From | Grok Bot Migration_Wims (wims4win lane) |
| To | Owner (ALF); G1_Geogebra_Migration; Claude (who applies the spec corrections) |
| Request | `Handoff_Migration_Wims_CDC_Validation_GROK_V1.md` @ `322c723` |
| Targets | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (main), WIMS parts of `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md`, against `QA_WIMS_Integration_Owner_ALF_V2.md` |
| Policy | Validation only. No spec/schema edits; corrections are proposed below as text. No PR, no merge, no GitHub comments. |
| WIMS reference | Upstream SVN **r19040** (WIMS 4.33a) = base of wims4win, sources at `/tmp/svn/svn-r19040` on the box. Paths below are relative to that tree. |
| Runs | `oef2wims` run on the box (Linux binary from `/workspace/oefc/wims-runtime`, **WIMS 4.23c**; the directive parser cited below is unchanged in r19040). No live CGI run was done for this report; F-1/F-2 rely on the GV-1 probe plus source reading. |

---

## 0. Verdict

| CDC | Verdict |
|---|---|
| `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` | **Validated with reservations** — 4 blocking corrections (WI-20/22/23, WI-12, WI-31/GAP-5, WI-05/GAP-6), 3 major, 3 minor. The offline MVP architecture is sound. The connected-mode and help-link sections misdescribe what stock WIMS does. |
| `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` (WIMS parts) | **Validated with reservations** — engine list incomplete vs. `src/Interfaces/`, and the exploration fallback (EE §"Missing binary → WIMS fallback") has no stock WIMS endpoint to call. |

---

## 1. Findings F-1..F-9

| Ref | Result | Evidence |
|---|---|---|
| F-1 | **Confirmed, with a nuance.** The full `cmd=` set is 14 verbs, not 6: `intro, new, renew, reply, config, hint, help, resume, next, getins, getframe, getfile, close, ref` (`src/wims.c:288-290`). The 450 message lists only the user-facing subset. `job=` is not parsed by `wims.c`; each module reads it itself (e.g. `modules/adm/raw/var.proc:13-14`). A module **cannot** add a `cmd=` verb. 450 = `msg/user_error.phtml.*:1`. | source |
| F-2 | **Confirmed, with nuances.** `adm/raw` is a stock machine API: `job` is bound to whitelists (`var.proc:14`; `defs:17-33`). The JSON header is `Content-Type: application/json ; charset=iso-8859-1` (`defs:2,11`), so the body is **not UTF-8**. The jobs that need no auth are only `listmodules, getmodule, getinfoserver, getserverstat, getmodulesstat` (`defs:33`). Every other job runs `var.check` (`var.proc:19-25`), which reads `log/classes/.connections/$ident` (`var.check:27`) and checks `passwd` (`:44`), the caller IP against `ident_site` (`:49`), an optional User-Agent (`:54`), an optional `https` requirement (`:59`) and allow/deny job lists (`:37-38`). | source |
| F-3 | **Confirmed.** WI-22's "adapter-defined `cmd=getresult`" is impossible (F-1). WI-23 Step 1 "None" is false for any `adm/raw` grade/score path (F-2). It is only true for an anonymous stock exercise session (`cmd=new`/`reply` on an OEF module), which does not record a class score. | F-1, F-2 |
| F-4 | **Confirmed.** `\help` is a native OEF directive (`src/OefMsg2wims/oef2wims.c:79`, `process.c:158`). Its text is shown by `scripts/oef/help.phtml:24-26` with `m_help_subject` set from the help link parameter. Authors branch on `\help_subject` (doc: `scripts/help/fr/special/help.phtml`). **Run:** `\help{aide.json}` compiled with `oef2wims` gives `help=!nosubst aide.json` and a `:help` section containing the literal `aide.json`, so stock WIMS shows the string "aide.json" in its help popup. The 2/300 corpus count was not re-run. | source + run |
| F-5 | **Accepted on cited evidence, not re-run.** The counts are consistent with the stock anstype tree: 61 answer types in `scripts/anstype/` (`ls | grep -v '\.' → 61`), against 4 CDC check types. | GV-3 `bf0184b` |
| F-6 | **Confirmed in principle; count not re-run.** `\text{..=wims(..)}`, `slib(..)`, `pari(..)` and `maxima(..)` are evaluated by WIMS when the exercise is **generated** (`cmd=new`), not converted (`OefMsg2wims/process.c:68` `p_wims`, compiled into `!exec`/`!` calls in the `.def`). None of WI-05 GAP-1..5 covers this. | source |
| F-7 | **Confirmed.** `src/Interfaces/` = `gap.c m2.c maxima.c octave.c pari.c scilab.c yacas.c` (+`common.c`). GIAC is absent. Gnuplot has no interface (called by scripts for plots only). | source |
| F-8 | **Accepted** (consistent with WI-21: PRs #40–#42 are parked and target an adapter that does not exist). Not re-run. | GV-2 |
| F-9 | **Accepted, not re-run** (PR #61 lane). One note: WIMS answer analysis itself calls Maxima (`anstype/formal:40`, `anstype/algexp:32`). Engine filter parity therefore also affects *grading* parity, not only exploration. | PR #61 + source |

---

## 2. P0 items and proposed correction text

### P0-1 — WI-20 / WI-22 / WI-23 (MW-1): connected grading design — **FAIL as written**

What WIMS really offers:
- `adm/raw job=testexo` **does not grade.** It writes `data1` to `submit.oef` in the session and runs `oef2wims` (`jobs/testexo.proc:6-17`), so it is a **compile check** only. It cannot score an answer set.
- `getscore / getscores / getsheetscores / getexamscores` return **aggregate class scores** recorded by wimslogd (`jobs/getscore.proc:21-42`: `!getscorepercent`, `!getscore`, `!getscoremean`, …). The finest grain is the exercise within a sheet. They hold **no per-answer** data, so they cannot fill Q-W4 `answers[]`.
- Per-answer judgments exist only **inside an OEF reply evaluation**, as `diareply$i` (e.g. `anstype/numeric:59-60`) and the reply-analysis variables. They are rendered to HTML by `scripts/oef/answer.phtml`. No stock path outputs them as JSON.

**Proposed replacement for WI-22 (text):**
> WI-22: Wire format (target). Stock WIMS has no grading API. `cmd=` is a closed list of 14 verbs in `wims.c`, so no adapter can add `cmd=getresult`. L2-1 is a two-call flow over **stock verbs**: (1) `cmd=new&module=<oef module>&exo=<id>&qnum=1&<seed>` opens an exercise in a WIMS session; (2) `cmd=reply&session=<s>&reply1=…&replyN=…` submits the answers. Per-answer JSON comes from a **wims4win OEF output hook**: when the request carries `special_parm=algogebra_json`, `scripts/oef` replies with `!shortout` + `Content-Type: application/json` and emits `{grade, answers:[{id, type, correct:(diareply==good), score, feedback}], feedback}` built from `diareply$i`, `reply$i`, `replytype$i` and the evaluated `\feedback`. Recording the score in a class is done by WIMS itself during `cmd=reply` in a class session. Reading scores back uses `adm/raw job=getscore` (aggregate only). `adm/raw job=testexo` is a compile check, not a grader.

**Proposed replacement for WI-23 (text):**
> Step 1 (local): anonymous WIMS session (no class login) for formative grading. Nothing is recorded. Any `adm/raw` call needs an `ident` file in `log/classes/.connections/<ident>` with `ident_password`, `ident_site=127.0.0.1` and `ident_allow=getscore,getscores,getsheetscores,checkuser,authuser` (and `ident_protocol=https` from Step 3). Step 2: class session (`authuser` via adm/raw, or user login) so `cmd=reply` records scores. Step 3: TLS, `ident_protocol=https`, institutional auth (CAS/SSO, as already supported per class: `defs:46-47`).

**Fix to WI-20 last paragraph:** delete "must use the stock `cmd=` verb namespace or implement a new WIMS module" and replace it with "uses stock `cmd=new/reply` plus a JSON output hook in the OEF script layer (wims4win patch, GPL v2); a sibling module alone cannot run another module's OEF engine". The alternative (HTML scraping of the reply page) remains WA-1 option B.

Why not a new `job=` on `adm/raw`: `adm/raw` has no OEF evaluation context. Adding a grading job there would mean re-implementing the reply pipeline (`scripts/oef/var.proc` → `ans.proc` → `anstype/*`). The output hook reuses it unchanged.

### P0-2 — WI-12 `\help` collision (MW-2) — **FAIL as written**

`\help{file.json}` overrides the native help popup text (run in F-4). Unknown directives are **silently dropped** by `oef2wims` (`oef2wims.c:197-211`: an unknown name that is not an `\mdef` is skipped with its braces; the run confirms `\helptemplate{aide.json}` leaves no trace in the `.def`). That is valid OEF but fragile, because a future WIMS release could claim the name.

**Proposed WI-12 text:**
> OEF link to a help template: `\text{algogebra_help=aide_derivation.json}` (a standard OEF text parameter, valid on stock WIMS, invisible unless the author displays it). The converter reads `algogebra_help` (and an optional `algogebra_course=` for the Q-W9b RAG chapter). Fallback when it is absent: a sidecar file by naming convention, `<exo>.help.json` next to `<exo>.oef`. Native `\help{…}` stays WIMS popup text. The converter maps it to a `text` help node and never reads it as a file name.

### P0-3 — WI-31 check types vs. OEF answer types (MW-3) — **PARTIAL**

How WIMS grades each GAP-5 family, and whether offline grading is possible:

| Family (F-5) | WIMS grading (source) | Offline feasible? | Proposed check |
|---|---|---|---|
| choice (`\choice`, radio/checkbox/menu) | Exact match of the selected item(s) (`anstype/checkbox`, `menu`, `radio`) | **Yes**, no engine | `choice_equals` {options[], correct[], multiple} |
| fill: clickfill/dragfill | Item-by-item comparison of the placed items (`anstype/clickfill`, `dragfill` + `.after`) | **Yes**, no engine | `sequence_equals` / `set_equals` |
| numeric | **Relative** error by default, `precision` default 1000; `absolute` option switches to `|diff|·precision<1` (`anstype/numeric:52-60`) | **Yes** | Extend `value_equals` with `mode: relative|absolute` and `precision`. The current absolute `tolerance` is not equivalent. |
| symbolic (formal/algexp/function) | Calls **Maxima** (`formal:40`, `algexp:32`) or PARI/numeric sampling (`function`) | Only with a local engine | `engine_check` (WI-31), engine = what the anstype uses, with no substitution (Q-W6) |
| variable-typed (`type=\t`, `\format`) | `replytype$i` is resolved **at exercise generation** (`scripts/oef/replytype.proc:11-32`) | Yes, if resolved at conversion | Converter must evaluate the type per frozen variant (see P0-4). Otherwise keep `object_exists` with a warning. |

**Proposed WI-31 addition (text):**
> Check types are a closed enum aligned with WIMS anstype families: `value_equals` (+`mode`, `precision`; default relative 1e-3 as in WIMS), `value_range`, `choice_equals`, `sequence_equals`, `set_equals`, `cas_equals` (GIAC, only for AlgoGebra-native steps), `engine_check` (WIMS-named engine). `object_exists` is a GeoGebra-construction check, not a grading fallback for OEF answers. A converted OEF answer that maps to none of these is marked `gradable: false`, and the converter emits a warning.

### P0-4 — WI-05 + GAP-6 computed parameters (MW-4) — **F-6 confirmed**

Recommendation: **pre-evaluate at conversion with a real WIMS run and ship N frozen variants** (default N=20), one parameter set per seed. The converter calls stock `cmd=new&exo=..&wims_seed?` (or `adm/raw job=testexo` for the compile check only) and captures the parameters. A local engine at runtime is only needed for `engine_check` grading, not for generation. Also add **GAP-6** to WI-05:
> GAP-6 — Parameters computed by `wims()/slib()/pari()/maxima()` (214/300). Status: Open. Resolution: conversion-time WIMS evaluation into `variants[]` (seed, params, expected answers), then offline replay. Live random generation is Phase 2 (connected).

---

## 3. MW-1..MW-9

| ID | Result | Summary |
|---|---|---|
| MW-1 | **FAIL** (CDC) / design proposed | See P0-1. `testexo` cannot grade. `getscore*` is aggregate only. |
| MW-2 | **FAIL** (CDC) / fix proposed | See P0-2. `\text{algogebra_help=…}` + sidecar. |
| MW-3 | **PARTIAL** | See P0-3. Choice/fill/numeric offline yes. Symbolic needs an engine. Typed answers depend on P0-4. |
| MW-4 | **PASS for F-6**, CDC FAIL | GAP-6 missing in WI-05. Frozen variants recommended. |
| MW-5 | **FAIL** | No stock compute endpoint. The nearest stock tools are modules such as `tool/pari`-style online calculators, which return HTML (not in r19040 SVN; site modules). Proposal: WI-24 exploration fallback = **Phase 2**, through the same wims4win JSON hook idea, on a dedicated module `local/algogebra_compute` that runs `!exec <engine>` under the wims4win sandbox. Until then: "engine missing → explicit error", no fallback. This needs owner confirmation, because it changes the Q-W6 "OK for the MVP" decision. |
| MW-6 | **PARTIAL** | EE-02/§Phase 2 list pari, maxima, gap, gnuplot (+octave later). Missing from the WIMS-engine list: **yacas, m2, scilab** (`src/Interfaces/`). Octave is listed as "later", OK. GIAC is correctly native-only (D-ENG-05). Gnuplot is correctly plot-only. Add one line: "Exercises naming yacas/m2/scilab → `gradable:false` offline until an engine slice exists." |
| MW-7 | **PARTIAL** | See table below. |
| MW-8 | **PARTIAL** | WI-40 says "WIMS OEF editor". Real teacher paths are **Createxo** (class-local exercises, stored in `log/classes/<c>/src/*.oef`) and **Modtool** (module dev accounts, `public_html/modules/devel/…`). The converter must accept both sources. Class exercises are reachable via `adm/raw job=getexofile` (`defs:17`, authenticated). Encoding: see WA-5. The `\hint` skeleton generator (WA-3) is consistent with Createxo, which exposes `\hint` and `\help` as separate fields. |
| MW-9 | **FAIL (missing risks)** | Add risks WI-R7..R10 below. |

### MW-7 — Q-W traceability

| Decision | CDC section | Status |
|---|---|---|
| Q-W1 (local wims4win → server → certs) | WI-01, WI-23 | **Contradicts** in WI-23 Step 1 "no auth" for adm/raw (P0-1). The Q-W1 validation question "same `job=`/`module=` params" is **yes**: wims4win runs the same r19040 CGI, so Step 1→2 is transport plus `.connections` config. |
| Q-W2 (offline first) | WI-01, WI-30 | OK |
| Q-W3 (OEF first, converter) | WI-03..05 | **Missing GAP-6** (P0-4) |
| Q-W4 (per-answer result, help requests) | WI-22 | Format OK. **No implementable source** in stock WIMS (P0-1). |
| Q-W4 retry (Phase 2) | WI-50 S-03 | OK |
| Q-W5 (OEF + .ggb authoring) | WI-40/41 | OK, nuance MW-8 |
| Q-W6 (fallback exploration only) | WI-24, EE §fallback | OK in intent. **Not implementable in MVP** (MW-5). |
| Q-W7 (wims4win for students/teachers) | WI-02, WI-R5 | OK |
| Q-W8 (scope boundary) | §1 | OK |
| Q-W9 (+a..d) | WI-10..13 | OK except the link mechanism (P0-2) |

### MW-9 — risks to add

| ID | Risk | Mitigation |
|---|---|---|
| WI-R7 | GPL v2 contamination: filter tables, headers and anstype logic ported from WIMS into EUPL code | Keep ported tables in a separate GPL v2 module/file with attribution. Decide at Gate E (OD-4). |
| WI-R8 | Encoding: WIMS French modules and adm/raw JSON are ISO-8859-1/windows-1252 (`adm/raw/defs:2`; wims4win showed `Â°` with UTF-8 OEF) | WA-5: converter decodes cp1252→UTF-8. The connected client decodes the declared charset. Never assume UTF-8 from WIMS. |
| WI-R9 | Version drift: Debian 4.31b vs wims4win 4.33a (r19040) — anstypes, adm/raw jobs | Pin r19040 as reference. The converter records the `wims_version` used for variants. |
| WI-R10 | Offline answer keys: frozen variants ship expected answers to the student machine | Accept for formative MVP. Graded/recorded mode stays on WIMS (Phase 2). |

---

## 4. Other findings (non-P0)

| ID | Section | Severity | Finding | Correction |
|---|---|---|---|---|
| V-1 | WI-20 | minor | "Every response was text/html" is true for `wims.cgi` modules, but `adm/raw` returns `text/plain`/`application/json` (`defs:5-11`) | Add: "except `adm/raw` (machine API)". |
| V-2 | WI-05 GAP-5 text | major | Says OEF has "regex, set equality, ordered list". The real set is 61 anstypes (`scripts/anstype`). | Reference P0-3 table. |
| V-3 | WI-R4 | major | "Fallback: connected mode delegates to WIMS's own evaluator" needs the P0-1 hook | Link to L2-1 hook. |
| V-4 | EE-02 | minor | Command `gap.exe -T -n` on Windows: wims4win runs GAP through Cygwin and needs `gap_command` plus a Cygwin DLL path (wims4win D21, `bin/ch..root.conf`) | Add a Windows note. |
| V-5 | WI-41 | minor | `--seed 42` single variant | Change to `--variants N --seed S` (P0-4). |

## 5. Open questions for the owner (not posted on GitHub)

1. **L2-0/WA-1:** approve the "stock `cmd=new/reply` + JSON output hook in wims4win `scripts/oef`" design (a GPL patch to the WIMS script tree) over HTML scraping?
2. **Help link:** `\text{algogebra_help=…}` + sidecar `<exo>.help.json`. OK?
3. **Q-W6 vs MW-5:** accept that the exploration fallback to WIMS is Phase 2 (no stock endpoint), so the MVP gives an explicit "engine missing" error?
4. **Frozen variants:** N=20 per exercise by default? And is it acceptable that answer keys ship offline (WI-R10)?
5. **yacas/m2/scilab exercises:** mark them `gradable:false` offline, or plan engine slices?

*End of `Validation_CDC_WIMS_Integration_MIGRATION_WIMS_V1.md`.*
