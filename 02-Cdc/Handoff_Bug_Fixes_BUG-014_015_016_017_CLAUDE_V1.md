<!-- CLAUDE_V1 -->
# Handoff — Bug Fixes: BUG-014, BUG-015, BUG-016, BUG-017

| Field | Value |
|---|---|
| Document | `02-Cdc/Handoff_Bug_Fixes_BUG-014_015_016_017_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-01 |
| From | Claude (architecture) |
| To | **Codex** (BUG-014, BUG-015, BUG-016) / **Grok Bot** (BUG-017) |
| Priority | BUG-014 is **critical** (blocks Gate B, WP2-06, course tree host integration) |

---

## BUG-014 — `evalCommand` returns false in RCP product for valid expressions

### Severity: HIGH — Critical path blocker

### Symptom

`evalCommand` returns `false` and a modal "Please check your input" / "CAS.GeneralErrorMessage" dialog appears for these valid expressions in the RCP product, while the **same pinned upstream desktop** (`5.4.934.0`, same JDK) returns `true`:

| Expression | Type | Scenario |
|---|---|---|
| `f(x)=x^2-2x` | Function definition | P-02 ALG-03 |
| `m={{1,2},{3,4}}` | Matrix definition | P-02 ALG-05 |
| `f(x)=a x^2-1` | Parameterized function | P-04 |
| `Plane(A,B,(1,0,0))` | 3D construction | P-02 G3-03 |

**Reproduced on both Windows and Debian** — systemic, not platform-specific.

### Leading hypothesis (unconfirmed)

OSGi classloader visibility of GeoGebra command-processing resources. The upstream desktop runs on a flat classpath; the RCP product wraps everything in OSGi bundles. If `CommandDispatcher` or `AlgebraProcessor` cannot find their resources through the bundle classloader, commands fail silently.

### Investigation path — what to check

#### 1. Command resolution chain

The call path is:
```
GgbAPI.evalCommand(String)                     // common/plugin/GgbAPI.java:239
  → evalCommandGetLabels(String)               // GgbAPI.java:252
    → kernel.getAlgebraProcessor()
      .processAlgebraCommand(string, false)     // AlgebraProcessor.java:770
        → parser.parseGeoGebraExpression(cmd)   // AlgebraProcessor.java:918
        → processAlgebraCommandNoExceptionHandling(ve, ...)  // AlgebraProcessor.java:946
          → CommandDispatcher.getProcessor(c)   // CommandDispatcher.java:275
            → cmdTable.get(cmdName)             // CommandDispatcher.java:300
            → commandTableSwitch(c)             // CommandDispatcher.java:303
              → Commands.valueOf(cmdName)        // CommandDispatcher.java:341
```

**Key question:** Does `Commands.valueOf(cmdName)` succeed in the OSGi classloader? `Commands` is an enum in `common` — it should be visible. But the command name arriving at the dispatcher may be **localized** or **untranslated**.

#### 2. Localization / command name translation

`Localization.getReverseCommand(String)` at `Localization.java:941` translates a localized command name to an internal name using `translateCommandTable`. If `translateCommandTable` is null (not initialized), it falls back to `Commands.lookupInternal(key)`.

**Check:** In the RCP product, is `Localization.initTranslateCommand()` called during startup? In the upstream desktop, it's called as part of the language initialization. If the OSGi host skips that path, `translateCommandTable` is null and any non-English-internal command name would fail.

For `f(x)=x^2-2x`, the parser produces an expression, not a named command — this is an assignment, not a `Command` object. So the `CommandDispatcher` path may not apply. Instead, look at:

#### 3. AlgebraProcessor expression parsing

For `f(x)=x^2-2x`:
- `parser.parseGeoGebraExpression()` at `AlgebraProcessor.java:520` parses the input
- The result is a `ValidExpression` with a function definition
- `processValidExpression()` at `AlgebraProcessor.java:987` handles it

**Check:** Does the parser find the `x` variable? Does the function factory exist? The parser uses string resources for operator names and error messages — if resource bundles are missing, it may fail.

#### 4. CommandProcessorFactory instances

`CommandDispatcher.commandTableSwitch()` at line 338 dispatches to factories:
```java
// line 416: getScriptingCommandProcessorFactory()
// line 527: getAdvancedCommandProcessorFactory()
// line 699: getBasicCommandProcessorFactory()
// line 876: getStatsCommandProcessorFactory()
// line 891: getDiscreteCommandProcessorFactory()
// line 925: getCASCommandProcessorFactory()
// line 959: getSpatialCommandProcessorFactory()   ← 3D commands like Plane
```

These are **abstract methods** implemented by `CommandDispatcherJre` (in `common-jre`). The Jre implementation may use `Class.forName()` or service lookup to find processor classes. 

**Check:** Are the processor factory implementations visible through the OSGi classloader? Specifically:
- `getSpatialCommandProcessorFactory()` — needed for `Plane(A,B,(1,0,0))`
- CAS factory — needed for CAS-evaluated expressions

#### 5. Comparison test

Run the same expressions through **both** launch modes from the same machine:
```powershell
# Upstream desktop (flat classpath)
cd D:\ALF_ZGit\G1_Geogebra_Migration
./gradlew -p source/desktop :desktop:run
# In the algebra bar, type: f(x)=x^2-2x

