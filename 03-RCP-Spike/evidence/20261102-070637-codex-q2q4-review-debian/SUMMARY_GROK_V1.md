# Review of feat/course-security-q2-q4 (Codex affc73a) on Debian (GROK_V1)
Owner decisions: https://github.com/io-e/AlgoGebra/issues/17#issuecomment-6569788303
- Java tests (javac/java 25.0.5, image-pr11 jars, `test-course-model.ps1`): CourseModelTest **9/0**, StepValidatorPolicyTest **18/0** (matches Windows 27/0).
- Suite 16 (PR #3 corpus, 62 cases) with `COURSE_VALIDATOR` = `tests/tools/CourseValidatorCliQ4_GROK_V1.java`: it uses Codex's **real** `StepValidator.validateCommand` with a headless GeoGebra `AppDNoGui` (post-parse walk, so localized names are checked), `validateOpen` and `DirectiveExecutor.resolveInput`, combined like `validateStep`.
  **134/2/1** (adapter over PR #11: 125/11/1). All 8 Sequence reject cases and T-03b/T-12b/T-16b (localized names) now REJECT; T-28 REJECT, T-33 ACCEPT_WITH_WARNING, T-55 REJECT.
- 2 FAILs: T-45 and T-51 (exact 1000-iteration boundary) return **ACCEPT_WITH_WARNING** instead of ACCEPT, because Codex added a near-limit warning at >= 800 iterations. That isn't in the owner decision. It is still accepted (no security impact) → owner/Codex to pick: keep the warning (update the corpus) or drop it.
- 1 SKIP: SPEC-GAP-1 (scanner absent; Claude Q5 / Codex WP9-04).
Check vs owner answers: Q2 fail-closed untrusted OPEN ✔ (+ SWT confirm dialog for trusted, not visually tested); Q3 1000/10000 static bounds, nested, step 0, dynamic ✔ (`Sequence(n)` short form always rejected, conservative); Q4 ACCEPT_WITH_WARNING + rejection wins ✔; watchdog: none, so nothing interrupts the UI thread ✔.
