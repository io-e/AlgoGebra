# External WIMS Engines — Implementation and Validation Report

**Date:** 2026-10-29 (Windows / Europe-Paris)<br>
**Branch:** `feat/external-engines`<br>
**Source of requirements:** `02-Cdc/Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` and `02-Cdc/Decisions_External_Engines_GROK_V1.md`<br>
**GeoGebra source pin:** `375db7faf540` (no `source/shared/common/src` edits)<br>
**Scope:** Windows x86_64 first; no WIMS C binary/library, no `AlgoElement`, one-shot compute only.

## Result summary

| Slice | Implementation | Local result |
|---|---|---|
| Shared process runtime | Java `ProcessBuilder`, stdin/stdout/stderr pipes, bounded capture, timeout and process-tree kill, PATH discovery, missing-engine errors | **PASS** — self-tests passed. |
| Pari/GP | WIMS header, setup, denied-term/escape checks, prompt cleanup | **Implementation and parser/filter tests PASS.** Real factorization acceptance **SKIP**: `gp`/`gp.exe` is not on PATH. |
| Maxima | WIMS header, precision setup, deny lists, prompt/output normalization; supports `maxima.bat` through `cmd.exe` | **Implementation and parser/filter tests PASS.** Real derivative acceptance **SKIP**: Maxima is not on PATH. |
| Gnuplot | Generated PNG terminal/output script, no-shell/output-redirection filter, PNG signature/IHDR validation, result cleanup API | **Implementation/filter tests PASS.** Real PNG acceptance **SKIP**: Gnuplot is not on PATH. |
| OSGi integration | API/runtime plus one bundle per engine; each engine bundle registers an `ExternalComputeService` | **PASS** — installed Equinox image starts, registers all three engines with `available=false`, and resolves the original 50/50 D-03 set. |

**Important:** no engine was installed, downloaded, or substituted. This follows D-ENG-02. The binary-dependent acceptance criteria remain open until the approved executables are installed on PATH and the same tests are rerun.

## Implementation

- `engines/api/`: `ExternalComputeService`, `ComputeContext`, capabilities, result/artifact lifecycle, and typed failure codes.
- `engines/runtime/`: reusable `SubprocessEngine` and `ExecutableResolver`. Each `eval` starts one process; there is no persistent session or fallback to GIAC/another engine.
- `engines/pari/`: Pari/GP wrapper; `gp.exe -f -q` on Windows, `gp -f -q` on Unix-like systems.
- `engines/maxima/`: Maxima wrapper; Windows `.exe`/`.bat`/`.cmd` entry points are discovered on PATH, with batch wrappers invoked by `cmd.exe`.
- `engines/gnuplot/`: Gnuplot wrapper returns an `image/png` artifact. The default output root is `%TEMP%/GeoGebraPlus/external-engines` (or the `ggbplus.tempDirectory` override); `ComputeResult.close()` removes the generated PNG and its per-call directory after the consumer is done.
- Each implementation is a distinct OSGi bundle. Pari and Maxima are isolated from the host and each other because their WIMS-derived strings/filters/parsers are GPL-2.0-or-later material. The source notice and license text are in `engines/licenses/` and copied into the installed image.
- The CDC diagram placed `ExternalComputeService` in the host bundle; this spike exposes the same API from a small dedicated `compute.api` bundle so engine providers do not depend on UI-host internals. This is a modularity refinement, not a common/kernel change; confirm it before freezing the bundle map for productization.
- `build.ps1` compiles and stages five new bundles: compute API, compute runtime, Pari, Maxima, and Gnuplot. The original 50 D-03 input bundles remain unchanged.
- `test-engines.ps1` builds the bundles and runs dependency-free parser/filter/process tests.

## WIMS port and security boundary

The Pari/GP and Maxima command headers, deny-list values, quit strings, and output-normalization behavior are ported from the WIMS source files named in `engines/licenses/WIMS-INTERFACES.md`. WIMS `check_parm()` mutates forbidden terms to break them; this Java implementation rejects the matching request explicitly instead. The Pari `illegal[]` array is empty in the referenced source; its `illpart[]` is `plot`, `write`, `help`. Maxima's `illegal[]` and `illpart[]` values are preserved.

These filters are the D-ENG-03 MVP boundary, **not** an OS sandbox. A student process escape is still a documented residual risk; institutional sandboxing remains later work. Gnuplot additionally rejects shell-prefix commands, `system`/`shell`, process-pipe plot sources, and user terminal/output redirection so the wrapper retains control of its PNG path.

## Tests run

Command:

```powershell
& .\03-RCP-Spike\test-engines.ps1
```

Observed:

- `PASS: PATH discovery (including Windows PATHEXT)`
- `PASS: ProcessBuilder pipes and timeout/process-tree kill`
- Pari output fixture, factor-row normalization, trailing-zero normalization, denied `plot`, and GP escape rejection: **PASS** (the test script exits non-zero on failure).
- Maxima prompt fixture, multiple outputs, `b`-exponent normalization, and denied `system`/`plot`: **PASS**.
- Gnuplot shell-prefix/system/output-redirection rejection: **PASS**.
- Real Pari, Maxima, and Gnuplot acceptance calls: **SKIP** because their binaries are missing. For each engine, a valid request returned `ENGINE_UNAVAILABLE`; no fallback engine was invoked.

Installed-image command:

```powershell
& .\launch.ps1 -Headless -NoBuild
```

Run ID `20261029-103637-22680-d16e791b`; log:
`D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8\logs\rcp-20261029-103637-22680-d16e791b.log`.

Observed: Equinox exited 0; Pari, Maxima, and Gnuplot service bundles all registered; each reported `available=false`; host `IApplication.start()` ran; 50/50 unchanged D-03 bundles resolved. No external binary was started by bundle activation.

## Installed image

`D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8`

The image contains the bundled Java 25 runtime, the original RCP payload, 10 host/native-fragment/compute JARs, the five Windows native/API classifier JARs, and the GPL notices. It is a runnable prebuilt Equinox image launched with `launch.ps1`, not a PDE-exported EXE installer. `install-manifest.sha256` covers all product JARs and `jre\bin\java.exe`.

## Open acceptance items

1. Install the approved Windows PARI/GP binary on PATH; rerun `test-engines.ps1`; confirm `factor(2^64-1)` yields all seven prime factors with exponent one.
2. Install Maxima on PATH; verify `diff(sin(x^2), x) -> 2*x*cos(x^2)` against the installed version's actual prompts/output.
3. Install Gnuplot on PATH; verify `plot sin(x)` creates a readable 800x600 PNG and that `ComputeResult.close()` removes it.
4. Grok Bot validates the same cases on Debian. No Linux runtime claim is made here.
5. Owner reviews GPL bundle boundaries and the public license policy before distributing the combined image.
6. UI routing from an activity and writing results into a GeoGebra construction remain later host-integration work. No construction object or `AlgoElement` is created in this slice.