# RCP product (OSGi)
cd D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike
.\launch.ps1
# Same input
```

Add debug logging to `CommandDispatcher.getProcessor()` (line 275) and `AlgebraProcessor.processAlgebraCommand()` (line 770) to trace where the failure occurs. **Do not modify `common`** — add the logging in the host bundle's ScenarioScript or a diagnostic wrapper.

### Acceptance criteria

- [ ] Root cause identified and documented
- [ ] Fix implemented (in host bundle or OSGi configuration — NOT in `common`)
- [ ] All four expressions return `true` from `evalCommand` in the RCP product
- [ ] P-02 and P-04 scenario scripts pass
- [ ] No regressions in existing passing scenarios (D-02, D-03, D-05)

### Evidence required

Date, commit, OS, Java version, product revision, command, expected vs actual, log path.

---

## BUG-015 — PARI engine returns OK with empty text for malformed input

### Severity: MEDIUM

### Symptom

Input `factor((` (malformed — unbalanced parenthesis) sent to the PARI/GP engine returns a successful `ComputeResult` with empty text instead of an `ExternalComputeException`.

### Root cause analysis

File: `03-RCP-Spike/engines/pari/src/org/geogebra/plus/engine/pari/PariGPEngine.java`

The `validateCommand()` method (line 101) checks for WIMS-blocked terms and escape commands, but does **not** validate expression syntax (balanced parentheses, etc.). That's by design — syntax validation is delegated to `gp` itself.

The problem is in `createResult()` (line 161) → `parseOutput()` (line 168):
- `gp` receives `factor((` and prints an error like `***   at top-level: factor((`
- The error line starts with `***`, not `? ` (a prompt)
- `parseOutput()` only collects text after `? ` prompts — it silently drops error messages
- Result: empty text, no error thrown

### Fix location

`PariGPEngine.java`, method `createResult()` or `parseOutput()`:

1. **Option A (recommended):** After `parseOutput`, if the result is empty AND the raw stdout contains `***` (GP error indicator), throw an `ExternalComputeException(Code.ENGINE_ERROR, <the error line>)`.

2. **Option B:** In `parseOutput`, detect `***` lines and collect them as error text.

### Key code

```java
// PariGPEngine.java:161-166
@Override
protected ComputeResult createResult(Request request, ProcessOutput output, Duration elapsed)
        throws ExternalComputeException {
    return ComputeResult.text(getEngineId(),
            parseOutput(extractOrFail(output.stdout(), request.markers())), elapsed);
    // ← If parseOutput returns empty, should check for GP error lines in stdout
}
```

### Acceptance criteria

- [ ] `factor((` throws `ExternalComputeException` with `Code.ENGINE_ERROR` containing the GP error text
- [ ] Other malformed inputs (e.g., `1/0`, `factor(`, `)`) also return typed errors
- [ ] Valid inputs still return correct results
- [ ] X-06 scenario passes
- [ ] Existing PARI tests in `PariEngineTests.java` still pass

---

## BUG-016 — Clean rebuild not byte-identical

### Severity: MEDIUM

### Symptom

A clean rebuild (`build.sh` into a fresh folder) produces JARs and `config.ini` that differ from the previous build. 11 files differ, primarily due to embedded timestamps.

### Root cause

JAR files embed creation timestamps in their manifests and ZIP entry headers. `config.ini` may include generation timestamps.

### Fix location

`03-RCP-Spike/build.ps1` (or `build.sh` on Linux):

1. **JAR timestamps:** Use `--date=` or equivalent to set a fixed timestamp when creating JARs. Alternatively, post-process JARs with `strip-nondeterminism` or set `SOURCE_DATE_EPOCH`.
2. **config.ini:** If generated, strip or fix the date line.

### Acceptance criteria

- [ ] Two consecutive clean builds produce byte-identical output
- [ ] O-03 scenario passes the reproducibility check

---

## BUG-017 — Linux image has no bundled Java; launch.sh hard-codes paths

### Severity: MEDIUM — **Grok Bot lane**

### Symptom

The Linux image has no bundled JDK. `launch.sh` falls back to `/workspace/AlgoGebra/jdk/jdk-25*` (a hard-coded Codex workspace path), which does not exist on a real Debian machine.

### Fix location

`03-RCP-Spike/launch.sh` (or equivalent Linux launcher):

1. Check `JAVA_HOME` environment variable first
2. Check common JDK install paths (`/usr/lib/jvm/java-*`, `/opt/java/`)
3. Check the product's own `jdk/` subdirectory (for a bundled JDK)
4. Fail with a clear error message if no JDK is found — exit **69** (EX_UNAVAILABLE), same as launch.ps1 (owner Q1, issue #17, 2026-11-02)

### Acceptance criteria

- [ ] `launch.sh` works on a standard Debian installation with `java` on PATH
- [ ] `launch.sh` works with `JAVA_HOME` set explicitly
- [ ] D-10 scenario passes on Debian
- [ ] Error message is clear when no JDK is found

### Note

This is **Grok Bot's lane** (Linux packaging). Codex should not modify `launch.sh` for Linux — only for Windows `launch.ps1`.

---

## Priority order

1. **BUG-014** (Codex) — critical path, blocks Gate B and course tree
2. **BUG-015** (Codex) — medium, blocks X-06, straightforward fix
3. **BUG-017** (Grok Bot) — medium, blocks D-10 on Linux
4. **BUG-016** (Codex) — medium, blocks O-03, lower priority

---

## Constraints reminder

- **`common` is untouchable.** All fixes must be in the host bundle, engine code, build scripts, or OSGi configuration.
- **No upstream edits.** If BUG-014 turns out to require a change in `common`, **stop** and report back. Allowed outcomes: change the host, revise the no-fork rule, or cut scope.
- Each fix must be committed with evidence (date, commit, OS, Java, command, expected vs actual, log path).
