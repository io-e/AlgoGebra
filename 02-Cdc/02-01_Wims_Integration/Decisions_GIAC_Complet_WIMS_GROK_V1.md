# GROK_V1

# Decisions: full GIAC integration, WIMS engines kept outside

Date: 2026-10-29.

Goal: GIAC is GeoGebra’s formula engine, so GeoGebraPlus must run it on every client the student uses. WIMS keeps its own engines. They are not a second CAS inside GeoGebra.

## 1. Two stacks, two jobs

| Stack | Job | Where it runs |
|---|---|---|
| GIAC / Xcas | GeoGebra CAS: expand, factor, simplify, the Algebra and CAS views | Inside GeoGebraPlus, desktop and web |
| GAP, PARI/GP, Maxima, Octave | WIMS exercise checking and number-theory or numeric work | WIMS server |
| Gnuplot, POV-Ray, Fly | WIMS pictures | WIMS server |
| TeX | WIMS formula typesetting | WIMS server |
| JOGL | GeoGebra 3D view | GeoGebraPlus desktop. Not GIAC. |

A WIMS activity may call PARI or Maxima to grade an answer. The construction the student edits is still evaluated by GIAC. Do not route `Expand` through Maxima. Do not embed GAP, PARI, Octave, Gnuplot, or POV-Ray in the RCP.

## 2. Full GIAC means both upstream paths

Upstream already has the complete integration. GeoGebraPlus uses it. It does not write a new one.

| Client | Mechanism | Status |
|---|---|---|
| Desktop Windows x86_64 | `javagiac` JNI, DLL from the native jar, `System.load` by absolute path | Accepted. Loader is `GiacNativeBootstrap`. |
| Desktop Linux, then macOS | Same JNI, `libjavagiac64.so` or the `.jnilib` | Required for “complete”. Not started. |
| Web | `CASgiacW` calls `caseval` on `giac.wasm` or `giac.js` | Required for “complete”. Not a new wrapper. The GWT app already contains this class. |

C++ stays in [geogebra/giac](https://github.com/geogebra/giac). This project does not recompile GIAC for the MVP. `common` is not edited.

## 3. What “complete” is, in order

1. Desktop factory wiring and the missing-DLL fallback, already specified in `Decisions_GIAC_AlgoGebra_GROK_V1.md`. Windows JNI stays PASS.
2. The same Windows product opens the CAS view and evaluates through `CASgiacD`, not only through the spike smoke test.
3. Linux JNI with the same fragment pattern and no boot delegation.
4. Web: the existing `CASgiacW` path, same commands, same string result, on the student page. Gate C still chooses whether that page remains the current GWT build. It does not choose a different CAS.

Until step 4, the integration is not complete. Calling Windows-only JNI “the GIAC integration” is false.

## 4. Rejected

- Replacing GIAC with Maxima, PARI, or GAP inside GeoGebra.
- Treating JOGL as part of the formula engine.
- A new Java JNI layer, or a new WASM binding, beside `javagiac` and `caseval`.
- Compiling Bernard Parisse’s C++ inside the RCP build.
- Using the WIMS engines to draw the GeoGebra 2D or 3D view.
