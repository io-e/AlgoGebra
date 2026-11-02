# P0 — launch.sh -Course + suite 18 on Debian (GROK_V1)

| Field | Value |
|---|---|
| Run ID | `20261101-133332-p0-launch-course-debian` |
| Host | Debian 13 (trixie), pwsh 7.6.9, Temurin 25.0.5 |
| Base | `feat/external-engines` @ `9d1a297` + PR #4 commit `1b7a8d0` cherry-picked (BUG-017 discovery) |
| Design | `03-RCP-Spike/docs/Design_LaunchSh_Course_Flag_GROK_V1.md` (PR #8) |

| Suite | PASS | FAIL | SKIP | Note |
|---|---|---|---|---|
| 18 LaunchCourse | 17 | 0 | 2 | LC-01..17 dry-run PASS; LC-18/19 SKIP (no CourseTreePanel in image, X-T4) |
| 17 Launcher (regression) | 13 | 0 | 0 | BUG-017 discovery unchanged incl. real headless start L-13 |

Deviation from design §5: "no JDK" stays **exit 4** (PR #4 / suite 17 contract), not 69; "no image" stays 3.
Files: TAP + CSV for 17 and 18, SHA256SUMS.
