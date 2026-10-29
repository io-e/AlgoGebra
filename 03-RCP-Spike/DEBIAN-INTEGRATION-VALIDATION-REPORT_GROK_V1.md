<!-- GROK_V1 -->
# Debian Integration Validation Report — External Engines + Linux RCP image

**Author / version:** Grok Bot, GROK_V1<br>
**Date:** 2026-10-29, runs 13:27–13:35 Europe/Paris (UTC+1)<br>
**Branch:** `feat/debian-integration` (forked from `feat/external-engines` @ `8054109`)<br>
**GeoGebra pin:** `375db7faf5407390bb322165f2414415da8faeda` (shallow clone, unmodified; used only for resources)<br>
**Scope:** Grok Bot role per AGENTS.md — Debian integration tests of PARI/GP, Maxima, Gnuplot engines; Linux port of the RCP spike pipeline.

## Environment

| Item | Value |
|---|---|
| OS | Debian 13.7 (trixie) x86_64, kernel 6.12.94+ |
| Build JDK | Temurin 21.0.13+9 (tarball from api.adoptium.net; Debian apt mirror returned HTTP 500 at test time) |
| Runtime JDK | Temurin 25.0.5+8 (Windows image uses JustJ 25.0.4) |
| PARI/GP | 2.17.2 (/usr/bin/gp) |
| Maxima | 5.47.0 (/usr/bin/maxima) |
| Gnuplot | 6.0 patchlevel 2 (/usr/bin/gnuplot) |
| Display | Xvfb (xvfb-run, 1600x1000x24), Mesa 25.0.7, GTK 3.24.49 |
| Fixture | 50 D-03 bundles copied byte-identical from Windows image `GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8`; input-set SHA-256 `f5113da0e22d00c08c596793aacfb05aa1af05436e18f8b6ee62e3cf8a1750f4` (identical to r8) |
| Linux natives | SWT `org.eclipse.swt.gtk.linux.x86_64` 3.135.0.v20260819-1952 (same qualifier as win32 fragment), gluegen-rt/jogl-all 2.6.0 natives-linux-amd64 (Maven Central), javagiac 70501 natives-linux-amd64 (dev.geogebra.org/maven2) |

## New scripts (bash ports)

- `test-engines.sh` — port of `test-engines.ps1`: builds the 5 engine bundles (compile classpath = engines + osgi.core 8.0.0) and runs `EngineAcceptanceTest`.
- `build.sh` — port of `build.ps1` + `install-product.ps1`: stages `image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64` from the r8 reference bundles, swaps win32 natives for Linux natives, builds host/resource/native fragments and engine bundles, generates `config.ini` and `bundles.info`, computes the D-03 set hash with the build.ps1 algorithm.
- `launch.sh` — port of `launch.ps1` (`--headless`, `--boot-delegate-jogamp`).
- Project code change (no upstream change): the three native bootstrap fragments (`GiacNativeBootstrap`, `GeoGebraPlusGlueGenNativeBootstrap`, `GeoGebraPlusJoglNativeBootstrap`) now pick `.so`/`natives/linux-amd64` names on non-Windows; Windows behaviour is unchanged.
- Not ported: Gradle/bnd production of the 50 bundles on Linux (bundles reused from the Windows build, they are pure Java and byte-identical).

## Scenario results

| ID | Scenario | Command | Expected | Actual | Status | Log |
|---|---|---|---|---|---|---|
| DEB-ENG-01 | Subprocess runtime self-tests | `./test-engines.sh` | PASS | PASS (PATH discovery; pipes + timeout/process-tree kill) | **RUN — PASS** | evidence/debian/test-engines.log |
| DEB-ENG-02 | PARI engine `factor(2^64-1)` | `./test-engines.sh` | rows 3,5,17,257,641,65537,6700417 | AssertionError: output contains header echoes `I`, `2.7182818284590452354` (×2) before the matrix; parsed map wrong | **RUN — FAIL** | evidence/debian/test-engines.log |
| DEB-ENG-03 | Maxima engine `diff(sin(x^2),x)` | MaximaEngineTests.run() via one-off runner | `2*x*cos(x^2)` | AssertionError "Unexpected Maxima derivative": every WIMS header line result (20, false, true, …, done) precedes the correct `2*x*cos(x^2)` | **RUN — FAIL** | evidence/debian/maxima-gnuplot-suites.log |
| DEB-ENG-04 | Gnuplot engine PNG `sin(x)` 800x600 | GnuplotEngineTests.run() | valid 800x600 PNG | "PASS: Gnuplot produced a valid 800x600 PNG" | **RUN — PASS** | evidence/debian/maxima-gnuplot-suites.log |
| DEB-CLI-01 | Direct CLI cross-check (gp, maxima, gnuplot pngcairo 800x600, file deleted after) | see log | factors, `2*x*cos(x^2)`, PNG | all correct; PNG sha256 dfe541e8…f760a, deleted (ls: no such file) | **RUN — PASS** | evidence/debian/direct-cli-compute.log |
| DEB-RCP-01 | Linux image build | `./build.sh` | image + 50/50 hash = r8 | built; hash f5113da0… identical | **RUN — PASS** | evidence/debian/build.log |
| DEB-RCP-02 | Headless D-02 + engine registration under Xvfb | `xvfb-run -a ./launch.sh --headless` | 50/50 RESOLVED, 3 engines available=true | D-02 PASS 50/50; pari/maxima/gnuplot `available=true` | **RUN — PASS** | evidence/debian/launch-headless-xvfb.log |
| DEB-RCP-03 | UI + GIAC `Expand[(x+1)^2]` + JOGL under Xvfb (D-04/D-05 Linux) | `timeout 180 xvfb-run -a ./launch.sh` | GIAC native loaded, x²+2x+1 | libjavagiac64.so, libgluegen_rt.so, 5 JOGL .so loaded in owning bundle loaders; CAS result `x² + 2x + 1`, ASSERTION PASS; 3D point accepted, 3D view initialized | **RUN — PASS** (window kept open, killed by timeout 124 as designed) | evidence/debian/launch-ui-xvfb.log |
| DEB-RCP-04 | D-04 keyboard/focus/clipboard, HiDPI, strict 3D screenshot on Linux | — | — | — | **NOT RUN** | — |

