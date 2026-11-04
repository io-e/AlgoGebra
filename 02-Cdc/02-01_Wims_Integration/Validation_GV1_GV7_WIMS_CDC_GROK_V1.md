<!-- GROK_V1 -->
# Validation GV-1..GV-7 + WIMS CDC review

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Version | GROK_V1 |
| Checklist | `QA_WIMS_Integration_Owner_ALF_V2.md` §Grok validation checklist |
| CDC under review | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (`db5222f`) |
| Code audit input | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (`556749b`) |
| Status | **Complete** — evidence-backed; no live institutional WIMS probe |

---

## Summary

| ID | Result | One-line |
|---|---|---|
| **GV-1** | **PASS with caveat** | Stock `module=` + `cmd=` match institutional WIMS; D-S01 `job=getresult` is **not** stock — adapter required (CDC WI-20/WI-22 correct) |
| **GV-2** | **PASS (aligned)** | Suites 21–23 use a **local mock**, not live WIMS; they prototype Phase 2 connected mode and do not contradict offline-first MVP |
| **GV-3** | **PASS (gaps confirmed)** | Suite 19: fixtures PASS; corpus 300 = 300/300 schema-valid (Debian evidence). **GAP-5 blocks the most exercises** by fidelity (degraded `object_exists`) |
| **GV-4** | **PASS** | Real OEF constructs: `\hint`, `\feedback{cond}{text}`, `\help`, `\solution`, `\steps` — converter only maps `\hint` (flat text) |
| **GV-5** | **PASS** | wims4win serves via Laragon/Apache CGI on localhost; documented runtime + conf exist |
| **GV-6** | **PASS** | `\help` / `\hint` / `\feedback` exist in banks; **no** stock `\help{aide_xxx.json}` — that is AlgoGebra’s Q-W9 extension |
| **GV-7** | **PASS (negative)** | No existing WIMS/XWims JSON encodes a step-by-step **resolution process tree**; Schema_Help_Template is new |

**CDC acceptance recommendation:** accept draft for offline MVP + Phase 2 design. Keep WA-1 (adapter ownership) and WA-6 closed by this report. Fix one terminology note (`cmd=` vs `job=`) in a CDC bump if desired.

---

## GV-1 — CGI `job=` / `module=` parity

### Evidence

From `D:\ALF_ZGit\02-wims4win\src\wims.c`:

```c
char *commands[]={
    "intro" , "new" , "renew" , "reply" , "config" , "hint" , "help" ,
      "resume", "next", "getins", "getframe", "getfile", "close", "ref"
};
```

- HTTP entry: `wims.cgi` / `wims.exe` (`config.c` `cgi_name`).
- Module selection: query/form `module=` (used throughout `calc.c`, `variables.c`, `auth.c`).
- Command selection: reserved var **`cmd=`**, values = `commands[]` above. Unknown cmd → `user_error("bad_command")`.
- `getscore*` / `getscoreuser` are **calc/exec builtins** and `wimslogd` IPC (`score.c`), **not** HTTP `job=` values.
- **`getresult` does not appear** in `commands[]` or as a stock CGI job.

### Verdict

| Claim | Result |
|---|---|
| wims4win accepts same **`module=`** as institutional WIMS | **Yes** — same CGI core |
| wims4win accepts same **`cmd=`** vocabulary | **Yes** — identical command list lineage (r19040 / 4.33a) |
| D-S01 `job=getresult` on `adm/class/sheet` is stock | **No** — unverified / absent; CDC WI-20 is correct |
| Step 1→2 is “config only” for **stock** WIMS browsing | **Yes** for `cmd=intro\|new\|reply\|hint\|…` |
| Step 1→2 is “config only” for **D-S01 grading** | **No** — needs L2-1 adapter that invents `job=getresult` → JSON |

**Caveat for QA Q-W1 wording:** the transport story (localhost → network → TLS) holds for stock CGI. The AlgoGebra grade contract is an **adapter API** layered on that transport.

---

## GV-2 — Suites 21–23 vs offline-first (Q-W2)

| Suite | Branch | What it tests | Needs live WIMS? | Offline-first alignment |
|---|---|---|---|---|
| **21** WimsTemplate | `feat/grok-g14-wims-template` | Static HTML/README contract (D-S01 placeholders, no local grade) | No | **OK** — documents connected contract; no runtime server |
| **22** WimsGradeClient | `feat/grok-g15-wims-grade-client` | JS client vs **`mock_wims_cgi_GROK_V1.mjs`** | No (mock on 127.0.0.1) | **OK** — prototypes Phase 2; mock explicitly says “NOT a WIMS server” |
| **23** WimsFullCycle | `feat/grok-g16-wims-full-cycle` | Playwright Firefox + same mock | No (mock) | **OK** — connected-path UI smoke; SKIP without Node/Playwright/WAR |

