# Suite 15 (web WAR + python http.server + headless Chrome/CDP probe) - Debian, tip 4e13b83

Script: 03-RCP-Spike/tests/15_Test_WebBuild_GROK_V1.ps1 (existing WAR, GGB_WEB_BUILD not set).
WAR: /workspace/AlgoGebra/webwar/war, built 2026-11-01 from upstream GeoGebra pin 375db7f (2026-10-27, "Merge branch 'apps-7914'").
SHA256: deployggb.js 3644dae5...80d8; web3d/web3d.nocache.js b4c7254f...e6233; web3d/0C67C8A47F0579D49611F42F63B45791.cache.js 08f778fa...0f90.
Browser: Google Chrome 156.0.8078.47 headless (the script drives Chromium-family via CDP; not Firefox/Playwright). Node v20.19.2, python3 http.server bound to 127.0.0.1. 8 CPUs.

| Run | Port | Result | appletOnLoad | Wall |
|---|---|---|---|---|
| run1 | 8771 | 15/0/0 | 1854 ms | 4 s |
| run2 | 8772 | 15/0/0 | 1625 ms | 4 s |
| run3 | 8773 | 15/0/0 | 1712 ms | 4 s |
| run4-cpu16 (16 busy loops on 8 CPUs) | 8774 | 15/0/0 | 3866 ms | 7 s |

Console/logs: no page errors. browser.log only has dbus connection noise and the SwiftShader software-WebGL deprecation warning. http.server: only 404 favicon.ico and the probe's /__probe_result beacon (expected). No external resources loaded.

Earlier flakiness (6/9 failing in Run_All with applet timeout vs 15/0/0 standalone): not reproduced, even with 2x CPU oversubscription load only doubled (3.9 s vs 90 s timeout). Likely cause is contention with concurrent UI suites/browsers or a port collision in Run_All rather than load speed. Test-only change: probe timeout now configurable via GGB_WEB_PROBE_TIMEOUT_MS (default 90000, unchanged) and reported in WEB-11 detail. Product untouched.
