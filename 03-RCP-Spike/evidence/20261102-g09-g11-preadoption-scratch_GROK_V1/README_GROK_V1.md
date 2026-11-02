# G-09 / G-11 on Debian: PRE-ADOPTION, SCRATCH PATCHES (GROK_V1)
**These results come from a scratch image, not from production sources.** The image is the `feat/external-engines` tip `e4362ac`, built by `build.sh`, plus two reference diffs applied in a scratch worktree and never committed:
- the #27 font diff: `20261102-1954-refpatches-27-21_GROK_V1/issue27_build_sh_retex_fonts_GROK_V1.diff`, PR #36;
- the #28 logger diff: `20261102-bug010-logger-experiment_GROK_V1/BUG-010_LoggerInit_GROK_V1.diff`, PR #32.

All runs use Xvfb at 1600x1000 and JDK 25.0.5. The runner is `Run_G09_G11_GROK_V1.ps1`; screenshots are full-screen grabs (PIL) taken about 35 s after launch.

## Confirmation runs on the scratch image (`verify_27_28_scratch.txt`)
- **#27: PASS.** 46 .ttf in the renderer bundle, P-02 50/0/1, D-11 8/0/0, suite 09 D04-FONT-01 PASS.
- **Suite 09: 19/1/0.** The only failure is D04-FOCUS-01-2d-to-3d (#33). There are no "keys-reach-input" failures. #28 is therefore still FAIL, as expected, because of #33.

## G-09: the SWT course tree renders on GTK. **PASS**
- `run1/G09-trig-en-CUTF8.png` (`courses/trigonometry_intro.json`, LANG=C.UTF-8). The log says `Course loaded ... (5 chapters; schema 1.0)`.
- The screenshot shows the SWT Tree with 5 chapters, the description pane, the Run/Check/Next/Reset buttons and the "formative only; WIMS owns grading" note, next to the embedded 2D and 3D GeoGebra panes.

## G-11: font and locale in the course tree. **PASS for the course tree; one documented gap in the GeoGebra UI**
- The fixture `course_locale_fixture_GROK_V1.json` is the trigonometry course with titles in French accents, Cyrillic, Greek, CJK, math symbols, an emoji and Latin-1 letters.

| case | screenshot | course tree text |
|---|---|---|
| LANG=C.UTF-8, default locale | `run1/G11-fixture-CUTF8-en.png` | renders correctly (é è à ç ù œ « », Cyrillic, Greek αβγ, CJK 三角函数, √ ≤ π ≥ ∑ ∞ ∫ → ± ½) |
| LANG=C.UTF-8 with `-Duser.language=fr -Duser.country=FR` | `fr-rerun/G11-fixture-CUTF8-fr.png` | same, correct |
| LANG=C (POSIX) | `run1/G11-fixture-POSIX.png` | same, correct: the JSON is read as UTF-8 whatever the locale. Minor: xdotool did not list the product window title in this case. |

- `run1/G11-fixture-CUTF8-fr.png` is black. In that run the product was launched while another run (suite 09) was using a different display, and it shut down early. The isolated rerun in `fr-rerun/` is clean, so this was a test-environment collision, not a product defect.
- **Gap (G-11-GAP-1):** the embedded GeoGebra UI shows raw localization keys instead of translated text, in every locale. Examples are `AlgebraWindow`, `DrawingPad`, `InputLabel`, and `GraphicsView3D` (where the 3D view should have its proper name). `-Duser.language=fr` does not change this.
  - Experiment in `props-experiment/`: I added the upstream `org/geogebra/common/jre/properties/*` (390 files) to a copy of the `shared.common.jre` bundle. **Nothing changed**, so the missing files in that bundle are not the only cause.
  - Suspect: how resource bundles are loaded under OSGi (`LocalizationD` / `ResourceBundle` class loader). Earlier runs logged `MissingResourceException ... properties.menu/command/symbols`.
  - This is for Codex, and it is not filed as an issue (owner decides).
- Rendered glyphs for the sub-items (children) are not captured, because only the chapters are expanded.

`SHA256SUMS` covers every file in this folder.
