<!-- GROK_V1 -->
# Handoff — GBot GB-N3: WA-9 live re-smoke on Debian

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| From | Grok Build |
| To | **Grok Bot** (Debian WIMS + hook) |
| Codex branch | [`codex/wims-wa9-client`](https://github.com/io-e/AlgoGebra/tree/codex/wims-wa9-client) @ **`9177a5a`** |
| No PR yet | Evidence-only draft OK; **do not merge** without owner |
| Policy | Live HTTP only; keep **wimslogd** as auto-spawned by CGI or stopped — do not start it yourself; tear down with the server |
| Prior gaps | Closed for product code by Codex; this run proves **live** (fixtures in branch are replays only) |

---

## 0. Context

Codex WA-9 is pushed:

- Java `HttpWimsClient`: `cmd=new` → `cmd=reply`, `special_parm=algogebra_json` on reply only, strict **windows-1252**, JSON grades + 3-way no-JSON handling  
- Fixture replay: Java **46/0**; suites **21 24/0/0**, **22 24/0/0**, **23 26/0/1** (skip = live not configured)  
- Live entrypoint: `03-RCP-Spike/host/test-wims-live.ps1` + suite 23 when `GGB_WIMS_LIVE_ENDPOINT` is set  

Your job: **GB-N3** — make that skip a PASS against real Debian WIMS + AlgoGebra hook.

---

## 1. Prep

```bash
cd /path/to/AlgoGebra
git fetch origin codex/wims-wa9-client
git checkout -B wa9-live-resmoke origin/codex/wims-wa9-client   # or detached @ 9177a5a
# confirm tip
git rev-parse --short HEAD   # expect 9177a5a
```

Start the same CGI front as #64 (`http://127.0.0.1:18431/wims/wims.cgi`) with hook still installed (`algogebra_json.phtml` + patched `answer.phtml`). Modules `H6/test/oef2html.fr` with `00006` / optional `gbw8acc`.

**wimslogd:** if the CGI server spawns it, leave it for the session; stop with the server afterward. Do not start it manually unless owner asks.

---

## 2. P0 — live smoke matrix

Evidence root:

`03-RCP-Spike/evidence/YYYYMMDD-gbot-wa9-live-9177a5a_GROK_V1/`

### 2.1 Direct live runner (required)

```powershell
$env:JAVA_HOME = '…'   # JDK 21+
pwsh -NoProfile -File 03-RCP-Spike/host/test-wims-live.ps1 `
  -Endpoint 'http://127.0.0.1:18431/wims/wims.cgi' `
  -Module 'H6/test/oef2html.fr' `
  -Exercise '00006' `
  -Field 'reply1' `
  -Answer '2' `
  -ExpectedGrade '1' `
  -Language 'fr'
```

Also run **wrong** path (`Answer '0'`, `ExpectedGrade '0'`). Capture stdout + exit codes into the evidence folder.

### 2.2 Suite 23 with live opt-in (required)

```powershell
$env:GGB_WIMS_LIVE_ENDPOINT = 'http://127.0.0.1:18431/wims/wims.cgi'
$env:GGB_WIMS_LIVE_MODULE = 'H6/test/oef2html.fr'
$env:GGB_WIMS_LIVE_EXERCISE = '00006'
$env:GGB_WIMS_LIVE_FIELD = 'reply1'
$env:GGB_WIMS_LIVE_ANSWER = '2'
$env:GGB_WIMS_LIVE_EXPECTED_GRADE = '1'
$env:GGB_WIMS_LIVE_LANGUAGE = 'fr'
pwsh -NoProfile -File 03-RCP-Spike/tests/23_Test_WimsFullCycle_CODEX_V1.ps1
```

Expect: previous fixture cycle still green **and** `W4-live-*` no longer SKIP.

### 2.3 Optional accent (GB-W8 live via client)

If `gbw8acc` still installed:

```powershell
pwsh -NoProfile -File 03-RCP-Spike/host/test-wims-live.ps1 `
  -Endpoint 'http://127.0.0.1:18431/wims/wims.cgi' `
  -Module 'H6/test/oef2html.fr' `
  -Exercise 'gbw8acc' `
  -Field 'reply1' `
  -Answer 'été' `
  -ExpectedGrade '1' `
  -Language 'fr'
```

Confirm the client sends **cp1252** (wrong grade if UTF-8) — if live fails with mojibake, capture request bytes and file a Codex bug; do not “fix” by changing Spec in product without report.

### 2.4 Optional suite 21/22 fixture re-check on this checkout

```powershell
pwsh -NoProfile -File 03-RCP-Spike/tests/21_Test_WimsProtocol_CODEX_V1.ps1
pwsh -NoProfile -File 03-RCP-Spike/tests/22_Test_WimsClient_CODEX_V1.ps1
```

(Replay only; still not live evidence.)

---

## 3. Deliverable

Create draft PR or push branch `grok/gbot-wa9-live-9177a5a` with:

1. Evidence folder + `SHA256SUMS`  
2. Short report: `02-Cdc/02-01_Wims_Integration/Report_GBot_WA9_Live_9177a5a_GROK_V1.md`  

| Check | PASS/FAIL | Notes |
|---|---|---|
| live 00006 right grade 1 | | |
| live 00006 wrong grade 0 | | |
| suite 23 W4-live (no skip) | | |
| optional gbw8acc | | |
| wimslogd policy | stopped or auto-spawned then torn down | |

**Do not merge** Codex branch or your evidence PR without owner OK.

---

## 4. Paste brief

> Checkout `codex/wims-wa9-client` @ `9177a5a`. With Debian WIMS+hook on `:18431`, run `test-wims-live.ps1` for 00006 right/wrong, then suite 23 with `GGB_WIMS_LIVE_ENDPOINT` set (un-skip W4-live). Optional `gbw8acc` + `été`. Evidence under `evidence/…-gbot-wa9-live-9177a5a_GROK_V1/`. wimslogd: don’t start manually; tear down with CGI. No merges.

---

*End of `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md`.*
