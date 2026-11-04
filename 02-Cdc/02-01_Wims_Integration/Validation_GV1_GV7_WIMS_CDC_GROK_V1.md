<!-- GROK_V1_1 -->
# Validation GV-1..GV-7 + WIMS CDC review

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Version | GROK_V1_1 |
| Checklist | `QA_WIMS_Integration_Owner_ALF_V2.md` §Grok validation checklist |
| CDC under review | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (`e48d1dd` WI-20 probe fold-in) |
| Code audit input | `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` (`556749b`) |
| Live probe | `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/` |
| Status | **Complete (desktop)** — GV-1 live CGI done; GV-2..GV-7 evidenced; Debian twins optional for Grok Bot |

---

## Summary

| ID | Result | One-line |
|---|---|---|
| **GV-1** | **PASS (live)** | Direct CGI probe: `job=getresult` → HTML worksheet; `cmd=getresult` → **450** (valid cmds: new, renew, reply, help, hint, config). Adapter = new module / front door |
| **GV-2** | **PASS (aligned)** | g14/g15/g16 templates + mock; WT-* contract re-checked 2026-11-04; offline-first OK |
| **GV-3** | **PASS (gaps confirmed)** | Tip suite 19: **15 PASS / 1 SKIP** (no `OEF_CORPUS`); archive corpus 300 = 300/300 schema-valid. **GAP-5 #1** |
| **GV-4** | **PASS** | `\hint`, `\feedback{cond}{text}`, `\help`, `\solution`, `\steps` — converter only flat `\hint` |
| **GV-5** | **PASS** | Runtime + Laragon conf exist; CGI also runs **without** Apache via direct env (this probe) |
| **GV-6** | **PASS** | Bank tags exist; no stock `\help{aide_xxx.json}` |
| **GV-7** | **PASS (negative)** | No upstream resolution-process JSON; Schema_Help_Template is new |

**CDC:** WI-20 at `e48d1dd` matches the probe. **WA-6 closed** for desktop. Remaining for Grok Bot: optional Debian twin (GB-R2..R5 in residual handoff); GB-R1 Windows half **done**.

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

### Live CGI probe (2026-11-04) — closes WI-20

Runtime: `Reprise_Wims_Grok/wims-runtime-oef`, `wims.cgi.exe` as CGI (Apache down). Full pack: `evidence/20261104-gv1-wims-cgi-probe_GROK_V1/` (`Probe_Note_GV1_WIMS_CGI_GROK_V1.md`).

| ID | Request | Result |
|---|---|---|
| A | `module=home&cmd=intro` | 200 HTML home |
| B/C | `module=adm/class/sheet&job=getresult&…` GET/POST | 200 HTML *Edit worksheet* (supervisor-only) — **not** a grade API |
| D | `module=adm/class/sheet&cmd=intro` | 200 HTML sheet UI |
| E | `module=adm/class/sheet&cmd=getresult` | **450** — *command ``getresult'' is not valid*; valid: **new, renew, reply, help, hint, config** |

Static: `adm/class/sheet` exists; literal `getresult` = **0** under `public_html`; sheet `job=` list has getsource/print/… — no getresult.

### Verdict

| Claim | Result |
|---|---|
| Same **`module=`** / **`cmd=`** as institutional lineage | **Yes** (4.33a) |
| D-S01 `job=getresult` is stock grade API | **No** — live HTML only |
| `cmd=getresult` works today | **No** — 450 bad_command |
| L2-1 needed | **Yes** — CDC `e48d1dd` |

### L2-1 design note (from probe)

Valid stock **`cmd=`** set exposed to the user error page: `new, renew, reply, help, hint, config`. A grade adapter should be a **new WIMS module** (or product front door) speaking the CDC `cmd=` wire format from `e48d1dd`. Module-local `job=` alone cannot add a new CGI verb; extending `commands[]` is a heavier core change (owner WA-1).

---

## GV-2 — Suites 21–23 vs offline-first (Q-W2)

| Suite | Branch | What it tests | Needs live WIMS? | Offline-first alignment |
|---|---|---|---|---|
| **21** WimsTemplate | `feat/grok-g14-wims-template` | Static HTML/README contract (D-S01 placeholders, no local grade) | No | **OK** |
| **22** WimsGradeClient | `feat/grok-g15-wims-grade-client` | JS client vs **`mock_wims_cgi_GROK_V1.mjs`** | No (mock) | **OK** |
| **23** WimsFullCycle | `feat/grok-g16-wims-full-cycle` | Playwright Firefox + same mock | No (mock) | **OK** |

**Re-check 2026-11-04 (g14 artifacts, tip has no suite 21 files):** WT-03..07, WT-12, WT-13, README HTML note — all **True**. Mock (g15) still assumes D-S01 `job=getresult` JSON — correct as **adapter target**, wrong as stock behaviour (GV-1).

Suites do **not** exercise offline `check` scoring. Parked Phase 2 (OD-3 / WI-21) remains correct for Q-W2.

---

## GV-3 — Suite 19 + GAP-1..5 vs corpus

### Suite 19 status

| Run | Result | Source |
|---|---|---|
| Fixtures **tip Windows 2026-11-04** | **15 PASS, 1 SKIP** (OC-16, no `OEF_CORPUS`) | `tests/results/19_OefConverter_GROK_V1.csv` |
| Fixtures Debian 2026-11-02 | **15 PASS, 1 SKIP** | `evidence/20261102-054819-g06-oef-converter-debian/19_OefConverter_GROK_V1.tap` |
| Corpus 300 (Debian archive) | **16 PASS** — 300/300 schema-valid | same dir `19_OefConverter_corpus300_GROK_V1.tap` |

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
| WI-20 CGI returns HTML; no stock JSON grade API | **Confirmed live** (probe pack + `e48d1dd`) |
| WI-21 L2-0…L2-4 | Sound; L2-1 still blocks real S-01/S-02 |
| WI-22 `cmd=` wire format | **Aligned** after `e48d1dd`; L2-1 = new module / front door |
| WI-24 Q-W6 grading vs exploration | Consistent with engine D-ENG-02 |
| GAP-1..5 table | Confirmed; GAP-5 = largest fidelity blocker (GV-3) |
| WI-12 `\help{aide_….json}` | Extension vs stock `\help` (GV-4/6) — still worth a one-line CDC note |
| PRs #40–#42 parked | Matches OD-3 / suite mock strategy (GV-2) |
| WA-6 = this validation | **Satisfied** (desktop); Debian GB-R2..R5 optional |

### Remaining optional CDC editorial

1. WI-12: stock OEF `\help` ≠ JSON template reference.
2. GAP-5 / WI-51: corpus 300 schema-pass + fidelity caveat (interactive → `object_exists`).

---

## File index (evidence)

| Path | Used for |
|---|---|
| `evidence/20261104-gv1-wims-cgi-probe_GROK_V1/` | GV-1 live |
| `02-wims4win/src/wims.c` (`commands[]`) | GV-1 source |
| `origin/feat/grok-g14|g15|g16` + WT re-check | GV-2 |
| Tip suite 19 + `evidence/20261102-054819-g06-oef-converter-debian/` | GV-3 |
| `oef2course_GROK_V1.py` + OEF banks | GV-3/4/6 |
| Laragon conf + Reprise runtimes + direct CGI | GV-5 |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` | GV-7 |
| `Handoff_GrokBot_WIMS_GV_Residual_GROK_V1.md` | Debian residuals |

---

*End of `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` (GROK_V1_1).*
