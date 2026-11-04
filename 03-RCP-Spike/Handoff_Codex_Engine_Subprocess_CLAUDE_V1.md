<!-- CLAUDE_V1 -->
# Handoff — Engine Subprocess Implementation (EE-P1)

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_Engine_Subprocess_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Assigned to | **Codex** |
| Priority | **Normal** — no dependency on D-04 (pure Java, no RCP/SWT) |
| CDC | `02-Cdc/02-01_Wims_Integration/Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` |
| Existing code | `03-RCP-Spike/engines/` (skeleton already exists) |
| Branch | Create `feat/engine-subprocess-p1` from current tip |

---

## 1. Current state — what Codex already built

The `03-RCP-Spike/engines/` directory already has:

| Component | File | Status |
|---|---|---|
| `ExternalComputeService` interface | `api/src/.../ExternalComputeService.java` | **Exists** |
| `ComputeResult`, `ComputeContext`, `ComputeCapability` | `api/src/.../` | **Exists** |
| `ExternalComputeException` (with `Code` enum) | `api/src/.../ExternalComputeException.java` | **Exists** |
| `SubprocessEngine` (abstract) | `runtime/src/.../SubprocessEngine.java` | **Exists** — ProcessBuilder, timeout, process kill, stdin/stdout, stream drain |
| `ExecutableResolver` | `runtime/src/.../ExecutableResolver.java` | **Exists** |
| `PariGPEngine` | `pari/src/.../PariGPEngine.java` | **Exists** — WIMS header, security filter started |
| `MaximaEngine` | `maxima/src/.../MaximaEngine.java` | **Exists** |
| `GnuplotEngine` | `gnuplot/src/.../GnuplotEngine.java` | **Exists** |
| Engine activators (OSGi) | `pari/`, `maxima/`, `gnuplot/` Activator.java | **Exist** |
| Tests | `SubprocessEngineTests`, `PariEngineTests`, `MaximaEngineTests`, `GnuplotEngineTests`, `EngineAcceptanceTest` | **Exist** |

**Assessment:** The skeleton is substantial. The remaining work is hardening against the CDC V1_2 acceptance criteria, not greenfield.

---

## 2. What needs to be done — gap analysis vs. CDC V1_2

### 2.1 PariGPEngine (EE-P1b)

| CDC criterion | Current state | Work needed |
|---|---|---|
| Full AGB_ILLEGAL list | Filter started, may be incomplete | **Verify** against `Decisions_PARI_Forbidden_GROK_V1.md`: must block `plot`, `plotinit`, `write`, `writebin`, `help`, `system`, `extern`, `externstr`, `fileextern`, `install`, `eval`. Whole-word match. Return `COMMAND_REJECTED`. |
| `default(secure,1)` in header | Present in WIMS_HEADER | **Verify** it's the first line after aliases |
| `factor(2^64-1)` test | Test file exists | **Verify** expected output matches CDC: `[3, 1; 5, 1; 17, 1; 257, 1; 641, 1; 65537, 1; 6700417, 1]` (after output parser) |
| `system("ls")` → COMMAND_REJECTED | Unknown | **Add** explicit negative test |
| Empty output on valid input = error | Unknown | **Add** test: valid expression that produces empty output must throw, not return success (BUG-015 / X-06) |

### 2.2 MaximaEngine (EE-P1c)

| CDC criterion | Current state | Work needed |
|---|---|---|
| `diff(sin(x^2), x)` → `2*x*cos(x^2)` | Test file exists | **Verify** expected output |
| Blocked commands: `system`, `save`, `load`, `file`, `debug`, `plot`, `batch`, `demo` | Unknown completeness | **Verify** filter list against CDC §EE-11 |
| Empty output = error | Unknown | **Add** same as Pari |

### 2.3 GnuplotEngine (EE-P1d)

| CDC criterion | Current state | Work needed |
|---|---|---|
| `set terminal pngcairo` (not `png`) | Unknown | **Verify** header uses `pngcairo` |
| Host-controlled output path | Unknown | **Verify** engine forces output path, student cannot redirect |
| Block: `set output`, `set print`, `load`, `call`, `save`, backticks | Unknown completeness | **Verify** filter list against CDC §EE-12 |
| PNG magic bytes validation | Unknown | **Add** — read first 8 bytes of output file, verify PNG signature `\x89PNG\r\n\x1a\n` |
| `set output "/etc/passwd"` → COMMAND_REJECTED | Unknown | **Add** explicit negative test |

### 2.4 SubprocessEngine base (EE-P1a)

| CDC criterion | Current state | Work needed |
|---|---|---|
| Timeout + process kill | Exists | **Verify** `destroyForcibly()` is called, not just `destroy()` |
| `isAvailable()` = true/false | Exists (`ExecutableResolver`) | **Verify** error message names the engine when false |
| Mock engine unit test | `SubprocessEngineTests` exists | **Verify** covers: start, send, receive, timeout kills |