Mock behaviour (g15): accepts only `module=adm/class/sheet` + `job=getresult`; returns JSON, HTML, 413, XSS samples — matches CDC “stock returns HTML; adapter returns JSON”.

**Note:** suites 21–23 do **not** exercise offline local scoring (`check` in course.json). That is fine for Q-W2: MVP offline is engine CDC + course tree; these suites are parked Phase 2 (OD-3 / CDC WI-21).

---

## GV-3 — Suite 19 + GAP-1..5 vs corpus

### Suite 19 status

| Run | Result | Source |
|---|---|---|
| Fixtures (tip/Debian 2026-11-02) | **15 PASS, 1 SKIP** (OC-16 without `OEF_CORPUS`) | `evidence/20261102-054819-g06-oef-converter-debian/19_OefConverter_GROK_V1.tap` |
| Corpus 300 | **16 PASS** — `files=300 converted=300 schema-valid=300` | same dir `19_OefConverter_corpus300_GROK_V1.tap` |

OC-05 confirms `\hint` is **inlined** into `step.description` (“Hint: Multiply first”) — GAP-1 still true at converter level (schema V1_1 may add `help`/`engine` slots; converter emit of structured help is still WA-3).

### Gap impact (sampled banks)

| Bank | Files | Numeric `\answer` | Non-numeric `\answer` | With `\hint` | With `\help` | With `\feedback` |
|---|---|---|---|---|---|---|
| `certified_oef_OLD` (first 400) | 400 | 222 | **132** | 0 | 0 | **257** |
| Amato WIMS modules | 256 | 18 | **212** | 56 | 26 | 38 |
| wims4win html exemples | 18 | 1 | 16 | 3 | 1 | 2 |

Corpus 300 path list is dominated by interactive models (`clickfill`, `menu`, `dragfill`, `coordclick`, …). **Schema-valid ≠ faithful:** non-numeric answers become `object_exists` + warning (OC-08).

### Which gap blocks the most exercises?

| Gap | Blocks | Rank |
|---|---|---|
| **GAP-5** limited check types | Majority of real bank items (menus, click, fill, draw, chem, …) — silent fidelity loss while schema still passes | **#1** |
| **GAP-1** no structured cheat sheet | `\feedback` (very frequent) and `\hint` lost as separate UI; only flat hint text today | **#2** |
| **GAP-2** no engine field | Exercises that call CAS via WIMS (`wims(…)` / named engine) cannot route offline help | **#3** (needs deeper `wims(` scan; not counted here) |
| **GAP-3** computeRequest | Runtime contract — not a static convert blocker | Phase help UX |
| **GAP-4** submission | Phase 2 only | Deferred |

**CDC path:** `engine_check` (WI-31) addresses GAP-5; Q-W9 help templates address GAP-1/3. Converter still needs emit work (WA-2/WA-3).

---

## GV-4 — OEF hint / help / cheat-sheet constructs

| Construct | Role in stock OEF | In converter today |
|---|---|---|
| `\hint{text}` | Student hint (also CGI `cmd=hint`) | Appended as `" Hint: …"` in description |
| `\feedback{condition}{html}` | Conditional feedback after reply | **Ignored** |
| `\help{…}` | Subject-scoped help blocks (rare) | **Ignored** |
| `\solution{…}` | Solution narrative | **Ignored** |
| `\steps{…}` | Multi-step / multi-answer sequencing | **Ignored** (only as unknown / partial) |

No standard OEF directive means “attach AlgoGebra cheat-sheet JSON”. Teacher cheat sheets (Q-W5/Q-W9) are an **AlgoGebra packaging convention** (`\help{aide_derivation.json}` proposed in CDC WI-12), not upstream OEF.

---

## GV-5 — wims4win as local HTTP service (Windows)

### Confirmed

| Piece | Location |
|---|---|
| Apache/Laragon conf | `02-wims4win/docs/apache-laragon-wims-runtime.conf` — `ScriptAliasMatch` → `wims.cgi.exe`, `Alias /wims` |
| Install guide | `Reprise_Wims_Grok/04_Guide_Installation_et_CGI_Laragon.md` |
| Runtime trees | `…/wims-runtime`, `…/wims-runtime-oef` (public_html + conf + CAS paths) |
| CGI binary | `wims.cgi.exe` / `wims.exe` present under Reprise |
| OEF→HTML via CGI | `HANDOFF_Claude_OEF_Python.md` — `oef2html.py --cgi "$RT\public_html\wims.cgi.exe"` already used on this PC |

