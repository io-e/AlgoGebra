# Bonus — suite 16 with a test-side COURSE_VALIDATOR adapter over PR #11 classes (GROK_V1)

PR #11 `StepValidator.validateCommand(App, String)` needs a live GeoGebra `App` (kernel parse), so it cannot be a CLI directly. Adapter `03-RCP-Spike/tests/tools/CourseValidatorCli_GROK_V1.java` (test side) uses the **real** PR #11 code where possible:
- `CourseModel.load` (schema version, limits, 1 MiB, `trustedGgb` only on OPEN),
- `StepValidator.isAllowed(Commands)` (allow-list),
- `DirectiveExecutor.resolveInput` via reflection (OPEN path rules incl. `toRealPath`), and DirectiveExecutor's "untrusted OPEN disabled" policy.
Approximation: command names found by regex + `Commands.stringToCommand` (no localized-name resolution).

Also ran Codex's own Java tests on Debian (javac/java 25, image jars): CourseModelTest **9/0**, StepValidatorPolicyTest **9/0**.

| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| PR #3 / PR #7 (no validator) | 71 | 0 | 44 |
| With adapter | **108** | **6** | 1 |

Failures:
| Case | Got | Expected | Cause |
|---|---|---|---|
| T-03b nested localized Execute | ACCEPT | REJECT | adapter limitation (no localized parse); real `validateCommand` should catch it — needs App-backed test |
| T-16b fr RunClickScript | ACCEPT | REJECT | same |
| T-12b fr Delete | ACCEPT | REJECT | same |
| T-21 runaway Sequence | ACCEPT | REJECT | **real gap** (SPEC-GAP-2): no Sequence size/time limit in PR #11 |
| T-28 clean trusted? archive OPEN | REJECT (untrusted OPEN disabled) | ACCEPT | **policy divergence**: PR #11 disables all untrusted OPEN until the scanner exists — stricter than spec; corpus expectation or spec needs owner call |
| T-33 trustedGgb scripted file | ACCEPT | ACCEPT_WITH_WARNING | no warning channel in PR #11 |
Note: T-02 (fr Exécute) passes only because its value also contains `Delete` — coincidental.
Scanner (WP9-04) is still absent: T-06/07/29–32 pass only because untrusted OPEN is disabled wholesale.
