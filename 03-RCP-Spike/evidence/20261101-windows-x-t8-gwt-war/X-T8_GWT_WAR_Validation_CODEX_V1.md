# X-T8 — Windows GWT WAR Build Evidence

| Field | Result |
|---|---|
| Status | **PASS — build and deploy output produced** |
| Date | 2026-11-01 |
| Host | Windows 11 x86_64 |
| Source | GeoGebra commit `375db7faf5407390bb322165f2414415da8faeda` |
| Java | Temurin JDK 21.0.12.101-hotspot (build toolchain) |
| Gradle | Wrapper 9.4.1 |
| Command | `gradlew.bat -p source/web :web:gwtCompile :web:copyHtml :web:mergeDeploy --no-daemon` |
| Result | `BUILD SUCCESSFUL`; 63 actionable tasks (full initial build: 10m35s; recorded follow-up: 26s, GWT compile up-to-date) |
| Output | `source/web/web/war/` in isolated pinned-source worktree |
| Captured follow-up log | `gwt-war-build-followup.log` |

The WAR contains `deployggb.js`, `web3d/web3d.nocache.js`, `web/web.nocache.js`, `webSimple/webSimple.nocache.js`, and `tablet3d/tablet3d.nocache.js`. A local junction was created at `D:\ALF_Agents\G1_Geogebra_Migration\web-host\GeoGebra`, targeting this generated `war` directory. The junction is local-only and excluded through this checkout's `.git/info/exclude`; it is not staged or committed.

**Scope limit:** this validates the pinned GWT build/deploy tasks and output structure only. Playwright/W-09 has not yet been run. The committed host page currently references `GeoGebra/HTML5/5.0/web3d/`, which is absent from this WAR; before the browser test, change it to the actual `GeoGebra/web3d/` output path, then validate script/network loading.

Hashes for the log and principal deploy files are in `sha256-manifest.txt`.
