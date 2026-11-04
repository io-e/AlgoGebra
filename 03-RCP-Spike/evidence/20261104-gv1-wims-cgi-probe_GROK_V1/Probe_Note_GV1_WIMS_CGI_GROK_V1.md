<!-- GROK_V1 -->
# Probe note — GV-1 / WI-20 live CGI (`getresult`)

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Host | Windows (Shadow) |
| Runtime | `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime-oef` |
| CGI | `public_html\wims.cgi.exe` invoked as CGI (env + stdin); Apache/Laragon **not** running |
| Server banner | `WIMS 4.33a (WWW Interactive Multipurpose Server)` |
| CDC | WI-20 updated in `e48d1dd` |
| Pack | this directory |

## Method

Set standard CGI environment (`REQUEST_METHOD`, `QUERY_STRING` / POST body, `CONTENT_LENGTH`, `SCRIPT_NAME=/wims/wims.cgi`, cwd = `public_html`). Capture stdout to `*.out`.

## Static checks

| Check | Result |
|---|---|
| `modules/adm/class/sheet` | Present |
| Literal `getresult` under `public_html` | **0** matches |
| Sheet module `job=` values | `activate`, `chseries`, `cleantechvar`, `deactivate`, `delete`, `duplicate`, `erase`, `expire`, `getsource`, `hide`, `indiv`, `modify`, `moveto`, `moveup`, `prep_*`, `print`, `putsource`, … — **no `getresult`** |

WIMS uses two different namespaces:

- **`cmd=`** — CGI verb (`commands[]` in `wims.c`): `intro`, `new`, `renew`, `reply`, `config`, `hint`, `help`, …
- **`job=`** — module-local switch inside a module’s templates (e.g. sheet `job=getsource`)

## Probe table

| ID | File | Request | Status | Content-Type | JSON `"grade"` |
|---|---|---|---|---|---|
| A | `A_stock_intro.out` | GET `module=home&cmd=intro&lang=en` | 200 OK | text/html | no |
| B | `B_ds01_get.out` | GET `module=adm/class/sheet&job=getresult&exercise=test1&ans1=QQ==` | 200 OK | text/html | no |
| C | `C_ds01_post.out` | POST same fields | 200 OK | text/html | no |
| D | `D_sheet_intro.out` | GET `module=adm/class/sheet&cmd=intro&lang=en` | 200 OK | text/html | no |
| E | `E_cmd_getresult.out` | GET `module=adm/class/sheet&cmd=getresult&lang=en` | **450** WIMS User Error | text/html | no |

### B / C body (substance)

HTML worksheet editor: title “Worksheet”, h1 “Edit worksheet”, text *“Sorry, only the registered supervisor of a class can edit a worksheet”*. Unknown module `job=getresult` does not select a grade handler.

### E body (substance)

> The command ``getresult'' is not valid. Valid commands are: **new, renew, reply, help, hint, config**

## Conclusion for WI-20 / L2-1

1. Stock CGI returns **HTML**, never D-S01 JSON.
2. D-S01 `job=getresult` on `adm/class/sheet` is **not** a grade API.
3. `cmd=getresult` is **rejected** (not in stock `commands[]`).
4. **L2-1 adapter design implication:** implement a **new WIMS module** (or product CGI front) that registers / accepts a dedicated grade verb. Prefer the **`cmd=`** namespace (as CDC `e48d1dd` wire format), because stock modules cannot invent a new `cmd=` without core or adapter process changes — a new module alone only owns **`job=`**. Practical options for L2-0 owner choice:
   - **A.** New module `adm/…/algogebra_grade` with `cmd=reply` + module `job=getresult` returning JSON via custom template/`!exit` path (still needs HTML-suppression / JSON Content-Type support in the adapter path).
   - **B.** Thin product-side CGI/servlet in front of WIMS that speaks D-S01 and drives stock `cmd=reply` / scoring internals.
   - **C.** Patch/port a small `commands[]` extension (heavier; avoid unless owner accepts).

CDC already records: adapter required; `cmd=` vs `job=` distinction; valid command list from probe E.

## Repro (PowerShell sketch)

```powershell
$RT = 'D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime-oef'
$cgi = Join-Path $RT 'public_html\wims.cgi.exe'
# Set REQUEST_METHOD, QUERY_STRING or POST body, CONTENT_LENGTH, SCRIPT_NAME, cwd=public_html
# Start-Process / ProcessStartInfo with redirected stdin/stdout — see session notes 2026-11-04
```

---

*End of probe note.*
