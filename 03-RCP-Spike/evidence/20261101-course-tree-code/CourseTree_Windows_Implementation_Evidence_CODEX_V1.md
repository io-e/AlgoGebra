# Course Tree — Windows Implementation Evidence

| Field | Value |
|---|---|
| Date | 2026-11-01 |
| OS | Windows 11 x86_64 |
| Branch | `feat/course-tree-sprint1` (based on `04b0c15` before this delivery) |
| GeoGebra source | Pinned commit `375db7faf5407390bb322165f2414415da8faeda` |
| Build JDK | Temurin 21.0.12.101-hotspot |
| RCP runtime | Eclipse JustJ Java 25.0.4.1 |
| Scope | WP2-06 host implementation, X-T5 launcher contract, host build, parser/policy tests, headless course-load smoke |

## Results

- `build.ps1 -JavaHome <JDK21> -GeoGebraSourceRoot D:\ALF_ZGit\G1_Geogebra_Migration\source` — **PASS**; built the host and five engine bundles and generated `bundles.info` for 50 D-03 inputs.
- `test-course-model.ps1 -JavaHome <JDK21> -BundleRoot <worktree>\03-RCP-Spike` — **PASS**; `CourseModelTest: 9 PASS, 0 FAIL`; `StepValidatorPolicyTest: 9 PASS, 0 FAIL`.
- `tests/18_Test_LaunchCourse_GROK_V1.ps1` — **PASS**; 16 PASS, 0 FAIL, 0 SKIP. Covers course argument validation, environment fallback and precedence, path-with-spaces, root confinement, and dry-run Java arguments.
- `launch.ps1 -NoBuild -Headless -Course <absolute smoke-fixture path>` with `GGBPLUS_COURSE_ROOT` set — **PASS**; course schema 1.0 loaded, 50/50 bundles resolved, D-02 smoke passed, Equinox exited 0.

The smoke fixture SHA-256 is `67f5f275a8b722620370c9426e565e2ea64ca43ed7deaa2aa5d38224c457beca`.

## Implementation summary

The host bundle now contains the native SWT `CourseTreePanel`, `DirectiveExecutor`, and `StepValidator`. The panel is constructed only when `-Dggbplus.course` is supplied, preserving the existing two-pane layout and unattended UI-test surface when no course is requested. The course path is resolved and checked for a local JSON file; optional `GGBPLUS_COURSE_ROOT` confines loading. UI-thread crossings use asynchronous SWT/Swing scheduling. The launcher implements PR #8's course-file validation contract and supports `-Course`, `--course`, `--course=<path>`, and `GGBPLUS_COURSE`.

## Limits / not claimed

- The headless smoke deliberately skips SWT/GeoGebra UI creation; it **does not** prove that the tree renders or that Run/Check/Next/Reset work in an attended desktop session. D-11 remains **NOT RUN** pending that UI test.
- Course check types implemented in this slice are formative client-side checks; they are not trusted grading. WIMS must perform authoritative grading server-side.
- GWT/WAR build evidence is in `X-T8_GWT_WAR_Validation_CODEX_V1.md`. Playwright/W-09 remains **NOT RUN**; the host-page loader path needs correction before running it.
- No merge was performed. No files in upstream GeoGebra `common` were changed.

## Logs

- `rcp-build.log`
- `course-model-tests.log`
- `launch-course-suite-18.log`
- `course-headless-launch.log` (launcher console)
- `course-headless-equinox.log` (Equinox application log)
- `sha256-manifest.txt`
