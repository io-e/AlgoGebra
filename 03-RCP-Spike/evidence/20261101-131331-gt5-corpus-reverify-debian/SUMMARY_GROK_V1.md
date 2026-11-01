# G-T5 — Security corpus re-verify on Debian (GROK_V1)

| Field | Value |
|---|---|
| Run ID | `20261101-131331-gt5-corpus-reverify-debian` |
| Host | Debian 13 (trixie), pwsh 7.6.9 |
| Product tree | `origin/feat/external-engines` @ `88eca94` (contains `6baf1d4`) |
| Suite source | `16_Test_CourseSecurity_GROK_V1.ps1` + `fixtures/course-security/` overlaid from PR #3 (`c990606`) — suite 16 is not on the base yet |
| COURSE_VALIDATOR | unset (no validator/scanner in tree: no `StepValidator`/`GgbScriptScanner`/`allowed-commands.json`) |

## Result

| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| PR #3 (`c990606`) | 71 | 0 | 44 |
| This run (`88eca94`) | 71 | 0 | 44 |

No change. The 44 SKIPs are 43 `VAL-*` validator/scanner cases pending Codex WP9-02/04 (X-T3/X-T6) plus the SPEC-GAP-1 finding marker. `6baf1d4`/`88eca94` only add Playwright/RCPTT scaffolding and docs, nothing the schema layer reads.
Re-run with `COURSE_VALIDATOR='<cmd>'` once WP9-02/04 lands to turn the SKIPs into real checks.

Files: `16_CourseSecurity_GROK_V1.tap`, `16_CourseSecurity_GROK_V1.csv`, `SHA256SUMS`.