### Startup procedure (short)

1. Build/install runtime (`tools/build-runtime-tree.sh` lineage) under e.g. `Reprise_Wims_Grok/wims-runtime-oef`.
2. Include `apache-laragon-wims-runtime.conf` in Laragon Apache (`Define WIMS_RT` → runtime `public_html`).
3. Ensure `log/wims.conf` CAS paths (`pari_command`, maxima via `sbcl.exe --core`, …) and empty webmaster pass set when exposing beyond localhost.
4. Start Laragon Apache → open `http://localhost/wims/wims.cgi`.

**Limits:** wims4win repo alone has **no** full `public_html` tree (README). Local-connected Mode needs the Reprise runtime (or equivalent), not only the C sources. wimslogd Windows still partial for scoring housekeeping.

---

## GV-6 — `\help` (and equivalents) in exercise banks

| Finding | Detail |
|---|---|
| `\hint` | Present in Amato modules (56/256 files) and validation exemples; fixture `numeric_GROK_V1.oef` |
| `\help` | Present (26/256 Amato; `00045.oef` subject-based `\help` + `\help_subject`) |
| `\feedback` | Dominant in certified_oef_OLD (257/400 files) |
| `\help{*.json}` | **Not found** in sampled sources — AlgoGebra extension only |

Format of stock `\help`: OEF/HTML prose (often conditional), **not** Schema_Help_Template JSON.

---

## GV-7 — Existing resolution-process JSON?

| Source checked | Step-by-step resolution JSON? |
|---|---|
| WIMS C / OEF directives | `\steps`, `\hint`, `\solution`, `\feedback` — **flat / conditional text**, not a typed process tree |
| wims4win OEF tools | HTML correction pages via CGI; no helpStep JSON |
| WA-OEF2IPYNB interpreter | Notebook/practice grading — no Schema_Help_Template twin |
| Historical “XWims” mentions in G1 archives | Conversion target name only; **no** checked-in resolution-tree schema from WIMS |

**Conclusion:** AlgoGebra `Schema_Help_Template_JSON` (`process` / `helpStep`) is a **new** contract. CDC WI-10 correctly treats it as teacher-authored JSON, not a port of an upstream format.

---

## CDC review (alongside GV)

| CDC claim | GV / code check |
|---|---|
| L1/L2 scope split (OD-1) | Matches implementation supplement + engine CDC V1_2 |
| WI-20 CGI returns HTML; no stock JSON grade API | **Confirmed** (GV-1, mock suite 22) |
| WI-21 L2-0…L2-4 | Sound; L2-1 still blocks real S-01/S-02 |
| WI-22 wire format uses `job=getresult` | **Design target** — document explicitly that stock WIMS uses **`cmd=`**, not `job=` |
| WI-24 Q-W6 grading vs exploration | Consistent with engine D-ENG-02 |
| GAP-1..5 table | Confirmed; GAP-5 = largest fidelity blocker (GV-3) |
| WI-12 `\help{aide_….json}` | Extension — call out vs stock `\help` (GV-4/6) |
| PRs #40–#42 parked | Matches OD-3 / suite mock strategy (GV-2) |
| WA-6 = this validation | **Satisfied** by this document |

### Suggested CDC editorial (optional V1_1)

1. In WI-22: “Stock WIMS parameter is `cmd=`; `job=getresult` is the AlgoGebra adapter contract.”
2. In WI-12: “Stock OEF `\help` ≠ JSON template reference; converter must special-case AlgoGebra’s `\help{*.json}` convention.”
3. In WI-51 / GAP-5: cite corpus 300 schema-pass + fidelity caveat (interactive models).

---

## File index (evidence)

| Path | Used for |
|---|---|
| `02-wims4win/src/wims.c` (`commands[]`) | GV-1 |
| `02-wims4win/src/score.c`, `calc.c` | GV-1 getscore* |
| `origin/feat/grok-g14|g15|g16` suites + mock | GV-2 |
| `evidence/20261102-054819-g06-oef-converter-debian/` | GV-3 |
| `oef2course_GROK_V1.py` | GV-3/4 |
| `certified_oef_OLD`, Amato modules, oef-validation exemples | GV-3/4/6 |
| `apache-laragon-wims-runtime.conf`, Laragon guide, Reprise runtimes | GV-5 |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` (by reference) | GV-7 |

---

*End of `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md`.*
