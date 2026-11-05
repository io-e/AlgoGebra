<!-- GROK_V1 -->
# Report — AlgoGebra JSON hook on Debian WIMS (GB-W1..W4 + GB-W8)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Author | Grok Bot (Debian lane) |
| Sources | `Planning_GBot_Next_Actions_GROK_V1.md`, `Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` (@ `29f7771`), `Spec_WIMS_Message_Integration_GROK_V1_1.md`, `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md` |
| Evidence | `03-RCP-Spike/evidence/20261105-gbot-algogebra-json-debian_GROK_V1/` (SHA256SUMS) |
| Policy | Evidence-only. No merge, no wims4win push, no product edits. |

**Verdict: P0 GREEN. 4/4 smoke cases PASS, 2/2 negatives PASS.** The Windows hook works unmodified on stock Linux WIMS 4.31b.

## 1. Environment

| Item | Value |
|---|---|
| WIMS | 4.31b, Debian-built runtime (box copy `gv_wimsrt`) |
| HTTP | `http://127.0.0.1:18431/wims/wims.cgi` (python CGI front `gv_wims_cgi_server.py`, GET) |
| Module | `H6/test/oef2html.fr`, seed fixed at 1 in `var.proc` (already present) |
| wims4win tip (GB-W1) | `feat/algogebra-wims-integration` @ `928d383` (contains `bb929e3`) |
| AlgoGebra base | `feat/grok-sprint3-plan-v1-1` @ `29f7771` |

## 2. GB-W1 — variable map and patch summary

- Chain: `main.phtml → answer.phtml`; grading `var.proc → ans.proc → screply.proc → module_score`.
- Hook reads live vars `module_score` (0–10 → `grade`=/10), `wims_seed`, `replycnt`/`choicecnt`, `replyN`, `replygoodN`, `m_sc_replyN` (0/0.5/1), `choiceN`/`m_sc_choiceN`.
- `correct = m_sc_* >= 1`. Strings: `!singlespace`, escape `\`, `"`, and `--` → `\u002d\u002d`. `feedback` empty in V1.
- `answer.phtml` injection: 6 lines after `!!end of .answer_analysis</div>`, before `!!presentsol=1 deprecated`, gated `!if $special_parm=algogebra_json`.
- Trigger on reply only (`select.phtml` would treat `special_parm` as `exo` on `cmd=new`).

## 3. GB-W2 — install

Done with a Python equivalent of `install_algogebra_hook_GROK_V1.ps1` (same regex, LF line endings; Debian `answer.phtml` is LF). The anchor matched once.

| File (under `gv_wimsrt/public_html/`) | Before SHA256 | After SHA256 | Backup |
|---|---|---|---|
| `scripts/oef/answer.phtml` | `7b96041f…eb24cae2` | `a3ce338e…cf0ea9e0` | `answer.phtml.bak_pre_algogebra` |
| `scripts/oef/algogebra_json.phtml` | absent | `8174221d…0444743e837b0a` (= wims4win `928d383`) | n/a (new) |
| `modules/H6/test/oef2html.fr/def/00006.def`, `00076.def` | absent | see `sha256_after.txt` | n/a (new) |
| `modules/H6/test/oef2html.fr/Exindex` | `1e66c39b…` | rewritten per case, **restored** to original at end | `Exindex.bak_pre_algogebra` |
| `modules/H6/test/oef2html.fr/var.proc` | `9dba4c74…` | unchanged (already `!setseed 1`) | `var.proc.bak_pre_algogebra` |

00006/00076 were not in the runtime. They were compiled from wims4win `tools/oef-validation/html/exemples/sources/{00006,00076}.oef` with the Debian `bin/oef2wims` (rc=0), exactly as `test_algogebra_json_GROK_V1.py` does. Full hashes: `sha256_before.txt`, `sha256_after.txt`; diff: `answer_phtml_GROK_V1.diff`. The hook is still installed in the box runtime (needed for GB-W7).

