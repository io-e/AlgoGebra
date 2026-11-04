<!-- CLAUDE_V1 -->
# Handoff — D-06 Extension Bundle Management (Codex)

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_D06_Extension_Mgmt_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Assigned to | **Codex** |
| Priority | **High** — last Gate B blocker (D-02..D-05 are PASS) |
| Branch | Create `feat/d06-extension-mgmt` from current `main` tip |
| Host code | `03-RCP-Spike/host/src/org/geogebra/plus/host/GeoGebraPlusApplication.java` |

---

## 1. Goal

Demonstrate that the RCP host can **install, start, stop, and uninstall an OSGi bundle at runtime** — the minimal proof that extension management works. This closes D-06 and unblocks Gate B.

## 2. What D-06 requires

From V2 scenario D-06: "Extension bundle management: the host can install a bundle from a URL or file path, start it, query its services, stop it, and uninstall it. The bundle resolves against the existing 50-bundle set without requiring a restart."

## 3. Implementation plan

### 3.1 Create a dummy extension bundle

Create a minimal OSGi bundle `org.geogebra.plus.test.extension`:

```java
// test-extension/src/org/geogebra/plus/test/extension/Activator.java
package org.geogebra.plus.test.extension;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

public class Activator implements BundleActivator {
    @Override
    public void start(BundleContext context) {
        System.out.println("[TEST-EXT] Extension started");
        // Register a dummy service
        context.registerService(Runnable.class, () -> {
            System.out.println("[TEST-EXT] Extension service called");
        }, null);
    }

    @Override
    public void stop(BundleContext context) {
        System.out.println("[TEST-EXT] Extension stopped");
    }
}
```

MANIFEST.MF:
```
Bundle-SymbolicName: org.geogebra.plus.test.extension
Bundle-Version: 1.0.0
Bundle-Activator: org.geogebra.plus.test.extension.Activator
Import-Package: org.osgi.framework
```

Build it as a JAR (no Gradle — just `javac` + `jar` with manifest). Place at `03-RCP-Spike/test-extension/`.

### 3.2 Add extension management to the host

In `GeoGebraPlusApplication.java`, add a method:

```java
/**
 * D-06 proof: install, start, query, stop, uninstall a bundle at runtime.
 */
private void runD06ExtensionProof(BundleContext ctx, String bundlePath) throws Exception {
    // Install
    Bundle ext = ctx.installBundle("file:" + bundlePath);
    assert ext.getState() == Bundle.INSTALLED;
    
    // Start
    ext.start();
    assert ext.getState() == Bundle.ACTIVE;
    
    // Query service
    ServiceReference<Runnable> ref = ctx.getServiceReference(Runnable.class);
    assert ref != null;
    Runnable svc = ctx.getService(ref);
    svc.run();
    ctx.ungetService(ref);
    
    // Stop
    ext.stop();
    assert ext.getState() == Bundle.RESOLVED;
    
    // Uninstall
    ext.uninstall();
    assert ext.getState() == Bundle.UNINSTALLED;
    
    System.out.println("D-06 PASS: extension lifecycle complete");
}
```

### 3.3 Integrate into launch

Add a `-D06` flag to `launch.ps1` (or a `--run-d06` argument). When present, after D-02 startup, run the extension proof. The test is:
1. Host starts normally (D-02 PASS)
2. Extension installs and resolves against the existing 50 bundles
3. Extension's `Activator.start()` runs, service is registered
4. Service is discovered via `ServiceReference`
5. Extension stops and uninstalls cleanly

## 4. Test matrix

| Test ID | Input | Expected | Type |
|---|---|---|---|
| **T-D06-01** | Install + start test-extension | `[TEST-EXT] Extension started` in log, bundle ACTIVE | Lifecycle |
| **T-D06-02** | Query `Runnable` service | Service found, `run()` prints message | Service discovery |
| **T-D06-03** | Stop + uninstall | Bundle UNINSTALLED, `Runnable` service gone | Cleanup |
| **T-D06-04** | Install a bundle with missing import | `BundleException` (resolution failure), no crash | Error handling |
| **T-D06-05** | Install same bundle twice | Second install returns existing bundle or throws | Idempotency |

## 5. Acceptance criteria

| ID | Criterion | Evidence |
|---|---|---|
| **D06-01** | Extension bundle installs and starts in the running Equinox framework | Log output + bundle state assertion |
| **D06-02** | Extension's OSGi service is discoverable by the host | `ServiceReference` not null |
| **D06-03** | Extension stops and uninstalls without framework restart | Bundle state UNINSTALLED after uninstall |
| **D06-04** | Existing 50 bundles remain RESOLVED after extension lifecycle | Bundle count check before/after |

## 6. What NOT to do

- Do **not** implement a full extension marketplace or UI
- Do **not** modify the existing 50-bundle set
- Do **not** add extension persistence (install on restart) — that's future work
- Do **not** touch `common` or GeoGebra upstream source

## 7. Deliverables

| # | File | What |
|---|---|---|
| 1 | `03-RCP-Spike/test-extension/` | Dummy extension bundle source + built JAR |
| 2 | `GeoGebraPlusApplication.java` (modified) | `runD06ExtensionProof()` method |
| 3 | `03-RCP-Spike/evidence/D06_Extension_Report_CODEX_V1.md` | Test results with log excerpts |

---

*End of `Handoff_Codex_D06_Extension_Mgmt_CLAUDE_V1.md`.*
