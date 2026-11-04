<!-- GROK_V1 -->
# Validation note — WIMS CDC vs GV-1..GV-7 (post-push)

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Branch | `feat/grok-sprint3-plan-v1-1` @ `c5177f9` (origin pushed) |
| CDC | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V1.md` (`e48d1dd` WI-20/WI-22) |
| Prior GV report | `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` (GROK_V1_1) |
| Parallel box report | `origin/grok/gv-validation-wims-cdc` (`Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md`) |
| Audience | Claude (CDC fold-in) + owner (WA-1) |

---

## Verdict

| Question | Answer |
|---|---|
| Do GV-1..GV-7 still hold against the pushed CDC? | **Yes** for the HTML/`getresult`-absent findings |
| Are WI-20 probe citations correct? | **Yes** (`cmd=` vs `job=`, 450, valid command list, evidence path) |
| Is WI-22 ready to implement as written? | **Needs correction** — `cmd=getresult` is not inventable by a module alone |
| Does **`adm/raw`** change L2-1? | **Yes — material** — it is the stock machine JSON API; base the adapter on it (or a sibling), not on `adm/class/sheet` + new CGI verb |

**Overall:** CDC accepted for offline MVP + Phase 2 *intent*. Apply the WI-20/WI-22 corrections below before L2-0/L2-1 coding.

---

## 1. WI-20 — probe citations (OK)

Current CDC text correctly states:

- Stock CGI renders HTML; no built-in D-S01 JSON grade API on `adm/class/sheet`.
- Live GV-1: `job=getresult` ignored → worksheet HTML; `cmd=getresult` → **450**; valid cmds `new, renew, reply, help, hint, config`.
- Evidence path `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/`.

**Add (missing):** WIMS already has a **JSON machine interface**: `module=adm/raw`.

### Live spot-check (2026-11-04, same runtime as GV-1)

```text
GET module=adm/raw&job=getinfoserver&code=probe1
→ Content-Type: application/json ; charset=iso-8859-1
→ {"status":"OK","code":"probe1","job":"getinfoserver","server_version":"4.33a",...}
```

No HTML wrapper. Mechanism: `defs` → `header_json` + `!shortout` in `var.proc` / job procs.

So WI-20’s “CGI returns HTML” is true for **interactive modules** (home, sheet, OEF UI). It is **false** as a blanket statement for every module: `adm/raw` is the counterexample and the right L2-1 substrate.

---

## 2. WI-22 — wire format (correct `cmd=` intent, wrong verb placement)

### What WI-22 says now

```text
module=<adapter_module>
&cmd=getresult
&exercise=…
&ans1=…
```

### Problem

1. **`cmd=getresult` is not in stock `commands[]`.** Probe E proved the core rejects it with 450. A **new module cannot register a new `cmd=`** — only core `wims.c` / `commands[]` can.
2. D-S01’s old `module=adm/class/sheet&job=getresult` remains wrong (teacher sheet editor; `getresult` absent).
3. Parallel box validation (`grok/gv-validation-wims-cdc`) already named the real API: **`module=adm/raw` + `ident`/`passwd`/`code`/`job`**.

### What `adm/raw` actually is

| Item | Value |
|---|---|
| Path | `public_html/modules/adm/raw/` (present in wims-runtime-oef) |
| Protocol doc | `protocol.md` |
| CGI shape | `module=adm/raw&ident=…&passwd=…&code=…&job=<name>&…` |
| JSON | `ident_type=json` (default for several jobs) → `Content-Type: application/json` |
| Auth | Declared in `log/classes/.connections/$ident` — **required** for most jobs (incl. score) |
| Existing jobs (examples) | `getscore`, `getscores`, `getsheetscores`, `getexamscores`, `testexo`, `authuser`, `listmodules`, `getmodule`, … |
| **`job=getresult`** | **Absent** (same as everywhere else) |

`getscore*` here **reads stored scores**; it does **not** submit a student construction and return a fresh grade. `testexo` compiles an OEF in a sandbox — still not D-S01.

### Recommended L2-1 shapes (for WA-1)

| Option | Shape | Pros | Cons |
|---|---|---|---|
| **A (preferred)** | Extend **`adm/raw`** with new **`job=gradeexo`** (or `job=getresult` as *module* job) that accepts answers, runs WIMS evaluation, `!shortout` JSON `{grade, feedback, answers[]}` | Matches stock JSON + auth pattern; no `commands[]` patch | Needs connection identity; GPL module work; must implement grading glue |
| **B** | New sibling module `adm/algogebra_grade` copied from `adm/raw` patterns (`header_json`, `!shortout`, `job=` dispatch) | Isolates AlgoGebra; same mechanics | Duplicate auth/connection plumbing |
| **C** | Product front door (Java/Node) → drives anonymous OEF `cmd=reply` / session HTML, scrapes or reimplements score | Avoids WIMS module edit | Fragile; fights WI-20 HTML finding |
| **D** | Patch core `commands[]` to add `getresult` | Matches WI-22 literally | High cost; avoid |

**WI-22 should be rewritten roughly as:**

```text
POST /wims/wims.cgi
  module=adm/raw                    ← or adm/<adapter> sibling
  &ident=<connection_id>
  &passwd=<connection_secret>
  &code=<nonce>
  &job=gradeexo                     ← NEW module job (not cmd=)
  &qclass=…&qsheet=…&qexo=…         ← or exercise=<id> mapped by adapter
  &ans1=…&ans2=…
  (&format=json / ident_type=json)

