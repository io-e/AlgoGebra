<!-- GROK_V1 -->
# WIMS CDC validation — GV-1…GV-7 (answer to `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md`)

| Field | Value |
|---|---|
| Document | `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md` |
| Author | Grok Bot |
| Date | 2026-11-04 (Europe/Paris) |
| Base | `feat/grok-sprint3-plan-v1-1` @ `49d98f9` (PR #56) |
| Files validated (sha256 prefix) | `02-Cdc/QA_WIMS_Integration_Owner_ALF_V2.md` ALF_V2_3 (`28abfe19`), `02-Cdc/Schema_Help_Template_JSON_CLAUDE_V1.json` (`14dda883`), `02-Cdc/Schema_Course_JSON_CLAUDE_V1.json` V1_1 (`22f75355`), `02-Cdc/Example_Help_Template_CLAUDE_V1.json` (`960e939f`) |
| Related | PR #59 `02-Cdc/Review_Cdc_External_Engines_V1_1_GROK_V1.md` (CDC V1_1 review, findings reused here, not redone) |
| Evidence | `03-RCP-Spike/evidence/20261104-gv-validation-wims-cdc_GROK_V1/` (+ `SHA256SUMS`) |
| Scope | Validation only. No schema/spec edits, no PR, no GitHub comment, no merge, no change to #40/#41/#42, no S-01/S-02 work. |

## 0. Sources and access

| Source | What | Access |
|---|---|---|
| `D:\ALF_ZGit\02-wims4win` (owner's Shadow PC) | wims4win checkout, HEAD `45a7e96` (2026-10-25), origin `io-e/wims4win`, 1 dirty path | **Reachable, read-only** (`Get-ChildItem`, `Select-String`, hashing). `CopyToBox` refused (path outside allowed root) so no file was copied; nothing was written on Windows. Contains only **40 OEF** (the `tools/oef-validation` fixtures), no module bank. |
| `/workspace/wims-port` (box) | wims4win clone, HEAD `dc09f2f` (2026-10-28), same origin | Full. `src/wims.c` is **byte-identical** to the D: copy after CRLF→LF normalisation (sha256 `6e674c40…` on both sides). |
| `/workspace/wims-full` (box) | stock WIMS 4.x tree (Linux, institutional reference) incl. `public_html/scripts/help/en/oef*`, `modules/adm/raw/protocol.md` | Full |
| Corpus 300 | `03-RCP-Spike/evidence/20261102-054819-g06-oef-converter-debian/corpus_list_GROK_V1.txt` (300 paths into `/workspace/wims-full`); all 300 files still present on the box | Full |
| wims4win OEF bank (box) | 10 417 `.oef` under `wims-port` (mostly `build/` runtime copies) → **1 479 unique** by sha256 (≈ the "1438 OEF parity" set of `docs/05_Etat_et_Decisions.yaml`) | Full |
| Public | WIMS OEF docs (`wims.univ-cotedazur.fr/docs/introProgOEF.pdf`), `wimsapi.readthedocs.io/adm-raw/`, xWIMS slides (indico.in2p3.fr 2016) | Web |

## 1. Verdicts at a glance

| # | Prio | Verdict | One line |
|---|---|---|---|
| GV-1 | P0 | **PARTIAL** | wims4win `wims.cgi` = stock WIMS (identical `ro_name[]` and `commands[]`, only a `_WIN32` hook added) → Step 1→2 is a config change. **But** the D-S01 call used by #40–#42 (`module=adm/class/sheet&job=getresult`) does not exist in WIMS; the real machine API is `module=adm/raw` + `ident/passwd/code/job` and it **requires a declared connection (auth)** even on localhost. |
| GV-2 | P1 | **FAIL (vs offline-first)** | Suites 21–23 are connected-mode only: all three target `POST /wims/wims.cgi` (D-S01) on a local mock; none exercises offline scoring. Fine as Phase 2 assets, not MVP evidence. |
| GV-3 | P0 | **PASS (gaps confirmed), with one missing gap** | Suite 19 at tip `4e13b83`: 16/0/0, 300/300 converted and schema-valid (also valid under Course V1_1). GAP-5 blocks the most: **281/300** files have ≥1 answer degraded to `object_exists` (1 824 of 1 840 answers). Not in the Q&A: server-side computation in parameters (`wims()`/`slib()`/`pari()`/`maxima()`) in **214/300** files. |
| GV-4 | P0 | **PASS (constructs exist) → schema impact** | OEF has native `\hint{}`, `\help{}`, `\feedback{cond}{}`, `\solution{}`, `\condition{}{}`, `\steps{}`, `\nextstep{}`. **`\help{}` is already a native OEF command** (inline popup text, once per exercise) — `\help{file.json}` collides with it. |
| GV-5 | P1 | **PARTIAL** | Documented and once proven (HTTP 200 on `http://wims_paris_saclay_fr.test/wims/wims.cgi`, 2026-10-27, Laragon). Laragon present (`C:\laragon`), no `httpd` running at check time; the runtime it serves is `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime`, **not** `02-wims4win`. Not started (read-only). |
| GV-6 | P0 | **PASS (they exist, rarely, inline only)** | `\help{}`: 2/300 corpus, 2/1 479 wims4win-unique, 1/40 on D:. All inline OEF/HTML with `\if{\help_subject …}` and `\special{help …}` — never a file reference. Teacher help mostly lives in `\feedback` (543/1 479) and `\hint` (43/1 479). |
| GV-7 | P1 | **PASS (nothing equivalent exists)** | No WIMS/OEF/XWims format encodes a resolution tree. Closest: OEF `\steps`/`\nextstep` (multi-step *questions*, 126+36/1 479), `\feedback` conditions, STACK PRTs (answer-test trees). xWIMS is a search/annotation prototype, not an exercise format. The help-template `process` type is new design, not a mapping. |

## 2. Per-file results

### 2.1 `QA_WIMS_Integration_Owner_ALF_V2.md` (ALF_V2_3)

| Item | Status | Detail |
|---|---|---|
| Q-W1 "same `job=`/`module=` params" | PARTIAL | True at the CGI layer (§3 GV-1). Wrong on two points: (a) `job=` is not a `wims.cgi` parameter, it is a module variable (adm modules); (b) "Step 1: no authentication" holds for the anonymous OEF flow (`module=<exo module>&cmd=new|reply|hint|help|next&session=…`) but **not** for grade/class access, which goes through `adm/raw` with `ident`/`passwd` declared in `log/classes/.connections/`. Recommend the CDC name the real endpoints. |
| Q-W2 offline first | OK as decision | Inconsistent with the test assets: suites 21–23 are connected-mode (GV-2). |
| Q-W3 converter table | OK, 2 corrections | (a) `\hint`: converter keeps **only the first** `\hint` and **drops** `\help`, `\feedback`, `\solution` (`tools/oef2course_GROK_V1.py` L144–L179). (b) Gap list misses parameter computation (`wims()`, `slib()`, `pari()`, `maxima()`) — 214/300 files; the converter only resolves `random`/`randint`. |
| Q-W4 per-answer result | Still open vs code | #41/#42 return a single 0..1 `grade` (PR #59 finding, unchanged). WIMS natively has `cmd=hint`/`cmd=help` (see `wims.c` `commands[]`), useful for the "help request" half of Q-W4. |
| Q-W5 cheat sheets "authored in OEF" | Clarify | OEF has no cheat-sheet construct; the nearest are `\hint` (difficulty-gated, once) and `\help` (always available popup, once). |
| Q-W6 | OK | Reflected here, still missing from CDC V1_1 (PR #59). |
| Q-W7 | OK | wims4win runtime is wired for CAS PARI 2.19, Maxima 5.49, Octave 11.3, GAP 4.16.1 (`docs/05_Etat_et_Decisions.yaml` L209); Octave/Maxima security tests S6–S8 still `not_tested`. |
| §9.6 vs schema | MISMATCH | §9.6 shows `help.explanations`, `help.template`, `help.llm`, `step.transform`; Course V1_1 implements `help.{template|inline, variables}` and no `transform`/`llm` (schema checks C5, C6 rejected). Q-W9d says "Done" — it is only partially done. |

### 2.2 `Schema_Help_Template_JSON_CLAUDE_V1.json`

Valid draft 2020-12 schema (`check_schema` OK). Issues:

| # | Sev | Issue | Evidence |
|---|---|---|---|
| H1 | **P0** | Link tag `\help{file.json}` reuses a **native OEF command** whose body is displayed as popup text. In stock WIMS, `\help{aide_derivation.json}` would show the literal string "aide_derivation.json" in the Help popup. Needs a non-colliding carrier, e.g. `\text{algogebra_help=aide_derivation.json}` (ignored by WIMS rendering) or a `%%algogebra-help:` comment line (stripped by OEF). | `public_html/scripts/help/en/oefcommand` L91–93 ("gives a help to the exercise… always accessible… in a popup window. Can be used only one time"); real use `wims-full/log/classes/9001/src/ex6.oef` L9 |
| H2 | P1 | `engine` enum `giac, pari, maxima, gnuplot, gap` ≠ wims4win. wims4win CAS interfaces: `pari, maxima, octave, yacas, gap, m2, scilab` (`src/Interfaces/*.c`, same on D:); **GIAC is not a WIMS engine** (it is GeoGebra's built-in CAS); gnuplot is a plotting backend, not a CAS interface. Real OEF usage (1 479 unique): `pari()` 951 calls/110 files, `maxima()` 42/12, `wims()` 8 412/684, `slib()` 154/128; no `yacas()`/`octave()`/`gap()` calls found. | `wims4win_box_oef_unique_stats_GROK_V1.txt` |
| H3 | P1 | "Maximum nesting depth: 3" is prose only; the schema accepts 7 levels. Enforce in validator or unroll `$defs` per level. | schema check E4 VALID |
| H4 | P1 | `defaults` keys are not tied to `variables` (E5 VALID); OEF matrix/list variables (`\matrix` in 300/1 479 files) cannot be expressed (E6 INVALID: only string/number). | E5, E6 |
| H5 | P1 | `helpAction` CMD/CAS/VAL is right for help (no file I/O); but the allowlist/Sequence budget is not in the schema (`Delete(x)` validates, E7) — runtime validator must apply course security (Spec V1_2) to help actions **after** `{{}}` substitution. Also `CAS` in a help panel needs a CAS view; specify fallback. | E7 |
| H6 | P2 | `{{name}}` placeholders: **no conflict with OEF** (OEF uses `\name`, `\(..\)`, `{}`; the sequence `{{x}}` is not an OEF token and no `{{[a-zA-Z_]` occurrence was found in corpus 300). But inside LaTeX an unresolved `{{a}}` is valid TeX grouping → renders "a" silently; and `{{` collides with `{{WIMS_CGI_URL}}` template placeholders used in #40 (`web-host` template) — distinct files, but the substitution engine must not run twice. Sign handling: with `b=-1` the example renders `x^2 + 3x + -1`. | example, suite 21 WT-05 |
| H7 | P2 | Locale keys accept `fr_FR`, reject BCP-47 `fr-FR` (E3) — PR #59 finding, unchanged. OEF `\language{fr}` maps fine. |
| H8 | P2 | `maxItems` 20 steps / 10 children / 10 actions: reasonable. Real exercises: answers/file p95 = 20, max 54, 24/1 479 files have > 20 answers; multi-step OEF (`\steps`) rarely exceed 10 steps. A resolution tree per exercise ≤ 20 top steps fits. |
| H9 | P2 | No per-step `check`/expected-value machine form: `expectedResult` is display text only, so intermediate results (GAP-5 "intermediate checks") cannot be verified. |

### 2.3 `Schema_Course_JSON_CLAUDE_V1.json` (V1_1)

| # | Sev | Issue | Evidence |
|---|---|---|---|
| C-a | P1 | `helpRef` uses `oneOf` → `template` **and** `inline` together is rejected, contrary to its description "at least one". Use `anyOf` or fix the text. | check C2 |
| C-b | P1 | `variables` is an **object** in `helpRef` but an **array** (+ `defaults` object) in the help template — two shapes for one concept. | schema |
| C-c | P1 | `engine` enum same as H2 (no `octave`, check C4). And `checkAction` has no engine → `engine` per step cannot route a *check* (GAP-5 bridge `engine_check` absent, C7). | C4, C7 |
| C-d | P1 | WIMS declares engines **per call inside parameter definitions** (`\text{r=pari(…)}`, `\text{s=maxima(…)}`, `wims(…)`), possibly several engines per exercise; it is not a per-step property. A per-step `engine` is an AlgoGebra concept; the converter can only derive it heuristically from the calls used by that answer's variables. | corpus stats |
| C-e | P2 | `schemaVersion` stays `const "1.0"` although fields were added — no way for a reader to know V1_1 features are present. All 300 converter outputs are still valid under V1_1 (C8 300/300), so the change is backward compatible. | C8 |
| C-f | P2 | Converter pipeline: today the converter emits no `help`/`engine`. `helpRef.template` path resolution "relative to the course file" breaks when the converter writes the course elsewhere than the `.oef` directory (`-o` option); spec should say relative to the source OEF or copy templates beside the output. GAP-4 (submission namespace) not reserved. | `oef2course_GROK_V1.py` CLI |

### 2.4 `Example_Help_Template_CLAUDE_V1.json`

| # | Sev | Issue | Evidence |
|---|---|---|---|
| X1 | **P0** | Fails its own schema: top-level `$comment` vs `additionalProperties:false`. Valid once removed (PR #59 finding; re-run: E1 INVALID, E2 VALID). |
| X2 | P1 | `engine:"giac"` + `engineCommand:"Derivative(x^2 + {{a}}*x + {{b}}, x)"` is **GeoGebra CAS syntax**, not native GIAC. GeoGebra translates it in `Ggb2giac.java` (`Derivative.2` → `diff(…)`, L264). Native giac expects `diff(x^2+3*x-1,x)`. Works if "giac" means "GeoGebra CAS via `evalCommandCAS`", fails if sent to a giac subprocess. GIAC is not packaged for Debian trixie on the box (`apt: Unable to locate package giac`), so not executed; conclusion from GeoGebra source. Spec should define "giac" = GeoGebra CAS command language. |
| X3 | P2 | `\( … \)`: supported by JLaTeXMath as used by GeoGebra (`renderer-base/…/share/Commands.java` L523–529, `\(`→`OpenBracket`, mismatch error "The command \) doesn't match any \("). But JLaTeXMath parses the whole string as TeX: the plain-text parts (French accents, apostrophes `C'est`, `f'(x)` outside math) need the help panel to split text/math segments (or use `\text{}`); `'` outside math would become a prime. In the web host, MathJax/KaTeX accept `\(..\)` natively. |
| X4 | P2 | Representativeness: a symbolic derivation is **atypical** of the WIMS bank — 70/4 702 answers are `type=formal` vs 1 512 `numeric`, 464 `radio`, 344 `clickfill` (wims4win unique set). Most real exercises would need a `text` template or a numeric/choice-oriented process. `s` (=2+a) duplicates a derived value that should be computed, not a free default (with `a` re-injected at runtime and `s` not, the step-3 text becomes wrong). |

## 3. Checks GV-1…GV-7 with evidence

### GV-1 (P0) — CGI parameters — PARTIAL
- `src/wims.c` L268–291, identical in stock WIMS (`/workspace/wims-full`), box wims4win (`dc09f2f`) and D: wims4win (`45a7e96`, LF-normalised sha256 `6e674c406732ee9b…`):
  - read-only CGI names `ro_name[]`: `cmd, empty, lang, module, session, special_parm, special_parm2..4, useropts, wims_session, wims_subsession`;
  - `commands[]`: `intro, new, renew, reply, config, hint, help, resume, next, getins, getframe, getfile, close, ref`.
- `diff wims-full/src/wims.c wims-port/src/wims.c`: 2 hunks only — `#ifdef _WIN32 wp_cgi_prepare();` (L1191) and a variable rename at L770. Protocol unchanged → **Step 1→2 = transport/config change**. ✔
- `job=`: not a core parameter; used by `adm/*` modules (e.g. `adm/raw` jobs `checkclass, getscore, getsheetscores, addexo, putexo, …`; `adm/class` jobs `configfw, list, arch, student…`).
- ✘ D-S01 contract in #40/#41/#42 (`module=adm/class/sheet&job=getresult&exercise=<id>&ans1=<b64>`, README checked by suite 21 WT-13, enforced by `mock_wims_cgi_GROK_V1.mjs`): `grep -r getresult wims-full/public_html/modules` → **0 hits**. `adm/class/sheet` is the teacher sheet editor. Real server-to-server API = `module=adm/raw&ident=…&passwd=…&code=…&job=…` (`modules/adm/raw/protocol.md` L20–51), JSON output when the connection is declared `ident_type=json`; `ident/passwd` must exist in `log/classes/.connections/` → "no authentication" is false for grades even locally.

### GV-2 (P1) — suites 21–23 vs offline-first — FAIL (aligned with Phase 2, not MVP)
| Suite | Branch @ sha | Assumes server? |
|---|---|---|
| 21 WimsTemplate | `feat/grok-g14-wims-template` @ `0222ce1` | Yes: WT-05 `{{WIMS_CGI_URL}}`, WT-06 default `/wims/wims.cgi`, WT-12 "template computes no grade" (grade owned by WIMS), WT-13 D-S01 request. |
| 22 WimsGradeClient | `feat/grok-g15-wims-grade-client` @ `a30f8ec` | Yes: contract tests against a local **mock** of D-S01 (`mock_wims_cgi_GROK_V1.mjs`), single `grade` 0..1. |
| 23 WimsFullCycle | `feat/grok-g16-wims-full-cycle` @ `c9a6dd5` | Yes: Firefox cycle against the same mock. |
No offline scorer, no engine subprocess, no per-answer result. Recommendation (no action taken): keep them as Phase 2 "local-connected" assets; rebase the mock on the real `adm/raw` (or anonymous OEF `cmd=reply`) protocol before Phase 2.

### GV-3 (P0) — suite 19 vs GAP-1..5 — PASS with one extra gap
- Run: fresh worktree of `origin/feat/external-engines` @ `4e13b83`; `OEF_CORPUS=corpus300_list pwsh tests/19_Test_OefConverter_GROK_V1.ps1` → **16 PASS / 0 FAIL / 0 SKIP**, OC-16 `files=300 converted=300 schema-valid=300` (log `19_OefConverter_corpus300_tip4e13b83_GROK_V1.log`, 2026-11-04 07:31 CET).
- Per-file counts (`gap_count_GROK_V1.py` → `gap_counts_corpus300_GROK_V1.csv`):

| Gap | Operational definition | Files /300 |
|---|---|---|
| GAP-1 cheat sheet / structured help | file has `\hint`, `\help`, `\feedback`, `\solution` (teacher help the schema has no slot for; converter keeps only first `\hint`) | **53** (hint 16, help 2, feedback 36, solution 6) |
| GAP-2 engine routing | `pari()`/`maxima()`/`yacas()`/`octave()`/`gap()` used | **18** (pari 16, maxima 2) |
| GAP-3 compute/explore contract | GAP-2 or symbolic answer type (formal, algexp, function, matrix, set, units…) — proxy, runtime gap | **30** |
| GAP-4 submission/session | every file (no wire format) — Phase 2, not blocking offline | 300 |
| GAP-5 check types | ≥1 answer emitted as `object_exists` | **281** (answers: 16 `value_equals`, 1 824 `object_exists`); only 9 files fully auto-checkable |
| *Missing* — parameter computation | `wims()`, `slib()`, `pari()`, `maxima()` in definitions; converter resolves only `random/randint` | **214** |

- **GAP-5 blocks the most exercises** (281/300 = 94 %); 265 of those do not involve an external engine, i.e. they are choice/fill types (clickfill 334, dragfill 261, case 181, menu 135, puzzle 44 answers) that need new non-numeric check types, not an `engine_check`.
- Suggest a GAP-6 "server-side parameter computation" in the CDC (or an explicit "offline = seed-resolved by a WIMS run at conversion time" rule).

### GV-4 (P0) — hint/help/feedback constructs in real OEF — PASS
Official semantics (`wims-full/public_html/scripts/help/en/oefcommand`, `oefadv.phtml`; public `introProgOEF.pdf`):
- `\hint{…}` — hint, shown according to difficulty setup, **once per exercise** (L87–89).
- `\help{…}` — help text, **always accessible in a popup**, once per exercise (L91–93).
- `\feedback{condition}{text}` — conditional message on the reply, typically for common errors (L95–100).
- `\solution{…}` — explained solution after the exercise (L83–85).
- `\condition{name}{test}` / `\conditions{…}` — custom evaluation conditions (L76–81, L110–112).
- `\steps{…}` / `\nextstep{…}` — multi-step questions, static or answer-dependent (oefadv L24–58); `\if`, `\ifval`, `\while` usable inside hint/solution/feedback (oefadv L61–75).
- `\special{help name,label}` — link opening the `\help` popup with `\help_subject` (ex6.oef).

Counts:

| Construct | corpus 300 (files) | wims4win unique 1 479 (occ / files) | D: 40 fixtures (files) |
|---|---|---|---|
| `\hint` | 16 | 43 / 43 | 4 |
| `\help` | 2 | 2 / 2 | 1 |
| `\feedback` | 36 | 4 984 / 543 | 2 |
| `\solution` | 6 | 11 / 11 | 3 |
| `\condition` | 21 | 537 / 114 | – |
| `\steps` | 93 | 127 / 126 | 2 |
| `\nextstep` | 32 | 36 / 36 | 1 |
| `\remark` | 0 | 0 | – |

Examples: `wims-full/log/classes/1367/src/parallelo.oef` L38 `\hint{Prova a disegnare il quadrilatero sulla carta a quadretti.}`; `public_html/scripts/model/en/src/tablecheckbox.oef` L207 `\feedback{\givegood>0}{…}`; `scripts/model/fr/src/152twoparms.oef` L118 `\solution{\textsol}`; `modules/adm/tool/coordclick/data/example12.oef` L51 `\steps{\Step}`; `scripts/model/it/src/hanging.oef` L164 `\nextstep{\nstep}`.

### GV-5 (P1) — wims4win local HTTP on Windows — PARTIAL
- Procedure (`wims-port/docs/04_Guide_Installation_et_CGI_Laragon.md` §5, `docs/apache-laragon-wims-runtime.conf`): Laragon Apache + `mod_cgi`; `ScriptAliasMatch "^/wims/wims\.(.*)$" → ${WIMS_RT}/wims.cgi.exe` (+ index., `.._*.html`, `getfile/`), `Alias /wims`, `bin/` denied; restart via Laragon UI (not a Windows service); `wimslogd` is started on demand by `wims.exe` (named pipe per runtime).
- Proof on record: `docs/05_Etat_et_Decisions.yaml` L237 "200 sur http://wims_paris_saclay_fr.test/wims/wims.cgi (2026-10-27)"; `tool/algebra/factor.fr` → 450 (module not installed).
- Live check (read-only, 2026-11-04): `C:\laragon` exists; no `httpd` process; nothing started. The served tree is `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime`, not `D:\ALF_ZGit\02-wims4win` (which has sources only). The Q&A should name that runtime path.

### GV-6 (P0) — OEF with `\help` or equivalent — PASS
Yes, but rare and always **inline**: 2/300, 2/1 479, 1/40. Format = OEF text/HTML with conditionals, e.g. `wims-full/log/classes/9001/src/ex6.oef` L9–15:
```
\help{
  \if{ \help_subject issametext cara}{ Carabistouille est ma \special{help sorc, sorcière} préférée.}
  \if{ \help_subject issametext melu}{ Mélusine est ma \special{help fee, fée} préférée.}
  …}
```
No OEF anywhere references an external file from `\help`. Equivalent teacher help is predominantly `\feedback` (543 files) then `\hint` (43). Module-level help pages exist as `scripts/oef/<lang>/help.phtml` and `help/<lang>/oefchapterhelp` (system help, not exercise help).

### GV-7 (P1) — existing step-by-step resolution encoding — PASS (none)
- OEF `\steps`/`\nextstep`: sequence of *answer fields* per step (`\steps{choice 1, reply 1 \n reply 2,reply 3}`), no explanations/transformations; conditional `\nextstep` gives branching by student answer.
- `\feedback` + `\condition`: rule-based messages, no tree.
- xWIMS (UPEM 2016): Java search/annotation prototype — not an exercise format. La Ruche saves an editor JSON of OEF blocks, not resolutions. WIMS JSON exists only as `adm/raw` output (`ident_type=json`).
- Moodle STACK: Potential Response Trees encode answer-test trees with feedback per node — closest analogue for *evaluation* trees, still not a resolution process.
→ The `process` content type is a new format; it should borrow `\nextstep`-style branching (by student answer) and STACK-like node tests if Phase 2 needs intermediate checks.

## 4. OEF / WIMS patterns not covered by the schemas

| Pattern | Real frequency (unique 1 479 unless noted) | Not covered by |
|---|---|---|
| Non-numeric answer types (`radio` 464, `clickfill` 344, `dragfill` 272, `case` 269, `menu` 155, `correspond` 66, `puzzle` 55, `checkbox` 55, `reorder` 26…) | majority of answers | `checkAction.type` (GAP-5) |
| Symbolic answers `formal`/`algexp`/`function`/`numexp` + `\range`, `\computeanswer` (81 files) | 70+ answers | `cas_equals` has no range/variable/equivalence options |
| `\feedback{cond}{text}` conditional messages | 4 984 occ / 543 files | only `feedback.pass/fail`; no condition list |
| `\hint` / `\solution` (difficulty-gated, post-exercise) | 43 / 11 files | help template has `hint` per step but no exercise-level hint/solution slots or visibility rules |
| `\steps` / `\nextstep` multi-step with branching | 126 / 36 files | course steps are linear, no answer-dependent next step |
| `\condition` / `\conditions` custom evaluation | 114 files | – |
| Parameter computation `wims()`, `slib()`, `pari()`, `maxima()`, `evalue()` | 684 / 128 / 110 / 12 / 55 files | converter + schema (no deferred/computed values) |
| Matrix / list variables (`\matrix`) | 300 files | `defaults`/`variables` scalar only |
| `\embed{reply n, options}` answer placement inside the statement | 1 108 files | statement is flat text; inputs are separate steps |
| Answer options (`shuffle`, `noorder`, `nonstop`, `split`, `hide` …) | thousands | – |
| Exercise-level `\help` popup with `\special{help …}` subjects | 2 files | `\help{file.json}` collides (H1) |
| Engines `octave`, `yacas`, `m2`, `scilab` in wims4win | interfaces present, no OEF calls found | `engine` enum |

## 5. Recommendations (for Claude / owner; nothing applied)
1. **P0** Replace the `\help{file.json}` carrier (H1). Proposed: `\text{algogebra_help=aide_derivation.json}` or `%%algogebra-help: aide_derivation.json`; keep native `\help{}` mapped to a `text` help.
2. **P0** Fix X1 (`$comment`), and define "giac" = GeoGebra CAS command language (X2), or rename to `geogebra-cas`.
3. **P0/P1** Base the Phase 2 wire format on real WIMS (`adm/raw` or anonymous `cmd=reply`), drop `adm/class/sheet&job=getresult`; document auth for Step 1.
4. **P1** Extend `checkAction` for choice/fill types (biggest blocker, 281/300) before `engine_check`.
5. **P1** Align `engine` enum with wims4win (add `octave`, `yacas`; reconsider `gnuplot`), unify `variables` shape, `oneOf`→`anyOf`, enforce depth, add matrix/list defaults, bump `schemaVersion` or add a feature flag.
6. **P1** Add GAP-6 (parameter computation) to Q-W3 and decide: seed-resolve via WIMS at conversion time vs. unsupported.

## Appendix — commands and evidence
```
git worktree add --detach /workspace/AlgoGebra/wt-gv-tip origin/feat/external-engines   # 4e13b83
OEF_CORPUS=corpus300_list_GROK_V1.txt pwsh -File 03-RCP-Spike/tests/19_Test_OefConverter_GROK_V1.ps1
python3 gap_count_GROK_V1.py tools/oef2course_GROK_V1.py corpus300_list_GROK_V1.txt gap_counts_corpus300_GROK_V1.csv
python schema_checks_GROK_V1.py        # jsonschema Draft202012Validator, checks E1–E7, C1–C8
find /workspace/wims-port -name '*.oef' | sha256sum-dedupe → 1 479 unique; directive/answer-type stats
diff /workspace/wims-full/src/wims.c /workspace/wims-port/src/wims.c
grep -r getresult /workspace/wims-full/public_html/modules            # 0 hits
# Windows (read-only): Get-ChildItem, Select-String on D:\ALF_ZGit\02-wims4win\src\wims.c, LF-normalised SHA256
```
Files in `03-RCP-Spike/evidence/20261104-gv-validation-wims-cdc_GROK_V1/`: `19_OefConverter_corpus300_tip4e13b83_GROK_V1.log`, `19_OefConverter_GROK_V1.csv`, `corpus300_list_GROK_V1.txt`, `gap_count_GROK_V1.py`, `gap_counts_corpus300_GROK_V1.csv`, `gap_summary_corpus300_GROK_V1.txt`, `schema_checks_GROK_V1.py`, `schema_checks_GROK_V1.txt`, `wims4win_box_oef_unique_stats_GROK_V1.txt`, `SHA256SUMS`.

*End of `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md`.*
