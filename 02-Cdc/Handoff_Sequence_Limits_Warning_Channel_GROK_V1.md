# Handoff to Codex — Sequence limits (Q3) + warning channel (Q4) (GROK_V1)

Owner decision: https://github.com/io-e/AlgoGebra/issues/17#issuecomment-6569788303 (Q3, Q4). Tests: suite 16 corpus (PR #3) T-21, T-45..T-55, T-33. Grok did **not** change `StepValidator`/`DirectiveExecutor`; this is the contract to implement.

## Q3 — deterministic `Sequence` budget (validation time, before execution)
- **≤ 1000 iterations per `Sequence`**, **≤ 10000 generated items per directive** (one CMD/CAS value; sum over all `Sequence` calls, nested = product).
- Bounds must be **statically provable** from the parsed expression tree (post-parse walk in `StepValidator.validateCommand`, same place as the allow-list): start/end/step must evaluate to numeric constants without referencing construction objects, sliders, random or free variables. Otherwise → REJECT (`sequence-bound-not-static`).
- Count forms: `Sequence(n)` → n; `Sequence(expr, var, a, b)` → floor((b−a)/1)+1; `Sequence(expr, var, a, b, s)` → floor((b−a)/s)+1, `s = 0` or wrong sign → REJECT (unbounded). Nested: inner count × outer count, inner bounds must not depend on the outer variable unless still provable (simplest: reject if they do).
- Over budget → REJECT (`sequence-over-budget: <n> > 1000` / `directive-items <n> > 10000`).
- Corpus expectations: ACCEPT T-45 (1000), T-49 (100×100 = 10000), T-51 (10×1000 in one `Join`); REJECT T-21 (1e9), T-46 (1001), T-47 (bound = object `n`), T-48 (`10^12`), T-50 (100×101), T-52 (11×1000), T-53 (`Sequence(1001)`), T-54 (step 0).
- **Watchdog (2 s)**: optional, *report-only* (log + test marker `D-xx WARN slow directive <ms>`). It must **never** interrupt, cancel or `Thread.stop` work on the SWT/GeoGebra UI thread and is not a security control; the static budget is.

## Q4 — structured validation result
```java
enum Verdict { ACCEPT, ACCEPT_WITH_WARNING, REJECT }
record ValidationResult(Verdict verdict, List<String> reasons, List<String> warnings) {}
```
- Combine per directive → per step → per course: any REJECT ⇒ REJECT (warnings kept for the log only). **Warnings never override a rejection** (T-55: trusted OPEN + `Execute` ⇒ REJECT).
- `trustedGgb: true` OPEN that passes the path rules (and, after WP9-04, has scanner findings) ⇒ ACCEPT_WITH_WARNING; the UI must show a visible warning (T-33). Untrusted OPEN stays **REJECT until the scanner exists** (Q2, T-28); afterwards a clean in-course `.ggb` may ACCEPT.
- CLI contract for suite 16 (`COURSE_VALIDATOR="<cmd>"`, called `<cmd> <course.json>`): first stdout token exactly `ACCEPT | ACCEPT_WITH_WARNING | REJECT`, rest = reasons/warnings; exit code ignored. Any other first token = CONTRACT_VIOLATION (FAIL).

## Current state (Debian, test-side adapter over PR #11 classes, PR #12)
Suite 16 with adapter: 125/11/1. T-28 and T-33 now pass; failing: 8 Sequence cases (product gap above) + T-03b/T-12b/T-16b (adapter cannot resolve localized names; needs an App-backed test).
