<!-- GROK_V1 -->
# Decision — PARI/GP forbidden commands (BUG-006) — GROK_V1

**Author / version:** Grok Bot, GROK_V1 — 2026-10-29 (Europe/Paris). **Status:** ACCEPTED by the user on 2026-10-29 (`eval` addition pending user confirmation, see below).
**Scope:** `03-RCP-Spike/engines/pari/.../PariGPEngine.java` (`AGB_ILLEGAL`, checked in `validateCommand`). Related: D-ENG-03 in `Decisions_External_Engines_GROK_V1.md`.

## Decision
The command filter rejects these gp functions (whole-word, case-insensitive match, after WIMS control normalisation) **before the gp process is resolved or started**.
The request fails with `COMMAND_REJECTED`:

| Name | Why (gp 2.17.2 `?name`) |
|---|---|
| `system` | "execute the system command str" |
| `extern` | "execute shell command str, and feeds the result to GP" |
| `externstr` | "execute shell command str, and returns the result as a vector of GP strings" |
| `fileextern` | "execute shell command str and returns a file descriptor" |
| `install` | "load from dynamic library 'lib' the function 'name'" |
| `eval` | can rebuild any blocked name from strings at run time (see the finding below) |

`systemstr` does not exist in gp 2.17.2 ("unknown identifier"), so it is not listed. Because the match is on whole words, `alias(s,system)` is rejected too, while `systematic`, `installed`, `evaluate` are not.
The header keeps `default(secure,1)`, unchanged. The filter is defence in depth. It is not a replacement for secure mode.

## Rationale (PARI documentation)
- GP defaults, `secure` (https://pari.math.u-bordeaux.fr/dochtml/html/GP_defaults.html): "If on, the `system` and `extern` command are disabled … The default value is `0`." Secure mode is off by default, so a gp started without our header (or with the header broken) has no protection.
- `install` (https://pari.math.u-bordeaux.fr/dochtml/ref-stable/Programming_in_GP__other_specific_functions.html) loads external symbols from shared libraries. That can make `system` unnecessary, because the C `system` function can itself be installed.

## Finding: secure mode does not stop `install`
With gp 2.17.2 and `default(secure,1)`, `install` only prints `[secure mode]: about to install 'getpid'. OK ? (^C if not)` and waits for a line.
With piped stdin, which is how the engine talks to gp, the next input line confirms it.
On 2026-10-29, through the engine (EngineCli, before this change), `eval(Str("ins","tall(\"getpid\",\"l\")"))` followed by `print(getpid())` printed a real PID: a native libc symbol was loaded.
The plain-word filter alone would miss this, because the name is built from strings. So `eval` is also blocked.
**User confirmation needed for `eval`:** blocking it also refuses harmless uses such as `eval("x^2")`.

## Deviation from WIMS
WIMS `pari.c` has an empty `illegal[]` list (only `illpart[]` = plot, write, help). This is a deliberate, documented deviation from WIMS. `WIMS_ILLEGAL` and `WIMS_ILLPART` stay byte-for-byte identical to WIMS; the extra list is separate (`AGB_ILLEGAL`).

## Not a sandbox claim
Consistent with D-ENG-03, the filter and secure mode lower the risk; **the PARI engine is not a sandbox**. Other risks remain: reading files (`read`, `readstr`, `readvec`), resource exhaustion inside the timeout, and gp features not reviewed here. Real isolation needs OS-level confinement (separate user, container, seccomp/AppContainer), which is out of MVP scope.

## Tests
- Unit: `engines/pari/test/.../PariEngineTests.java`: each name, `alias(s,system)`, upper case, a second line, and `eval(Str(..install..))` give `COMMAND_REJECTED`. The rejection happens in `validateCommand`, before the executable is resolved, so it does not depend on gp. A whole-word negative check is included.
- Pack: `03-RCP-Spike/tests/fixtures/sandbox_GROK_V1.tsv`: SBX-02 changed from NOEXEC to REJECT, new SBX-14..19 (extern, externstr, fileextern, install, alias, eval/Str install), run by `05_Test_Sandbox_GROK_V1.ps1`.
- Windows image: must be rebuilt (r9, BUG-008) to include this filter.
