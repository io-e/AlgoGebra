<!-- CLAUDE_V1 -->
# Codex Handoff — C-3: OSGi Service Registration for External Engines

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_C3_OSGi_Service_Registration_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Depends on | `Spec_Capability_Descriptor_CLAUDE_V1.md`, `Spec_Activity_Contract_CLAUDE_V1.md`, `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` |
| Priority | After C-2 (D-06 extension management) |

---

## 1. Goal

Implement OSGi Declarative Services (DS) so that external compute engine bundles register themselves with the AlgoGebra host at startup. The host discovers available engines via the OSGi service registry — no hardcoded list, no classpath scanning.

---

## 2. What to implement

### 2.1 Service interface (host API bundle)

Create `org.geogebraplus.api.ExternalComputeService` in the host API bundle:

```java
package org.geogebraplus.api;

public interface ExternalComputeService {
    ComputeResult eval(String command, ComputeContext ctx)
        throws ExternalComputeException;
    Set<ComputeCapability> getCapabilities();
    boolean isAvailable();
    String getEngineId();  // "pari", "maxima", "gap", etc.
}
```

This interface is exported by the host API bundle. Engine bundles import it.

### 2.2 Engine bundle DS component (one per engine)

Each engine bundle (e.g., `org.geogebraplus.engine.pari`) declares a DS component:

```xml
<!-- OSGI-INF/org.geogebraplus.engine.pari.PariComputeService.xml -->
<component name="pari-compute-service" immediate="true">
    <implementation class="org.geogebraplus.engine.pari.PariComputeService"/>
    <service>
        <provide interface="org.geogebraplus.api.ExternalComputeService"/>
    </service>
    <property name="engine.id" value="pari"/>
    <property name="engine.version" value="2.17.1"/>
</component>
```

Or via DS annotations (preferred):

```java
@Component(
    service = ExternalComputeService.class,
    property = {
        "engine.id=pari",
        "engine.version=2.17.1"
    }
)
public class PariComputeService implements ExternalComputeService {
    // delegates to SubprocessEngine from engine CDC V1_3
}
```

### 2.3 Host-side service tracker

The host bundle tracks all `ExternalComputeService` registrations:

```java
@Component(service = EngineRegistry.class, immediate = true)
public class EngineRegistry {

    private final Map<String, ExternalComputeService> engines =
        new ConcurrentHashMap<>();

    @Reference(
        cardinality = ReferenceCardinality.MULTIPLE,
        policy = ReferencePolicy.DYNAMIC
    )
    void addEngine(ExternalComputeService svc, Map<String, Object> props) {
        String id = (String) props.get("engine.id");
        engines.put(id, svc);
        // log: "Engine registered: {id}"
    }

    void removeEngine(ExternalComputeService svc, Map<String, Object> props) {
        String id = (String) props.get("engine.id");
        engines.remove(id);
        // log: "Engine unregistered: {id}"
    }

    public Optional<ExternalComputeService> getEngine(String engineId) {
        return Optional.ofNullable(engines.get(engineId));
    }

    public Set<String> availableEngines() {
        return Collections.unmodifiableSet(engines.keySet());
    }
}
```

### 2.4 Capability descriptor loading

Each engine bundle also includes `META-INF/capability.json` per `Spec_Capability_Descriptor_CLAUDE_V1.md`. The host's D-06 extension manager (C-2) reads it for allowlist validation. The DS registration happens only after the allowlist check passes.

---

## 3. Bundle structure

```
org.geogebraplus.engine.pari/
├── META-INF/
│   ├── MANIFEST.MF
│   └── capability.json
├── OSGI-INF/
│   └── org.geogebraplus.engine.pari.PariComputeService.xml
└── org/geogebraplus/engine/pari/
    └── PariComputeService.java
```

`MANIFEST.MF` must include:
```
Import-Package: org.geogebraplus.api;version="[1.0,2.0)"
Service-Component: OSGI-INF/*.xml
```

---

## 4. Test plan

| Test | Expected |
|---|---|
| Start Equinox with Pari engine bundle present | `EngineRegistry.availableEngines()` contains `"pari"` |
| Start without Pari bundle | `EngineRegistry.getEngine("pari")` returns `Optional.empty()` |
| Add Pari bundle at startup, remove it (stop bundle) | Dynamic unbind: engine disappears from registry |
| Engine bundle present but `isAvailable()` returns false (binary not on PATH) | Engine is registered in OSGi but `isAvailable()` = false; host logs warning |
| Two bundles claim same `engine.id` | Second registration logged as conflict; first wins |

---

## 5. Files to create/modify

| Action | Path | Notes |
|---|---|---|
| **Create** | `org.geogebraplus.api/src/.../ExternalComputeService.java` | Interface + DTOs (`ComputeResult`, `ComputeContext`, `ComputeCapability`, `ExternalComputeException`) |
| **Create** | `org.geogebraplus.host/src/.../EngineRegistry.java` | DS component with `@Reference` tracker |
| **Create** | `org.geogebraplus.engine.pari/` | First engine bundle — proof of pattern |
| **Modify** | `org.geogebraplus.host/META-INF/MANIFEST.MF` | Add `Import-Package: org.geogebraplus.api` |
| **Modify** | Bnd instructions | Ensure `Service-Component` header is generated for DS annotations |

---

## 6. Constraints

- **No hot unload** at Phase 1. Bundles are discovered at startup. Dynamic policy in DS handles bundle stop/uninstall, but the user flow is restart-to-change.
- **No `common` edit.** All interfaces live in the host API bundle, not in `org.geogebra.common`.
- **Subprocess engines** delegate to `SubprocessEngine` from `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md`. The DS component is a thin adapter.

---

*End of `Handoff_Codex_C3_OSGi_Service_Registration_CLAUDE_V1.md`.*
