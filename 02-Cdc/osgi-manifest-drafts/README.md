# OSGi manifest recipe drafts

These 14 `.bnd` descriptors are generator inputs for Bnd, **not validated bundles or final `MANIFEST.MF` files**. They use local built jars from `D:\ALF_ZGit\G1_Geogebra_Migration` and the package ownership TSV from commit `375db7faf54`.

The GeoGebra source version is `5.4.934.0`. The descriptors are broad bootstrap drafts: Bnd must scan actual bytecode, calculate `Import-Package`, and its output must be checked for dynamic/reflection/service/resource references and `uses` consistency before Equinox resolution. The package exports are not a promised public API.

`jogl2.bnd` is drafted as a fragment hosted by `org.geogebra.migration.desktop` to keep the only observed split package in one host class space. The V2 architecture says native JOGL/GIAC classifier jars remain on the application loader; no native-code manifest is asserted here. The two test-only built modules (`keyboard-scientific`, `ggbjdk`) are included in this recipe set but are not production desktop runtime dependencies. `xr-base` is deliberately excluded: no built jar was in the reviewed inventory, and it is not in `:desktop:runtimeClasspath`.

No source or Eclipse installation files were modified. Bundle generation/resolution has not yet been run.
