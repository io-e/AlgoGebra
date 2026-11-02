# BUG-014: Debian analysis (GROK_V1)

| Field | Value |
|---|---|
| Date | 2026-11-02 (Europe/Paris) |
| Owner of the fix | Codex (product/build); Grok only investigated, no production Java changed |
| Image | `build.sh` from tip `650a38ad`+ (image-final); experiment copy image-fontfix = same + ReTeX font resources added to the renderer bundle |
| Tracking | no dedicated BUG-014 issue/PR exists, hence this doc |

## TL;DR
1. **D-11's "BUG-014" was a test-harness bug, not BUG-014.** `S_D-11` wrote directives as `CMD<TAB>cmd` without the id column that `ScenarioScript` expects (`OP<TAB>id<TAB>arg`). So `evalCommand("")` ran and returned false. I introduced that mislabel in PR #14 and have fixed it here. **D-11 now passes 8/0/0** on both images (was 5/3/0). The CAS identity also passes (`1`).
2. **The real BUG-014 (P-02: `f(x) = x^2 - 2x`, `m = {{1,2},{3,4}}`, 3D `Plane(A,B,(1,0,0))` → evalCommand false + dialog) is reproduced on the Linux image and disappears when ReTeX fonts are added.**
   - The Linux image's `org.geogebra.migration.desktop.renderer-5.4.934.0.jar` has the classes but **0 resources** (no `fonts/**.ttf`). `build.sh` copies it from the r8 reference image (`cp "$REF_IMAGE"/bundles/*.jar`).
   - Rendering a new function, matrix or plane in the algebra view goes through ReTeX: `FontLoaderD.loadFont` throws `ResourceParseException: Problem reading font data` on the AWT EDT, then the command is reported as failed with "Please check your input null".
   - Points don't need those glyphs, which is why they work.
   - **P-02: 46/4/1 → 50/0/1** with the fonts (same build, only the renderer jar changed).
3. **Headless control:** the same jars on a plain classpath with `AppDNoGui` (no algebra-view rendering) create all six objects (`evalCommand=true`). So the parser and kernel are fine; the failure is rendering/resources in the product.

## Stack (image-final, P-02 product log)
```
Exception in thread "AWT-EventQueue-0" com.himamis.retex.renderer.share.exception.ResourceParseException: FontLoader: FontLoader 'fonts/latin/jlm_cmr10.ttf'. Error message: Problem reading font data.
  at com.himamis.retex.renderer.desktop.font.FontLoaderD.loadFont(FontLoaderD.java:78)
  at com.himamis.retex.renderer.share.platform.FontAdapter.loadFont(FontAdapter.java:68)
  at com.himamis.retex.renderer.share.FontInfo.getFont(FontInfo.java:325)
  ... TeXFormula.createTeXIcon(TeXFormula.java:447)
```
SCN: `ALG-03 f(x) = x^2 - 2x → OK false`, `ALG-05 m = {{1, 2}, {3, 4}} → OK false`, `G3-03 pl = Plane(A, B, (1, 0, 0)) → OK false`, `_DIALOG GeoGebra - Error | Please check your input null`.

## Minimal repro
1. `IMAGE=<image> bash 03-RCP-Spike/build.sh` (Debian) → `unzip -l <image>/bundles/org.geogebra.migration.desktop.renderer-*.jar | grep -c ttf` → **0**.
2. `IMAGE=<image> xvfb-run -a pwsh -Command "& 03-RCP-Spike/tests/Run_All_GROK_V1.ps1 -Only 'P-02'"` → ALG-03/ALG-05/G3-03 false.
3. Add `source/desktop/renderer-desktop/src/main/resources/com/**` (upstream pin) to that jar (`jar uf`), rerun → all true.

## Proposals for Codex (not applied)
- **Fix (build):** package the renderer-desktop resources into `org.geogebra.migration.desktop.renderer`. This is the unpushed "r12 renderer-resources packaging" noted in `states.yaml` open items. Push it and make `build.sh` (Linux) use the r12 bundle or add the resources. Then rebuild both images.
- **Check Windows:** if the Windows r11 image also lacks the fonts, BUG-014 on Windows has the same root cause (BUG-011 "fonts FIXED on r12" points that way).
- **Related, separate (BUG-010, suite 09):** valid typed input still raises the dialog even with fonts. Lead: the embedded `GeoGebraPanel` never calls `Log.setLogger` (only `GeoGebraFrame.main` does). `ScreenReaderAdapterD.readText → Log.read → logger.doRead` would then throw an NPE after the object is created. Candidate fix in the host: `Log.setLogger(new LoggerD())` before the panel is built. Unproven.

## Evidence
- `03-RCP-Spike/evidence/20261102-linux-bug014-image-final-20261102_080637-grok-bot-vm-419969949/` (image-final: D-11 8/0/0, P-02 46/4/1)
- `03-RCP-Spike/evidence/20261102-linux-bug014-image-fontfix-20261102_080709-grok-bot-vm-419969949/` (image-fontfix: D-11 8/0/0, P-02 50/0/1)
- `03-RCP-Spike/evidence/20261102-bug014-headless-repro/` (headless control, renderer jar listing)
