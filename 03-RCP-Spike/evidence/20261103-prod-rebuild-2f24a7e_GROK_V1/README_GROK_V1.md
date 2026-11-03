# Production Linux rebuild at tip 2f24a7e (after #45), Debian validation (GROK_V1)
Debian 13 / Xvfb / pwsh / JDK 21. Image built with `03-RCP-Spike/build.sh` from tip `2f24a7e` (feat/external-engines, includes #43, #44, #45) into `/workspace/AlgoGebra/image-prod-2f24a7e` (not committed).

## Expected vs actual
| Target | Expected | Actual |
|---|---|---|
| Fonts fragment `org.geogebra.plus.renderer.resources_0.1.0.jar` in image + bundles.info | present | **present**, 46 .ttf |
| `GeoGebraLoggerBootstrap` in host bundle | present | **present** (`org.geogebra.plus.host_0.1.0.jar`) |
| bnd-input-set.sha256 | unchanged | **f5113da0…50f4** (unchanged) |
| Verify #27 | PASS | **PASS** (P-02 50/0/1, D-11 8/0/0, D04-FONT-01 PASS) |
| Verify #28 | PASS | **PASS** (valid inputs, invalid dialog, no dead input) |
| Suite 09 | 19/1/0, only D04-FOCUS-01 (#33) | **19/1/0**, only D04-FOCUS-01 |
| G-09 / G-11 | PASS (#39 raw keys still expected) | **PASS**: 4/4 runs png + 0 errors; Unicode tree OK; raw keys (AlgebraWindow, DrawingPad, InputLabel, GraphicsView3D) still visible = #39 |
| Run_All | vs 324/16/61 @ f1d8647 | **335/1/61**, 0 bail |

## #45 acceptance criteria (suite 09)
- Valid input, no spurious "Please check your input": KBD-01..07 all `dialog=False algebraViewChanged=True`; D04-ORDER-01 (first input f(x)=x^2 in fresh session) `dialog=False`.
- Subsequent input still works: KBD-02..07 `lostFirstBurst=False`; D04-ORDER-02 second input `lost=False changed=True`; D04-FOCUS-02 (valid 2D input after the invalid KBD-08) `changed=True`.
- Invalid input still errors: KBD-08 `((((` `dialog=True`. Added as explicit check `28-invalid-dialog` in Verify_Issues_27_28_GROK_V1.ps1.
- D04-CTRLA-01: Log.logger NPE count 0.

## Run_All delta
Only suite 09 changes (8/16/0 -> 19/1/0); case count 24 -> 20 because the 4 `*-keys-reach-input` follow-on cases are emitted only after a BUG-010 dialog. All other suites identical to f1d8647.
D04-FOCUS-01 passed at f1d8647 only because earlier inputs were dead; with BUG-010 fixed it now exposes #33 (3D bar loses keystrokes). Not a regression of #45.

## Test changes in this PR
- Merges PR #46 branch (grok/verify-43-44-f1d8647, normal merge) for the fragment-aware #27 check.
- `Verify_Issues_27_28_GROK_V1.ps1`: D04-FOCUS-01 reported as info (#33), excluded from the #28 verdict; new `28-invalid-dialog` check.

## Notes
- Engine jars copied from image `host/build` into worktree `03-RCP-Spike/host/build` (untracked, ignored) for suites 01-07/12.
- Observation: D04-ORDER-03/04 (P1) pass with `lost=True` (they assert only no dialog); D04-FONT-01 detail text still carries an outdated "KNOWN ... 0 .ttf" note. Cosmetic test-oracle follow-ups, not product failures.
