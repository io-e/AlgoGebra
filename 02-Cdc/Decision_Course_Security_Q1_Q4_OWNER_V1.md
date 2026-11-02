# Owner Decisions — Course Security Q1–Q4

| Field | Value |
|---|---|
| Date | 2026-11-02 |
| Source | [GitHub issue #17](https://github.com/io-e/AlgoGebra/issues/17), owner comment `6569788303` |
| Scope | Q1–Q4 only; no merge authorized |

## Decisions

1. **No-JDK exit:** Standardize both launchers on exit code `69` (`EX_UNAVAILABLE`). Preserve the existing `64/65/66/77` meanings. This is implemented and tested in Grok PR #9, commit `6c32896`; this branch does not duplicate that change.
2. **Untrusted `OPEN`:** Until a `.ggb` script scanner is implemented, reject all `OPEN` actions without explicit `trustedGgb: true`. A trusted open requires an interactive warning before loading; the warning does not imply that the archive is safe. After scanning exists, clean in-course files may be accepted without trust. Keep tests clear about this temporary pre-scanner restriction versus the future contract.
3. **`Sequence` budget:** Require statically provable finite bounds. Limit each `Sequence` to **1,000 iterations** and total generated sequence items to **10,000 per directive**, counting nested expansion. Reject zero/non-finite steps, dynamic bounds, over-limit expressions, and expressions whose validation tree exceeds its safety cap. Slow-execution timing is diagnostic only; do not claim that a timer can safely interrupt GeoGebra's UI thread.
4. **Validation result:** Support `ACCEPT`, `ACCEPT_WITH_WARNING`, and `REJECT`. Warnings remain visible to the user and never override a rejection.

## Source-of-truth note

This decision supersedes the earlier `10,000 per Sequence` value in `Spec_Course_Security_CLAUDE_V1.md` §5 and its related limit example until Claude incorporates the decision into a revised specification. The remaining spec gaps concerning `<ggbscript>` and symlink scanning remain assigned to Claude under Q5 of issue #17.

## Implementation trace

The companion implementation is on `feat/course-security-q2-q4`. It adds a typed validation result, bounded post-parse `Sequence` accounting, fail-closed untrusted `OPEN`, and a pre-load warning for explicitly trusted files. Unit tests cover the result states, open policy, individual and aggregate sequence limits, and invalid bounds.