→ Content-Type: application/json
→ { "status":"OK", "code":"<nonce>", "grade":0..1, "feedback":"…", "answers":[…] }
```

Stock **`cmd=`** stays whatever WIMS sets for module entry (typically `intro`/`new`/`reply` under the hood). The adapter verb lives in **`job=`**, which is exactly how `adm/raw` already works.

Q-W1 “Step 1: no authentication” applies to **anonymous OEF play** (`module=<exo>&cmd=new|reply|…`). It does **not** apply to `adm/raw` grade/class jobs. CDC WI-23 should say: local-connected grading uses a **declared `.connections/` identity** (can be a local-only ident).

---

## 3. GV-1..GV-7 vs pushed CDC (still hold)

| ID | Still hold? | Note vs CDC |
|---|---|---|
| GV-1 | **Yes** | WI-20 citations OK; add `adm/raw` exception |
| GV-2 | **Yes** | Suites 21–23 = Phase 2 mock; rebase mock on `adm/raw` before L2-2 |
| GV-3 | **Yes** | GAP-5 #1; box addendum also flags `wims()`/`pari()` in params (~214/300) — optional GAP-6 for converter |
| GV-4 | **Yes** | `\hint`/`\feedback`/`\help`/`\solution`/`\steps` |
| GV-5 | **Yes** | Runtime + direct CGI; `adm/raw` JSON works without Apache |
| GV-6 | **Yes** | No stock `\help{*.json}` |
| GV-7 | **Yes** | No upstream resolution-process JSON; `adm/raw` JSON ≠ helpStep tree |

---

## 4. Requested CDC corrections (Claude)

1. **WI-20** — After the HTML finding, add a short subsection: *Exception / machine API: `adm/raw` returns JSON via `!shortout` + `header_json`; requires `ident`/`passwd`/`code`; see `protocol.md`.* Cite the getinfoserver probe above.
2. **WI-22** — Replace `cmd=getresult` with **`module=adm/raw` (or sibling) + `job=<new>`**; drop implication that a module can mint CGI verbs. Keep response JSON schema (Q-W4 `answers[]`).
3. **WI-23 / Q-W1** — Clarify anonymous OEF vs authenticated `adm/raw` for grading.
4. **WI-21 L2-1** — Prefer “new **job** on `adm/raw` (or sibling module)” over “adapter defines `cmd=getresult`”.
5. **Optional** — Suites 21–23 / mock: plan rebase from fake `adm/class/sheet&job=getresult` to `adm/raw` shape (L2-2).
6. **Optional** — Converter GAP: parameter-time `wims()`/`pari()`/`maxima()` (box GV-3 addendum).

No block on offline MVP / L1 engines.

---

## 5. Evidence index

| Item | Path |
|---|---|
| Sheet/`getresult` probe | `03-RCP-Spike/evidence/20261104-gv1-wims-cgi-probe_GROK_V1/` |
| `adm/raw` JSON probe | this note §1 (getinfoserver); runtime `modules/adm/raw/` |
| Protocol | `…/modules/adm/raw/protocol.md` |
| Desktop GV report | `Validation_GV1_GV7_WIMS_CDC_GROK_V1.md` |
| Box GV report | `origin/grok/gv-validation-wims-cdc` → `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md` |

---

*End of `Validation_Note_CDC_WI20_WI22_adm_raw_GROK_V1.md`.*
