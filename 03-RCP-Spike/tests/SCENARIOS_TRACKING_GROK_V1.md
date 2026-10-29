<!-- GROK_V1 -->
# Scenario tracking — 45 scenarios of the validation spec (GROK_V1)

**Author / version:** Grok Bot, GROK_V1, 2026-10-29 (Europe/Paris). **Source:** `02-Cdc/Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` section 5 (45 rows). **Focus:** desktop (RCP heavy client) first; web rows are listed and marked *deferred: web phase*.

## Rules
- **Status** is the spec-level status of the whole scenario (desktop + web where the spec says D+W, both OSes where relevant). It is set by review, not by the runner.
- **Debian desktop** is the mechanical result of the script on Debian 13 / Xvfb in run `20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949` (commit 2f4a352 tree, tested from 7e2f02e + working changes; pin 375db7faf54, VERSION_STRING 5.4.934.0, Java 25.0.5 product / 21.0.13 tools, pwsh 7.6.9). Evidence: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/` (`MANIFEST_GROK_V1.tsv` sha256, one log per script, CSV, screenshots).
- A script never reports PASS for a missing feature: such checks are `# SKIP NOT RUN - blocked by: <reason>`. A *precheck* checks what exists today (resolver, GgbAPI, files); a precheck PASS does not make the scenario PASS.
- Run_All verdict per script: FAIL (any failed check), NOT RUN (blocked P0 check and nothing passed), PARTIAL (a P0 check blocked), PASS (all P0 checks ran and passed).

## Run
```powershell
cd 03-RCP-Spike/tests
pwsh -File Run_All_GROK_V1.ps1 -Scenarios                     # all 33 scenario scripts
pwsh -File Run_All_GROK_V1.ps1 -Gate A                         # P-02..P-05 (Gate B also runs suites 08/09/10/11 for D-02..D-05)
pwsh -File Run_All_GROK_V1.ps1 -Only P-02,P-04 -ExportEvidence <name>
pwsh -File scenarios/S_P-02_CoreFeatures_GROK_V1.ps1         # one scenario
```
Env: `IMAGE`, `JAVA_HOME` (JDK 21), `GGB_SOURCE` (upstream checkout at the pin), `GGB_BASELINE_LIB` (lib/ of the pinned upstream `desktop.tar`), `BASELINE_JAVA`, `GGB_NEXT_COMMIT` (O-01).

## Test hook in the product (opt-in, off by default)
`host/src/org/geogebra/plus/host/ScenarioScript.java` and `GeoGebraPlusApplication.startScenarioHookIfRequested()`: does nothing unless the JVM property `-Dggbplus.scenario=<directives.tsv>` is set (optional `ggbplus.scenarioDelayMs`, `ggbplus.scenarioExit=true`). It runs tab-separated directives (CMD, CMD3, VAL, VAL3, TYPE, DEF, CAS, NAMES, NAMES3, COUNT, SETVAL, XMLSHA, SAVE, NEW, OPEN/OPENRAW, PNG, SVG, TOOLS, UNDOPOINT, UNDO, JAVA, SLEEP, EXIT) through the public GgbAPI by reflection on the AWT thread and prints `[GeoGebraPlus] SCN<TAB>id<TAB>OK|ERR<TAB>value`. While active, a watchdog records modal error dialogs as `SCN _DIALOG` and closes them so a run cannot hang. No manifest change, no upstream change. `tests/tools/ScenarioBaseline_GROK_V1.java` runs the same directives in the pinned upstream desktop build (plain classpath, no OSGi) for product-vs-baseline comparison.

## Counts
| Status | Count |
|---|---|
| NOT RUN | 24 |
| PARTIAL | 13 |
| FAIL | 5 |
| PASS | 3 |

| Client | Count |
|---|---|
| both | 20 |
| desktop | 16 |
| web | 8 |
| infra | 1 |

The former "40 NOT RUN" are now: 24 NOT RUN, 11 PARTIAL, 5 FAIL (D-02/03/05 PASS, D-04 and P-08 PARTIAL unchanged).

