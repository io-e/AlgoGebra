# AlgoGebra

A public project combining a pinned GeoGebra source snapshot with the architecture and validation materials for the Eclipse/Equinox migration.

## Contents

- `geogebra-source/` — tracked source snapshot of [GeoGebra](https://github.com/geogebra/geogebra) at commit 375db7faf5407390bb322165f2414415da8faeda. See `geogebra-source/README.md` and `geogebra-source/UPSTREAM.md` for upstream information and provenance.
- `migration/` — architecture, audit, decision, and Bnd/Equinox package-resolution materials from commit 949558ade6458779acc42a5bbe017fb3e563f3f4 on branch `feat/init-claude-md`.

The GeoGebra source snapshot is nested intentionally so the AlgoGebra project metadata and migration documents remain distinct from upstream source. Build GeoGebra from inside `geogebra-source/` using its Gradle wrapper and instructions.

## Status

The Windows x86_64 D-03 package-resolution gate passed for the selected 50-bundle set. The RCP launch, SWT/AWT embedding, and GIAC/JOGL native-loading gates (D-02, D-04, D-05) remain open; see `migration/02-Cdc/Audit_C_OSGi_Wrapping_CODEX_V1.md` and `migration/02-Cdc/Audit_D_Path_Comparison_CODEX_V1.md`.

## Licensing

This is a multi-license repository; **no single root license covers every imported file**. See `LICENSES/README.md` before copying, modifying, or redistributing any part of the repository. The AGPL target applies to AlgoGebra-authored software code only when explicitly designated; it does not replace upstream or third-party notices.