<!-- CLAUDE_V1 -->
# Handoff — CourseModel V1_2 Upgrade + CheckEvaluator (Codex)

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_CourseModel_V1_2_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Assigned to | **Codex** |
| Priority | **Normal** — WIMS integration backbone, no Gate B dependency |
| Branch | Create `feat/course-model-v1_2` from current tip |
| Schema | `02-Cdc/Schema_Course_JSON_CLAUDE_V1_2.json` |
| Existing code | `03-RCP-Spike/host/src/org/geogebra/plus/course/` |

---

## 1. Current state

The course model classes already exist and parse Schema V1_1:

| File | What it does | V1_2 change needed |
|---|---|---|
| `CourseModel.java` | Parses JSON, validates schema, builds tree | Add `variants[]`, `help`, `engine`, `gradable` to allowed keys and parsing |
| `CourseNode.java` | Immutable record: `Kind`, `CheckType` enum (4 types), `Check` record | Extend `CheckType` to 8 types, add `engine`, `gradable`, `help` fields |
| `CourseAction.java` | Immutable record: `Directive`, `Target`, `value`, `trustedGgb` | No change |
| `CourseTreePanel.java` | SWT `TreeViewer` wiring | Add step badges (visited/passed/failed), help panel trigger |
| `DirectiveExecutor.java` | Executes actions against GgbAPI | Add `engine_check` delegation |
| `StepValidator.java` | Runs check against GeoGebra state | Extend for 4 new check types |

## 2. Task C-4: Extend CourseModel for Schema V1_2

### 2.1 `CourseNode.java` changes

**Extend `CheckType` enum:**

```java
public enum CheckType {
    VALUE_EQUALS("value_equals"),
    VALUE_RANGE("value_range"),
    OBJECT_EXISTS("object_exists"),
    CAS_EQUALS("cas_equals"),
    CHOICE_EQUALS("choice_equals"),       // NEW
    SEQUENCE_EQUALS("sequence_equals"),   // NEW
    SET_EQUALS("set_equals"),             // NEW
    ENGINE_CHECK("engine_check");         // NEW
    // ... rest unchanged
}
```

**Extend `Check` record — add `mode`, `precision`, `engineCommand`:**

```java
public record Check(CheckType type, String variable, Object expected,
        double tolerance, String mode, Integer precision, String engineCommand,
        CourseAction.Target target, String passFeedback, String failFeedback) {
    // expected can also be List<String> for choice/sequence/set types
}
```

**Add new fields to the step:**

```java
// In CourseNode record
public record CourseNode(Kind kind, String title, String description,
        List<CourseAction> actions, Check check, List<CourseNode> children,
        HelpRef help, String engine, boolean gradable) {
    // engine defaults to "geogebra-cas"
    // gradable defaults to true
}
```

**Add `HelpRef` record:**

```java
public record HelpRef(String template, Map<String, String> inline,
        Map<String, Object> variables) {
    // template XOR inline must be present
}
```

### 2.2 `CourseModel.java` changes

**ROOT_KEYS:** Add `"variants"` to the allowed set.

**STEP_KEYS:** Add `"help"`, `"engine"`, `"gradable"`.

**CHECK_KEYS:** Add `"mode"`, `"precision"`, `"engineCommand"`.

**Parse `variants[]`:** New field on CourseModel:

```java
private final List<Map<String, Object>> variants; // may be null (no variants)
```

Parse from root JSON: array of objects, each with at least `"seed"` (integer).

**Parse `engine`:** String field on step, default `"geogebra-cas"`. Validate against enum: `geogebra-cas`, `pari`, `maxima`, `gnuplot`, `gap`, `octave`, `yacas`, `m2`, `scilab`.

**Parse `gradable`:** Boolean field on step, default `true`.

**Parse `help`:** Object with either `template` (string) or `inline` (locale→string map). Optional `variables` map.

## 3. Task C-5: CheckEvaluator

Create `03-RCP-Spike/host/src/org/geogebra/plus/course/CheckEvaluator.java`:

```java
public class CheckEvaluator {
    public CheckResult evaluate(CourseNode.Check check, GgbAPI api,
            ExternalComputeService engine) {
        return switch (check.type()) {
            case VALUE_EQUALS -> evalValueEquals(check, api);
            case VALUE_RANGE -> evalValueRange(check, api);
            case OBJECT_EXISTS -> evalObjectExists(check, api);
            case CAS_EQUALS -> evalCasEquals(check, api);
            case CHOICE_EQUALS -> evalChoiceEquals(check, api);
            case SEQUENCE_EQUALS -> evalSequenceEquals(check, api);
            case SET_EQUALS -> evalSetEquals(check, api);
            case ENGINE_CHECK -> evalEngineCheck(check, api, engine);
        };
    }
}
```