## Codex Windows r11 run (2026-10-29 17:43, image r11 built from afa9d1f; r10 preserved)
32/33 scenario scripts: 137 PASS / 10 FAIL / 38 SKIP; P-07 excluded (input-driven). Non-UI pack 101/0/3 Gate MET; suite 08 7/7.
Failures: P-02/P-04 (BUG-014), O-02 (47 JARs lack license metadata), P-08 (older evidence lacks pin), X-01/X-02/X-06 (BUG-015).
**P-01 INVALID** (screenshot = browser editor). P-07 and D-04 paused until the foreground guard is merged. Results local only (not exported).

## Table
| ID | Gate | Scenario | Client | Status | Debian desktop | Script | Priority |
|---|---|---|---|---|---|---|---|
| P-01 | - | Clean product, no optional extension | both | **PARTIAL** (Windows r11: INVALID) | PASS | `S_P-01_CleanProduct_GROK_V1.ps1` | P0 |
| P-02 | A | Algebra, CAS, spreadsheet, 2D, 3D | both | **FAIL** | FAIL | `S_P-02_CoreFeatures_GROK_V1.ps1` | P0 |
| P-03 | A | Standard tools | both | **PARTIAL** | PARTIAL | `S_P-03_StandardTools_GROK_V1.ps1` | P0 |
| P-04 | A | Open, save, reopen .ggb | both | **FAIL** | FAIL | `S_P-04_SaveReopen_GROK_V1.ps1` | P0 |
| P-05 | A | Scripts, macros, images, export | both | **PARTIAL** | PARTIAL | `S_P-05_ScriptsMacrosExport_GROK_V1.ps1` | P1 |
| P-06 | - | Offline after install | desktop | **PARTIAL** | PASS | `S_P-06_Offline_GROK_V1.ps1` | P0 |
| P-07 | - | Resize, DPI, keyboard, narrow browser | both | **FAIL** | FAIL | `S_P-07_ScreensInput_GROK_V1.ps1` | P0 |
| P-08 | - | Pin recorded | both | **PARTIAL** | PARTIAL | `S_P-08_PinTraceability_GROK_V1.ps1` | P1 |
| D-01 | - | Import the Gradle composite into Eclipse | desktop | **NOT RUN** | NOT RUN | `S_D-01_EclipseImport_GROK_V1.ps1` | P2 |
| D-02 | B | RCP starts on the jar set, no edit in common | desktop | **PASS** | PASS | `08_Test_RCP_Image_GROK_V1.ps1 (suite)` | P0 |
| D-03 | B | Package-ownership report | desktop | **PASS** | PASS | `11_Test_Bundle_Build_GROK_V1.ps1 (suite)` | P0 |
| D-04 | B | Swing GeoGebra inside an RCP shell | desktop | **PARTIAL** | FAIL | `09_Test_D04_UI_GROK_V1.ps1 (suite)` | P0 |
| D-05 | B | CAS and 3D from the RCP product | desktop | **PASS** | PASS | `10_Test_D05_Strict3D_GROK_V1.ps1 (suite)` | P0 |
| D-06 | B | One good and one bad extension bundle at startup | desktop | **PARTIAL** | PARTIAL | `S_D-06_ExtensionRegistry_GROK_V1.ps1` | P0 |
| D-07 | B | Change the set, restart | desktop | **PARTIAL** | PARTIAL | `S_D-07_EnableDisable_GROK_V1.ps1` | P1 |
| D-08 | B | Incompatible version ranges | desktop | **PARTIAL** | PARTIAL | `S_D-08_IncompatibleExtension_GROK_V1.ps1` | P1 |
| D-09 | E | Unsigned or unapproved jar | desktop | **NOT RUN** | NOT RUN | `S_D-09_SignatureChannel_GROK_V1.ps1` | P0 |
| D-10 | - | Install, upgrade, rollback on clean Windows | desktop | **NOT RUN** | FAIL | `S_D-10_InstallUpgrade_GROK_V1.ps1` | P1 |
| W-01 | C | Score Java-to-web and JS/TS | web | **NOT RUN** | - | `-` | P1 |
| W-02 | C | Chosen non-GWT client runs P-02 and P-03 | web | **NOT RUN** | - | `-` | P1 |
| W-03 | - | Approved, missing, incompatible web modules | web | **NOT RUN** | - | `-` | P1 |
| W-04 | E | XSS, malicious .ggb, command injection | web | **NOT RUN** | - | `-` | P1 |
| W-05 | - | 2D and 3D together, then reload | web | **NOT RUN** | - | `-` | P1 |
| W-06 | - | Resize and touch on supported browsers | web | **NOT RUN** | - | `-` | P1 |
| W-07 | - | Offline after first load | web | **NOT RUN** | - | `-` | P1 |
| W-08 | - | Same activity contract on both clients | web | **NOT RUN** | - | `-` | P1 |
| X-01 | D | External algorithm, not an AlgoElement | both | **PARTIAL** | FAIL | `S_X-01_ComputeContract_GROK_V1.ps1` | P0 |
| X-02 | D | Input changes during compute | both | **NOT RUN** | FAIL | `S_X-02_StaleResult_GROK_V1.ps1` | P0 |
| X-03 | D | Write an allowlisted number back | both | **NOT RUN** | PASS (precheck) | `S_X-03_WriteBack_GROK_V1.ps1` | P0 |
| X-04 | D | Save and undo | both | **NOT RUN** | PASS (precheck) | `S_X-04_SaveUndo_GROK_V1.ps1` | P0 |
| X-05 | D | Same capability id, two artifacts | both | **PARTIAL** | PASS (desktop half) | `S_X-05_CapabilityArtifacts_GROK_V1.ps1` | P1 |
| X-06 | D | Timeout and bad output | both | **FAIL** | FAIL | `S_X-06_TimeoutBadOutput_GROK_V1.ps1` | P0 |
| X-07 | - | Lean 4 absent | desktop | **PARTIAL** | PASS | `S_X-07_LeanAbsent_GROK_V1.ps1` | P1 |
| S-01 | D | Teacher picks a schema and a capability | both | **NOT RUN** | NOT RUN | `S_S-01_SchemaCapability_GROK_V1.ps1` | P1 |
| S-02 | D | Submit once | both | **NOT RUN** | NOT RUN | `S_S-02_SubmitOnce_GROK_V1.ps1` | P1 |
| S-03 | D | Retry the same idempotency key | both | **NOT RUN** | NOT RUN | `S_S-03_Idempotency_GROK_V1.ps1` | P1 |
| S-04 | D | Offline draft, then sync | both | **NOT RUN** | NOT RUN | `S_S-04_OfflineDraftSync_GROK_V1.ps1` | P1 |
| S-05 | D | Bad schema | both | **NOT RUN** | NOT RUN | `S_S-05_BadSchema_GROK_V1.ps1` | P1 |
| S-06 | - | Token not visible to the extension | both | **NOT RUN** | NOT RUN | `S_S-06_TokenHidden_GROK_V1.ps1` | P1 |
| S-07 | - | Sample OEF to XWims | both | **NOT RUN** | NOT RUN | `S_S-07_OefToXWims_GROK_V1.ps1` | P1 |
| O-01 | - | Newer upstream commit, still no edit in common | infra | **NOT RUN** | PASS (precheck) | `S_O-01_UpstreamUpdate_GROK_V1.ps1` | P2 |
| O-02 | E | License inventory | desktop | **NOT RUN** | FAIL | `S_O-02_LicenseInventory_GROK_V1.ps1` | P0 |
| O-03 | E | Clean rebuild and hashes | desktop | **FAIL** | FAIL | `S_O-03_CleanRebuildSbom_GROK_V1.ps1` | P0 |
| O-04 | - | Missing bundle, bad .ggb, Wims down | desktop | **PARTIAL** | PARTIAL | `S_O-04_FailureMessages_GROK_V1.ps1` | P1 |
| O-05 | - | One activity upgrade | desktop | **NOT RUN** | PASS (precheck) | `S_O-05_ActivityUpgrade_GROK_V1.ps1` | P2 |

