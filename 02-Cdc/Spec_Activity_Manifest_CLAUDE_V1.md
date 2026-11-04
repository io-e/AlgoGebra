<!-- CLAUDE_V1 -->
# Specification — Activity Manifest Contract

| Field | Value |
|---|---|
| Document | `02-Cdc/Spec_Activity_Manifest_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Status | **Draft** — ready for review |
| Depends on | `Schema_Course_JSON_CLAUDE_V1_2.json`, `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md`, `Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md` §4 |

---

## 1. Purpose

An activity manifest is the declarative file that tells the AlgoGebra host **what a teacher-authored activity needs** before the student session starts. It links the course content to the GeoGebra baseline, declares which capabilities are required, sets permissions, and names the evaluation schema.

The manifest is read-only at runtime. The host validates it at load time and refuses to start if a required capability is missing or the GeoGebra baseline is incompatible.

---

## 2. File location and naming

```
<activity_dir>/
├── activity.json          ← this manifest
├── course.json            ← course tree (Schema_Course_JSON_CLAUDE_V1_2.json)
├── figures/               ← .ggb files referenced by course.json
│   ├── triangle_01.ggb
│   └── derivation_02.ggb
└── help/                  ← help templates (optional)
    └── step1_hint.json
```

The manifest is always `activity.json` at the root of the activity directory.

---

## 3. Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://geogebraplus.local/schemas/activity/v1",
  "title": "AlgoGebra Activity Manifest",
  "type": "object",
  "required": [
    "manifestVersion",
    "activityId",
    "courseFile",
    "geoGebraBaseline"
  ],
  "additionalProperties": false,
  "properties": {
    "manifestVersion": {
      "type": "string",
      "const": "1.0",
      "description": "Manifest schema version."
    },
    "activityId": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9_-]{2,63}$",
      "description": "Unique identifier for this activity. Lowercase, 3-64 chars, starts with letter."
    },
    "title": {
      "type": "string",
      "maxLength": 200,
      "description": "Human-readable activity title. Falls back to course.json 'course' field if absent."
    },
    "courseFile": {
      "type": "string",
      "default": "course.json",
      "description": "Relative path to the course tree file within this activity directory."
    },
    "geoGebraBaseline": {
      "type": "object",
      "required": ["commit", "versionString"],
      "additionalProperties": false,
      "properties": {
        "commit": {
          "type": "string",
          "pattern": "^[0-9a-f]{7,40}$",
          "description": "Git commit hash of the GeoGebra source pin. Short or full."
        },
        "versionString": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+\\.\\d+$",
          "description": "GeoGebra VERSION_STRING this activity was tested against."
        }
      },
      "description": "Pinned GeoGebra version this activity requires."
    },
    "figures": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["file"],
        "additionalProperties": false,
        "properties": {
          "file": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_/-]+\\.ggb$",
            "description": "Relative path to the .ggb file from activity root."
          },
          "sha256": {
            "type": "string",
            "pattern": "^[0-9a-f]{64}$",
            "description": "SHA-256 hash of the .ggb file. Host verifies at load time if present."
          }
        }
      },
      "description": "GeoGebra construction files used by this activity."
    },
    "enabledCapabilities": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-z][a-z0-9._-]{2,63}$"
      },
      "uniqueItems": true,
      "description": "Capability IDs this activity requires. The host checks each is available and allowed. See Spec_Capability_Descriptor_CLAUDE_V1.md."
    },
    "permissions": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "evalCommand": {
          "type": "boolean",
          "default": false,
          "description": "Whether the activity may call evalCommand() on the GeoGebra API. Privileged — only teacher-authored steps should need this."
        },
        "externalCompute": {
          "type": "boolean",
          "default": false,
          "description": "Whether the activity invokes external computation engines."
        },
        "fileAccess": {
          "type": "string",
          "enum": ["none", "read-figures", "read-write-session"],
          "default": "read-figures",
          "description": "File system access level. 'none' = no file I/O. 'read-figures' = can read .ggb files. 'read-write-session' = can also write session state."
        },
        "networkAccess": {
          "type": "boolean",
          "default": false,
          "description": "Whether the activity needs network access (e.g., WIMS submission in connected mode)."
        }
      },
      "description": "Permissions the host grants to this activity. Principle of least privilege: only declare what's needed."
    },
    "evaluationSchemaRef": {
      "type": "string",
      "description": "Reference to the WIMS evaluation schema this activity targets. Format: '<schema_name>-v<version>', e.g. 'alphavalon-eval-v1'. Absent means offline-only (no WIMS submission)."
    },
    "wimsClassRef": {
      "type": "string",
      "description": "Optional WIMS class identifier for connected mode. Format: '<server>/<class_id>'. Absent in standalone mode."
    },
    "metadata": {
      "type": "object",
      "additionalProperties": true,
      "properties": {
        "author": { "type": "string" },
        "createdAt": { "type": "string", "format": "date" },
        "tags": {
          "type": "array",
          "items": { "type": "string" }
        },
        "difficulty": {
          "type": "string",
          "enum": ["beginner", "intermediate", "advanced"]
        }
      },
      "description": "Informational metadata. Not used by the host for loading decisions."
    }
  }
}
```

---

## 4. Host validation at load time

The host reads `activity.json` and runs these checks before creating a student session:

| Step | Check | On failure |
|---|---|---|
| 1 | JSON parses and validates against schema | Error: "Invalid activity manifest" |
| 2 | `manifestVersion` is supported | Error: "Unsupported manifest version {v}" |
| 3 | `courseFile` exists and validates against `Schema_Course_JSON_CLAUDE_V1_2.json` | Error: "Course file missing or invalid" |
| 4 | `geoGebraBaseline.versionString` matches the running GeoGebra | Warning if minor mismatch; error if major mismatch |
| 5 | Each `figures[].file` exists; `sha256` matches if present | Error: "Figure file missing or corrupt: {file}" |
| 6 | Each `enabledCapabilities[]` is registered and available | Error: "Missing capability: {id}" |
| 7 | `permissions` do not exceed host policy | Error: "Permission denied: {permission}" |
| 8 | `evaluationSchemaRef` exists in WIMS if connected mode | Warning: "Evaluation schema not found" (still loads in offline mode) |

All checks pass → host creates `SessionState` and starts the course tree.

---

## 5. Relationship to course.json

The manifest wraps the course file:

```
activity.json  →  declares WHAT the activity needs
course.json    →  declares WHAT the student sees and does
```

`course.json` is content (chapters, steps, checks). `activity.json` is policy (capabilities, permissions, baseline). A single `course.json` could be used by multiple activities with different permissions (e.g., one with external compute, one without).

---

## 6. Versioning

`manifestVersion` is `"1.0"` for all features in this spec. Future fields are additive — a `"1.0"` manifest remains valid when the host supports `"1.1"`. A breaking change (removing or renaming a required field) bumps to `"2.0"`.

---

## 7. Scenario mapping

| Scenario | Requirement | This spec |
|---|---|---|
| **X-01** | Activity loads with external compute | §3 `permissions.externalCompute`, §4 validation step 6–7 |
| **X-03** | Capability missing → fail closed | §4 step 6 |
| **D-06** | Extension bundle registered → capability available | §3 `enabledCapabilities[]` |
| **P-01** | Clean product, no extension | Manifest with empty `enabledCapabilities[]` |

---

*End of `Spec_Activity_Manifest_CLAUDE_V1.md`.*
