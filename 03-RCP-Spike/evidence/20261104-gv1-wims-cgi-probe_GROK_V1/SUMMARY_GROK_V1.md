<!-- GROK_V1 -->
# GV-1 live CGI probe (WI-20) — summary

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Host | Windows (Shadow PC) |
| Runtime | `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime-oef` |
| CGI | `public_html\wims.cgi.exe` (direct CGI env; Apache not running) |
| Server banner | WIMS 4.33a |
| Full note | `Probe_Note_GV1_WIMS_CGI_GROK_V1.md` |
| CDC fold-in | `e48d1dd` (WI-20) |

## Static search

- `adm/class/sheet`: **EXISTS**
- `getresult` string in `public_html`: **0 hits**
- Sheet `job=` values: activate, chseries, getsource, print, putsource, … — **NO getresult**

## Probes

| ID | Request | Status | Content-Type | JSON grade | Notes |
|---|---|---|---|---|---|
| A | GET `module=home&cmd=intro` | 200 OK | text/html | no | stock home HTML |
| B | GET `module=adm/class/sheet&job=getresult&exercise=test1&ans1=QQ==` | 200 OK | text/html | no | worksheet editor HTML; supervisor-only message |
| C | POST body same as B | 200 OK | text/html | no | same as B |
| D | GET `module=adm/class/sheet&cmd=intro` | 200 OK | text/html | no | sheet module HTML |
| E | GET `module=adm/class/sheet&cmd=getresult` | **450** User Error | text/html | no | `getresult` not valid; valid: new, renew, reply, help, hint, config |

## WI-20 conclusion

**CONFIRMED:** stock wims4win CGI returns HTML; D-S01 `job=getresult` is not a grade API; `cmd=getresult` is rejected. L2-1 adapter required (prefer new module / front door using documented `cmd=` design from CDC `e48d1dd`).