## Per scenario
### P-01 — Clean product, no optional extension
- Gate -; client both; priority P0; status **PARTIAL**; Debian desktop: PASS.
- Acceptance (spec): Views open, no missing mandatory bundle.
- Automation: Image copy with engine/compute.runtime bundles removed from bundles.info; D-02 50/50; 2D+3D views; CAS; no ClassNotFound/MissingResource.
- Blockers / findings: web: deferred: web phase.
- **Windows r11 result INVALID** (Codex run `20261029_174320-SHADOW-TB64BO9R`, image r11 from afa9d1f): the screenshot captured the user's browser editor, not GeoGebra (unguarded foreground capture, BUG-019). Must be re-run with the foreground guard (`feat/ui-foreground-guard`); the screenshot is now check P01-08, BLOCKED when GeoGebraPlus is not foreground.
- Script: `03-RCP-Spike/tests/scenarios/S_P-01_CleanProduct_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-01_CleanProduct_GROK_V1.log`.

### P-02 — Algebra, CAS, spreadsheet, 2D, 3D
- Gate A; client both; priority P0; status **FAIL**; Debian desktop: FAIL.
- Acceptance (spec): Same results as the pinned baseline, within a written tolerance.
- Automation: fixtures/p02_core_GROK_V1.tsv (34 directives) run in the product and in the pinned upstream desktop distribution (ScenarioBaseline_GROK_V1.java); string equality after whitespace normalisation, numeric 1e-9.
- Blockers / findings: BUG-014 (3 divergences: f(x)=x^2-2x, m={{1,2},{3,4}}, 3D Plane(A,B,(1,0,0)): evalCommand false + error dialog in product, true in baseline); web deferred.
- Script: `03-RCP-Spike/tests/scenarios/S_P-02_CoreFeatures_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-02_CoreFeatures_GROK_V1.log`.

