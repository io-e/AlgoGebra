<!-- GROK_V1 -->
# Handoff to Codex (Windows) from Grok Bot (Debian) — GROK_V1

**Author / version:** Grok Bot, GROK_V1 — 2026-10-29 (Europe/Paris). **Audience:** Codex on the Windows PC.

## Branches / commits
- `feat/external-engines` — integration branch for Codex. Contains everything below after the merge of `feat/debian-integration`.
- `feat/debian-integration` — Debian work: bash ports (`03-RCP-Spike/build.sh`, `launch.sh`, `test-engines.sh`), Linux native loader fix (83887ca, BUG-003), cross-platform PowerShell test pack 01-13.
- Key commits: 093b302 (WIMS start/end markers, BUG-001/002 fix), 2cb7bf2 (test pack), e6f4bbc (gp alias fix), 689d4b4 (Codex: Run_All empty-run guard, counters, quotes), 820f0b7 (merge of 689d4b4 into debian-integration). Latest heads: see `git log` / `states.yaml`.

## Validated
- Debian 13.7, pwsh 7.6.9, Temurin 21/25: suites 01-08, 10-13 PASS (01-07 = 75/0/3, same as Codex on Windows), 09 (D-04 UI) FAIL with recorded findings. See `03-RCP-Spike/tests/README_TESTS_GROK_V1.md` and `states.yaml` (`test_packs`).
- Windows (Codex, 689d4b4): `test-engines.ps1` PASS; suites 01-07 75 PASS / 0 FAIL / 3 SKIP with temporary PATH (gp 2.19 Pari64, Maxima 5.49.0, its gnuplot). Suite 08 skipped.

## Next Codex tasks
1. **BUG-008**: rebuild the Windows image r9 with `03-RCP-Spike\build.ps1` then `install-product.ps1` (r8 ships engine bundles without the marker fix). Set `IMAGE` to r9.
2. Run suite 08, then the new suites on Windows: 10 (strict 3D screenshot), 12 (robustness), 11 (`-WithBuild`, set `GGB_SOURCE`, `BND_JAR`), 13 (`-WithBaseline`). 09/10 drive the desktop (SendKeys, mouse, CopyFromScreen) — run only in an attended session, do not touch the PC meanwhile. The Windows UI path of `lib/UiDriver_GROK_V1.ps1` is syntax-checked only (NOT RUN); pane geometry on Windows is an approximation (58/42 split) — check the screenshots and fix if needed.
3. **D-04** findings to confirm on Windows (BUG-004, BUG-010..013): error dialog on valid input, lost keystrokes after the dialog, functions not created, clipboard 2D->3D, ReTeX font load error, untranslated labels; BUG-009 ctrl+a NPE intermittent.
4. **BUG-006** (PARI system()/extern() not in the deny list): **decision pending from the user** — do not change.
5. **BUG-003** (native loader fragments pick Linux `.so` on Linux, Windows unchanged): review the diff in 83887ca and confirm Windows suite 08 still passes.

## How to run the pack (Windows)
```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration
git pull --ff-only
$env:PATH = 'C:\Program Files (x86)\Pari64-2-19-0;C:\maxima-5.49.0\bin;C:\maxima-5.49.0\gnuplot\bin;' + $env:PATH
$env:IMAGE = 'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r9'
pwsh -File 03-RCP-Spike\tests\Run_All_GROK_V1.ps1 -SkipUi            # 01-08, 12
pwsh -File 03-RCP-Spike\tests\Run_All_GROK_V1.ps1 -WithBuild -WithBaseline   # everything (attended for 09/10)
```
Evidence rule (AGENTS.md): record date, commit, OS, Java, fixture hash, command, expected vs actual, log path; otherwise NOT RUN.
Constraints: no upstream GeoGebra edits, no force push / history rewrite, do not install engines without the user's approval (D-ENG-02), never modify Claude's WIMS test files.
