<!-- CLAUDE_V1 -->
# Specification — Capability Descriptor Contract

| Field | Value |
|---|---|
| Document | `02-Cdc/Spec_Capability_Descriptor_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Status | **Draft** — ready for review |
| Depends on | `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` §4, `Spec_Activity_Manifest_CLAUDE_V1.md`, `Handoff_Codex_D06_Extension_Mgmt_CLAUDE_V1.md` |

---

## 1. Purpose

A capability descriptor declares what an extension bundle provides to the AlgoGebra host. The host's allowlist references capability IDs. An activity manifest's `enabledCapabilities[]` references the same IDs. The descriptor sits between them: it tells the host what the capability does, what it needs, and what happens if it fails.

**Binding decision:** Teachers select prebuilt capabilities; only developers/admins manage extension code. The descriptor is authored by the developer who builds the extension bundle, not by the teacher.

---

## 2. File location

### 2.1 Desktop RCP

Each OSGi extension bundle contains a descriptor at a well-known path:

```
META-INF/
├── MANIFEST.MF              ← OSGi bundle manifest
└── capability.json           ← this descriptor
```

The host scans `META-INF/capability.json` in every RESOLVED extension bundle at startup (D-06).

### 2.2 Web

Web capabilities are declared in a registry file loaded by the host page:

```
capabilities/
├── pari-compute.json
├── maxima-compute.json
└── gnuplot-render.json
```

Same schema, different discovery mechanism. The web host reads a `capabilities/` directory or an inline registry in the host HTML.

---

## 3. Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://geogebraplus.local/schemas/capability/v1",
  "title": "AlgoGebra Capability Descriptor",
  "type": "object",
  "required": [
    "capabilityId",
    "version",
    "name",
    "runtime",
    "provides"
  ],
  "additionalProperties": false,
  "properties": {
    "capabilityId": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9._-]{2,63}$",
      "description": "Unique capability identifier. Convention: '<domain>.<function>', e.g. 'compute.pari', 'compute.maxima', 'render.gnuplot', 'cas.giac'."
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Semantic version of this capability descriptor."
    },
    "name": {
      "type": "string",
      "maxLength": 100,
      "description": "Human-readable name for logs and admin UI."
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "One-paragraph description of what this capability provides."
    },
    "hostApiRange": {
      "type": "object",
      "required": ["min"],
      "additionalProperties": false,
      "properties": {
        "min": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+$",
          "description": "Minimum host API version this capability requires."
        },
        "max": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+$",
          "description": "Maximum host API version tested. Absent means 'no upper bound known'."
        }
      },
      "description": "Host API version range this capability is compatible with. The host checks its own version falls within [min, max]."
    },
    "runtime": {
      "type": "string",
      "enum": ["desktop", "web", "both"],
      "description": "Which host runtime(s) this capability supports."
    },
    "provides": {
      "type": "string",
      "enum": [
        "external-compute",
        "render",
        "check-evaluator",
        "help-provider",
        "view-extension"
      ],
      "description": "The type of service this capability registers with the host."
    },
    "serviceInterface": {
      "type": "string",
      "description": "Fully qualified Java interface name for desktop OSGi service registration. E.g. 'org.geogebraplus.api.ExternalComputeService'. Web capabilities use the JS equivalent."
    },
    "permissions": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "subprocess.spawn",
          "filesystem.read",
          "filesystem.write-temp",
          "network.localhost",
          "network.outbound",
          "geogebra.evalCommand",
          "geogebra.readState"
        ]
      },
      "uniqueItems": true,
      "description": "Permissions this capability needs from the host. The host grants only these — the capability cannot escalate."
    },
    "failureMode": {
      "type": "string",
      "enum": ["degrade", "block", "silent"],
      "default": "degrade",
      "description": "What happens when this capability is unavailable at runtime. 'degrade': activity loads but features using this capability show 'unavailable'. 'block': activity refuses to load. 'silent': capability is optional, no user feedback."
    },
    "engines": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "pari", "maxima", "gap", "gnuplot",
          "geogebra-cas", "yacas", "m2", "scilab"
        ]
      },
      "description": "For 'external-compute' and 'check-evaluator' providers: which engine(s) this capability wraps."
    },
    "nativeLibraries": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "os", "arch"],
        "additionalProperties": false,
        "properties": {
          "name": {
            "type": "string",
            "description": "Library base name (e.g. 'giac', 'gluegen_rt')."
          },
          "os": {
            "type": "string",
            "enum": ["windows", "linux", "macos"]
          },
          "arch": {
            "type": "string",
            "enum": ["x86_64", "aarch64"]
          }
        }
      },
      "description": "Native libraries this capability requires. The host checks they can be loaded before registering the capability."
    }
  }
}
```

