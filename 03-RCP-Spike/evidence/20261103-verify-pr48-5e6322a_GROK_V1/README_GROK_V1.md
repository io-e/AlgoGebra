# PR #48 head 5e6322a: Debian verification of suites 09/10 (GROK_V1)
Debian 13 / dedicated Xvfb :153 (probe on :154). Both displays were checked free beforehand: no socket, no lock, no duplicate 5e6322a worktree or process.
Image built with `build.sh` from `scratch/v48b-plus-49` = 5e6322a + #49 (normal local merge; #49 is not on tip) into `/workspace/AlgoGebra/image-pr48-5e6322a` (not committed). bnd-input-set unchanged (f5113da0...50f4).
Build JDK 21, runtime JDK 25.

| Run | Result | Failing |
|---|---|---|
| suite 09 strict (#49) x3 | 17/3/0, 17/3/0, 17/3/0 | FOCUS-01, ORDER-03, ORDER-04 (all `lost=True`) |
| suite 09 plain (#48 only) x2 | 19/1/0, 19/1/0 | FOCUS-01 |
| suite 10 x3 | 5/0/0 x3 | none: the 924f764 D05-05 regression is gone |
| Verify_27_28 | #27 PASS, #28 FAIL | only ORDER-03/04, which are the #33 symptom |
| Run_All | 333/3/61 (baseline 335/1/61) | suite 09 only (17/3/0 vs 19/1/0; extra 2 = #49 checks) |

## Focus trace (-Dggbplus.focusTrace=true, probe/)
- Click in the 2D field: `requestAccepted=false; alreadyFocused=true; owner=AutoCompleteTextFieldD`. OK.
- 1st click in the 3D field: `requestAccepted=false; alreadyFocused=false; inputHasFocus=false; owner=EuclidianViewJPanelD` (a component of the *2D* frame). Keystrokes are lost.
- 2nd click in the 3D field: `requestAccepted=false; owner=null`. Keystrokes arrive.

## Root cause
`requestFocusInWindow()` is refused by contract when the field's window is not the focused window. After the first click, the AWT focused window is still the 2D XEmbeddedFrame, so the request can never succeed. On Debian, nothing activates the 3D embedded frame on that first click. The X input focus stays on the SWT shell (no WM), and the XEmbed activation only arrives with the next click.
The fix has to activate the target embedded frame (cross-window `requestFocus()` on the field, or SWT `composite.setFocus()` / XEmbed activation) before the field request.
My earlier candidate (SWT `setFocus` + `synthesizeWindowActivation`, evidence in PR #51) also did not fix this under Xvfb. Windows results for suite 09 would show whether the problem is specific to Linux without a WM.
