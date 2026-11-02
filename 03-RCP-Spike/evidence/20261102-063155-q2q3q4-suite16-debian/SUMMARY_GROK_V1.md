# Suite 16 after owner Q2/Q3/Q4 (GROK_V1)
Owner: https://github.com/io-e/AlgoGebra/issues/17#issuecomment-6569788303. Corpus 51 → 62 cases (T-45..T-55); T-28 expected REJECT (fail-closed); strict first-token parsing.
| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| no validator | 82 | 0 | 55 |
| test-side adapter over PR #11 classes (PR #12, ACCEPT_WITH_WARNING for trusted OPEN) | 125 | 11 | 1 |
Fixed vs 108/6/1: T-28 (REJECT = REJECT), T-33 (ACCEPT_WITH_WARNING). New T-55 passes (warning never overrides REJECT).
Failures: 8 Sequence budget cases T-21/46/47/48/50/52/53/54 (product gap, Codex: 02-Cdc/Handoff_Sequence_Limits_Warning_Channel_GROK_V1.md); T-03b/T-12b/T-16b adapter limitation (localized names).
Adapter run: java 25 -cp <adapter classes>:<image-pr11 jars> org.geogebra.plus.course.CourseValidatorCli_GROK_V1.
