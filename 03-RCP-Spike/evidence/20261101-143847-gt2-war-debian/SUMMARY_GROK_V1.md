# G-T2 — GWT WAR on Debian (GROK_V1)

- Recipe (Codex X-T8): `./gradlew -p source/web :web:gwtCompile :web:copyHtml :web:mergeDeploy --no-daemon` at pin `375db7faf54`, Temurin 21.0.13, Gradle wrapper 9.4.1 → **BUILD SUCCESSFUL** in 6m30s (63 tasks, 5 executed, 58 up-to-date; full GWT compile was done earlier for PR #5). Log: `gwt-war-build_GROK_V1.log`.
- WAR is **not in git** (201 MB); Codex's is a local junction. Debian layout: `web-host/GeoGebra` → symlink to `geogebra/source/web/web/war` (scratch only, not committed). Full manifest (741 files): `war_full_manifest_GROK_V1.sha256`.

| File | Debian sha256 | Codex (Windows) sha256 | Match |
|---|---|---|---|
| deployggb.js | 55bfe441…13056d97 | b4307df6…2ef9781b | no |
| web3d/web3d.nocache.js | b4c7254f…e6233 | 5212e733…a7be6 | no |
| web/web.nocache.js | c14b35a9…f81e4dc3 | 829c80ad…c1141c | no |
| webSimple/webSimple.nocache.js | 91bbb078…4dc3 | b4c717ac…bd4b69 | no |
| tablet3d/tablet3d.nocache.js | d9a15861…c8b8c277 | 067e31e8…d25ee | no |

Not byte-identical: GWT permutation names (strong names) and `deployggb.js` embed build-specific values; same source pin and same task recipe, so functional equivalence is checked by G-T3 instead of hashes. Reproducible-build comparison would need the same JDK build + locale + `-Dgwt.persistentunitcache=false`; not attempted.
