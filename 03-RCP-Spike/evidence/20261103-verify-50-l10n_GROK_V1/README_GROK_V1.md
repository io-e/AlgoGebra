# GROK_V1 — Debian UI verification of PR #50 (issue #39, G-11-GAP-1 / BUG-013)

Date: 2026-11-03 (Europe/Paris). Host: Debian 13 trixie, Xvfb (private displays :232–:242), pwsh 7.6, JDK 21.
PR #50 head `c092710` (`codex/issue-39-localization`, contains tip `6d62ef4`; independent of #48).
Image: `03-RCP-Spike/build.sh` → `/workspace/AlgoGebra/image-pr50/...` (not committed; log `build_pr50_c092710.log`).
D-03 input set unchanged: `f5113da0…` (same 50 jars). New fragment `org.geogebra.plus.common.jre.resources_0.1.0.jar` (391 properties entries) attached to `org.geogebra.migration.shared.common.jre`.

## #50 diff (7 files, +93/−1) — `pr50_diffstat.txt`
- `host/common-jre-resources/META-INF/MANIFEST.MF`: new fragment, `Fragment-Host: org.geogebra.migration.shared.common.jre;[5.4.934,5.4.935)`.
- `build.sh` / `build.ps1`: jar `shared/common-jre/src/main/resources` into the fragment; fail-closed check for menu/command/symbols (+ `_fr`); build.ps1 also checks Fragment-Host.
- `bundles.info`, `geogebraplus.product`: register the fragment (start=false).
- Host `MANIFEST.MF` imports `org.geogebra.common.jre.headless`; `GeoGebraPlusApplication.traceLocalization()` opt-in via `-Dggbplus.localizationTrace=true`.
- No upstream `common`/`common-jre` source edits.

## Language selection (box has no fr system locale)
`LANG=LC_ALL=C.UTF-8`; JVM locale via `JDK_JAVA_OPTIONS='-Duser.language=fr -Duser.country=FR'` (EN: `-Duser.language=en -Duser.country=US`). GeoGebra LocalizationD follows the JVM default Locale.

## Raw-key / label check — `tests/Verify_Issue_39_L10n_GROK_V1.ps1` (new, standalone, not auto-discovered by Run_All)
Launches image on a private Xvfb, screenshots main window (2D Algebra/Graphics/Input + 3D Algebra/3D Graphics/Input) and the 2D and 3D File menus, OCR (rapidocr, venv `/workspace/ocrvenv`) via `tests/tools/ocr_l10n_GROK_V1.py`, fails on any of AlgebraWindow/DrawingPad/InputLabel/GraphicsView3D or a missing expected label; also records the #50 trace labels. Results: `l10n/summary.tsv`, `l10n/*-ocr.json`.

| Image | Lang | Raw keys (OCR) | Expected labels | Trace | Verdict |
|---|---|---|---|---|---|
| #50 c092710 | EN | none | Algebra, Graphics, Input, 3D Graphics | AlgebraWindow=Algebra; DrawingPad=Graphics; InputLabel=Input; GraphicsView3D=3D Graphics | PASS |
| #50 c092710 | FR | none | Algèbre, Graphique, Saisie, Graphique 3D (menus Fichier/Éditer/Affichage/Outils/Fenêtre/Aide; File menu Nouvelle fenêtre, Aperçu avant impression…) | AlgebraWindow=Algèbre; …; GraphicsView3D=Graphique 3D | PASS |
| baseline 2f24a7e | EN | all 4 (+ CloseAll, SaveAs, PrintPreview, OpenFromwebpage, SaveOnline in File menu) | missing | n/a | FAIL (expected) |
| baseline 2f24a7e | FR | all 4 (same raw keys; no French) | missing | n/a | FAIL (expected) |

OCR note: `AffichageOptions` in FR is two adjacent menu titles merged by OCR, not a key. The Options-menu screenshot (`*-menu-Options.png`) did not open the menu (click lands after Escape) — only File menus (2D and 3D) are captured open; menu bar titles are covered by the main screenshot.

