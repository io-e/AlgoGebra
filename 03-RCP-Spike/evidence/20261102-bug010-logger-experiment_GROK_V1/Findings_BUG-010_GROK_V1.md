# BUG-010 (issue #28) logger experiment, Debian, 2026-11-02 (GROK_V1)
**Verdict: PROVEN (root cause), with 1 residual, separate failure (D04-FOCUS-01).**

## Root cause (unpatched image-fontfix, captured with `JDK_JAVA_OPTIONS=-Xlog:exceptions=info`)
The embedded panel never calls `Log.setLogger`, so `Log.logger` is null. `Log.debug/info/warn/error` check for null, but `Log.read()` (Log.java:349, `logger.doRead(string)`) does not.
When a valid input is entered, the object gets created, and then this chain runs on AWT-EventQueue-0:
```
NullPointerException at org.geogebra.common.util.debug.Log.read (bci 4)
  ScreenReaderAdapterD.readText (ScreenReaderAdapterD.java:26, Log.read("Reading text: "+text))
  ScreenReader.readText / ScreenReader.updateSelection
  App.updateSelection / SelectionManager.updateSelection / setSelectedGeos
  InputBarCallback.callback
  AlgebraProcessor.postProcessCreatedElements
  AlgebraProcessor.processAlgebraCommandNoExceptionHandling  -> error handler -> "Please check your input"
```
In the first suite 09 session, 5 NPEs were thrown, one per BUG-010 dialog in that session. The excerpt is `npe_throw_trace_unpatched_excerpt.txt`.

## Experiment (local scratch copy, not committed to production)
- `BUG-010_LoggerInit_GROK_V1.diff`: `GeoGebraPlusApplication.start()` installs `new LoggerD()` via `Log.setLogger`, using reflection through the GeoGebraPanel class loader so no manifest change is needed, and sets the log level to DEBUG.
- Only that one class was recompiled into a copy of `host/build/org.geogebra.plus.host_0.1.0.jar` (image-bug010).

| image | suite 09 | Verify #27 | Verify #28 |
|---|---|---|---|
| image-fontfix (unpatched) | 8/16/0 | PASS | FAIL (10 valid-input fails, 4 dead-input) |
| image-bug010 (patched), run 1 | 19/1/0 | PASS (P-02 50/0/1, D-11 8/0/0) | FAIL: only D04-FOCUS-01; dead-input 0 |
| image-bug010 (patched), run 2 | 19/1/0 | - | same |

- With the patch, KBD-01..07, D04-FOCUS-02 and D04-ORDER-01..04 all pass, there are no "keys-reach-input" failures, and KBD-08 (an invalid input) still shows the error dialog.
- Residual failure, reproduced in both runs: D04-FOCUS-01-2d-to-3d. Keystrokes for the 3D bar are lost (lost=True, dialog=False).
  - It passed on the unpatched image, where the earlier dialog changes the focus sequence.
  - This is a separate focus issue, not BUG-010.

## Recommendation for Codex
Adopt the diff, or a direct `Log.setLogger(new LoggerD())` with an Import-Package of `org.geogebra.desktop.util` and `org.geogebra.common.util.debug`. Then rerun `tests/Verify_Issues_27_28_GROK_V1.ps1 -Image <image>`.
