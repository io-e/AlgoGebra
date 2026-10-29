# GROK_V1

# GIAC decisions for AlgoGebra RCP

Date: 2026-10-29.

Fills the open choices in `02-Cdc\Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md`. That CDC stays the anatomy note. Where it disagrees with this file or with `03-RCP-Spike\Gate_Decision_D-04_D-05_GROK_V1_1.md`, this file wins.

## D-GIAC-01 — Accept the product-local loader

**Choice: A.** `GiacNativeBootstrap`, as a fragment of the `giac-jni` bundle, is the Equinox loader.

`NativeLibClassPathLoader` is not required. Copying it into the fragment (option C) is rejected. `source/shared/common` and upstream `desktop` sources stay unmodified.

This was already accepted for D-05 native loading on image `GeoGebraPlus-RCP-0.1.0-win32-x86_64-r3`, strict launch, log `rcp-20261029-073727-5656-eee96ccd`. A later strict launch on 2026-10-29 (`rcp-20261029-085020-16004-1b40c343`) showed the same loads with boot delegation null.

Correction to the CDC: the native JARs are on the application classpath, so `ClassLoader.getSystemResource` does see `javagiac64.dll`. The upstream loader fails only if the DLL is hidden inside a bundle. Do not move the native JAR into the bundle without adding a bundle-resource fallback. Today only the GIAC bootstrap has that fallback. JOGL and GlueGen do not, and they are outside this decision.

## D-GIAC-02 — Wire the CAS factory from the desktop wrapper

**Choice: C.** The OSGi wrapper around `desktop` gets a `BundleActivator` that calls `CASFactory.setPrototype(new CASFactoryD())` on start.

The activator is new wrapper code. It is not a patch to upstream `CASFactoryD.java` or `AppD.java`. The host bundle does not import `org.geogebra.desktop.factories` and does not call `setPrototype` by reflection.

Start order: the `giac-jni` fragment loads the DLL before this activator constructs `CASgiacD`. If the first CAS call still returns `?`, the activator ran too late and the start level changes. That is a defect, not a reason to put the call back in the host.

Declarative Services (option B) is rejected for this one registration.

## D-GIAC-03 — Cache the DLL under the product directory

**Choice: C as a hardening step, not as a condition for D-05.**

Extract `javagiac64.dll` to `<product>/natives/cache/5.4.934.0/` and reuse the file when the size matches. Do not delete it while the process is running. A crash may leave the file. That is acceptable.

The current temp-directory extract already satisfies D-05. G-01, G-03, and G-04 are met by the strict logs. G-06 (missing DLL falls back to `CASFactoryDummy`) and the cache directory are the next Codex change. They do not reopen the loader decision.

## What is not accepted from the CDC

- Section 9 still says the owner review is open. It is closed by `Gate_Decision_D-04_D-05_GROK_V1_1.md` and by D-GIAC-01 above.
- The printed GIAC result in the strict log is `x^2+2x+1`, after GeoGebra normalization. Do not require the raw form `x^2+2*x+1` as the acceptance string.
- G-02, G-05, and G-06 are not done. D-05 native loading is PASS. The production factory wiring and the error test are still open.
- Gate B stays open until D-04 input, clipboard, and high-DPI are resolved and D-06 is run. JOGL has its own gate note. It is not closed by this GIAC choice.
- WebAssembly and `giac.wasm` are out of this MVP.

## Next implementation

1. Desktop-wrapper activator for `CASFactory.setPrototype` (D-GIAC-02).
2. Product-local DLL cache and a missing-DLL log that leaves the dummy CAS in place (D-GIAC-03, G-06).
3. One two-thread evaluation fixture (G-05).
4. Evidence row per V2 section 9. No edit under `source/shared/common/src`.
