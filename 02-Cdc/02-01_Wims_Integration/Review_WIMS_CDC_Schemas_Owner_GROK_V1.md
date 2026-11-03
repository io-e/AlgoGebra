<!-- GROK_V1 -->
# Owner / Grok Build review — WIMS CDC schemas (Claude @ 7552af2 / 49d98f9)

| Field | Value |
|---|---|
| Date | 2026-11-03 |
| Scope | Pedagogy/architecture skim + structural schema check |
| Does **not** replace | Grok Bot GV-1..GV-7 technical validation |
| Branch | `feat/grok-sprint3-plan-v1-1` |

## Verdict

**Conditionally accepted** for owner content review and for Grok Bot GV run.

- Q-W9d / help architecture: **OK to treat as decided** pending Grok Bot P0 checks (GV-1, GV-3, GV-4, GV-6).
- Schemas + example: **directionally sound**; one **must-fix** before treating the example as schema-valid.

## Per file

| File | Verdict | Notes |
|---|---|---|
| `QA_WIMS_Integration_Owner_ALF_V2.md` (ALF_V2_3) | **Accept** | Offline-first, wims4win Step 1, help vs grade split, Phase 3 RAG — aligned with Architecture V2 / engines CDC |
| `Schema_Help_Template_JSON_CLAUDE_V1.json` | **Accept with notes** | process/text split, CMD/CAS/VAL-only, engines enum, size caps — good security posture |
| `Schema_Course_JSON_CLAUDE_V1.json` (V1_1 fields) | **Accept with notes** | `help` + `engine` close GAP-1/GAP-2 as decided; `schemaVersion` still `"1.0"` (see below) |
| `Example_Help_Template_CLAUDE_V1.json` | **Fix then accept** | Pedagogically clear; **fails** Draft 2020-12 validation today |
| `Handoff_GrokBot_WIMS_CDC_CLAUDE_V1.md` | **Accept** | Correct GV list; review-only rules match Planning V1_1 |

## Must-fix (P0 for “example is valid”)

`Example_Help_Template_CLAUDE_V1.json` includes a top-level `$comment`, but the help schema sets `additionalProperties: false` and does not list `$comment`.

```
jsonschema: Additional properties are not allowed ('$comment' was unexpected)
```

**Fix (either):** remove `$comment` from the example, **or** add optional `"$comment": { "type": "string" }` to the help (and course) schemas.

Without that, CI/schema tests will reject the canonical example.

## Should-fix / clarify (P1 — do not block owner relecture)

1. **Version labeling:** Course file comment says V1_1 but `schemaVersion` const remains `"1.0"`. Prefer either bump to `"1.1"` or document “fields additive under 1.0”.
2. **Max nesting depth 3:** stated in prose; JSON Schema does not enforce it. Acceptable for V1 if runtime validator enforces depth.
3. **`defaults` ⊆ `variables`:** stated in prose; not enforced by schema.
4. **GAP-5** (richer check types) still open — correctly out of this Q-W9d delivery.
5. **GeoGebra example syntax** `Point({1, g(1)})` and GIAC `Derivative(...)` — leave to Grok Bot / product (GV / suite).

## Security alignment (spot check)

| Rule | Status |
|---|---|
| Help actions CMD/CAS/VAL only (no OPEN/SAVE/PNG) | **OK** |
| Same allowlist / Sequence budget as course actions (stated) | **OK** (runtime must enforce) |
| `trustedGgb` only on course OPEN | **OK** |
| LLM/RAG only via `courseRef` Phase 3 | **OK** |

## Grok Bot (unchanged ask)

Run GV-1..GV-7 → `Handoff_GrokBot_WIMS_CDC_Validation_GROK_V1.md`. No merges, no implementation, no schema edits unless owner asks after findings.

## Owner next

1. Finish pedagogy relecture.  
2. Ask Claude for the `$comment` one-liner fix.  
3. Wait for Grok Bot GV report before freezing the WIMS CDC.
