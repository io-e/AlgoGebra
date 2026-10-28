#!/usr/bin/env python3
"""Generate local Bnd recipe drafts; this does not build/test OSGi bundles."""
from __future__ import annotations

import csv
import pathlib

ROOT = pathlib.Path(r"D:\ALF_Agents\G1_Geogebra_Migration")
SOURCE = pathlib.Path(r"D:\ALF_ZGit\G1_Geogebra_Migration")
TSV = ROOT / "02-Cdc" / "Audit_A_Package_Ownership_CODEX_V1.tsv"
OUT = ROOT / "02-Cdc" / "osgi-manifest-drafts"
OUT.mkdir(parents=True, exist_ok=True)

# These are the 14 observed built module jars (9 shared + 5 desktop).
# xr-base is a source module but was not built in the captured jar inventory
# and is not in :desktop:runtimeClasspath.
MODULES = [
    ("common", "shared/common", "org.geogebra.migration.shared.common"),
    ("common-jre", "shared/common-jre", "org.geogebra.migration.shared.common.jre"),
    ("renderer-base", "shared/renderer-base", "org.geogebra.migration.shared.renderer.base"),
    ("editor-base", "shared/editor-base", "org.geogebra.migration.shared.editor.base"),
    ("canvas-base", "shared/canvas-base", "org.geogebra.migration.shared.canvas.base"),
    ("keyboard-base", "shared/keyboard-base", "org.geogebra.migration.shared.keyboard.base"),
    ("keyboard-scientific", "shared/keyboard-scientific", "org.geogebra.migration.shared.keyboard.scientific"),
    ("ggbjdk", "shared/ggbjdk", "org.geogebra.migration.shared.ggbjdk"),
    ("giac-jni", "shared/giac-jni", "org.geogebra.migration.shared.giac.jni"),
    ("desktop", "desktop/desktop", "org.geogebra.migration.desktop"),
    ("canvas-desktop", "desktop/canvas-desktop", "org.geogebra.migration.desktop.canvas"),
    ("editor-desktop", "desktop/editor-desktop", "org.geogebra.migration.desktop.editor"),
    ("renderer-desktop", "desktop/renderer-desktop", "org.geogebra.migration.desktop.renderer"),
    ("jogl2", "desktop/jogl2", "org.geogebra.migration.desktop.jogl2"),
]

packages: dict[str, set[str]] = {name: set() for name, _, _ in MODULES}
with TSV.open(encoding="utf-8", newline="") as stream:
    for row in csv.DictReader(stream, delimiter="\t"):
        if row["module"] in packages:
            packages[row["module"]].add(row["package"])

version = "5.4.934.0"  # GeoGebraConstants.VERSION_STRING at pinned commit.

def continuation(header: str, values: list[str]) -> str:
    """Return Bnd property continuation with proper comma/backslash syntax."""
    if not values:
        return ""
    return header + ": " + ",\\\n\t".join(values)

for module, module_path, bsn in MODULES:
    libs = SOURCE / "source" / pathlib.Path(module_path) / "build" / "libs"
    candidates = sorted(p for p in libs.glob("*.jar") if "test-fixtures" not in p.name)
    if len(candidates) != 1:
        raise FileNotFoundError(f"Expected one built main jar in {libs}, found: {candidates}")
    jar = candidates[0]

    # Only GeoGebra-owned namespaces are candidates for package exports.
    # Bnd bytecode analysis must still remove/adjust unneeded exports and add
    # import versions; this is intentionally a first resolver-smoke-test draft.
    exports = sorted(
        p for p in packages[module]
        if p.startswith(("org.geogebra.", "com.himamis.retex.")) or p == "javagiac"
    )
    lines = [
        f"# DRAFT Bnd recipe for {module}; generated from commit 375db7faf54 package scan.",
        "# Not a final/validated bundle. Run Bnd, inspect imports/uses and resolve in Equinox.",
        f"-classpath: {jar.as_posix()}",
        f"-output: {OUT.as_posix()}/{bsn}-{version}.jar",
        "Bundle-ManifestVersion: 2",
        f"Bundle-SymbolicName: {bsn}",
        f"Bundle-Version: {version}",
    ]

    if module == "jogl2":
        lines += [
            "# Fixes the one source split: this module attaches to desktop; do not install as a peer exporter.",
            "Fragment-Host: org.geogebra.migration.desktop;bundle-version=\"[5.4.934,5.4.935)\"",
            "# The host desktop bundle exports org.geogebra.desktop.geogebra3D.euclidian3D.opengl.",
            "# Include the fragment classes privately; the host owns the package export.",
            "Private-Package: " + ",".join(sorted(packages[module])),
            "Import-Package: *",
        ]
    else:
        lines.append("# Broad initial export set only; narrow after API and Bnd package-use review.")
        export_values = [f"{p};version={version}" for p in exports]
        if export_values:
            lines.append(continuation("Export-Package", export_values))
        private = sorted(packages[module] - set(exports))
        if private:
            lines += [
                "# Included but not exported; includes vendored/implementation-only packages.",
                "Private-Package: " + ",".join(private),
            ]
        lines.append("# Bnd calculates bytecode imports; generated Import-Package must be reviewed, not hand-guessed.")
        if module == "desktop":
            lines += [
                "# Legacy Apple fallback in BrowserLauncher is reached only on macOS; keep it optional for Win64.",
                "Import-Package: \\",
                "  com.apple.eio;resolution:=optional,\\",
                "  *",
            ]
        else:
            lines.append("Import-Package: *")
        if module == "desktop":
            lines += [
                "# RCP launch does not use Main-Class; keep/verify manifest attributes separately.",
                "# JOGL/GIAC classifier jars stay on the application loader per Architecture V2.",
                "# Do not add Bundle-NativeCode until native payload layout and loader behavior are tested.",
            ]

    (OUT / f"{module}.bnd").write_text("\n".join(lines) + "\n", encoding="utf-8")

readme = f"""# OSGi manifest recipe drafts

These 14 `.bnd` descriptors are generator inputs for Bnd, **not validated bundles or final `MANIFEST.MF` files**. They use local built jars from `{SOURCE}` and the package ownership TSV from commit `375db7faf54`.

The GeoGebra source version is `{version}`. The descriptors are broad bootstrap drafts: Bnd must scan actual bytecode, calculate `Import-Package`, and its output must be checked for dynamic/reflection/service/resource references and `uses` consistency before Equinox resolution. The package exports are not a promised public API.

`jogl2.bnd` is drafted as a fragment hosted by `org.geogebra.migration.desktop` to keep the only observed split package in one host class space. The V2 architecture says native JOGL/GIAC classifier jars remain on the application loader; no native-code manifest is asserted here. The two test-only built modules (`keyboard-scientific`, `ggbjdk`) are included in this recipe set but are not production desktop runtime dependencies. `xr-base` is deliberately excluded: no built jar was in the reviewed inventory, and it is not in `:desktop:runtimeClasspath`.

The 12 production recipes have since been processed by Bnd 7.4.0 and the resulting bundles resolved in the installed Equinox 3.24.300 framework on Java 25. See `02-Cdc\Audit_C_OSGi_Wrapping_CODEX_V1.md` addendum and `02-Cdc\Bnd_Equinox_Resolution_Win64\` for manifests, resolver evidence and limitations. The two nonproduction recipes remain drafts only. No source or Eclipse installation files were modified.
"""
(OUT / "README.md").write_text(readme, encoding="utf-8")
print(f"Generated {len(MODULES)} Bnd recipe drafts in {OUT}")