## Findings

1. **PARI and Maxima output parsers are not robust to real binaries (first real run on any OS).** On Windows these acceptance tests were SKIP (no binaries), so this is not necessarily Linux-specific. With stdin not a TTY, gp 2.17.2 prints results of header assignments (`i=I`, `e=exp(1)`, `E=exp(1)`) despite `default(output,0)`; Maxima prints every header statement result. Suggested fix (engine code, owner to decide): terminate header statements with `;`/`$`, or emit a sentinel (e.g. `print("__GGBPLUS_BEGIN__")`) before the user command and parse only after it.
2. Linux native loading via owning-bundle fragments works without `java.library.path` or boot delegation.
3. Upstream pin and the 50 bundles are unchanged.

## Log hashes (SHA-256)

```
0a53e11f583136a76cc93e2b38bd1d997f6ed881d1cbb30031b7a2a425011490  build.log
5f2430bc55e94e3c425f6ca5022aeebdb76d2a146030cec201301491f0c5a388  direct-cli-compute.log
6f36d5986ecfb3dbb12354e81a0e737de5b112d01057af3b12b7da810753c807  launch-headless-xvfb.log
0a2d6a8a4e678d6df3ec0015788b3d99720202af36917b9629fb67b2e7abc4b8  launch-ui-xvfb.log
b5bb67e551f471dd175528d245e99021047eecdbe9b313aaabcac4da38129678  maxima-gnuplot-suites.log
37ac1fe288c9aad73205ec3ecab938f072ea41eda89149ed68bf42276a3fdd95  test-engines.log
```

## Addendum GROK_V1 (14:21 Europe/Paris) — test pack `tests/`

Full pack `tests/Run_All_GROK_V1.sh` RUN on Debian: **66 PASS / 25 FAIL / 3 SKIP** (gate NOT MET). Per-suite: 01 10/0/0, 02 5/5/0,
03 7/7/0, 04 8/0/0, 05 16/0/0, 06 7/4/0, 07 6/9/3, 08 7/0/0. All FAILs = BUG-001/BUG-002 (engine parsers), direct references PASS.
Logs and CSV: `tests/results/`. Windows `.ps1` twins: NOT RUN. See `tests/README_TESTS_GROK_V1.md`.

### WIMS vs AlgoGebra port (root cause of BUG-001/BUG-002)
WIMS `src/Interfaces/common.c` (`prepare1`, `putparm`, `readresult`) generates per call a random `Start line <prog> r1 r2 r3 r4` /
`End line …` pair, sends header, then `stringprinter(start)`, the command, `stringprinter(end)` (PARI: `print("%s")`, Maxima: `"%s";`),
and parses **only the text after the last start marker up to the end marker** before the per-CAS `output()` (prompt splitting,
Mat()/[] stripping, one-line join; Maxima also lowercases). Headers in `pari.c`/`maxima.c` are byte-identical to our `WIMS_HEADER`s:
the header is not quiet in WIMS either — it is simply discarded by the markers. Our `PariGPEngine`/`MaximaEngine.prepareRequest`
concatenate header + command without markers, so `parseOutput` returns every header result. Other differences: PARI port adds
`setrand`/`\e1`; WIMS sets `GPRC=../.gprc`; Maxima WIMS lowercases input/output and appends `;`.
**Faithful fix (not applied):** port `putparm`/`readresult` into `SubprocessEngine` (random markers, extract last-start..end) and keep the existing parsers on the extracted slice.
