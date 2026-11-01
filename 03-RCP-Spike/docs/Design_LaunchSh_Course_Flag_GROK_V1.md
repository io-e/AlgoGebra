# Design — `launch.sh -Course <path>` (G-T1, GROK_V1)

| Field | Value |
|---|---|
| Status | **Design only** — no `launch.sh` change in this PR |
| Base | `feat/external-engines` @ `88eca94` |
| Mirrors | Codex **X-T5** `launch.ps1 -Course` (Handoff_CLAUDE_by_GROK_V1_1 §4), Study V1_2 §2.7/§2.8 (G-10) |
| Depends on | X-T4 (panel wired when `-Dggbplus.course` set); BUG-017 (PR #4) JDK discovery |
| Owner locks followed | Questions_Course_Tree_Owner_GROK_V1_1: L3 tree ships before BUG-014 (trig/CAS only, matrix CMD desktop skipped); L7 no-merge |

## 1. Why not the Study §2.8 snippet as-is
§2.8 treats `$1` as a course if it is a file. That collides with existing flags (`--headless`, `--boot-delegate-jogamp`), passes a relative path the JVM resolves against an unknown cwd, and silently ignores a mistyped path (falls back to the 2-pane UI, so a test "passes" without a tree). This design replaces it.

## 2. CLI contract
```
launch.sh [--headless] [--boot-delegate-jogamp] [-Course <path> | --course <path> | --course=<path>]
```
- `-Course` kept for parity with `launch.ps1`; `--course` is the Linux-idiomatic alias.
- Parsing moves from `for a in "$@"` to `while (($#)); case ...; shift` so the flag can take a value; flags in any order.
- Repeated `-Course` → exit 64 (no last-wins).
- Unknown args: warning on stderr, otherwise ignored (don't break Run_All callers).
- Env fallback `GGBPLUS_COURSE` for Xvfb/CI wrappers; the flag wins.

## 3. Canonicalization and launcher checks (SPEC-GAP-3)
The launcher is a **convenience gate, not the security boundary**. Java `DirectiveExecutor`/`StepValidator` (X-T3/WP9-02) stays authoritative and re-checks with `toRealPath()` (Spec_Course_Security_CLAUDE_V1 §2.1, T-17, corpus T-27).
1. `COURSE_REAL="$(realpath -e -- "$path")"` — resolves symlinks, fails if missing. Only the canonical absolute path is passed on.
2. Regular file, readable, name ends `.json`, size ≤ 1 MB (spec T-10) — clear message instead of a Java stack.
3. Argument with a URL scheme (`^[A-Za-z][A-Za-z0-9+.-]*://`) rejected — no remote courses on desktop.
4. Course dir = `dirname "$COURSE_REAL"`. The launcher does **not** inspect `OPEN` targets; that stays in Java (`courseDir.toRealPath()` + `startsWith`).
5. Optional allow-root `GGBPLUS_COURSE_ROOT`: if set, `COURSE_REAL` must be under its realpath (prefix check with trailing `/`). Unset = developer mode (any local file). Student/kiosk images set it.
6. A symlinked `course.json` is allowed (resolved path is what's validated and logged); symlinks inside the course dir are Java's job.

## 4. Mapping to the JVM
`ARGS+=("-Dggbplus.course=$COURSE_REAL")` — a system property before `org.eclipse.equinox.launcher.Main`, quoted array element (spaces safe, no `eval`). Log line `Run <id> course <COURSE_REAL> sha256 <hash>` for evidence.

## 5. Exit codes (before Java starts; sysexits.h)
| Code | Meaning |
|---|---|
| 0 / Java's | normal |
| 64 | usage: missing value, repeated flag, URL |
| 65 | not `.json` or > 1 MB |
| 66 | missing / unreadable / not a regular file |
| 69 | no usable JDK (BUG-017 discovery; also without a course) |
| 77 | outside `GGBPLUS_COURSE_ROOT` |
Proposal to Codex: X-T5 uses the same numbers so suite 18 cases are cross-platform.

## 6. Interplay with BUG-017 JDK discovery (PR #4)
Order: parse args → validate course → discover JDK → build ARGS → exec. Course errors fail fast without a JVM. PR #4's discovery chain (`$JAVA` → image `jre/` → `/workspace/AlgoGebra/jdk/jdk-25*` → mise → `PATH`, require ≥ 25) is unchanged; `-Course` adds no Java requirement. Java 21 is never selected for the product (RQ-1 fallback is RCPTT AUT only).

## 7. Xvfb
`launch.sh` does not start Xvfb (stays usable on a real desktop). Headless UI runs: `xvfb-run -a -s "-screen 0 1600x1000x24" ./launch.sh -Course courses/trigonometry_intro.json`. With `--headless` the property is still passed and the host must not build the SWT tree (tested).

## 8. Planned suite — `18_Test_LaunchCourse_GROK_V1.ps1`
15/16/17 are taken by PRs #5/#3/#4 → **18**. pwsh only, TAP + CSV like suite 16. Needs a dry-run hook (`GGBPLUS_LAUNCH_DRYRUN=1` → print final java argv, exit 0) so LC-01..17 run without a JVM.

| Id | Case | Expect |
|---|---|---|
| LC-01 | no flag | no `-Dggbplus.course` (2-pane, P-07 unchanged) |
| LC-02 | `-Course courses/trigonometry_intro.json` (relative) | absolute realpath in argv |
| LC-03 | `--course=<abs>` | same as LC-02 |
| LC-04 | path with spaces | one argv element, exact |
| LC-05 | `-Course` without value | 64 |
| LC-06 | `-Course` twice | 64 |
| LC-07 | missing file | 66 |
| LC-08 | directory | 66 |
| LC-09 | `.ggb` / `.txt` | 65 |
| LC-10 | 1 MB + 1 byte | 65 |
| LC-11 | `https://x/c.json` | 64 |
| LC-12 | symlink → valid course | argv = target realpath |
| LC-13 | `GGBPLUS_COURSE_ROOT` set; course outside via abs, `..`, symlink | 77 |
| LC-14 | `GGBPLUS_COURSE` only; then flag + env | env honored; flag wins |
| LC-15 | `--headless -Course x` and `-Course x --headless` | both parsed |
| LC-16 | filename with `$(touch /tmp/pwn)` / `;` | literal, nothing executed |
| LC-17 | no JDK + bad course | course error (65/66) wins; no JDK alone → 69 |
| LC-18 | Xvfb real launch, trig course (needs X-T4 image) | log shows CourseTreePanel, 3 panes |
| LC-19 | Xvfb, corpus T-27 symlink escape | launcher accepts, Java rejects OPEN (layering proof) |

LC-18/19 SKIP until the image contains X-T4. One-line `Run_All_GROK_V1.ps1` entry in the implementation PR (shared file, minimal edit).

## 9. Out of scope
Implementation (follow-up PR once X-T4/X-T5 land, to match behaviour); web `?course=` (W-09); validator logic.
