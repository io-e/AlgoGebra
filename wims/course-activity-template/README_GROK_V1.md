# WIMS course activity template (G-14, WP7-01) — WA-9 protocol

This template follows owner decision **D-WIMS-G01**: WIMS grades OEF answers through its existing `cmd=new` → `cmd=reply` flow. On reply only, the client sends `special_parm=algogebra_json` and reads the JSON comment block emitted by the WIMS hook. **WIMS owns the grade; GeoGebra's formative checks are not grades.**

## Files

| File | Role |
|---|---|
| `course-activity_GROK_V1.html` | Course activity page with a WIMS submission panel. |
| `wims-grade-client_GROK_V1.js` | G-15 client: creates a WIMS session, submits mapped OEF answer fields, and renders the server response. |

## Configuration

Deploy beside `course-tree.js`, `course-tree.css` and the self-hosted `GeoGebra/` assets. Replace placeholders or use query overrides:

| Placeholder | Query parameter | Meaning |
|---|---|---|
| `{{WIMS_CGI_URL}}` | `wims_endpoint` | CGI endpoint; default `/wims/wims.cgi`. |
| `{{WIMS_MODULE_ID}}` | `wims_module` | OEF module path, e.g. `H6/test/oef2html.fr`. |
| `{{WIMS_EXO_ID}}` | `wims_exo` | Exercise id within that OEF module, e.g. `00006`. |
| `{{COURSE_JSON_URL}}` | `course_url` | Course tree JSON URL. |

The host must define `window.GeoGebraWimsAnswerProvider(api, session)`, which returns a map of actual OEF fields and values, such as `{reply1: "2"}` or `{reply1: ["3", "5"]}`. This mapping is exercise-specific; the generic template does not guess how a GeoGebra construction maps to an OEF answer. If the provider or module/exercise is missing, submission stays disabled.

## Wire protocol

1. `GET <endpoint>?module=<module>&cmd=new&exo=<exo>&lang=<lang>`; parse the returned HTML for the hidden `session` and available `replyN` / `choiceN` fields.
2. `POST` form-urlencoded to the same CGI with `module`, `cmd=reply`, `session`, `special_parm=algogebra_json`, and the selected real answer fields (`replyN` / `choiceN`). Never invent `ansN`; never send the hook trigger on `cmd=new`.
3. Extract the JSON between `ALGOGEBRA_JSON_BEGIN` and `ALGOGEBRA_JSON_END` in the HTML comment. It contains the overall grade and per-answer `answers[]` data. Missing marker, malformed JSON, or invalid grades are errors—not grades.

Form bodies use Windows-1252, matching WIMS's declared response charset. JSON from the hook is ASCII-safe. The client renders server feedback using text nodes, never HTML injection. Same-origin hosting is required by default; remote HTTP endpoints are rejected by the companion client.

## Test

Suite 22 replays a loopback mock of the real OEF protocol, including correct/wrong numeric and checkbox answers, reply-only hook triggering, no-leak behavior, Windows-1252 encoding, and schema validation. It does not claim live-server evidence. Run the project test runner for suites 21–23; live Laragon/Debian evidence is recorded separately in the WA-9 handoff.
