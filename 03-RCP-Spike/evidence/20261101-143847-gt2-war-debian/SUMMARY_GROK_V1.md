# G-T2 — GWT WAR on Debian (GROK_V1)

- Recipe (Codex X-T8): `./gradlew -p source/web :web:gwtCompile :web:copyHtml :web:mergeDeploy --no-daemon` at pin `375db7faf54`, Temurin 21.0.13, Gradle wrapper 9.4.1 → **BUILD SUCCESSFUL** in 6m30s (63 tasks, 5 executed, 58 up-to-date; full GWT compile was done earlier for PR #5). Log: `gwt-war-build_GROK_V1.log`.
- WAR is **not in git** (201 MB); Codex's is a local junction. Debian layout: `web-host/GeoGebra` → symlink to `geogebra/source/web/web/war` (scratch only, not committed). Full manifest (741 files): `war_full_manifest_GROK_V1.sha256`.

| File | Debian sha256 (full) | Codex Windows sha256 (prefix) | Match |
|---|---|---|---|
| deployggb.js | `55bfe441dc97bcbbeaa6fc9fc924cf11f2533d1f1610436276c501dc13056d97` | `b4307df658c5…` | no |
| web3d/web3d.nocache.js | `b4c7254f85388e015539d4c7f92f77eac62371a9674ec08bb44468cce78e6233` | `5212e733435318f3…` | no |
| web/web.nocache.js | `c14b35a9b1cc11864cf72bda18e1e3e8b85386b00ce731abb88cf1e0760b81f4` | `829c80ad5b16056b…` | no |
| webSimple/webSimple.nocache.js | `91bbb078ea0f261b2c502841f592c98c1fa3883c3e6d1d14bd14dbb1f81e4dc3` | `b4c717ac8b0f7931…` | no |
| tablet3d/tablet3d.nocache.js | `d9a15861f1953ed254db6a6ef483214ada258eb4c1febc50f063935bc8b8c277` | `067e31e8647b39f0…` | no |

Not byte-identical: GWT permutation names (strong names) and `deployggb.js` embed build-specific values; same source pin and same task recipe, so functional equivalence is checked by G-T3 instead of hashes. Reproducible-build comparison would need the same JDK build + locale + `-Dgwt.persistentunitcache=false`; not attempted.
