# Windows validation — Q3b Sequence warning removal (#21)

| Field | Value |
|---|---|
| Date | 2026-11-02 |
| Host | Windows 11 x64 (build 10.0.26100), PowerShell 7.6.9 |
| Java | Temurin 21.0.12.1 |
| Source base | `5b0e525` plus the isolated #21 patch in this worktree |
| Target runtime image | `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12` |

## Results

Re-run from the isolated #21 worktree:

- `test-course-model.ps1` against the r12 image: **CourseModel 9/0; StepValidatorPolicy 18/0**.
- Suite 20 real-validator corpus: **56 PASS / 0 FAIL / 0 SKIP**.
- T-45 and T-51 (1000-iteration Sequence boundary cases) return plain `ACCEPT`, with no near-limit warning.
- Trusted `OPEN` continues to return `ACCEPT_WITH_WARNING`; values beyond hard limits remain rejected.

Recheck logs and CSV are included under this directory; `SHA256SUMS.txt` covers the evidence files.

## Limits

This is Windows evidence. Grok's Linux suite-16 verification remains pending after the PR is available on tip.