---

## 4. Examples

### 4.1 Pari compute capability

```json
{
  "capabilityId": "compute.pari",
  "version": "1.0.0",
  "name": "PARI/GP Computation",
  "description": "Provides symbolic and numeric computation via PARI/GP subprocess.",
  "hostApiRange": { "min": "1.0.0" },
  "runtime": "desktop",
  "provides": "external-compute",
  "serviceInterface": "org.geogebraplus.api.ExternalComputeService",
  "permissions": ["subprocess.spawn", "filesystem.read"],
  "failureMode": "degrade",
  "engines": ["pari"]
}
```

### 4.2 GIAC CAS capability (both runtimes)

```json
{
  "capabilityId": "cas.giac",
  "version": "1.0.0",
  "name": "GIAC CAS",
  "description": "GeoGebra's built-in CAS via GIAC (JNI on desktop, WASM on web).",
  "hostApiRange": { "min": "1.0.0" },
  "runtime": "both",
  "provides": "external-compute",
  "serviceInterface": "org.geogebraplus.api.ExternalComputeService",
  "permissions": ["geogebra.evalCommand"],
  "failureMode": "block",
  "engines": ["geogebra-cas"],
  "nativeLibraries": [
    { "name": "giac", "os": "windows", "arch": "x86_64" }
  ]
}
```

### 4.3 Gnuplot render capability

```json
{
  "capabilityId": "render.gnuplot",
  "version": "1.0.0",
  "name": "Gnuplot Rendering",
  "description": "Renders 2D/3D plots via Gnuplot subprocess. Produces PNG images.",
  "hostApiRange": { "min": "1.0.0" },
  "runtime": "desktop",
  "provides": "render",
  "serviceInterface": "org.geogebraplus.api.RenderService",
  "permissions": ["subprocess.spawn", "filesystem.write-temp"],
  "failureMode": "degrade",
  "engines": ["gnuplot"]
}
```

---

## 5. Host discovery and registration

### 5.1 Desktop (D-06)

1. At startup, the host scans the extension bundle directory
2. For each RESOLVED bundle, read `META-INF/capability.json`
3. Validate against this schema
4. Check `hostApiRange` compatibility
5. Check `runtime` = `desktop` or `both`
6. Check all `permissions` are in the host allowlist
7. If `nativeLibraries` declared, verify each can be loaded
8. Register the service via OSGi DS (`serviceInterface`)
9. Log: `"Capability registered: {capabilityId} v{version} [{provides}]"`

If any check fails:
- Log the specific failure
- Do NOT register the capability
- Do NOT crash the host — other capabilities and the core app continue

### 5.2 Web

1. Host page loads `capabilities/*.json` (or inline registry)
2. Same validation as desktop, skip native library and OSGi steps
3. Register as a JS module available to the activity runtime

### 5.3 Discovery is not trust

A registered capability is available for activities to reference. Registration does NOT mean the capability is trusted to do anything beyond its declared permissions. The host enforces permissions at call time, not just at registration.

---

## 6. Relationship to activity manifest

```
capability.json (developer)    activity.json (teacher)
        |                              |
   "capabilityId": "compute.pari"     "enabledCapabilities": ["compute.pari"]
        |                              |
        v                              v
    Host capability registry  ←→  Activity load-time validation
```

The activity manifest says "I need compute.pari". The host checks "is compute.pari registered?" If yes, the activity loads. If no, the activity refuses to load (if `failureMode` is `block`) or loads with degraded features (if `degrade`).

---

## 7. Scenario mapping

| Scenario | Requirement | This spec |
|---|---|---|
| **D-06** | Good bundle registered, bad bundle rejected | §5.1 — registration with validation |
| **D-08** | Incompatible version ranges | §3 `hostApiRange` — host refuses if out of range |
| **D-09** | Unsigned/unapproved jar not loaded | §5.1 step 6 — permissions not in allowlist |
| **X-03** | Missing capability → fail closed | §6 — `failureMode: "block"` |
| **X-05** | Capability available on desktop but not web | §3 `runtime` field — `desktop` vs `both` |
| **W-03** | Approved/missing/incompatible web modules | §5.2 — web registration with same checks |

---

*End of `Spec_Capability_Descriptor_CLAUDE_V1.md`.*