### P-03 — Standard tools
- Gate A; client both; priority P0; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): No missing tool against the pin.
- Automation: 2D toolbar definition (mode ids) product vs baseline: identical.
- Blockers / findings: 3D toolbar not compared (needs a 3D GuiManager directive); web deferred.
- Script: `03-RCP-Spike/tests/scenarios/S_P-03_StandardTools_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-03_StandardTools_GROK_V1.log`.

### P-04 — Open, save, reopen .ggb
- Gate A; client both; priority P0; status **FAIL**; Debian desktop: FAIL.
- Acceptance (spec): No silent loss.
- Automation: 8-object construction, SAVE/NEW/OPEN in-session, reopen in a fresh session, baseline opens the product file; values compared.
- Blockers / findings: BUG-014: f(x) = a x^2 - 1 not created by evalCommand in the product (so it is absent from the saved file); all other values identical, baseline reads the product file.
- Script: `03-RCP-Spike/tests/scenarios/S_P-04_SaveReopen_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-04_SaveReopen_GROK_V1.log`.

### P-05 — Scripts, macros, images, export
- Gate A; client both; priority P1; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): Gaps listed, not ignored.
- Automation: Execute/SetValue/SetCaption/UpdateConstruction vs baseline; PNG (writePNGtoFile) and SVG export.
- Blockers / findings: listed gaps: JavaScript ggbOnInit, user macro tool, image object, PDF/animated GIF/print; web deferred.
- Script: `03-RCP-Spike/tests/scenarios/S_P-05_ScriptsMacrosExport_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-05_ScriptsMacrosExport_GROK_V1.log`.

