<!-- GROK_V1 -->
# Live Debian WIMS + AlgoGebra hook fixtures (GB-N1, for WA-9 / Codex CI)

Recorded 2026-11-05 on Debian WIMS 4.31b with the `algogebra_json` hook (evidence of PR #64). They are byte-exact copies of the live responses; replay them from a mock. `manifest_GROK_V1.json` lists every case.

## Wire flow
1. `GET wims.cgi?` + `request_new.query` (`cmd=new`, `module`, `exo`, **no** `special_parm`). Read `name="session" value="…"` from `response_new.html`.
2. `cmd=reply` with `session`, `module`, `replyN`/`choiceN` (never `ansN`) and `special_parm=algogebra_json` (**reply only**). The body is in `request_reply.body`; it is percent-encoded **windows-1252**.

## Client rules
- **Decode** the whole page as `windows-1252`, extract `<!-- ALGOGEBRA_JSON_BEGIN … ALGOGEBRA_JSON_END -->`, then `json.loads`. The JSON holds raw cp1252 bytes (no `\u` escapes).
- **3-way classification** (no extra status field):
  - JSON present → graded (`json`)
  - no JSON + `answer_analysis` → hook off / `special_parm` missing (`hook_off`)
  - no JSON + retry UI (`Êtes-vous sûr`, `replyform`, "n'est pas compréhensible") → incomplete or unparsable answer, ask again (`retry`)
- **`grade`** is a number in 0..1; integers `0` and `1` occur and must be accepted.
- **`given`** is WIMS-normalised (`2--0` → `2+0`, spacing collapsed); never show it as the user's keystrokes.
- **Encoding:** send `replyN` as windows-1252. A correct `été` sent as UTF-8 is graded **wrong** (case `gbw8acc_ete_utf8_graded_wrong`). Characters outside cp1252 must be rejected client-side, with no request (case `client_reject_unrepresentable_cp1252`).
- Checkbox `expected` keeps the option list: `3,5;1,2,3,4,5,6`.

## Cases (11)
00006 right/wrong · 00076 checkbox right/wrong · 00006 hook-off · 00006 retry · gbw8acc `été` cp1252 right · `ÉTÉ` right · `février` wrong · `été` UTF-8 graded wrong · unrepresentable-char client reject.

Sessions in the files are dead; replay only. Integrity: `SHA256SUMS`.
