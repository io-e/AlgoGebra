# WIMS integration — open questions (DRAFT for owner, GROK_V1)

Status: **draft, not posted**. Scope: G-14…G-16 under decision D-S01
(`02-Cdc/Decision_Open_Points_Sprint3_CLAUDE_V1.md`: POST `/wims/wims.cgi`,
`module=adm/class/sheet&job=getresult&exercise=<id>&ans1=<construction_base64>` → `{grade, feedback}`; WIMS owns the grade).
Each question has a **proposed default** already implemented (or not implemented) in `wims/course-activity-template/wims-grade-client_GROK_V1.js`
so work can continue; the owner can override any of them.

| # | Question | Proposed default | Where in code/tests |
|---|---|---|---|
| Q-W1 | Stock `wims.cgi` returns **HTML**, not JSON. Who provides the D-S01 JSON: a WIMS-side adapter module, or the client parsing HTML? | A **WIMS-side adapter** returns D-S01 JSON (preferred). Meanwhile the client has an **opt-in HTML adapter** (`htmlAdapter: true`, **default OFF**) that reads only an explicit marker `<script type="application/json" id="wims-result">` or `<div id="wims-result" data-grade data-feedback>`. No marker → error; no scraping of prose. | `extractFromHtml`; suite 22 GC-08, GC-17…GC-22 |
| Q-W2 | The request carries **no session/user**, and the existence of `job=getresult` in `adm/class/sheet` is unconfirmed. How does WIMS attribute the grade to a student? | Rely on the **same-origin WIMS session cookie** (`credentials: 'same-origin'`), add **no** user field client-side; WIMS team to confirm `getresult` (or name the real job) and whether `session=` must be passed. | `submit()`; suite 22 GC-01/GC-02 |
| Q-W3 | **CORS** and the **maximum `ans1` size** are undefined. | Same-origin deployment only (host page served by the WIMS server); no CORS headers requested. Client limit **1 MiB of base64** (configurable `maxAnsBytes`); HTTP **413** reported as "too large". WIMS-side limit to be set by WIMS admin. | `DEFAULT_MAX_ANS_BYTES`; suite 22 GC-23…GC-26 |
| Q-W4 | The plan ties **G-15 to S-02** (Lean 4), but D-S01 makes G-15 depend on **S-01 only**. | Update the plan: G-15 depends on **S-01 only**; S-02 (Lean 4 batch proof checking) stays out of sprint and gets no hook in G-15. | plan / states.yaml (owner) |

Other defaults already in the client (no decision needed unless the owner disagrees): timeout 15 s (`timeoutMs`), redirects refused,
grade must be a number in 0..1, feedback rendered with `textContent` only (never `innerHTML`), the client never computes or sends a grade.