## Suites (image #50)
| Check | #50 | Baseline 2f24a7e | Delta |
|---|---|---|---|
| Verify_Issues_27_28 | #27 PASS, #28 PASS | PASS/PASS | = |
| Suite 09 (no #49 checks) | 19/1/0 (only D04-FOCUS-01 = #33) | 19/1/0 | = |
| Suite 10 | 5/0/0 | 5/0/0 | = |
| Run_All | **335/1/61, 0 bail** | 335/1/61 | = no regressions |

`runall_console_attempt1_bail-no-engine-jars.txt`: first attempt bailed suites 01–07/12 because the fresh worktree had no `host/build` engine jars; copied unchanged engine/compute jars from the 2f24a7e worktree (not touched by #50) and reran.
Not run: legacy `Run_G09_G11_GROK_V1.ps1` (hard-coded displays :140–:143 which have sockets on the shared box); the new script covers the G-11 label checks in EN/FR.

## Addendum 2026-11-03 12:45 (Europe/Paris) — gaps closed (owner-approved)
### Options menus (`l10n-v2/`, private displays :266/:267)
Root cause of the earlier miss: a click on a Swing menubar title right after `Escape` does not reopen a menu. `Verify_Issue_39_L10n_GROK_V1.ps1` now resets (Escape ×2 + click on empty 2D graphics) before each menu and opens File + Options in both the 2D and 3D panes, with per-language title coordinates (FR titles are wider). `ocr_l10n_GROK_V1.py` checks Options items per screenshot.

| Lang | 2D Options | 3D Options | Raw keys | Verdict |
|---|---|---|---|---|
| EN | Rounding, Labeling, Font Size, Language (+ Advanced…, Save Settings, Restore Default Settings) | same | none | PASS |
| FR | Arrondi, Étiquetage, Taille des caractères, Langue (+ Avancé…, Sauvegarder la configuration, Configuration par défaut) | same | none | PASS |

Screenshots: `l10n-v2/pr50-{en,fr}-menu-{File,Options,File3D,Options3D}.png`, `l10n-v2/pr50-{en,fr}-main.png`; results `l10n-v2/summary.tsv`, `*-ocr.json`. `summary_attempt1_wrong-fr-regex.tsv` / `attempt1-*`: first run expected "Taille de police"; GeoGebra's FR string is "Taille des caractères" (test bug, regex fixed).

### G-09 / G-11 course tree (`g09_g11/`, displays :270–:273, :275)
`tests/Run_G09_G11_GROK_V1.ps1` (copy of the 2026-11-02 evidence script, original left unchanged): new `-DisplayBase` (default 140 = old behaviour), refuses a display whose X socket exists, adds case `G09-trig-fr-CUTF8`, fixture moved to `tests/fixtures/course_locale_fixture_GROK_V1.json`. Screenshots OCR-checked (`g09_g11/ocr_summary.txt`).

| Case | Course tree | GeoGebra labels | Raw keys | Errors in log |
|---|---|---|---|---|
| G09-trig-en-CUTF8 | trigonometry_intro, 5 chapters | Algebra/Graphics/Input/3D Graphics | none | 0 |
| G09-trig-fr-CUTF8 | same | Algèbre/Graphique/Saisie/Graphique 3D | none | 0 |
| G11-fixture-CUTF8-en | Unicode fixture: "Trigonométrie — αβγ / Тригонометрия / 三角函数", "√2 ≤ π ≥ ∑ ∞ ∫ → ± ½", "é è à ç ù œ « »" render correctly | EN | none | 0 |
| G11-fixture-CUTF8-fr | same Unicode rendering | FR | none | 0 |
| G11-fixture-POSIX (LANG=C) | same | EN | none | 0 |

OCR noise in camelCase list: `TpuroHoMeTpu9` = Cyrillic "Тригонометрия" read as Latin; `OptionsTools`/`AffichageOptions` = adjacent menu titles merged. Observation (not #39): host course-panel buttons (Run/Check/Next/Reset) and footer stay English in FR — host strings, not GeoGebra localization.