## 4. GB-W3 / GB-W4 — results

Flow per case: `cmd=new` (no `special_parm`) → `cmd=reply&special_parm=algogebra_json&reply1=…`. No JSON marker appeared on any `cmd=new` page.

| Case | reply1 | JSON present | Valid JSON | grade (exp) | correct/score | id=reply1 | given echoed | Result |
|---|---|---|---|---|---|---|---|---|
| 00006 wrong | `0` | Y | Y | 0 (0) | false / 0 | Y | `0` | **PASS** |
| 00006 right | `2` | Y | Y | 1 (1) | true / 1 | Y | `2` | **PASS** |
| 00076 wrong (checkbox) | `1` | Y | Y | 0 (0) | false / 0 | Y | `1` | **PASS** |
| 00076 right (checkbox) | `3, 5` | Y | Y | 1 (1) | true / 1 | Y | `3, 5` | **PASS** |
| GB-W4 00006 no `special_parm` | `2` | **N** (expected) | – | graded page (`answer_analysis`) | – | – | – | **PASS** |
| GB-W4 00076 no `special_parm` | `3, 5` | **N** (expected) | – | graded page | – | – | – | **PASS** |

Raw: `raw/*.html`, extracted: `json/*.json`, machine results: `results.json`, script: `smoke_gbw3_w4_GROK_V1.py`.

## 5. Diffs vs Windows smoke (`bb929e3`)

- Same schema and same grades. 00076 `expected` = `3,5;1,2,3,4,5,6` (option-list suffix, as the Spec V1 note says).
- `grade` is emitted as an integer literal (`0`, `1`), not `0.0`/`1.0`. Valid JSON, but clients must parse it as a number, not require a float token.
- `given` is WIMS-normalised, not raw: `2--0` came back as `"given":"2+0"`. The `--` escape path was never reached for numeric input.

## 6. GB-W8 — charset

| Check | Finding |
|---|---|
| HTTP `Content-Type` (all 21 responses) | `text/html; charset=windows-1252` |
| HTML meta | `<meta charset="windows-1252">` |
| Page body | French UI text is raw cp1252 bytes (`0xE9` é, `0xE8` è), not entities |
| JSON block, 6 smoke + 2 extra | 100 % ASCII; decodes identically as cp1252 / UTF-8 |
| Non-ASCII in JSON | **Not observable with 00006/00076**: numeric and checkbox fields reject `é "x" -- a\b` (cp1252- or UTF-8-encoded) with the retry page "La réponse n'est pas compréhensible", and **no JSON block** is emitted |

Analysis: the hook only escapes `\`, `"` and `--`. Any non-ASCII byte in `replyN`/`replygoodN` would be copied raw in **cp1252**, not `\uXXXX`. A client that decodes the page as cp1252 (Spec §5) gets correct text; a client that assumes UTF-8 gets mojibake. The Spec claim "JSON block is ASCII-safe" holds only for ASCII answers.

## 7. Findings / proposals (no redesign done)

1. **F1 – retry page has no JSON.** An unparseable answer returns a "not understood" page without the block. Under CDC AC-C7 the client would wrongly report "hook not installed". Proposal: either (a) client distinguishes via the `answer_analysis` marker / retry form `name="replyform"`, or (b) emit a small block such as `{"status":"unparsed"}` from the retry template (would need a second injection; owner/Claude call).
2. **F2 – non-ASCII.** Proposal: the Spec states "decode the whole page as `windows-1252` before extracting", or the hook escapes bytes ≥ 0x80 as `\u00XX`. Needs a text-answer exercise (GB-W10/W8 follow-up) to confirm live.
3. **F3 – integer `grade`.** Spec example shows `0.75`; document that `0`/`1` integers are possible.

## 8. GB-W5..W7 status

GB-W5 (build-runtime-tree.sh) not started; wims4win untouched. GB-W6 N/A (phtml-only, no C changed). GB-W7 not started.