### P-06 — Offline after install
- Gate -; client desktop; priority P0; status **PARTIAL**; Debian desktop: PASS.
- Acceptance (spec): No hidden download for the core.
- Automation: Linux: product in unshare -rn (only lo), CAS + 3D + save/reopen, no network exception.
- Blockers / findings: Windows: needs admin firewall rule or disconnected VM.
- Script: `03-RCP-Spike/tests/scenarios/S_P-06_Offline_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-06_Offline_GROK_V1.log`.

### P-07 — Resize, DPI, keyboard, narrow browser
- Gate -; client both; priority P0; status **FAIL**; Debian desktop: FAIL.
- Acceptance (spec): No blocked control.
- Automation: xdotool resize 1024x700/1400x900/800x560; typed input in the 2D bar checked through GgbAPI; GDK_SCALE=2 start.
- Blockers / findings: BUG-010: K=(4,4) is created but the 'Please check your input' dialog opens; touch: no device; narrow browser: web.
- Script: `03-RCP-Spike/tests/scenarios/S_P-07_ScreensInput_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-07_ScreensInput_GROK_V1.log`.

### P-08 — Pin recorded
- Gate -; client both; priority P1; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): Reports cite 375db7faf54 and 5.4.934.0.
- Automation: source HEAD = pin, upstream tracked tree clean, common bundle version, states.yaml and evidence folders cite the pin.
- Blockers / findings: acceptance tag not chosen (owner); 3 older evidence folders do not cite the pin.
- Script: `03-RCP-Spike/tests/scenarios/S_P-08_PinTraceability_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_P-08_PinTraceability_GROK_V1.log`.

### D-01 — Import the Gradle composite into Eclipse
- Gate -; client desktop; priority P2; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): IDE builds the existing tasks; Gradle stays the build.
- Automation: precheck: settings.gradle.kts present; no gradle wrapper in the pinned source (noted).
- Blockers / findings: Eclipse + Buildship not installed (owner approval needed).
- Script: `03-RCP-Spike/tests/scenarios/S_D-01_EclipseImport_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-01_EclipseImport_GROK_V1.log`.

### D-02 — RCP starts on the jar set, no edit in common
- Gate B; client desktop; priority P0; status **PASS**; Debian desktop: PASS.
- Acceptance (spec): UI starts, logs show the jar set.
- Automation: suite 08 (no duplicate scenario script); re-checked by S_P-01.
- Blockers / findings: -.

### D-03 — Package-ownership report
- Gate B; client desktop; priority P0; status **PASS**; Debian desktop: PASS.
- Acceptance (spec): No accidental split packages.
- Automation: suite 11 (bnd rebuild + Equinox resolution).
- Blockers / findings: -.

### D-04 — Swing GeoGebra inside an RCP shell
- Gate B; client desktop; priority P0; status **PARTIAL**; Debian desktop: FAIL.
- Acceptance (spec): Focus, menus, clipboard, DPI work, or the SWT rewrite cost is written down.
- Automation: suite 09 (Linux FAIL); P-07 adds API-verified keyboard check.
- Blockers / findings: BUG-004, BUG-010..013; Windows suite 09 NOT RUN (attended).

### D-05 — CAS and 3D from the RCP product
- Gate B; client desktop; priority P0; status **PASS**; Debian desktop: PASS.
- Acceptance (spec): GIAC and JOGL load once.
- Automation: suite 10 + suite 08.
- Blockers / findings: -.

### D-06 — One good and one bad extension bundle at startup
- Gate B; client desktop; priority P0; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): Good one registered once; bad one reported; core stays up.
- Automation: Equinox resolver probe: good test bundle RESOLVED, bad one INSTALLED + UNRESOLVED_BUNDLE, core count unchanged.
- Blockers / findings: product extension registry not implemented.
- Script: `03-RCP-Spike/tests/scenarios/S_D-06_ExtensionRegistry_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-06_ExtensionRegistry_GROK_V1.log`.

