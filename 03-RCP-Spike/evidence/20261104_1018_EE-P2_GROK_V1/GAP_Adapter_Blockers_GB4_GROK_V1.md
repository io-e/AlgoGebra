<!-- GROK_V1 -->
# GAP adapter blockers (G-B4)

## Blocker
#60 (head e483500) has no Java GAP adapter, so `ee_fixture_set_F_GROK_V1.json` lists `gap` in `engines_without_java_adapter`. All 24 GAP cases (G-01..G-24) run WIMS-side only (REF-PASS 24/24 in the 20261104_1018 run). There is no soft-parity check until Codex adds `engines/gap`.

## Minimum subset once the adapter lands (13 cases)
| Purpose | ids |
|---|---|
| Integers / big ints | G-01, G-05, G-12 |
| Boolean | G-04 |
| List output (bracket and space normalization) | G-07 |
| Syntax error must error | G-13 |
| illegal[] names | G-14 (Exec), G-15 (Process), G-17 (SaveWorkspace) |
| illpart[] substrings | G-19 (To), G-21 (Read), G-22 (File) |
| Underscore / package escape | G-24 (`IO_fork`) |
The full 24 should still run, but these 13 cover every gap.c code path.

## Expected output normalization
- `ws-collapse` (remove all whitespace/CR/newlines) on both sides, as for pari. Example: G-07 `[ 2, 2, 2, 3, 3, 5 ]` compares as `[2,2,2,3,3,5]`.
- gap.c `output()` joins multi-line results onto one line, strips leading/trailing spaces, and strips one outer `[ ]` pair when the result starts with `[` and ends with `]`. The Java adapter should either do the same or the comparison should drop an outer `[ ]` before comparing. G-07's recorded WIMS output still has brackets, so check this on the first Java run.
- Booleans are lowercase `true`/`false`; `fail` is a value, not an error.

## WIMS gap.c quirks (from `ee_wims/src/Interfaces/gap.c`)
- Command `gap.sh -T -n`; prompt `gap> ` is used to split outputs; I/O size limit 131072 bytes.
- `check_parm` replaces every `_` with `K` (so `IO_fork` becomes `IOKfork`), appends `;` if missing, then `find_illegal`.
- `illegal[]` = Reread, Process, Exec, Filename, SaveWorkspace; `illpart[]` = File, Path, Read, To. Blocking is by token mangling, not an error code, so Java should reject explicitly (soft parity: at least as strict).
- `illpart` is a substring match: legitimate names containing `To`/`Read`/`File`/`Path` are also blocked (for example `ToString` gets mangled). The Java adapter should copy this list, or the owner should approve a narrower one.
- gap.c sets HOME=/nodir, so a `.gap_hist` PrintTo error line shows up on stderr (the harness filters it as noise).
