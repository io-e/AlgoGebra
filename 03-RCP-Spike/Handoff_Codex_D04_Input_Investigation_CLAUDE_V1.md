<!-- CLAUDE_V1 -->
# Handoff — D-04 Input/Focus Investigation

| Field | Value |
|---|---|
| Document | `03-RCP-Spike/Handoff_Codex_D04_Input_Investigation_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-04 |
| Assigned to | **Codex** |
| Priority | **Blocker** — D-04 closure required before any interactive dev work |
| Branch | `feat/rcp-product-spike` (spike code) |
| Evidence | `03-RCP-Spike/D-02-D-04-D-05-VALIDATION-REPORT.md` §D-04 |
| Host code | `03-RCP-Spike/host/src/org/geogebra/plus/host/GeoGebraPlusApplication.java` |
| Screenshot | `03-RCP-Spike/evidence/rcp-20261029-000134-9160-c931fe29.png` (warning captured) |

---

## 1. Problem statement

During the D-04 UI smoke test (2026-10-29), typing `C=5` into the GeoGebra input bar and pressing Enter triggered:
- The object `C = 5` **did** appear in the Algebra View (command was processed)
- A **GeoGebra warning dialog** "Please check your input" appeared and had to be dismissed manually

This warning makes the RCP product unusable for interactive work. **All user input goes through this path.**

The warning appeared in run `rcp-20261029-000134-9160-c931fe29`. The command was typed manually — not via `evalCommand()` API.

---

## 2. Hypothesis tree

### H1: SWT↔AWT focus transfer issue (most likely)

**Theory:** SWT's `SWT_AWT.new_Frame()` bridge creates an embedded AWT `Frame`. When the user clicks the GeoGebra input bar (which is a Swing `JTextField` inside the AWT Frame), SWT may not fully release keyboard focus. The Enter key might be dispatched to both the AWT component (GeoGebra processes it) and an SWT listener (which triggers a secondary event that GeoGebra interprets as invalid input).

**Evidence for:** The command was processed (object appeared), but a warning also appeared — suggesting a double-dispatch or a secondary event after the valid one.

**Test:**
1. Add a `java.awt.event.KeyListener` to the GeoGebra input bar component, log all `keyPressed`/`keyReleased`/`keyTyped` events with timestamps and key codes.
2. Add a `FocusListener` on the same component — log `focusGained`/`focusLost` with timestamps.
3. Type `C=5` + Enter. Check:
   - Is Enter dispatched once or twice?
   - Does focus leave the input bar between keyPressed and keyReleased?
   - Is there an SWT `Traverse` event firing on Enter?

**Fix if confirmed:** Add explicit focus management:
```java
twoDComposite.addListener(SWT.Activate, e -> {
    SwingUtilities.invokeLater(() -> {
        // Request focus on the AWT input component
        inputComponent.requestFocusInWindow();
    });
});
```
And/or consume the SWT Traverse event:
```java
twoDComposite.addListener(SWT.Traverse, e -> {
    if (e.detail == SWT.TRAVERSE_RETURN) {
        e.doit = false; // Don't let SWT process Enter
    }
});
```

### H2: GeoGebra locale/initialization issue

**Theory:** `GeoGebraPanel` in the spike is constructed with `enableFullGuiForSpike()` (line 361), which uses reflection. The `AppD` might not be fully initialized when the input bar becomes visible — missing localization, parser not wired, or CAS not ready.

**Evidence for:** The spike calls `enableFullGuiForSpike` after `buildGUI()` but the input bar's `AlgebraInput` component may not be wired to the kernel's `AlgebraProcessor`.

**Test:**
1. Before typing, call `scenarioApi2d.evalCommand("C=5")` programmatically. Does it work without warning?
2. Check `scenarioApp2d.getAlgebraProcessor()` is not null.
3. Log `scenarioApp2d.getLocalization().getLanguage()` — is it initialized?

**Fix if confirmed:** Ensure full initialization sequence runs before showing the shell. The upstream `GeoGebraFrame` calls `AppD.start()` which wires everything; the spike's `GeoGebraPanel` may skip some of that.

### H3: GeoGebra input bar parse error (unlikely)

**Theory:** `C=5` is ambiguous — `C` might conflict with a GeoGebra constant or command name. The parser accepts it but warns.

**Test:** Try `myVar = 5` instead of `C = 5`. If no warning → H3 confirmed (naming conflict). If same warning → H3 eliminated.

---

## 3. Investigation plan

| Step | Action | Time | Deliverable |
|---|---|---|---|
| **INV-01** | Add `KeyListener` + `FocusListener` instrumentation to the input bar component in `GeoGebraPlusApplication.java` | 20 min | Modified spike code with diagnostic logging |
| **INV-02** | Launch RCP, type `C=5` + Enter. Capture the full event log. | 10 min | Log file with timestamped key/focus events |
| **INV-03** | Test programmatic `evalCommand("C=5")` — does it trigger the warning? | 5 min | Log assertion: warning present/absent |
| **INV-04** | Test `myVar=5` manually — is the warning name-specific? | 5 min | Log assertion |
| **INV-05** | If H1 confirmed: add `SWT.Traverse` listener to consume Enter, test again | 15 min | Clean input without warning |
| **INV-06** | If H2 confirmed: trace `AlgebraProcessor` initialization, find the missing wiring | 30 min | Root cause in initialization sequence |
| **INV-07** | Document findings in `D-04-Input-Investigation-Report.md` with evidence per V2 §9 | 15 min | Report file |

**Total estimated time: 1–1.5 hours.**

---

## 4. Acceptance criteria

| ID | Criterion | Evidence |
|---|---|---|
| **D04-FIX-01** | Typing `C=5` + Enter in the input bar creates the object without any warning dialog | Screenshot + log |
| **D04-FIX-02** | Typing `f(x) = x^2` + Enter creates the function and plots it | Screenshot |
| **D04-FIX-03** | Focus transfers cleanly between the SWT course tree panel (left) and the AWT GeoGebra panel (right) | Manual test: click tree node → click input bar → type → Enter → no warning, no focus loss |
| **D04-FIX-04** | Programmatic `evalCommand()` still works unchanged | Existing scenario script passes |

---

## 5. Key code locations

| What | File | Line(s) |
|---|---|---|
| SWT shell + embedded AWT frames | `GeoGebraPlusApplication.java` | 219–274 |
| GeoGebraPanel construction | `GeoGebraPlusApplication.java` | 360–370 |
| `enableFullGuiForSpike()` | `GeoGebraPlusApplication.java` | 599+ |
| GeoGebra input bar component | upstream `org.geogebra.desktop.gui.inputbar.AlgebraInputD` | (in `desktop` module) |
| SWT_AWT bridge | `org.eclipse.swt.awt.SWT_AWT` | (in Equinox SWT) |

---

## 6. What NOT to do

- Do **not** modify `common` or `desktop` upstream source.
- Do **not** change the SWT_AWT embedding approach (it works — the issue is focus/event handling).
- Do **not** add workarounds that suppress the GeoGebra warning dialog — find the root cause.
- Do **not** merge this into `main` — keep on `feat/rcp-product-spike` or a child branch.

---

*End of `Handoff_Codex_D04_Input_Investigation_CLAUDE_V1.md`.*
