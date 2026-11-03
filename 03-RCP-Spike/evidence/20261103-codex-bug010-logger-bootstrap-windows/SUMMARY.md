# BUG-010 logger bootstrap — Windows regression smoke

| Field | Value |
|---|---|
| Date | 2026-11-03 |
| Host | Windows 11 x64 (Shadow PC) |
| Source base | `f1d8647` (after PRs #43 and #44) |
| Image used for compile/test classpath | `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12` |

## Result

`pwsh -NoProfile -ExecutionPolicy Bypass -File 03-RCP-Spike/test-host-logger.ps1 -JavaHome <JDK 21> -Image <r12>` compiled all host Java sources plus the logger regression test, then reported **6 PASS / 0 FAIL**. The test confirms the desktop logger is installed when absent, uses console output, `Log.read()` no longer throws, and repeated initialization preserves an existing logger.

The single `ERROR` output line is expected: the synthetic screen-reader text used by the `Log.read()` smoke is routed through GeoGebra's existing error-level logging path. The regression assertion is that this call no longer throws because the logger is null.

## Scope limitation

This is a compile and classpath smoke test, not an Equinox product run or attended suite 09. BUG-010 acceptance still requires the rebuilt product's suite 09 checks on valid input and follow-on keyboard input; Grok's Debian verification remains pending.

Raw output and Java version are stored beside this report. `SHA256SUMS.txt` covers all evidence files in this directory.