## 9. Blockers for Codex WA-9

None blocking. WA-9 should: decode as cp1252, accept integer `grade`, and handle F1 (no-block retry page ≠ hook missing).

## 10. Reproduce

```bash
python3 /workspace/grok-g1/gv_wims_cgi_server.py /workspace/grok-g1/gv_wimsrt/public_html 18431 &
python3 03-RCP-Spike/evidence/20261105-gbot-algogebra-json-debian_GROK_V1/smoke_gbw3_w4_GROK_V1.py <outdir-with-raw/-and-json/>
# stop: pkill -f gv_wims_cgi_server.py; pkill -f bin/wimslogd
```

---

## Addendum A (2026-11-05 17:40 UTC+1) — GB-W5 installer check, GB-W7 live suites, GB-W8 accented answer

Evidence: `03-RCP-Spike/evidence/20261105-gbot-live-suites-accent_GROK_V1/` (SHA256SUMS). Owner client rules (accepted): JSON present = OK; no JSON + `answer_analysis` = hook off; no JSON + "Êtes-vous sûr"/retry UI = incomplete; decode cp1252 → extract → `json.loads`; `grade` numeric (int OK); `given` normalised.

### A.1 GB-W5 installer parity (wims4win `4ae4d86`, read-only)

`install_algogebra_hook_GROK_V1.sh` run on a scratch copy of the pristine Debian `answer.phtml.bak_pre_algogebra`: output `answer.phtml` SHA256 `a3ce338e…cf0ea9e0` and `algogebra_json.phtml` `8174221d…e837b0a` — **byte-identical** to my manual install. Nothing pushed to wims4win.

### A.2 GB-W7 — suites 21–23 against LIVE Debian WIMS + hook

Fresh detached worktrees at PR heads: #40 `0222ce1` (21), #41 `a30f8ec` (22), #42 `c9a6dd5` (23). Server `http://127.0.0.1:18431/wims/wims.cgi`. The suites have no URL switch (the mock is started in-process on a random port), so I made **local, uncommitted, test-only** overrides keyed on `WIMS_LIVE_EP` (diffs in `overrides/`):
- s22: `grade_client_test_GROK_V1.mjs` imports an untracked `live_proxy_GROK_V1.mjs` (same `start()` API as the mock, forwards to live WIMS, writes the same request log). A first attempt that only swapped the endpoint crashed because the test reads the mock's log (`tap/suite22_attempt1_…`).
- s23: `serve_wims_cycle_GROK_V1.mjs` proxies `/wims/wims.cgi` to live WIMS with the same logging.
- No product code (`wims/course-activity-template/*`) touched.

| Suite | Mock (earlier) | **Live** | Notes |
|---|---|---|---|
| 21 template (static) | 14/0/0 | **14/0/0** | Never contacts WIMS; passes, but WT-06/WT-13 enshrine D-S01 |
| 22 grade client | 28/0/0 | **19/9/0** | All 8 node FAILs (+summary) are cases needing mock behaviour (JSON grade, 500, 413, out-of-range, slow, wims-result markers) |
| 23 full cycle (Firefox) | 13/0/0 | **4/2/0** | FC-01..04 pass (tree, applet, steps, check); FC-05 times out: client shows error, no grade; rest not reached |

Live WIMS reply to the client's POST `module=adm/class/sheet&job=getresult&exercise=…&ans1=…` is a 200 `text/html; charset=windows-1252` "Worksheet / Edit worksheet" page (no class session), **no JSON**, no `answer_analysis` (`s23_out/live_ok-trig-1.html`, `raw/s22/`). `cmd=getresult` still → HTTP 450.

### A.3 Gap list for Codex (WA-9)

