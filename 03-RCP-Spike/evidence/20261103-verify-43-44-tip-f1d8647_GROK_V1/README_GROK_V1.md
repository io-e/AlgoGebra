# Debian verification of #43 (issue #27) and #44 (issue #21) at tip f1d8647 (GROK_V1)
Host: Debian 13 (trixie), pwsh 7.6.9, JDK 21, Xvfb. Image built from tip with `03-RCP-Spike/build.sh` into a scratch dir (not committed).

## Results (expected vs actual)
| Target | Expected | Actual |
|---|---|---|
| Verify #27 (`Verify_Issues_27_28_GROK_V1.ps1`) | PASS | **PASS**: fragment `org.geogebra.plus.renderer.resources_0.1.0.jar` has 46 .ttf and is in bundles.info; D04-FONT-01 PASS |
| P-02 | 50/0/1 | **50/0/1** |
| D-11 | 8/0/0 | **8/0/0** |
| Verify #28 | FAIL (not merged) | FAIL as expected (suite 09 8/16/0) |
| Suite 16, real validator (`CourseValidatorCliQ4_GROK_V1`) | 136/0/1 | **136/0/1** (was 134/2/1) |
| Suite 20 | 56/0/0 | **56/0/0** (was 54/0/2) |
| Codex Java tests (`test-course-model.ps1 -BundleRoot <image>`) | green | **CourseModelTest 9/0, StepValidatorPolicyTest 18/0** |
| Run_All (full) | baseline 321/17/63 | **324/16/61**, 0 bail |

The Run_All change of +3 pass is suite 09 (D04-FONT-01: 7/17 → 8/16) and suite 20 (54/0/2 → 56/0/0); nothing regressed.

## bnd-input-set.sha256
The value is **unchanged**: `f5113da0…50f4`, the same as before #43. #43 does not modify the 50 D-03 jars. The fonts go into a new fragment bundle (`Fragment-Host: org.geogebra.migration.desktop.renderer;bundle-version="[5.4.934,5.4.935)"`), which is the "alternative" listed in the #36 reference. By contrast, the reference diff `jar uf` changed the hash to `9b2ca889…`.

## Diff comparison with the #36 reference (evidence/20261102-1954-refpatches-27-21_GROK_V1)
- **#43 vs `issue27_build_sh_retex_fonts`: materially different, and better.**
  - The fragment jar takes the place of rewriting the renderer jar.
  - Build fails fast if `jlm_cmr10.ttf` or `jlm_cmssbx10.ttf` is missing from the source or the fragment, or if the fragment is not in bundles.info.
  - Not carried over from the reference: the build.sh header comment, and a check against the renderer jar itself.
  - The reference's "copy only if no .ttf" guard no longer applies.
- **#44 vs `issue21_*`: functionally identical.** The only differences are in the comment text of StepValidator.java and the corpus test XFAIL Javadoc.

## Test change in this PR
`Verify_Issues_27_28_GROK_V1.ps1` used to count .ttf only inside the renderer jar, so it would have reported a false FAIL for the fragment approach. It now also counts the fragment and requires it to be in bundles.info.

## Run_All setup notes (not regressions)
- **First attempt (`runall_first_attempt_setup_gap.txt`): engine suites 01–07 and 12 BAIL.** They look for `03-RCP-Spike/host/build/org.geogebra.plus.engine.*.jar`, but on Linux build.sh writes those into the image. This is a setup gap: after copying the image's `host/build/*.jar` into the worktree (untracked), all engine suites pass.
- **Suite 15 in the first attempt: 6/9 (applet not loaded after 92 s).** Run alone straight after, it was 15/0/0 in 6 s (`suite15_standalone_rerun.txt`), and 15/0/0 in the second full run. This is a transient environment/timing issue on the shared box (same WAR, same upstream 375db7f), not a code regression.
- **Suite 20 Java validator:** clean, 56/0/0 in both the standalone run and the full Run_All. No exception was seen at f1d8647.
