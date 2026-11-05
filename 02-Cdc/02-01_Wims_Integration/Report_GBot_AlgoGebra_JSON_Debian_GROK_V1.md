<!-- GROK_V1 -->
# Report — GBot AlgoGebra JSON hook on Debian WIMS (GB-W1…W8)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Handoff | `Handoff_GBot_AlgoGebra_WIMS_Integration_GROK_V1.md` (wims4win `AlgoGebra_Wims_Integration/`, local PC branch `feat/algogebra-wims-integration` @ `928d383`, ≥ `bb929e3`; not on GitHub) |
| Evidence | `03-RCP-Spike/evidence/20261105-gbot-algogebra-json-debian_GROK_V1/` |
| wims4win packaging branch | `feat/algogebra-json-hook` @ `719549d` (not merged) |

## 1. Environment
- Debian box, WIMS **4.33a** (SVN r19040) Linux build from `tools/build-runtime-tree.sh` (`build/runtime-r19040/wims`), copied to a private tree `/workspace/mw-algogebra/debwims`.
- Module `H6/test/oef2html.fr` = stock `template/oef.fr` + `00006.def`, `00076.def` compiled by Linux `bin/oef2wims` from wims4win `tools/oef-validation/html/exemples/sources`; `!setseed 1`.
- CGI run directly (`public_html/wims`, CGI env, GET) — same method as the Windows smoke test; no HTTP server.
- Test-only: `log/wims.conf` gets `threshold1/2` raised (shared box load triggered "Nous sommes trop occupés").

## 2. Results
| Task | Result | Evidence |
|---|---|---|
| GB-W1 | PASS — tip `928d383`; variable map + `runtime_patch/` read | — |
| GB-W2 | PASS — `algogebra_json.phtml` copied; `answer.phtml` injected (6 lines, after `!!end of .answer_analysis`/`</div>`); backup `answer.phtml.bak_pre_algogebra`; installer idempotent | `install_algogebra_hook.sh` |
| GB-W3 | PASS 4/4 | `*_hook_reply.html`, `*.json`, `results.txt` |
| GB-W4 | PASS 4/4 — no `ALGOGEBRA_JSON_BEGIN`, page still graded | `*_nohook_reply.html` |
| GB-W5 | PASS (branch) — hook applied to `$OUT` only when patch dir present; `ALGOGEBRA_HOOK=0` disables; master builds unchanged | wims4win `719549d` |
| GB-W6 | PASS — phtml-only, no C changed; `check-linux-identical.sh` skipped | — |
| GB-W7 | 21: 14/14, 22: 28/28 (mock), 23: SKIP (no Playwright/WAR). **Cannot run vs live hook**: suites use D-S01 `adm/class/sheet&job=getresult&ans1=` | `suites/` |
| GB-W8 | PASS — page `charset=windows-1252`; JSON block bytes all ASCII; no mojibake | `results.txt` |

| Exo | Given | grade | id | correct | expected |
|---|---|---|---|---|---|
| 00006 | `0` | 0 | reply1 | false | `2` |
| 00006 | `2` | 1 | reply1 | true | `2` |
| 00076 | `1` | 0 | reply1 | false | `3,5;1,2,3,4,5,6` |
| 00076 | `3, 5` | 1 | reply1 | true | `3,5;1,2,3,4,5,6` |

**Parity with Windows (`bb929e3`):** same grades, ids and schema. No Linux-specific difference.

## 3. Gaps for Codex WA-9
1. `wims-grade-client_GROK_V1.js` builds `module=adm/class/sheet&job=getresult&exercise=&ans1=<base64>`, which is forbidden now. It must change to `cmd=new` (no special_parm), then `cmd=reply&session=…&special_parm=algogebra_json&replyN=…`. Live probe of the old request: HTTP 200, no grade/JSON (`suites/live_DS01_getresult.html`).
2. The response is HTML with a JSON block in an `<!-- ALGOGEBRA_JSON_BEGIN … END -->` comment. The client must extract it instead of `JSON.parse(body)`, and decode the page as windows-1252.
3. Session handling: the client has to read `name="session"` from the `cmd=new` page.
4. Field mapping: replace `ans1` with `reply1…N`/`choice1…N`. How a GeoGebra construction maps onto `replyN` is not defined yet.
5. Suite 21 WT-13 checks that the README documents D-S01 verbatim, and suite 22's mock serves D-S01. Both must be rebased, otherwise they enforce the forbidden path.
6. Suite 23 needs Playwright, Firefox and `GGB_WAR_DIR` on Debian (not done because it's P2/W9).
7. Checkbox `expected` keeps the `;optionlist` suffix (`3,5;1,2,3,4,5,6`), and `given` keeps the space (`3, 5`). Clients must not string-compare them.

## 4. Proposed spec text (not applied)
For `Spec_WIMS_Message_Integration_GROK_V1_1.md` §JSON:
> `answers[].expected` is the raw `replygoodN` after singlespace. For `replytypeN=checkbox` it is `<good indices>;<option list>`, and clients MUST take only the part before `;`. `given` is the raw student string, unnormalized. The JSON block is pure ASCII. The surrounding page is served in the WIMS language charset (`windows-1252` for fr), and clients MUST NOT assume UTF-8 for the HTML.

For the CDC (supersedes D-S01 in the G-14/G-15 README):
> The grade request is `cmd=reply` on an existing session with `special_parm=algogebra_json`. `module=adm/class/sheet&job=getresult` is not a grade path.

## 5. P2 not done (what is needed)
W9 needs a Debian HTTP front (Apache or a CGI shim) plus a small script. W10 needs a corpus exercise with `\choice`; none was checked. W11: the `*.json` files in this evidence pack can serve as fixtures directly. W12 doesn't apply, because no HTTP URL was used.

## 6. Reproduce
`install_algogebra_hook.sh <wims_root> <runtime_patch>` ; `python3 smoke_debian.py <evidence_dir>` (`WIMS_HOME`=tree).