### 2.5 Engine discovery (EE-P1e)

| CDC criterion | Current state | Work needed |
|---|---|---|
| Missing binary = error message naming the engine | `ExternalComputeException(Code.ENGINE_UNAVAILABLE, ...)` | **Verify** message includes engine name AND checked paths |
| `isAvailable()` per engine | Exists | OK |

---

## 3. Test matrix

All tests must pass on **Windows x86_64** with engines installed on PATH.

| Test ID | Engine | Input | Expected | Type |
|---|---|---|---|---|
| **T-PARI-01** | Pari/GP | `factor(2^64-1)` | `[3, 1; 5, 1; 17, 1; 257, 1; 641, 1; 65537, 1; 6700417, 1]` | Positive |
| **T-PARI-02** | Pari/GP | `system("dir")` | `COMMAND_REJECTED` | Security filter |
| **T-PARI-03** | Pari/GP | `extern("cmd")` | `COMMAND_REJECTED` | Security filter |
| **T-PARI-04** | Pari/GP | `install(...)` | `COMMAND_REJECTED` | Security filter |
| **T-PARI-05** | Pari/GP | empty string | `INVALID_REQUEST` exception | Validation |
| **T-MAX-01** | Maxima | `diff(sin(x^2), x);` | `2*x*cos(x^2)` | Positive |
| **T-MAX-02** | Maxima | `system("ls");` | `COMMAND_REJECTED` | Security filter |
| **T-MAX-03** | Maxima | `load("/etc/passwd");` | `COMMAND_REJECTED` | Security filter |
| **T-GNU-01** | Gnuplot | `plot sin(x)` | Valid PNG file (magic bytes `89 50 4E 47`) | Positive |
| **T-GNU-02** | Gnuplot | `set output "/tmp/evil.txt"` | `COMMAND_REJECTED` | Security filter |
| **T-GNU-03** | Gnuplot | `` `ls` `` (backtick) | `COMMAND_REJECTED` | Security filter |
| **T-BASE-01** | Mock | Send + receive | Correct output | Unit |
| **T-BASE-02** | Mock | Infinite loop | Timeout → process killed | Unit |
| **T-BASE-03** | Mock | Missing binary | `ENGINE_UNAVAILABLE` with engine name | Unit |

---

## 4. Engine installation on Windows (prerequisites)

Codex needs these on PATH for the tests to run:

| Engine | Windows install | Expected binary |
|---|---|---|
| Pari/GP | Download from `pari.math.u-bordeaux.fr` (~20 MB) | `gp.exe` |
| Maxima | MSYS2 `pacman -S mingw-w64-x86_64-maxima` or standalone installer (~100 MB) | `maxima.bat` or `maxima` |
| Gnuplot | Download from `gnuplot.info` or `choco install gnuplot` (~10 MB) | `gnuplot.exe` |

If binaries are not available on the Codex environment, mark the integration tests as `@Disabled("requires <engine> on PATH")` and ensure unit tests with mock engine pass.

---

## 5. Deliverables

| # | Deliverable | File |
|---|---|---|
| 1 | Hardened `PariGPEngine` with full AGB_ILLEGAL + negative tests | `engines/pari/` |
| 2 | Hardened `MaximaEngine` with complete filter + negative tests | `engines/maxima/` |
| 3 | Hardened `GnuplotEngine` with host-forced output + PNG validation + negative tests | `engines/gnuplot/` |
| 4 | `SubprocessEngine` timeout/kill verification | `engines/runtime/` |
| 5 | Test report: all T-xxx results with pass/fail/skip | `03-RCP-Spike/evidence/Engine_Subprocess_P1_Report_CODEX_V1.md` |

---

## 6. What NOT to do

- Do **not** implement connected mode (WIMS CGI, HTTP submission) — that's Phase 2/deferred.
- Do **not** add OSGi service registration wiring yet — that's Phase 3 (EE-P3b). Keep engines as plain Java classes testable with JUnit.
- Do **not** fall back to a different CAS engine if one is missing — `ENGINE_UNAVAILABLE` is the correct response.
- Do **not** implement GAP unless the other three are done and passing. GAP is optional (EE-P1f).
- Do **not** touch the `host/` or `giac-native/` code — engine work is independent.

---

## 7. Relation to D-04 investigation

These two handoffs are **independent**. Engine subprocess work has zero dependency on SWT/AWT focus transfer. Codex can work on both in parallel:

- D-04 input investigation → `feat/rcp-product-spike` branch
- Engine subprocess hardening → `feat/engine-subprocess-p1` branch (new)

---

*End of `Handoff_Codex_Engine_Subprocess_CLAUDE_V1.md`.*
