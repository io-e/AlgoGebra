# WIMS course activity template (G-14, WP7-01) — GROK_V1

Implements the owner decision **D-S01** in `02-Cdc/Decision_Open_Points_Sprint3_CLAUDE_V1.md` (commit `4f40d2b`):
the student client sends the construction to the existing WIMS CGI by HTTP POST, and WIMS evaluates it with its own engines.
**WIMS owns the grade**; the page only displays the formative feedback WIMS returns.

## Files
| File | Role |
|---|---|
| `course-activity_GROK_V1.html` | Activity page. It has the same layout as `web-host/course-host.html`, plus a "Submit to WIMS" panel. |
| `wims-grade-client_GROK_V1.js` | Grade callback client (G-15). Each item has its own PR; the page works without it, but the Submit button stays disabled. |

## Deployment
1. Put the template next to the web host assets: `course-tree.js`, `course-tree.css` and `GeoGebra/` (the self-hosted WAR). These come from `web-host/` and are not modified.
2. Replace the placeholders. Each one can also be overridden by a query parameter, which is used for local tests.

| Placeholder | Query param | Default if unset | Meaning |
|---|---|---|---|
| `{{WIMS_CGI_URL}}` | `wims_endpoint` | `/wims/wims.cgi` | WIMS CGI endpoint (D-S01) |
| `{{WIMS_EXERCISE_ID}}` | `wims_exercise` | empty (submit refused) | `exercise=<id>` sent to WIMS |
| `{{COURSE_JSON_URL}}` | `course_url` | `courses/trigonometry_intro.json` | Course JSON loaded into the tree |

3. Use the same origin as WIMS: serve the page from the WIMS host so the POST is same-origin. Cross-origin use would need CORS on WIMS, which D-S01 does not define.

## Request sent (D-S01, verbatim fields)
`POST <WIMS_CGI_URL>` with `application/x-www-form-urlencoded` and the body
`module=adm/class/sheet&job=getresult&exercise=<id>&ans1=<construction_base64>`.
`ans1` is `ggbApplet.getBase64()`, the `.ggb` zip in base64. The expected response is `{ "grade": 0..1, "feedback": "..." }`.

## Open points (not decided in D-S01, so not guessed here)
- **Session and authentication:** D-S01 sends no WIMS `session` or user/class identifiers. Stock WIMS needs a session to attribute a grade.
- **Response format:** stock `wims.cgi` answers with HTML. The JSON shape needs a WIMS-side adapter module. A non-JSON answer is reported to the student as an error and never treated as a grade.
- **The `adm/class/sheet` + `job=getresult` pair** is taken verbatim from D-S01. It is not checked against a real WIMS server, because none is available to Grok.
- **Payload size limits** for `ans1`, and CORS if the page is not served by WIMS.
