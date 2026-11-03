# PR #48 (Codex, closes #33) Debian verification: head 924f764 (GROK_V1)
Debian 13 / Xvfb :97 (the suite's own display, no WM) / pwsh 7.6 / build JDK 21, runtime JDK 25. Image built with `build.sh` from scratch branch
`scratch/v48-plus-49` = #48 head 924f764 + #49 (`grok/hygiene-suite09-order-font`, normal merge) into `/workspace/AlgoGebra/image-pr48` (not committed).
#49 is test-only, so the same image serves both test variants. The host jar contains the bridge (log: `D-04 3D input focus bridge installed`). bnd-input-set.sha256 is unchanged (f5113da0...50f4).

## Verdict: #48 does NOT fix #33 on Debian and regresses suite 10 D05-05

### Suite 09 (target 20/0/0)
| Run | Image | Tests | Result | Failing |
|---|---|---|---|---|
| base-hyg-1 | prod-2f24a7e | #49 | 17/3/0 | FOCUS-01, ORDER-03, ORDER-04 |
| pr48-49-1..3 | pr48 | #49 | 17/3/0 x3 | FOCUS-01, ORDER-03, ORDER-04 |
| pr48-plain-1..3 | pr48 | #48 only | 19/1/0 x3 | FOCUS-01 |
| ref48-49-1..2 | ref candidate | #49 | 17/3/0 x2 | FOCUS-01, ORDER-03, ORDER-04 |
Every run gives the same result, so the failures are deterministic, not flakiness. #48 changes nothing in suite 09.
(An earlier attempt pointed the suite at a shared Xvfb :7 by mistake. It was discarded and is not included.)

### Verify_Issues_27_28 (pr48 image, #49 checks)
#27 PASS. #28 FAIL: only because the stricter #49 checks fail ORDER-03/04, which are the #33 symptom. Invalid-dialog and no-dead-input checks pass.

### Run_All (pr48 image + #49): 323/13/61 vs 335/1/61 at 2f24a7e
- Suite 09: 19/1/0 -> 17/3/0. Both extra failures come from the #49 checks, not from the product.
- Suite 10: 5/0/0 -> 4/1/0. **Regression.** D05-05-3d-redraw-after-point fails in 3 of 3 runs on pr48, passes 2 of 2 on the baseline and passes on the ref candidate (no Codex bridge).
- Suite 15: 6/9/0 in Run_All (applet load timeout), 15/0/0 when rerun alone. Environment flake, unrelated to the host change.

## Root cause (probe/Probe_FocusTrace_GROK_V1.ps1, -Dggbplus.focusTrace=true)
- X input focus stays on the SWT shell toplevel the whole time; there is no WM, and XEmbed carries the focus.
- After the first click in the 3D bar, the bridge traces `frameFocused=true; accepted=true; inputHasFocus=false; owner=sun.awt.X11.XEmbeddedFrame`. The keystrokes are lost. A second click works.
- `embeddedFrame.requestFocus()` makes the *Frame component itself* the AWT focus owner. On a fresh session (suite 10: first-ever click into the 3D bar, which works on baseline) it steals focus from the text field, so `A=(1,2,3)` is lost. That is the D05-05 regression.
- The underlying #33 loss happens in both directions (ORDER-03 is 2D->3D, ORDER-04 is 3D->2D). The bridge only touches the 3D field, so it could never cover ORDER-04.

## Reference candidate (evidence only, NOT effective)
`ref_candidate_swt_awt_focus_NOT_EFFECTIVE.diff`:
- Replaces the Codex bridge with a global AWT mouse-press listener that does SWT `composite.setFocus()` -> `EmbeddedFrame.synthesizeWindowActivation` -> `requestFocusInWindow` on both panes.
- Result: it removes the D05-05 regression (suite 10 5/0/0), but suite 09 is still 17/3/0.
- So the remaining loss is a first-activation problem of XEmbed under a WM-less Xvfb. It still needs either a Windows confirmation of #48 or a deeper fix (for example re-dispatching the first key burst, or a pending-focus queue in the KeyboardFocusManager).
- Minimal advice for #48: drop `embeddedFrame.requestFocus()`.

## Files
- suite09/: TAP + csv per run, shots/
- suite10/: per-run TAP, screenshots
- probe/
- verify_27_28.txt, runall_console.txt, build-pr48.log, pr48_924f764.diff