### D-07 — Change the set, restart
- Gate B; client desktop; priority P1; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): New set after restart; open work kept.
- Automation: resolver probe with/without an extra bundle; work saved and reopened across two product sessions.
- Blockers / findings: no extension manager / persisted state.
- Script: `03-RCP-Spike/tests/scenarios/S_D-07_EnableDisable_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-07_EnableDisable_GROK_V1.log`.

### D-08 — Incompatible version ranges
- Gate B; client desktop; priority P1; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): Resolver refuses; no half-loaded feature.
- Automation: Require-Bundle common [9,10) stays INSTALLED, dependent bundle not resolved, core unaffected.
- Blockers / findings: user-facing refusal message not implemented.
- Script: `03-RCP-Spike/tests/scenarios/S_D-08_IncompatibleExtension_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-08_IncompatibleExtension_GROK_V1.log`.

### D-09 — Unsigned or unapproved jar
- Gate E; client desktop; priority P0; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Not loaded.
- Automation: precheck records today's state: an unsigned bundle is accepted (no signature policy).
- Blockers / findings: no signing key, channel or policy (owner decision).
- Script: `03-RCP-Spike/tests/scenarios/S_D-09_SignatureChannel_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-09_SignatureChannel_GROK_V1.log`.

### D-10 — Install, upgrade, rollback on clean Windows
- Gate -; client desktop; priority P1; status **NOT RUN**; Debian desktop: FAIL.
- Acceptance (spec): Java 25 and natives included.
- Automation: precheck on the Linux image: natives present, configuration relocatable; no bundled Java.
- Blockers / findings: BUG-017 (Linux image has no bundled Java; launch.sh hard-codes /workspace/AlgoGebra/jdk); no installer; no clean Windows VM.
- Script: `03-RCP-Spike/tests/scenarios/S_D-10_InstallUpgrade_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_D-10_InstallUpgrade_GROK_V1.log`.

### W-01 — Score Java-to-web and JS/TS
- Gate C; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Written matrix: fidelity, build, CAS, 3D, license, maintenance.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-02 — Chosen non-GWT client runs P-02 and P-03
- Gate C; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): No missing mandatory feature.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-03 — Approved, missing, incompatible web modules
- Gate -; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Fail closed. No URL from the activity.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-04 — XSS, malicious .ggb, command injection
- Gate E; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Extension has no broad page access.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-05 — 2D and 3D together, then reload
- Gate -; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Stable figure ids, no shared listeners.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-06 — Resize and touch on supported browsers
- Gate -; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Supported set written if one fails.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-07 — Offline after first load
- Gate -; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Agreed offline slice works.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### W-08 — Same activity contract on both clients
- Gate -; client web; priority P1; status **NOT RUN**; Debian desktop: -.
- Acceptance (spec): Same status codes and student-visible result.
- Automation: deferred: web phase.
- Blockers / findings: deferred: web phase (no script yet).

### X-01 — External algorithm, not an AlgoElement
- Gate D; client both; priority P0; status **PARTIAL**; Debian desktop: FAIL.
- Acceptance (spec): Deterministic typed result.
- Automation: ComputeResult fields; 3x PARI factor(2^64+1) identical; GeoGebra CAS identical across two product sessions.
- Blockers / findings: no result-kind enum in compute.api (typed contract gap); web deferred.
- Script: `03-RCP-Spike/tests/scenarios/S_X-01_ComputeContract_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-01_ComputeContract_GROK_V1.log`.

### X-02 — Input changes during compute
- Gate D; client both; priority P0; status **NOT RUN**; Debian desktop: FAIL.
- Acceptance (spec): Stale revision dropped.
- Automation: checks that the API carries a request id / revision: it does not.
- Blockers / findings: compute API has no revision (API change needed).
- Script: `03-RCP-Spike/tests/scenarios/S_X-02_StaleResult_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-02_StaleResult_GROK_V1.log`.

