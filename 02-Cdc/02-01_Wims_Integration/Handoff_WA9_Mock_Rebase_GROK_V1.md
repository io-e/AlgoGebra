<!-- GROK_V1 -->
# Handoff — WA-9 mock / client rebase (unblocked by WA-8)

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Handoff_WA9_Mock_Rebase_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-05 |
| For | Codex (primary) + Grok (suites 21–23) |
| Blocks lifted | **WA-8** Windows prototype done — WA-9 is **unblocked** |
| Canonical CDC | `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md` |
| Protocol | `Spec_WIMS_Message_Integration_GROK_V1_1.md` |
| WIMS evidence | `D:\ALF_ZGit\02-wims4win` commit `bb929e3` |

---

## 1. Why this exists

PRs **#40–#42** and `wims-grade-client_GROK_V1.js` still assume an older / mock grade contract (single `{grade, feedback}`, sometimes `adm/raw` / `job=getresult` / `ans1`). Owner decision **D-WIMS-G01** + the wims4win hook replace that with stock OEF `cmd=new` / `cmd=reply` + HTML-comment JSON.

WA-8 (Windows hook) is done enough for client work to start. Do **not** wait for Debian packaging.

---

## 2. Verified wire contract (implement against this)

### 2.1 Create exercise

```
GET/POST …/wims.cgi?module=<oef_module>&cmd=new&exo=<id>&lang=fr&…
```

Parse HTML for:

- `session` (hidden input)
- form field names: `reply1`… and/or `choice1`…

### 2.2 Submit answers

```
…&cmd=reply&session=<sid>&special_parm=algogebra_json&reply1=…&reply2=…
```

Rules:

- Send `special_parm=algogebra_json` **only on reply**
- Use real field names (`replyN` / `choiceN`), never invent `ansN`

### 2.3 Extract grade JSON

From the HTML response, extract the comment body between:

```text
ALGOGEBRA_JSON_BEGIN
…json…
ALGOGEBRA_JSON_END
```

Example (numeric 00006, correct):

```json
{
  "grade": 1,
  "seed": 1,
  "answers": [
    {
      "id": "reply1",
      "correct": true,
      "score": 1,
      "feedback": "",
      "expected": "2",
      "given": "2"
    }
  ],
  "feedback": ""
}
```

V1 limits to tolerate in mocks/UI:

- `feedback` / per-answer `feedback` may be `""`
- checkbox `expected` may look like `3,5;1,2,3,4,5,6` (good set before `;`)
- surrounding page charset is often `windows-1252`; JSON block is ASCII-safe

### 2.4 Regression

Without `special_parm=algogebra_json`, response must **not** contain `ALGOGEBRA_JSON_BEGIN` → client error `NO_JSON_BLOCK`.

---

## 3. Suggested WA-9 work items

| ID | Work | Owner |
|---|---|---|
| WA-9a | Update mock CGI fixtures to emit the comment JSON block with `replyN` ids | Codex |
| WA-9b | Change JS/Java client request builder: `replyN` + `special_parm` on reply only | Codex |
| WA-9c | Parse `answers[]` for per-answer UI (Q-W4); keep overall `grade` | Codex |
| WA-9d | Point one integration suite at real wims4win when available; keep mocks in CI | Grok |
| WA-9e | Document encoding: decode HTML with declared charset; parse JSON as UTF-8/ASCII | Codex |

Do **not** merge product PRs until owner OK (same as prior G-A8 caution). Draft / design branch is fine.

---

## 4. Pointers

| Resource | Path |
|---|---|
| Hook sources | `02-wims4win/AlgoGebra_Wims_Integration/runtime_patch/` |
| Smoke test | `…/tests/test_algogebra_json_GROK_V1.py` |
| Variable map | `…/OEF_Variable_Map_GROK_V1.md` |
| Install into a runtime | `…/runtime_patch/install_algogebra_hook_GROK_V1.ps1` |
| Runtime (dev) | `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime-oef` |

---

## 5. Still not WA-9

- Help templates / Q-W9 (unchanged)
- Offline engines CDC
- Gate E / EUPL–GPL distribution clearance (`Compatibility_Analysis_…_GROK_V1.md`)
- Debian GBot parity of the hook
