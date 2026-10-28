# Windows x86_64 Bnd / Equinox resolution profile

Isolated analysis output for GeoGebra commit `375db7faf54`, product version `5.4.934.0`.

- `bundles/` contains the 12 Bnd-built GeoGebra production bundles, 34 Bnd-wrapped external Java artifacts, four existing OSGi external bundles, and the Equinox framework jar used to run the resolver. The framework jar is not itself installed as a bundle by the harness.
- Nine JOGL, GlueGen and GIAC native classifier jars are deliberately excluded from the bundle set and remain application-loader artifacts under the accepted Architecture V2 decision.
- `artifact-disposition.tsv` records every external runtime file as wrapped, reused as an existing bundle, or left on the application loader. `wrap-logs/` contains Bnd output.
- `index.xml` and `geogebra-desktop-win64.bndrun` document the local repository and the 12 requested GeoGebra root bundles. The Bnd CLI did not supply the final execution result; `EquinoxResolveHarness.java` performs the actual resolution through the installed Equinox framework API.
- `manifest-summary.tsv` records exported/imported package counts and fragment/native headers for the 12 production bundles.
- `equinox-resolution.log` is the exact resolver output. It reports Equinox `3.24.300.v20260721-1251`, 50 installed bundles, `allResolved=true`, and `unresolved=0`.
- `EquinoxResolveHarness.java` was compiled with JDK 21 and run with the Eclipse-bundled Java 25.0.4 runtime.

**Scope boundary:** This is successful package resolution, not a started RCP application. It does not verify `IApplication`, SWT/AWT embedding, `GeoGebraPanel`, GIAC/JOGL native loading, or the owner’s full D-02/D-04/D-05 proof slice. The first resolver pass found the Mac-only reflective `com.apple.eio` fallback as a missing mandatory import; the desktop Bnd recipe now marks it optional, after source inspection confirmed it is used only in the macOS branch. The second Equinox resolution succeeds without changing upstream code.
