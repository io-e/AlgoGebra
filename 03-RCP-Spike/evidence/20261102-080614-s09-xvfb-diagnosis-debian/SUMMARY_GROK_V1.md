# Suite 09 (D-04) Xvfb keyboard-focus diagnosis (GROK_V1)
Result: the 17 failures are **not** a harness/focus problem. They come from two product issues; the harness now labels them.
| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| image-final (tip build), before | 7 | 17 | 0 |
| image-final, after (same counts, failures tagged KNOWN_BUG) | 7 | 17 | 0 |
| image-fontfix (renderer bundle + ReTeX fonts injected, experiment only) | 8 | 16 | 0 |
| experiment: xfwm4 WM on the private Xvfb | 6 | 21 | 0 |
| experiment: close dialog via windowfocus + XTEST Return | 6 | 21 | 0 |
Findings:
1. **Dialog after valid input (BUG-010):** `A=(1,2)` is created and "Please check your input" still opens (screenshot). The same happens with Return, KP_Enter, ctrl+m and a typed newline (probe), so it isn't how the key is delivered. Lead for Codex: the embedded GeoGebraPanel never calls `Log.setLogger` (only `GeoGebraFrame.main` does). `ScreenReaderAdapterD.readText` → `Log.read` → `logger.doRead` would then throw an NPE after the object is created, and that surfaces as the generic error dialog. Not proven: it would need a host change (`Log.setLogger(new LoggerD())`), which is Codex's code.
2. **Missing ReTeX fonts in the Linux image:** `org.geogebra.migration.desktop.renderer-5.4.934.0.jar` has 0 `.ttf` (classes from r8, no resources). That explains D04-FONT-01. With the fonts injected, functions `f(x)=x^2` and `g(x)=2x+1` are created (they weren't before).
3. Lost keys after a dialog are a follow-on of 1. The original `xdotool key --window` closes the dialog; with a WM or XTEST the dialog does not close, so those two harness changes were **rejected** (logs kept here).
Harness change: tagging only (`KNOWN_BUG BUG-010`, font count). No change to the UI driver.
