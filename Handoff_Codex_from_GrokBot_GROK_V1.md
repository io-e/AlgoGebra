<!-- GROK_V1_1 -->
# Handoff to Codex (Windows) from Grok Bot (Debian) — GROK_V1.1

**Author / version:** Grok Bot, GROK_V1.1 — 2026-10-29 (Europe/Paris). **Audience:** Codex on the Windows PC.
**Supersedes:** GROK_V1. This update records Codex's Windows r9 test results; see `03-RCP-Spike/tests/README_TESTS_GROK_V1.md` and `states.yaml` for detailed evidence.

## Branches / commits
- `feat/external-engines` — integration branch for Codex. It contains the Debian work and Codex fixes after the merge of `feat/debian-integration`.
- `feat/debian-integration` — Debian work: bash ports (`03-RCP-Spike/build.sh`, `launch.sh`, `test-engines.sh`), Linux native loader fix (83887ca, BUG-003), cross-platform PowerShell test pack 01-13.
- Key commits: 093b302 (WIMS start/end markers, BUG-001/002 fix), 83887ca (Linux native-loader fix, BUG-003), 689d4b4 (Codex runner fixes), ffb3ff2 (integrated 01-13 cross-platform pack), e3e8a82 (Windows baseline runner hardening). Latest head: see `git log` / `states.yaml`.

## Validated
- Debian 13.7, pwsh 7.6.9, Temurin 21/25: suites 01-08, 10-13 PASS (01-07 = 75/0/3, same as Codex on Windows), 09 (D-04 UI) FAIL with recorded findings. See `03-RCP-Spike/tests/README_TESTS_GROK_V1.md` and `states.yaml` (`test_packs`).
- Windows (Codex, tested code e3e8a82): rebuilt/installed r9; `test-engines.ps1` PASS; `Run_All -SkipUi` suites 01-08 and 12 = **95 PASS / 0 FAIL / 3 SKIP**. Suite 08 confirmed 50/50 bundles, PARI/GP + Maxima + Gnuplot available, GIAC CAS, and JOGL 3D initialization. Temporary PATH only; no permanent environment changes.
- Windows suite 13: **3 PASS / 2 FAIL** at scenario level. common-jre had 6,526 existing XML results (6,514 passed, 12 skipped; Gradle `UP-TO-DATE`, not freshly executed). Desktop ran 1,090 tests: 1,088 passed, 1 skipped, and the known locale-sensitive `CallJavaScriptTest.testEval` failed. The suite was hardened so a Gradle nonzero exit cannot be reported as a pass.
- Windows suites 09/10 were not run because they control the attended desktop; suite 11 was not run because the Bnd CLI JAR was unavailable. No Windows suite 13 rerun was counted in the 95/0/3 total.

## Next Codex tasks
1. **D-04 / suite 09:** run on Windows in an attended session to check input/focus, valid function creation, clipboard, and localization/font findings (BUG-004, BUG-009..013). Suite 09 drives the desktop; do not use the PC while it runs.
2. **Strict 3D / suite 10:** run on Windows in an attended session and capture the visual screenshot. Debian 13's software-OpenGL screenshot passed, but no real-GPU claim is made.
3. **Suite 11:** locate an existing Bnd CLI JAR or get owner approval before installing one; then set `GGB_SOURCE` and `BND_JAR`, run the bundle rebuild/resolution comparison, and record evidence.
4. **Suite 13:** rerun common-jre with Gradle forced to execute (current XML results were up-to-date). The desktop locale-dependent failure is known from the audit; preserve it as a baseline finding unless separately resolved.
5. **BUG-003:** Codex reviewed 83887ca; Linux selects `.so` resources and Windows DLL paths remain unchanged. Windows suite 08 passes on r9. Owner review is still pending, so keep status `FIXED_PENDING_REVIEW` until accepted.
6. **BUG-006 FIXED (user decision):** PARI rejects `system`, `extern`, `externstr`, `fileextern`, `install`, `eval` before gp starts (`02-Cdc/Decisions_PARI_Forbidden_GROK_V1.md`). **The r9 image predates this filter: rebuild (r10) with build.ps1 + install-product.ps1**, then rerun suites 05 and 08 and export them with `-ExportEvidence codex-r10`. Pending user confirmation of the `eval` block.
7. **BUG-008 is FIXED:** r9 was rebuilt and suite 08 passed. The image now changes (BUG-006), so a new rebuild is needed (item 6).
8. **Results tracking:** `03-RCP-Spike/tests/results/` is no longer tracked; runs go to `results/<runid>/`. Your earlier Windows results are preserved byte-exact in `03-RCP-Spike/evidence/20261029-windows-codex-689d4b4/` and `.../20261029-windows-codex-r9-e3e8a82/` (sha256 manifests). Export reviewed runs with `-ExportEvidence <name>` and commit the folder.

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
