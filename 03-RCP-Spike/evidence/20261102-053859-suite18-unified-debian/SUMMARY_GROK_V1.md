# Suite 18 unified (cross-platform) — Debian runs (GROK_V1)

Branch `feat/grok-p0-launch-course` after a normal merge of `origin/feat/external-engines` @ `bdfd306` (PR #11 merged). The add/add conflict on `03-RCP-Spike/tests/18_Test_LaunchCourse_GROK_V1.ps1` is resolved into ONE file: Linux → `launch.sh`, Windows → `launch.ps1 -NoBuild` (Codex's 16 cases merged, credited in header).

| Image | PASS | FAIL | SKIP |
|---|---|---|---|
| PR #11 image (`image-pr11`, built on Debian) | 21 | 0 | 1 (LC-19) |
| r8 Linux image (no course package) | 20 | 0 | 2 (LC-18, LC-19) |

22 test points: LC-01..LC-17, LC-13b, LC-17b, LC-18, LC-19, LC-20.
Windows run by Codex is still needed (expected on Windows: LC-12/LC-13b SKIP without symlink privilege, LC-17b/18/19 SKIP).
Exit-code divergence (not changed): no usable JDK = 4 in launch.sh vs 69 in launch.ps1.
