# G-T4 (optional) — Run_All -Only D-11 under Xvfb, mechanical (GROK_V1)

Image: built on Debian with `build.sh` from a **local scratch merge** of tip `9d1a297` + PR #11 `24f2d3a` + PR #9 (not pushed), into a separate dir `/workspace/AlgoGebra/image-pr11/…` (existing r8 image untouched). Host jar contains 16 `course/` classes. Build log: `build_image_pr11_GROK_V1.log`.

`xvfb-run pwsh Run_All_GROK_V1.ps1 -Only D-11` → **4 PASS / 4 FAIL / 0 SKIP, verdict FAIL** (mechanical only; attended SWT UI stays Windows).

| Check | Result | Cause |
|---|---|---|
| D11-01 schema-valid | FAIL | env: script calls `python` (Debian has `python3`) and needs `jsonschema` (not installed) |
| D11-02 product-launches | FAIL | scenario regex `GeoGebraPlus.*started|Application.*started` doesn't match this host's log, though the product ran (SCN _BEGIN…_END) |
| D11-03 tree-renders | FAIL | regex expects `CourseTreePanel|course tree|loadCourse`; log says `Course loaded: …trigonometry_intro.json (5 chapters; schema 1.0)` → product actually loaded the course |
| D11-04 step-O / circle | PASS (weak) | status OK but evalCommand returned `false` (BUG-014 pattern); check ignores the value |
| D11-05 cas-identity | FAIL | CAS result empty |
| D11-06 no-error-dialog | PASS (weak) | but log shows `AppD.showError` → AWT NPE `XWindowPeer.getOwnerPeer()` under Xvfb: an error dialog *was* attempted |
| D11-07 no-timeout | PASS | 9 s |

Net: course loading via `-Dggbplus.course` works on Linux; command execution reproduces BUG-014 (evalCommand false + error dialog); scenario regexes need updating to Codex's actual log markers.