| # | Area | Client / suite assumes (mock) | Real WIMS + hook |
|---|---|---|---|
| G1 | cmd flow | single POST `module=adm/class/sheet&job=getresult` | two steps: `cmd=new` (module+exo) → session → `cmd=reply&session=…` |
| G2 | session | none | must parse `name="session" value="…"` from `cmd=new` page and resend |
| G3 | field names | `exercise`, `ans1` (base64 .ggb) | `exo`, `replyN` / `choiceN`; no `ansN`; a `.ggb` base64 is not a gradable OEF reply |
| G4 | trigger | none | `special_parm=algogebra_json` on reply only |
| G5 | response | raw JSON body `{grade,feedback}` (or `wims-result` script/div adapter) | HTML page, JSON inside `<!-- ALGOGEBRA_JSON_BEGIN … END -->`; schema `{grade,seed,answers[],feedback}` |
| G6 | missing JSON | "HTML ⇒ error" only | 3-way rule: JSON / `answer_analysis` (hook off) / retry UI (incomplete) |
| G7 | encoding | `Content-Type …charset=UTF-8`, `JSON.parse(text)` | page cp1252; reply must be sent **cp1252**-encoded (see A.4) |
| G8 | HTTP errors | 413, 500, timeouts, out-of-range grades produced by mock | WIMS answers 200 HTML for all of these; tests GC-09/10/11/25 cannot be reproduced live and must stay mock-only |
| G9 | suite 21 | WT-06/WT-13 assert D-S01 README text | must be re-worded for `cmd=new`/`reply` contract |
| G10 | suite 23 | FC-06 asserts `module=adm/class/sheet`, `job=getresult` | rewrite to assert `cmd=reply`, `special_parm`, `replyN` |

### A.4 GB-W8 — accented correct answer (closed)

Exercise `gbw8acc.oef` (cp1252 source, `\answer{Saison}{\sol}{type=nocase}`, `sol=été`), compiled with Debian `bin/oef2wims` (rc 0) into `modules/H6/test/oef2html.fr/def/gbw8acc.def` (left installed; `Exindex` restored). Flow `cmd=new` → `cmd=reply&special_parm=algogebra_json&reply1=…`; page decoded cp1252 → comment extracted → `json.loads`.

| Case | Sent bytes | Parses | grade/correct | `given` bytes | `expected` bytes |
|---|---|---|---|---|---|
| right, cp1252 `été` | `e9 74 e9` | Y | 1 / true | `e9 74 e9` | `e9 74 e9` |
| right, cp1252 `ÉTÉ` (nocase) | `c9 54 c9` | Y | 1 / true | `c9 54 c9` | `e9 74 e9` |
| wrong, cp1252 `février` | `66 e9 76 72 69 65 72` | Y | 0 / false | same | `e9 74 e9` |
| **right, UTF-8 `été` (GET)** | `c3 a9 74 c3 a9` | Y | **0 / false** | `c3 a9 74 c3 a9` (→ `Ã©tÃ©`) | `e9 74 e9` |
| wrong, UTF-8 `février` | `66 c3 a9 …` | Y | 0 / false | raw UTF-8 bytes | `e9 74 e9` |
| **right, UTF-8 POST** (`charset=UTF-8` header) | `c3 a9 74 c3 a9` | Y | **0 / false** | raw UTF-8 bytes | `e9 74 e9` |

Findings: the JSON block carries **raw cp1252 bytes** (no `\u` escaping) and parses correctly after cp1252 decoding. WIMS does **not** honour a UTF-8 form charset: a correct accented answer sent as UTF-8 is graded **wrong**. **Proposal (Spec §5 / WA-9):** the client must percent-encode `replyN` in windows-1252 (and refuse/flag characters outside cp1252), not UTF-8 as `Spec_WIMS_Message_Integration_GROK_V1_1.md` §5 currently states. This is an owner/Claude spec correction; no hook change needed.

### A.5 Processes

Server PID 3953069 and the wimslogd it spawned (PID 3953086) stopped; no wimslogd was running before this run (`wimslogd_pids_before.txt`).
