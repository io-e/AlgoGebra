# D-06 Runtime Extension Lifecycle — Windows Evidence

**Run date:** 2026-11-04 (Europe/Paris)  
**Code commit:** `cca0cc8979e6a4555259f73761c6416cd16d4306` on `feat/d06-extension-mgmt`  
**Host:** Shadow PC, Windows build 26100, PowerShell 7.6.9  
**Product runtime:** Temurin 25.0.4.1+1-LTS; build tools: Temurin 21.0.12.1+1-LTS  
**GeoGebra pin:** `375db7faf5407390bb322165f2414415da8faeda` (`5.4.934.0`).

## Command and result

Build from the D-06 worktree using the pinned upstream resource checkout:

```powershell
cd D:\ALF_Agents\_worktrees\codex-d06-extension-mgmt\03-RCP-Spike
.\build.ps1 -JavaHome 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot' `
  -GeoGebraSourceRoot 'D:\ALF_ZGit\G1_Geogebra_Migration\source'
```

Then run the headless scenario:

```powershell
$env:IMAGE = 'D:\ALF_Agents\_worktrees\codex-d06-extension-mgmt\03-RCP-Spike'
$env:RESULTS_DIR = 'D:\ALF_Agents\_worktrees\codex-d06-extension-mgmt\03-RCP-Spike\tests\results\d06-product-proof'
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_D-06_ExtensionRegistry_GROK_V1.ps1
```

**Outcome:** 7 PASS / 0 FAIL / 0 SKIP. The process was headless; no UI opened and no user input was sent. The full suite output is `S_D-06_GROK_V1.csv`; Equinox output is `S_D-06.product-headless.log`.

## Checks proven

- D-02 resolved the existing core set: 50/50.
- The exact allowlisted test BSN installed and started through `BundleContext.installBundle()` / `Bundle.start()`.
- A `ServiceTracker<Runnable, Runnable>` discovered the service by an OSGi filter; the host invoked it.
- Stopping the bundle removed the service from the tracker; uninstall reached `UNINSTALLED` without restarting Equinox.
- An unapproved BSN was rejected before installation. A fixture with a mandatory missing import failed to resolve/start and remained `INSTALLED` before cleanup.
- All 50 existing D-03 core bundles remained `RESOLVED` or `ACTIVE` before and after the proof.

## Scope and remaining validation

This is a development spike, not a marketplace or a production security policy. The allowlist check is based on the exact `Bundle-SymbolicName`; it does not establish publisher identity or artifact integrity. The D-06 test JARs live under `test-extension/build`, are excluded from `bundles.info`, and are not copied into normal product images. Use `install-product.ps1 -IncludeD06Fixtures` only for a disposable development image.

Windows product proof is complete for this commit. Debian/Linux still needs Grok's rerun before D-06 can be recorded as a cross-platform PASS or Gate B closure reviewed by the owner. No upstream GeoGebra or `common` source was changed.

