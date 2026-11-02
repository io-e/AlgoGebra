# Reference patches for #27 and #21 (evidence only, GROK_V1)
Base: feat/external-engines @ acd71f3. Validated on Debian on 2026-11-02, using scratch worktrees and scratch images (none committed). **No production source is changed in this PR.** Codex can adopt or redo the patches: `git apply <diff>` from the repo root.

## #27 (BUG-014): `issue27_build_sh_retex_fonts_GROK_V1.diff`
- **What it changes:** `03-RCP-Spike/build.sh` adds the upstream ReTeX desktop fonts (`GGB_SRC/desktop/renderer-desktop/src/main/resources/com/himamis/retex/renderer/desktop/fonts`) to the staged `org.geogebra.migration.desktop.renderer` bundle when it has no .ttf. The build fails if the bundle still has none. The reference image (REF_IMAGE) is not touched.
- **Side effect:** the renderer bundle in the image changes, so `bnd-input-set.sha256` changes (new value in `build_p27.log`). The header comment is updated accordingly.
- **Validation** (image built from tip + patch), `Verify_Issues_27_28_GROK_V1.ps1`: **#27 PASS**.
  - 46 .ttf in the renderer bundle.
  - P-02 50/0/1, D-11 8/0/0.
  - Suite 09 D04-FONT-01 PASS.
  - #28 still FAIL as expected (suite 09 8/16/0): that needs the #28 logger fix (PR #32 diff).
- **Alternative:** a separate fragment bundle hosting the fonts, if the 50 D-03 jars must stay byte-identical.

## #21 (Q3b): `issue21_stepvalidator_drop_near_limit_warning_GROK_V1.diff` + `issue21_corpus_test_xfail_update_GROK_V1.diff`
- **What it changes:**
  - Removes `SEQUENCE_WARNING_THRESHOLD = 800` and the near-limit warning in `StepValidator`. A Sequence of up to 1000 iterations is plainly ACCEPT; the limits and the other ACCEPT_WITH_WARNING reasons are unchanged.
  - The second diff empties the XFAIL list of the Grok corpus test, since T-45/T-51 now pass.
- **Validation** (tip + both diffs):
  - Suite 16 with the real validator (`CourseValidatorCliQ4_GROK_V1`): **136/0/1**.
  - Codex Java tests (`test-course-model.ps1`): CourseModelTest 9/0, StepValidatorPolicyTest 18/0.
  - Suite 20: **56/0/0**; corpus test 54 PASS / 0 FAIL / 0 XFAIL / 0 XPASS.
  - Without the XFAIL diff, T-45/T-51 would be reported as XPASS.