**Per-type logic:**

| Type | Logic |
|---|---|
| `value_equals` | Get `api.getValue(variable)`. If `mode=absolute`: `|actual - expected| <= tolerance`. If `mode=relative`: `|actual - expected| / |expected| <= tolerance`. If `precision` set: compare rounded to N sig-figs. |
| `value_range` | Get numeric value, check `min <= actual <= max` |
| `object_exists` | `api.exists(variable)` returns true/false |
| `cas_equals` | `api.evalCommandCAS("Simplify(" + actual + " - " + expected + ")")` → check result is `"0"` |
| `choice_equals` | Compare student's selected option(s) with expected `List<String>`. Order doesn't matter for multi-choice. |
| `sequence_equals` | Compare ordered `List<String>` — order matters |
| `set_equals` | Compare as sets (unordered, no duplicates) |
| `engine_check` | Substitute `{{answer}}` in `engineCommand` with student answer. Send to engine. Compare result with `expected`. |

**`CheckResult` record:**

```java
public record CheckResult(boolean passed, String feedback) {}
```

## 4. Task C-6: Help template loader

Create `03-RCP-Spike/host/src/org/geogebra/plus/course/HelpTemplateLoader.java`:

- Read JSON file matching `Schema_Help_Template_JSON_CLAUDE_V1.json` (V1_2)
- Resolve `{{variable}}` placeholders from variant data + step variables
- Build a tree model (`HelpStep` records) for display
- `engine` field on help steps maps to the step's engine (default `geogebra-cas`)

## 5. Test fixtures

Use existing example files for tests:

| Fixture | Path | Tests |
|---|---|---|
| Course schema V1_2 | `02-Cdc/Schema_Course_JSON_CLAUDE_V1_2.json` | Schema validation |
| Help template schema | `02-Cdc/02-01_Wims_Integration/Schema_Help_Template_JSON_CLAUDE_V1.json` | Help loader |
| Help example | `02-Cdc/02-01_Wims_Integration/Example_Help_Template_CLAUDE_V1.json` | Variable injection |

**New test fixtures to create:**

| File | Content |
|---|---|
| `test/fixtures/course_v1_2_basic.json` | Minimal course with 1 chapter, 2 steps, one `value_equals` check, one `engine_check` |
| `test/fixtures/course_v1_2_variants.json` | Course with `variants[]` (3 variants, 2 parameters each) |
| `test/fixtures/course_v1_2_gradable_false.json` | Course with `gradable: false` step |
| `test/fixtures/course_v1_2_all_checks.json` | One step per check type (8 total) |

## 6. Test matrix

| Test ID | What | Expected |
|---|---|---|
| **T-CM-01** | Parse V1_1 course JSON (backward compat) | Loads successfully, `engine` defaults to `geogebra-cas`, `gradable` defaults to true |
| **T-CM-02** | Parse V1_2 course with all new fields | All fields populated correctly |
| **T-CM-03** | Parse `variants[]` | 3 variants loaded, each with `seed` and parameters |
| **T-CM-04** | Parse `gradable: false` step | `node.gradable() == false` |
| **T-CM-05** | Parse `engine: "pari"` step | `node.engine().equals("pari")` |
| **T-CM-06** | Parse unknown engine → error | `CourseFormatException` |
| **T-CM-07** | `value_equals` with `mode: relative` | Relative tolerance comparison works |
| **T-CM-08** | `choice_equals` with multi-option | Set comparison ignores order |
| **T-CM-09** | `engine_check` with mock engine | Delegates to engine, compares result |
| **T-CM-10** | Help template load + variable injection | `{{a}}` replaced with variant value |

## 7. What NOT to do

- Do **not** implement the SWT tree panel changes yet (that's C-7, depends on this)
- Do **not** implement session state save/resume (separate spec)
- Do **not** change the course tree security validation (`StepValidator`) — only extend `CheckEvaluator`
- Do **not** touch `common` or GeoGebra upstream source
- Do **not** implement WIMS connected mode or submission

## 8. Deliverables

| # | File | What |
|---|---|---|
| 1 | `CourseNode.java` (modified) | 4 new `CheckType` values, `HelpRef`, `engine`, `gradable` |
| 2 | `CourseModel.java` (modified) | Parse `variants[]`, `help`, `engine`, `gradable`, extended check keys |
| 3 | `CheckEvaluator.java` (new) | 8 check type strategies |
| 4 | `HelpTemplateLoader.java` (new) | JSON parser + variable injection |
| 5 | `HelpStep.java` (new) | Immutable help tree node record |
| 6 | Test fixtures + unit tests | T-CM-01..T-CM-10 |

---

*End of `Handoff_Codex_CourseModel_V1_2_CLAUDE_V1.md`.*
