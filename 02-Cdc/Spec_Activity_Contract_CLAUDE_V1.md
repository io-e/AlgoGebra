<!-- CLAUDE_V1 -->
# Specification — Activity and Compute Contracts (X-01 / X-02)

| Field | Value |
|---|---|
| Document | `02-Cdc/Spec_Activity_Contract_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Scenarios | X-01 (compute contract), X-02 (revision/stale-result), X-04 (external compute → kernel) |
| Status | **Draft** — ready for review |
| Depends on | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` (engine layer), `Schema_Course_JSON_CLAUDE_V1_2.json` |

---

## 1. Overview

The activity contract defines how the AlgoGebra host interacts with external computation engines and with the GeoGebra kernel. Three interactions:

1. **Compute request** — host sends a command to an engine, gets a result
2. **Result write** — host writes the result into the GeoGebra construction (one-shot)
3. **Check** — host evaluates the student's answer against expected values

This spec covers #1 and #2. Check evaluation is specified in WIMS CDC V2 §WI-31.

---

## 2. Compute request/response (X-01)

### 2.1 Request

```java
public interface ExternalComputeService {
    ComputeResult eval(String command, ComputeContext ctx)
        throws ExternalComputeException;
    Set<ComputeCapability> getCapabilities();
    boolean isAvailable();
}
```

**`ComputeContext`** carries:

| Field | Type | Required | Purpose |
|---|---|---|---|
| `engine` | `String` | Yes | Engine identifier: `pari`, `maxima`, `gnuplot`, `gap`, `geogebra-cas` |
| `timeout` | `Duration` | No (default 10s) | Maximum wall-clock time before process kill |
| `precision` | `int` | No (default 38) | Numeric precision (digits) for Pari `\p` / Maxima `fpprec` |
| `seed` | `long` | No | Random seed for reproducible results |
| `locale` | `Locale` | No (default `en`) | Locale for GeoGebra command resolution |
| `variables` | `Map<String, String>` | No | Variable substitution for `{{name}}` placeholders |

### 2.2 Response

```java
public class ComputeResult {
    public enum Kind { STRING, IMAGE, ERROR }
    
    private final Kind kind;
    private final String textResult;    // for STRING
    private final byte[] imageData;     // for IMAGE (PNG)
    private final String mimeType;      // "text/plain" or "image/png"
    private final Duration elapsed;
    private final String engineVersion; // e.g. "GP/PARI 2.17.1"
}
```

| Kind | When | Content |
|---|---|---|
| `STRING` | Pari, Maxima, GAP, GeoGebra CAS | Post-parser text result |
| `IMAGE` | Gnuplot | PNG bytes (validated magic bytes) |
| `ERROR` | Any failure | Error message with code |

### 2.3 Error codes

```java
public class ExternalComputeException extends Exception {
    public enum Code {
        ENGINE_UNAVAILABLE,   // Binary not on PATH
        COMMAND_REJECTED,     // Security filter match
        TIMEOUT,              // Process killed after deadline
        EMPTY_OUTPUT,         // Valid input but no output (BUG-015)
        PARSE_ERROR,          // Engine returned unparseable output
        ENGINE_ERROR          // Engine reported an error in its own format
    }
}
```

**Error contract:**
- `ENGINE_UNAVAILABLE`: message names the engine and lists checked paths
- `COMMAND_REJECTED`: message names the blocked command/pattern
- `TIMEOUT`: process is `destroyForcibly()`-ed, message includes the timeout value
- `EMPTY_OUTPUT`: valid command produced no stdout — treated as error, not empty success

---

## 3. Result write into kernel (X-04)

### 3.1 One-shot write pattern

An external computation result is written into the GeoGebra construction via the public API. It is **not** an `AlgoElement`. The construction does not auto-update when inputs change.

```java
// Host writes result into GeoGebra
GgbAPI api = scenarioApi2d;
String result = computeResult.getTextResult(); // e.g. "2*x*cos(x^2)"

// Write as a function definition
api.evalCommand("g(x) = " + result);

// Or write as a numeric value
api.evalCommand("A = " + result);
```

### 3.2 Constraints

| Constraint | Rationale |
|---|---|
| No `AlgoElement` subclass | Binding decision: `common` is untouchable |
| No auto-update | External compute is one-shot; use `evalCommand()` for each new evaluation |
| Result is a string or image | No structured object transfer. The host builds the GeoGebra command from the engine result. |
| Security: result is not eval'd raw | The host validates the result format before passing to `evalCommand()`. No arbitrary code injection from engine output. |

### 3.3 Image results (Gnuplot)

Gnuplot produces PNG files. The host:
1. Validates PNG magic bytes (`89 50 4E 47 0D 0A 1A 0A`)
2. Loads the image into a GeoGebra `GeoImage` object via `api.evalCommand("pic1 = ToolImage[...]")` or displays it in a dedicated panel
3. Does NOT pass raw image bytes to `evalCommand`

---

## 4. Stale result handling (X-02)

### 4.1 Problem

When the student modifies the construction (e.g. changes a parameter), results from previous external computations become stale. Since external results are not `AlgoElement`s, GeoGebra has no dependency tracking for them.

### 4.2 Design

| Strategy | When | Behavior |
|---|---|---|
| **Mark stale** | Student modifies a GeoGebra object that was an input to the last compute | Host marks the result display as "stale" (grey text, strikethrough, or badge). No automatic recomputation. |
| **Recompute on demand** | Student clicks "Recompute" or navigates to the step | Host re-sends the compute request with current parameter values. |
| **Never auto-recompute** | Always | External compute is expensive (subprocess spawn). Auto-recompute would be slow and potentially dangerous (security filters re-evaluated on each call). |

### 4.3 Staleness detection

The host tracks which GeoGebra objects were inputs to the last compute result for each step:

```java
public class ComputeResultRecord {
    String stepId;
    Map<String, String> inputValues;  // GeoGebra object name → value at compute time
    ComputeResult result;
    Instant computedAt;
    
    boolean isStale(GgbAPI api) {
        for (var entry : inputValues.entrySet()) {
            String current = api.getValueString(entry.getKey());
            if (!entry.getValue().equals(current)) return true;
        }
        return false;
    }
}
```

The host polls staleness when the step is displayed (not continuously). A `ConstructionUpdatedListener` on the GeoGebra kernel could trigger a check, but polling on step-focus is simpler and avoids overhead.

---

## 5. Sequence budget

External compute commands respect the same Sequence budget as course actions (see `Spec_Course_Security_CLAUDE_V1_2.md`):
- Maximum 20 actions per step
- Maximum 10 help actions per help step
- Maximum total execution time per step: 30 seconds (sum of engine timeouts)

Engine timeout (default 10s per call) counts against the step budget. If 3 engine calls are queued, total timeout budget is 30s.

---

## 6. Scenario mapping

| Scenario | Requirement | This spec |
|---|---|---|
| **X-01** | Compute contract: request/response types, error codes | §2 — `ExternalComputeService`, `ComputeResult`, `ComputeException` |
| **X-02** | Revision/stale-result handling | §4 — mark stale, recompute on demand, never auto-recompute |
| **X-04** | External compute → kernel (one-shot write) | §3 — `evalCommand()` pattern, no `AlgoElement` |
| **X-06** | Malformed input error handling (BUG-015) | §2.3 — `EMPTY_OUTPUT` error code |

After implementation, X-01 moves from PARTIAL to PASS. X-02 moves from FAIL to PASS.

---

*End of `Spec_Activity_Contract_CLAUDE_V1.md`.*
