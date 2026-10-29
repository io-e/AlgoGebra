# GROK_V1_1

# Gate decision update: D-05 native loading

Date: 2026-10-29. Supersedes the D-05 section of `Gate_Decision_D-04_D-05_GROK_V1.md`. D-04 is unchanged.

Evidence: installed image `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r3`, log `logs/rcp-20261029-073727-5656-eee96ccd.log`, command `.\launch.ps1 -NoBuild` with neither `-ManualNativeFallback` nor `-BootDelegateJogAmp`. Code read: `GiacNativeBootstrap`, `GeoGebraPlusGlueGenNativeBootstrap`, `GeoGebraPlusJoglNativeBootstrap`.

## Decision

Accept the three product-local fragments as the Equinox native architecture. Do not require `NativeLibClassPathLoader` to run under Equinox.

The fragments do the same job as that upstream loader: find the DLL resource, extract it, call `System.load` from the class loader that owns the JNI methods. `source/shared/common` stays unmodified. Forcing the upstream class to load would mean editing `common` or adding class-loader tricks with no functional gain.

D-05 native loading is **PASS** on Windows x86_64, Java 25, Equinox 3.24.300:

- Boot delegation reported null.
- GIAC: `javagiac64.dll` loaded, `1+1 -> 2`, `Expand[(x+1)^2] -> x^2+2x+1`.
- GlueGen: `gluegen_rt.dll` loaded.
- JOGL: `nativewindow_awt`, `nativewindow_win32`, `newt_head`, `jogl_desktop`, `jogl_mobile` loaded.
- No `UnsatisfiedLinkError`.
- The 3D command was accepted and the App3D view initialized.

## Limits that remain true

- Natives stay on the application classpath. Only the GIAC bootstrap falls back to the bundle class loader. The JOGL and GlueGen bootstraps throw if `ClassLoader.getSystemResource` is null. Do not describe all three as having that fallback.
- This pass is Windows x86_64 only. Linux and macOS natives are still open.
- The strict run has no screenshot. The earlier picture `evidence/rcp-20261028-235656-23884-34151d6a.png` was taken under boot delegation. It does not prove this loader. A strict-mode screenshot is evidence hygiene, not a reason to reopen the loader decision. Attach it when the next GUI run is captured.
- CAS factory setup by reflection remains a spike adapter, not a public API.
- Gate B is still open. D-04 input, clipboard, and high-DPI are partial, and D-06 has not been run.

The workaround launchers may stay as diagnostics. The product path is `Launch-Strict-Native-Gate.cmd`.
