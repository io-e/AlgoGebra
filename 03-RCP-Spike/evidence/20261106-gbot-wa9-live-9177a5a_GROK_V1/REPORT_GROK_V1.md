<!-- GROK_V1 -->
# GB-N3 — WA-9 live re-smoke @ 9177a5a

| Field | Value |
|---|---|
| Date | 2026-11-06 (Europe/Paris) |
| Client tip | `codex/wims-wa9-client` @ `9177a5a` (verified) |
| Endpoint | `http://127.0.0.1:18431/wims/wims.cgi` |
| Server | `gv_wims_cgi_server.py` PID **3966079** (left running) |
| wimslogd | auto-spawned by `wims.cgi` on first request → PID **3988139** (left running; not started manually) |
| Handoff | `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md` **not on origin** (planning ahead-3 unpushed); followed owner paste brief |
| Verdict | **ALL GREEN** |

## Counts

| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| `test-wims-live.ps1` 00006 right (`reply1=2`, expect 1) | 3 | 0 | 0 |
| `test-wims-live.ps1` 00006 wrong (`reply1=0`, expect 0) | 3 | 0 | 0 |
| suite 23 `23_Test_WimsFullCycle_CODEX_V1.ps1` (fixtures + W4-live) | **30** | **0** | **0** |
| optional `gbw8acc` / `été` cp1252 live | 3 | 0 | 0 |

**W4-live:** not SKIP. Cases `W4-live-live-session-and-reply`, `W4-live-live-grade-is-numeric`, `W4-live-live-grade-matches-expected`, `W4-live-smoke-exit` all **ok** (default live answer `2` / grade `1` on 00006).

**Accent:** `été` via Java client (strict windows-1252 encode) → grade 1, correct. Parallel curl capture confirms JSON `given`/`expected` bytes `e9 74 e9`.

## Failures
None. No Codex product gaps found on this tip for the exercised paths.

## Notes
- Suite 23 on this tip is the CODEX_V1 fixture-backed cycle + optional live smoke (not the older Playwright G-16). No WAR / X display needed.
- `Exindex` temporarily listed `00006,00076,gbw8acc` for the run; restored afterwards.
- Logs: `logs/`; curl request/response captures: `raw/`.
