# EE-P2a..d Linux validation — WIMS C interfaces vs Java SubprocessEngine (GROK_V1)

**ID mapping:** CDC V1_2 is not on GitHub. "EE-P2a..d" is mapped to **Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md §Phase 2 steps 2a–2d** (on `feat/engine-subprocess-p1` @ `dd8ba96`). Test commands: V1_1 Phase 1 rows 1b/1c/1d/1f plus Codex's `test-engines.ps1` checks from PR #60.

Run: 20261104_0742_EE-P2_GROK_V1, Debian 13 (trixie) x86-64, base `dd8ba96`.

## Versions (Debian vs Windows reference)
| Component | Debian (this run) | Windows (Codex, PR #60) |
|---|---|---|
| PARI/GP | 2.17.2 (apt pari-gp) | 2.19.0 (Pari64-2-19-0) |
| Maxima | 5.47.0 (apt) | 5.49.0 |
| Gnuplot | 6.0 patchlevel 2 (apt gnuplot-nox) | bundled with Maxima 5.49.0 |
| GAP | 4.14.0 (built from upstream tarball; apt mirror returned HTTP 500, `gap` not installable) | n/a |
| WIMS C interfaces | stock WIMS 4.31b `src/Interfaces` (`/workspace/wims-full`), built in a scratch copy: pari, maxima, gap | wims4win port |
| Java | Temurin 21.0.13 | Temurin 21.0.12 |

WIMS stock vs wims4win port: `pari.c` identical; `maxima.c`, `gap.c`, `common.c` differ only by `_WIN32` platform layers (process/pipe abstraction, `gap.exe`, sbcl env) — filters and headers unchanged.

## Step results
| Step | Verdict | Notes |
|---|---|---|
| 2a install | **PARTIAL→PASS** | pari/maxima/gnuplot from apt; GAP built from source because the Debian mirror was down (HTTP 500). |
| 2b WIMS C path | **PASS** | bin/pari, bin/maxima, bin/gap built from stock WIMS source; Gnuplot has no WIMS C interface (WIMS exec.c pipes scripts to gnuplot directly), so the raw gnuplot run with pngcairo 800x600 is the reference. |
| 2c Java path | **PASS** (Pari/Maxima/Gnuplot) | Codex's `EngineAcceptanceTest` passes unchanged on Linux (`codex_acceptance_linux.log`). No Java GAP adapter (step 1f optional, not implemented) → GAP is WIMS-side reference only. |
| 2d compare | **PASS** for values; **expected divergence** on negatives | All positive outputs byte-identical after WIMS normalisation. Negatives: Java rejects upfront (`COMMAND_REJECTED`); WIMS either mangles the token (e.g. `sjstem`, `pJot`) or relies on gp `default(secure,1)`. |

Scenario `tests/scenarios/S_EE-P2_Linux_Compare_GROK_V1.ps1`: **27/27 PASS** (see `results.csv`, `results.json`).

## Per-test table
| ID | Command | WIMS C output | Java output | Match |
|---|---|---|---|---|
| P-01 | `factor(2^64-1)` | `3,1;5,1;17,1;257,1;641,1;65537,1;6700417,1` | same | yes (exact) |
| P-02 | `factor((` (BUG-015) | gp syntax error text | `INVALID_OUTPUT` | yes (both error) |
| P-03 | `nextprime(10^20)` | `100000000000000000039` | same | yes |
| P-12 | `1.2300` | `1.23` | `1.23` | yes (strip_zeros parity) |
| P-04/P-11 | `plot(..)`, `write(..)` | illpart mangled (`pJot`, `wJite`) → gp error | `COMMAND_REJECTED` | yes (blocked) |
| P-05..P-07 | `system/extern/externstr("id")` | gp `[secure mode]` refusal | `COMMAND_REJECTED` | yes |
| P-08 | `install("getpid","l")` | gp asks "about to install … OK ?", WIMS times out | `COMMAND_REJECTED` | yes — Java stricter (BUG-006) |
| P-09 | `alias(s,system); s("id")` | gp error (built-in s) | `COMMAND_REJECTED` | yes |
| P-10 | `2+2\n\quit` | escape turned into `.quit` → syntax error | `COMMAND_REJECTED` | yes |
| M-01 | `diff(sin(x^2), x)` | `2*x*cos(x^2)` | same | yes (exact) |
| M-02 | `integrate(x^2, x)` | `x^3/3` | same | yes |
| M-03..M-06 | `system`, `load`, `plot2d`, `with_stdout` | token mangled, echoed unevaluated | `COMMAND_REJECTED` | yes (blocked) |
| G-01 | `Size(SymmetricGroup(5))` | `120` (+ harmless `.gap_hist` warning, HOME=/nodir) | no adapter | WIMS-only PASS |
| G-02/G-03 | `Exec`, `Process` | mangled → GAP error | no adapter | WIMS-only PASS (blocked) |
| N-01 | `plot sin(x)` | PNG 800x600 | PNG 800x600 | yes |
| N-02..N-06 | `!echo`, `system("id")`, `set output`, `call`, backticks | **executed / honoured by raw gnuplot** (N-03 ran `id`; N-06 backticks expanded) | `COMMAND_REJECTED` | Java blocks; WIMS has no gnuplot filter |

## Findings
1. Positive values are byte-identical between the WIMS C parsers and Java parsers on Debian (Pari, Maxima, Gnuplot dimensions).
2. Security behaviour diverges by design: the Java layer is strictly stronger (BUG-006 Pari list, EE-12/F-09 Gnuplot filter). The V1_1 2d wording "must match" should be read as "values match; rejections at least as strict".
3. Gnuplot has no WIMS C interface; raw gnuplot executes `system()` and backticks — WIMS relies on its own module-level controls. Not an AlgoGebra issue, but worth recording.
4. Version skew vs Windows (PARI 2.17.2 vs 2.19.0, Maxima 5.47.0 vs 5.49.0) did not change any tested output.
5. GAP Java adapter absent (1f optional) — GAP comparison is one-sided.

## Reproduce
Build the WIMS interfaces in a scratch copy (`src/configure`, `Lib` make, `Interfaces` make pari maxima gap), compile `03-RCP-Spike/engines` with javac 21 (excluding OSGi `Activator.java`), then:
`pwsh tests/scenarios/S_EE-P2_Linux_Compare_GROK_V1.ps1 -WimsInterfaces <dir> -JavaHome <jdk21> -EngineClasses <classes> -OutDir <dir> -ExtraPath <dir with gap.sh>`
