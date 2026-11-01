# Report – GWT web build, self-hosted (WP3a-03 / G-03) – GROK_V1

**Result: build OK, self-hosted applet OK** (suite 15: 15 pass / 0 fail / 0 skip).

## Environment
| Item | Value |
|---|---|
| Date | 2026-11-01, build 11:47:35 → 11:51:25 (Europe/Paris, CET) |
| Upstream | geogebra/geogebra @ `375db7f` (box clone `/workspace/AlgoGebra/geogebra`) |
| OS | Debian GNU/Linux 13.7 (trixie), kernel 6.12.94, x86_64, ~13 GB RAM free |
| JDK | Temurin OpenJDK 21.0.13+9 (`JAVA_HOME`) – Gradle 9.4.1 wrapper |
| Browser | Google Chrome 156.0.8078.47, `--headless=new`, driven via CDP (Node 20 `--experimental-websocket`) |
| Server | `python3 -m http.server 8765 --bind 127.0.0.1` (runtime only) |

## Exact build commands (from the upstream clone root – `gradlew` is at the root, not in `source/`)
```
./gradlew -p source/web -Pgmodule=org.geogebra.web.SuperWeb :web:deployIntoWar --no-daemon --console=plain -Dorg.gradle.jvmargs=-Xmx1g
./gradlew -p source/web -Pgmodule=org.geogebra.web.SuperWeb :web:copyHtml :web:mergeDeploy --no-daemon --console=plain
```
* Run 1: 3 min 49 s wall, `:web:gwtCompile` **succeeded** (1 permutation, *Compilation succeeded – 118.1 s*, link 2.3 s),
  then **`:web:deployIntoWar` FAILED** on a Gradle-9 validation error, not a compile error:
  `Type 'org.gradle.api.tasks.Copy' property 'destinationDir' doesn't have a configured value.`
  (upstream config issue: `deployIntoWar` has no `into(...)` under Gradle 9.4.1). The war was already linked.
* Run 2: 8 s, exit 0 – produces `deployggb.js` (template with the permutation id + `%MODULE_BASE%`=`./`).
* **Recommended task set** (what suite 15 uses with `GGB_WEB_BUILD=1`): `:web:gwtCompile :web:copyHtml :web:mergeDeploy`.
* Codex's Windows attempt (`:web:gwtCompile :web:compileSass`, 60c3246) should work with this set; `deployIntoWar` will fail there too.

## Outputs (NOT committed – binaries stay out of git)
| Path | Size | sha256 |
|---|---|---|
| `source/web/web/war/` (264 files) | 60 189 041 B | – |
| `war/web3d/web3d.nocache.js` | 6 188 B | `b4c7254f85388e015539d4c7f92f77eac62371a9674ec08bb44468cce78e6233` |
| `war/web3d/deferredjs/0C67C8A47F0579D49611F42F63B45791/` | (permutation) | – |
| `war/deployggb.js` | 68 604 B | `3644dae55e8e1068036a4227a7f9709d63b44e0087310011d3331f1f561680d8` |
| Archive `/workspace/AlgoGebra/webbuild/geogebra-web-SuperWeb-375db7f_GROK_V1.tar.gz` | 15 393 913 B | `d8b862f42d3e81c0469d7a7675eaadca70d645e5236ae068c54fd092c22cd99f` |
| Log `/workspace/AlgoGebra/webbuild/gwt-build.log` (run 1, ends `exit=1`) | | `715fc551cdc810e24c4629b560c00895336394da9d58c4cf45c6a18397365844` |
| Log `/workspace/AlgoGebra/webbuild/gwt-deploy.log` (run 2, `exit=0`) | | `9afdcdfa438721b479aea27dae41802a55d4ed82030ab0538fec8436611c721c` |
| Screenshot `/workspace/AlgoGebra/webbuild/probe.png` | 46 333 B | `ed0a90d9ec54b857a1dd597c426a232d735327edac64482c10cfe509d89e0549` |

## Runtime check (fixtures/web/webbuild_probe_GROK_V1.html)
`new GGBApplet({appName:'classic',...}, true)` + `setHTML5Codebase('war/web3d/')` + `inject()`; in `appletOnLoad`:

| Call | Expected | Actual |
|---|---|---|
| `evalCommand('A=(1,2)')` / `f(x)=x^2-2x` / `m={{1,2},{3,4}}` | true ×3 | true ×3 |
| `getValueString('A')` | `A = (1, 2)` | `A = (1, 2)` |
| `getValueString('f')` | `f(x) = x² - 2x` | `f(x) = x² - 2x` |
| `getValueString('m')` | `m = {{1, 2}, {3, 4}}` | same |
| `getValue('x(A)')` | 1 | 1 |
| `evalCommandCAS('Expand((x+1)^2)')` (giac.js) | `x² + 2x + 1` | same (2nd poll) |
| requests outside `127.0.0.1:8765` | 0 | 0 (17 resources, all local) |

Applet ready ~1.6 s after inject. The screenshot shows the classic UI with A, the parabola and the matrix in the algebra view.

## Notes
* `chrome --headless=new --screenshot/--dump-dom` hangs on this page (never idles); the CDP driver `fixtures/web/cdp_probe_GROK_V1.mjs` is used instead.
* Firefox-esr is not installed on the box; the test accepts any Chromium-family browser (`GGB_BROWSER`, Chrome, Chromium, Edge).
* The web build uses giac.js (wasm) for CAS – the external engines (PARI/Maxima) are not reachable from this path.

## Reproduce
```
pwsh 03-RCP-Spike/tests/15_Test_WebBuild_GROK_V1.ps1              # uses existing war (GGB_WEB_WAR or ../geogebra/source/web/web/war)
GGB_WEB_BUILD=1 GGB_UPSTREAM=/path/geogebra pwsh ...15_Test_WebBuild_GROK_V1.ps1   # builds first (JDK 21 in JAVA_HOME)
```
