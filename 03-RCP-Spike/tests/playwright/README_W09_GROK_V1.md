# W-09 Playwright — how to run (GROK_V1)

The GWT WAR is **not in git** (≈200 MB). Build it at pin `375db7faf54`:
`./gradlew -p source/web :web:gwtCompile :web:copyHtml :web:mergeDeploy --no-daemon` (JDK 21) → `source/web/web/war/`.

Stage it in one of two ways:
- `GGB_WAR_DIR=<geogebra>/source/web/web/war` (served as `/GeoGebra/*` by `serve_GROK_V1.mjs`), or
- a link `web-host/GeoGebra` → that `war` dir (Linux `ln -s`, Windows `mklink /J`); it is git-ignored.

Then: `cd 03-RCP-Spike/tests/playwright && npm install && npx playwright install firefox && npx playwright test --project=firefox`.
`serve_GROK_V1.mjs` (Node, no deps) serves `web-host/`, falls back to repo `courses/` for `/courses/*`, binds 127.0.0.1:4173.
