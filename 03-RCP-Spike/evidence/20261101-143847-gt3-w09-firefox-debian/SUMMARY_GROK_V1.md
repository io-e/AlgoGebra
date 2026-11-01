# G-T3 — W-09 on Debian: static + Playwright Firefox 157 (GROK_V1)

## S_W-09 static: **15 PASS / 0 FAIL / 4 SKIP** (same as Windows 15/0/4). Browser half W09-20..23 still SKIP by design in that script.

## Playwright `W09_CourseTree.spec.ts --project=firefox` against local Debian WAR
| Run | Pass | Fail |
|---|---|---|
| As committed (tip `9d1a297`) | 0 | 10 — all `NS_ERROR_CONNECTION_REFUSED` |
| With 3 scratch fixes (config + host page; not committed) | **5** | **5** |

### Blocking defects found in the committed harness (fixes proposed, not applied)
1. `playwright.config.ts` webServer serves `../../../../web-host` (one level above the repo) — should be `../../../web-host`; plus `npx serve`/`localhost` → used `python3 -m http.server --bind 127.0.0.1` in `playwright.grok.config_GROK_V1.ts`.
2. `course-host.html`: `html5codebase: 'GeoGebra/HTML5/5.0/web3d/'` is ignored by deployggb (it loaded `./web3d/` → 404). Needs `applet.setHTML5Codebase('GeoGebra/web3d/')` (matches Codex X-T8 note).
3. `course-host.html`: no `id: 'ggbApplet'` → `window.ggbApplet` undefined; and `ggbOnInit` is never called → tree never loads. Fix: `'id': 'ggbApplet'` + `'appletOnLoad': function(){ ggbOnInit('ggbApplet'); }`.
4. `web-host/courses/` missing — default `courses/trigonometry_intro.json` is at repo root (scratch symlink used).
Patch: `course-host_fix_PROPOSED_GROK_V1.patch` (Claude/Codex owned file — for owner decision).

### Per test (patched run)
| Test | Result | Cause |
|---|---|---|
| PW-W09-01 page loads | PASS | |
| PW-W09-02 CAS readiness | FAIL | spec: `waitForAppletReady` waits only for the API function; CAS returns `?` for ~3 s (then `2`) — fixture should poll `evalCommandCAS('1+1')==='2'` |
| PW-W09-03 ≥5 chapters | FAIL | spec: `#tree-root [role=treeitem]` counts nested steps (21) with `toHaveCount(5)`; use `#tree-root > [role=treeitem]` and `>=5` |
| PW-W09-04 step 1.1 → O | FAIL | spec: `.first()` treeitem is chapter 1, not step 1.1 (same selector issue) |
| PW-W09-05 step 1.2 → circle | PASS | |
| PW-W09-06 CAS identity | FAIL | same CAS warm-up as 02 (`?`) |
| PW-W09-07 Execute blocked | PASS | |
| PW-W09-08 traversal rejected | PASS | |
| PW-W09-09 keyboard nav | PASS | |
| PW-W09-10 mobile toggle | FAIL | `isVisible()` same before/after toggle — sidebar likely off-canvas via CSS transform; spec should assert a class/`aria-expanded` or bounding box |

No product (GeoGebra) failure observed; all 5 failures are harness/spec timing or selector issues.
