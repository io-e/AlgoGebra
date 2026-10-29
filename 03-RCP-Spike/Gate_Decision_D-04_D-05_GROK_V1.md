# GROK_V1

# Gate decision on the RCP spike

Date: 2026-10-29.

Evidence: `03-RCP-Spike\D-02-D-04-D-05-VALIDATION-REPORT.md`, commit `a821e589ca8a` on `feat/rcp-product-spike`.

Rule used: `02-Cdc\Architecture_GeoGebraPlus_RCP_Web_Validation_GROK_V2.md`, scenarios D-04 and D-05, Gate B.

## D-02

Accepted as PASS. Equinox starts the host `IApplication`, and the 50-bundle set resolves with none unresolved. This does not close Gate B. Gate B still needs D-03 through D-06, including a product-grade native load.

## Decision 1 — D-05 stays open

Yes. D-05 remains **PARTIAL**. Do not close it on this run.

The spike shows that CAS (`Expand[(x+1)^2]` → `x^2+2x+1`) and a rendered 3D point `A=(1,2,3)` work on Windows amd64, Java 25, with no `UnsatisfiedLinkError` in the successful run. That is a functional proof only.

The pass line for D-05 is that GIAC and JOGL load in the RCP product, once, without a special spike path. This run did not meet that line:

- GIAC was preloaded with `System.loadLibrary("javagiac64")` from a spike fragment. `NativeLibClassPathLoader` was not used.
- JOGL passed only after manual DLL extraction, `java.library.path`, `UseTempJarCache=false`, `org.osgi.framework.bootdelegation=com.jogamp.*,jogamp.*`, and `osgi.parentClassloader=app`.

Boot delegation puts JogAmp on the application loader and gives up the OSGi isolation the product is supposed to keep. That needs an explicit packaging decision before anyone calls native loading done. Linux and macOS natives were not run.

Next proof, still under D-05: one launch configuration that loads GIAC through the upstream loader path, or a written replacement if that path cannot work under Equinox, and a JOGL layout that does not require boot delegation. Until that note exists, Gate B stays open.

## Decision 2 — the input warning does not erase the embedding result, and it does block full D-04 sign-off

Keep D-04 split, as the report recommends.

- **Core embedding: PASS.** An SWT shell embedded `GeoGebraPanel`. Algebra View, toolbars, input rows, and 3D content were visible. Maximize resized and redrew. `C=5` was created in the Algebra View.
- **Input / focus: PARTIAL.** Enter also opened “Please check your input”. The object survived dismissing the dialog, so the command was not fully rejected, but a clean submit was not shown. Clipboard and high-DPI were not tested. Return of focus to an SWT control was not tested.

Do not mark the D-04 row PASS in the validation plan. V2 asks for focus, menus, clipboard, and DPI, or a written cost for an SWT rewrite. Those checks are still open. Do not treat the dialog as a kernel defect until the keystrokes and the command that produced it are recorded from the log. It may be a second empty command from the same Enter, an SWT_AWT focus duplicate, or a real parse warning. That is the next D-04 note.

## What this spike is allowed to support

It supports continued RCP work: the unchanged bundle set resolves, Swing can sit in an SWT shell, and CAS/3D can run on this Windows machine with documented workarounds.

It does not support a release claim, removal of the GWT web app, or a product decision that boot delegation is the JOGL design.
