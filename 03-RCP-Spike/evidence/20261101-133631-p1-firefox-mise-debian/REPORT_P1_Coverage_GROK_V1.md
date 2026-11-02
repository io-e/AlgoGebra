# P1 — Coverage gaps on Debian: Firefox + Mise → Java (GROK_V1)

Host: Debian 13 (trixie), node 20.19.2, pwsh 7.6.9. Base `feat/external-engines` @ `9d1a297`; launcher tested = PR #9 `launch.sh` (includes PR #4 BUG-017 discovery).

## (a) Firefox
- `apt firefox-esr` / `npx playwright install --with-deps firefox`: **blocked** — apt fails (`trixie-security InRelease is not signed` on this box), so OS deps could not be installed via apt.
- `npx playwright install firefox` (no deps, Playwright 1.64.1 from `tests/playwright/package.json` `^1.52.0`): **OK**, Firefox **157.0** build in `~/.cache/ms-playwright`.
- Headless smoke (`firefox_smoke_GROK_V1.mjs`): launch → load local `page.html` → screenshot → **PASS** (title "GGB FF smoke", UA `Firefox/157.0`). Screenshot: `firefox_smoke_GROK_V1.png`.
- `npx playwright test --project=firefox` (W-09 spec) without WAR: **expected FAIL** — PW-W09-01 locator not found, PW-W09-02 `waitForFunction` 60 s timeout; run cut at 120 s at test 3/10. Not a regression; G-T3 waits for the WAR (X-T8). Log: `playwright_w09_firefox_noWAR_GROK_V1.log`.

## (b) Mise → Java (BUG-017, PR #4 discovery)
mise 2026.10.25 installed user-local (`~/.local/bin/mise`), `mise use -g java@temurin-25` (25.0.5+8) and project-local `java@temurin-21` in `/tmp/m21`. No GGB_JAVA/JAVA/JAVA_HOME, no `/usr/lib/jvm`, no `java` on PATH. Raw: `mise_java_discovery_GROK_V1.txt`.

| Id | Setup | Result |
|---|---|---|
| M-01 | mise on PATH, global temurin-25 | **PASS** `SOURCE=mise MAJOR=25` |
| M-02 | mise not on PATH | **PASS** via installs glob `SOURCE=system` (picked `temurin-latest` symlink) |
| M-03 | cwd pins temurin-21 via mise | mise 21 rejected (< 25), then falls through to glob → another mise install (25). Works, but **silently ignores the project pin** — finding F-1 |
| M-04 | same, `GGB_JAVA_MIN=21` | **PASS** `SOURCE=mise MAJOR=21` (RCPTT Java 21 default per RQ-1 V1_1) |
| M-05 | `-Course` dry-run, mise-only Java | **PASS** argv uses mise temurin-25 |

**Mise path of BUG-017 is now verified** (was untested in PR #4).
F-1 (low): when the mise-resolved Java is too old, discovery continues into `~/.local/share/mise/installs/java/*`; consider printing a warning ("mise java X < MIN, using …"). Suggested suite 17 cases L-14 (mise on PATH) / L-15 (mise pin too old → warning) once PR #4 is merged — not added here to avoid editing PR #4's file on another branch.

Box side-effect: `~/.config/mise/config.toml` now pins `java@temurin-25` globally (box only).