### X-03 — Write an allowlisted number back
- Gate D; client both; priority P0; status **NOT RUN**; Debian desktop: PASS (precheck).
- Acceptance (spec): Views update.
- Automation: precheck: GgbAPI setValue on free/dependent/fixed numbers = baseline.
- Blockers / findings: state adapter / allow-list not implemented.
- Script: `03-RCP-Spike/tests/scenarios/S_X-03_WriteBack_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-03_WriteBack_GROK_V1.log`.

### X-04 — Save and undo
- Gate D; client both; priority P0; status **NOT RUN**; Debian desktop: PASS (precheck).
- Acceptance (spec): UI does not call the output a native dependent object.
- Automation: precheck: setUndoPoint + undo removes one step, = baseline.
- Blockers / findings: no path writes engine output into the construction.
- Script: `03-RCP-Spike/tests/scenarios/S_X-04_SaveUndo_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-04_SaveUndo_GROK_V1.log`.

### X-05 — Same capability id, two artifacts
- Gate D; client both; priority P1; status **PARTIAL**; Debian desktop: PASS (desktop half).
- Acceptance (spec): Desktop jar and web module stay distinct.
- Automation: ComputeCapability enum; engine bundles distinct in bundles.info.
- Blockers / findings: web module does not exist.
- Script: `03-RCP-Spike/tests/scenarios/S_X-05_CapabilityArtifacts_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-05_CapabilityArtifacts_GROK_V1.log`.

### X-06 — Timeout and bad output
- Gate D; client both; priority P0; status **FAIL**; Debian desktop: FAIL.
- Acceptance (spec): Core construction unchanged.
- Automation: PARI while(1,) 2 s -> ERR, gp killed, next call OK; malformed input must give a typed error.
- Blockers / findings: BUG-015 (malformed PARI input returns OK with empty text); construction path not integrated.
- Script: `03-RCP-Spike/tests/scenarios/S_X-06_TimeoutBadOutput_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-06_TimeoutBadOutput_GROK_V1.log`.

### X-07 — Lean 4 absent
- Gate -; client desktop; priority P1; status **PARTIAL**; Debian desktop: PASS.
- Acceptance (spec): App still opens.
- Automation: no lean on PATH, no Lean bundle, app opens, CAS works, no Lean error.
- Blockers / findings: Windows run pending.
- Script: `03-RCP-Spike/tests/scenarios/S_X-07_LeanAbsent_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_X-07_LeanAbsent_GROK_V1.log`.

### S-01 — Teacher picks a schema and a capability
- Gate D; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Student sees only those.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-01_SchemaCapability_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-01_SchemaCapability_GROK_V1.log`.

### S-02 — Submit once
- Gate D; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): One complete package.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-02_SubmitOnce_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-02_SubmitOnce_GROK_V1.log`.

### S-03 — Retry the same idempotency key
- Gate D; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): One grade record.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-03_Idempotency_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-03_Idempotency_GROK_V1.log`.

### S-04 — Offline draft, then sync
- Gate D; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Work kept.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-04_OfflineDraftSync_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-04_OfflineDraftSync_GROK_V1.log`.

### S-05 — Bad schema
- Gate D; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Work kept, no silent grade.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-05_BadSchema_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-05_BadSchema_GROK_V1.log`.

### S-06 — Token not visible to the extension
- Gate -; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Confirmed in logs.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-06_TokenHidden_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-06_TokenHidden_GROK_V1.log`.

### S-07 — Sample OEF to XWims
- Gate -; client both; priority P1; status **NOT RUN**; Debian desktop: NOT RUN.
- Acceptance (spec): Same grade on fixtures, or OEF kept.
- Automation: precheck: no Wims contract in product sources.
- Blockers / findings: no Wims activity/submission contract, client or test server.
- Script: `03-RCP-Spike/tests/scenarios/S_S-07_OefToXWims_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_S-07_OefToXWims_GROK_V1.log`.

