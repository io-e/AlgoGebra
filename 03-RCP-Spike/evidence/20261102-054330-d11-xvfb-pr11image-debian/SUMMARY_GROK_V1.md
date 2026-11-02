# D-11 under Xvfb with the PR #11 image — scenario fixed (GROK_V1)

Image: `image-pr11` (Debian build.sh from tip + PR #11 host). `xvfb-run pwsh Run_All_GROK_V1.ps1 -Only D-11`, 2 runs: **5 PASS / 3 FAIL / 0 SKIP each (verdict FAIL — honest)**. Before the fix: 4/4/0 with two false passes.

| Check | Result | Note |
|---|---|---|
| D11-01 schema | PASS | `Test-Json -SchemaFile` (pwsh 7.6); python3+jsonschema fallback |
| D11-02 launch | PASS | markers `IApplication.start()` + `D-02 PASS` |
| D11-03 tree | PASS | `Course loaded: … (5 chapters; schema 1.0)` |
| D11-04 step O / circle | **FAIL** | `KNOWN_BUG BUG-014: evalCommand returned false` (was a false PASS) |
| D11-05 CAS identity | **FAIL** | empty CAS result |
| D11-06 no error dialog | PASS | 0 `AppD…showError` markers in both runs; the 2026-11-01 run did log one → dialog is timing-dependent; the check now detects it |
| D11-07 no timeout | PASS | 9 s |