### O-01 — Newer upstream commit, still no edit in common
- Gate -; client infra; priority P2; status **NOT RUN**; Debian desktop: PASS (precheck).
- Acceptance (spec): Adapter-only diff, or a written refusal.
- Automation: no org.geogebra.common class in product sources; upstream shared/common has no tracked change; GGB_NEXT_COMMIT hook.
- Blockers / findings: no newer upstream commit selected.
- Script: `03-RCP-Spike/tests/scenarios/S_O-01_UpstreamUpdate_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_O-01_UpstreamUpdate_GROK_V1.log`.

### O-02 — License inventory
- Gate E; client desktop; priority P0; status **NOT RUN**; Debian desktop: FAIL.
- Acceptance (spec): Deployment review recorded.
- Automation: inventory TSV (jar sha256, Bundle-License, vendor, LICENSE/NOTICE, fonts, translations, natives).
- Blockers / findings: 46 jars without license metadata; human/legal review not recorded.
- Script: `03-RCP-Spike/tests/scenarios/S_O-02_LicenseInventory_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_O-02_LicenseInventory_GROK_V1.log`.

### O-03 — Clean rebuild and hashes
- Gate E; client desktop; priority P0; status **FAIL**; Debian desktop: FAIL.
- Acceptance (spec): SBOM matches the package.
- Automation: sha256 list of the image; bundles.info vs files; clean rebuild into a temp folder and compare.
- Blockers / findings: BUG-016 (rebuild not byte-identical: product jars and config.ini differ); no CycloneDX/SPDX.
- Script: `03-RCP-Spike/tests/scenarios/S_O-03_CleanRebuildSbom_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_O-03_CleanRebuildSbom_GROK_V1.log`.

### O-04 — Missing bundle, bad .ggb, Wims down
- Gate -; client desktop; priority P1; status **PARTIAL**; Debian desktop: PARTIAL.
- Acceptance (spec): Safe message, redacted log.
- Automation: image copy without desktop.editor -> D-02 failure reported, no hang; garbage and broken-XML .ggb -> app keeps working; no secrets in logs.
- Blockers / findings: Wims down: no client; user-facing message not designed.
- Script: `03-RCP-Spike/tests/scenarios/S_O-04_FailureMessages_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_O-04_FailureMessages_GROK_V1.log`.

### O-05 — One activity upgrade
- Gate -; client desktop; priority P2; status **NOT RUN**; Debian desktop: PASS (precheck).
- Acceptance (spec): Old file still opens.
- Automation: precheck: hand-built format 4.0 .ggb opens, = baseline.
- Blockers / findings: no activity manifest / versioned activity format.
- Script: `03-RCP-Spike/tests/scenarios/S_O-05_ActivityUpgrade_GROK_V1.ps1`; log: `03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/S_O-05_ActivityUpgrade_GROK_V1.log`.

## New findings from this run
- **BUG-014** (P-02/P-04): `evalCommand` returns false and opens "Please check your input" / "CAS.GeneralErrorMessage" for `f(x)=x^2-2x`, `m={{1,2},{3,4}}`, `f(x)=a x^2-1` and 3D `Plane(A,B,(1,0,0))` in the RCP product; the pinned upstream desktop returns true for the same inputs. Same family as BUG-010/BUG-013 (localisation/command resources in the OSGi image suspected, not proven).
- **BUG-015** (X-06): PARI engine returns OK with empty text for malformed input `factor((` instead of a typed error.
- **BUG-016** (O-03): a clean rebuild (build.sh into a fresh folder) is not byte-identical: 11 files differ (product jars with timestamps, config.ini).
- **BUG-017** (D-10): the Linux image has no bundled Java; `launch.sh` falls back to `/workspace/AlgoGebra/jdk/jdk-25*` and a hard-coded image path.
- O-02: 46 jars carry neither Bundle-License nor a LICENSE/NOTICE file. P-08: 3 older evidence folders do not cite the pin.

## Windows
The scenario scripts are syntax-checked on Windows only. Running them there needs an image rebuilt from this commit (r10: scenario hook + BUG-006 filter); UI scenarios must run in an attended session or on a test VM (handoff).
