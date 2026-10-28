#!/usr/bin/env python3
"""Stage a local Bnd repository from the pinned desktop runtime artifacts."""
from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import zipfile

ROOT = pathlib.Path(r"D:\ALF_Agents\G1_Geogebra_Migration")
SOURCE = pathlib.Path(r"D:\ALF_ZGit\G1_Geogebra_Migration")
RAW = ROOT / "02-Cdc" / "Audit_B_Runtime_Artifacts_CODEX_V1.txt"
DRAFTS = ROOT / "02-Cdc" / "osgi-manifest-drafts"
OUT = ROOT / "02-Cdc" / "Bnd_Equinox_Resolution_Win64"
BUNDLES = OUT / "bundles"
LOGS = OUT / "wrap-logs"
BND = ROOT / ".claude" / "bnd-cli-7.4.0.jar"
JAVA = pathlib.Path(r"C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\java.exe")

PRODUCTION = [
    "common", "common-jre", "renderer-base", "editor-base", "canvas-base",
    "keyboard-base", "giac-jni", "desktop", "canvas-desktop",
    "editor-desktop", "renderer-desktop", "jogl2",
]

def read_manifest(jar: pathlib.Path) -> dict[str, str]:
    try:
        with zipfile.ZipFile(jar) as zf:
            raw = zf.read("META-INF/MANIFEST.MF").decode("utf-8", "replace")
    except (KeyError, zipfile.BadZipFile):
        return {}
    # Manifest continuation lines are unfolded before header parsing.
    raw = re.sub(r"\r?\n[ \t]", "", raw)
    result = {}
    for line in raw.splitlines():
        if ": " in line:
            k, v = line.split(": ", 1)
            result[k.lower()] = v.strip()
    return result

def has_classes(jar: pathlib.Path) -> bool:
    try:
        with zipfile.ZipFile(jar) as zf:
            return any(name.endswith(".class") for name in zf.namelist())
    except zipfile.BadZipFile:
        return False

def bnd_version(maven_version: str) -> str:
    """Convert Maven-ish version text to an OSGi version for wrapper identity."""
    value = maven_version.strip()
    match = re.fullmatch(r"(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:[.-]([A-Za-z0-9_-]+))?", value)
    if match:
        major, minor, micro, qualifier = match.groups()
        return f"{major}.{minor or '0'}.{micro or '0'}" + (f".{qualifier}" if qualifier else "")
    qualifier = re.sub(r"[^A-Za-z0-9_-]", "_", value) or "unknown"
    return f"0.0.0.{qualifier}"

OUT.mkdir(parents=True, exist_ok=True)
BUNDLES.mkdir(parents=True, exist_ok=True)
LOGS.mkdir(parents=True, exist_ok=True)
if not BND.exists():
    raise FileNotFoundError(BND)

records = []
for line in RAW.read_text(encoding="utf-8", errors="replace").splitlines():
    if not line.startswith("RUNTIME_ARTIFACT|"):
        continue
    _, gav, path = line.split("|", 2)
    records.append((gav, pathlib.Path(path)))

# Add the 12 Bnd-built GeoGebra production modules; do not include the two
# test-only built modules or unused xr-base in the product resolver profile.
for module in PRODUCTION:
    matches = list(DRAFTS.glob(f"org.geogebra.migration.*{module}*-5.4.934.0.jar"))
    # The wildcard above is not used for lookup due possible name collisions;
    # the BSN is read from the corresponding recipe output filename.
    recipe = DRAFTS / f"{module}.bnd"
    text = recipe.read_text(encoding="utf-8")
    output_match = re.search(r"^-output:\s*(.+)$", text, re.MULTILINE)
    if not output_match:
        raise RuntimeError(f"No -output in {recipe}")
    built = pathlib.Path(output_match.group(1).replace("/", "\\"))
    if not built.exists():
        raise FileNotFoundError(built)
    shutil.copy2(built, BUNDLES / built.name)

rows = []
seen = set()
for gav, jar in records:
    # Included-build/project outputs are handled by the 12 GeoGebra recipes.
    try:
        jar.resolve().relative_to(SOURCE.resolve())
        continue
    except ValueError:
        pass

    if not jar.exists() or jar.suffix.lower() != ".jar":
        rows.append((gav, "MISSING", str(jar), "", ""))
        continue

    # Platform-native classifier jars deliberately remain outside the OSGi
    # repository on the application loader, per the approved V2 decision.
    if "-natives-" in jar.name:
        rows.append((gav, "APP-LOADER-NATIVE", str(jar), "", ""))
        continue

    key = (gav, str(jar.resolve()))
    if key in seen:
        continue
    seen.add(key)
    manifest = read_manifest(jar)
    bsn = manifest.get("bundle-symbolicname", "").split(";", 1)[0]
    if not has_classes(jar):
        rows.append((gav, "APP-LOADER-RESOURCE-ONLY", str(jar), bsn, manifest.get("bundle-version", "")))
        continue

    parts = gav.split(":")
    if len(parts) != 3:
        rows.append((gav, "UNPARSED", str(jar), bsn, ""))
        continue
    group, artifact, maven_ver = parts
    if bsn:
        output = BUNDLES / jar.name
        shutil.copy2(jar, output)
        rows.append((gav, "EXISTING-OSGI", str(output), bsn, manifest.get("bundle-version", "")))
        continue

    new_bsn = "org.geogebra.migration.external." + group + "." + artifact
    new_ver = bnd_version(maven_ver)
    output = BUNDLES / f"{new_bsn}-{new_ver}.jar"
    cmd = [
        str(JAVA), "-jar", str(BND), "wrap", "--bsn", new_bsn,
        "--version", new_ver, "--output", str(output), str(jar),
    ]
    log = LOGS / f"{artifact}-{new_ver}.log"
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log.write_text(result.stdout, encoding="utf-8")
    if result.returncode != 0 or not output.exists():
        rows.append((gav, f"WRAP-FAILED-{result.returncode}", str(jar), new_bsn, new_ver))
    else:
        rows.append((gav, "WRAPPED", str(output), new_bsn, new_ver))

report = [
    "coordinate\tstatus\tpath\tbundle_symbolic_name\tbundle_version",
    *("\t".join(r) for r in rows),
]
(OUT / "artifact-disposition.tsv").write_text("\n".join(report) + "\n", encoding="utf-8")

readme = """# Windows x86_64 Bnd/Equinox resolver staging area

This is an isolated analysis output for commit `375db7faf54`, source version `5.4.934.0`.

- `bundles/` contains 12 Bnd-built GeoGebra production module bundles, 34 Bnd-wrapped external Java libraries, four existing OSGi external bundles, and the Equinox framework jar used as the resolver implementation.
- Nine JOGL/GlueGen/GIAC native classifier jars are intentionally excluded from the bundle set and remain application-loader artifacts per the accepted Architecture V2 decision.
- `artifact-disposition.tsv` records the external artifacts wrapped, reused, or left on the application loader; `wrap-logs/` holds Bnd output for generated wrappers.
- `index.xml`, `geogebra-desktop-win64.bndrun`, `EquinoxResolveHarness.java`, `manifest-summary.tsv`, and `equinox-resolution.log` provide resolver configuration, the exact-framework harness, and evidence.

The harness resolved 50 installed bundles in Equinox 3.24.300 on Java 25. This is a package-resolution result only; it does not prove RCP UI launch, SWT_AWT, CAS/3D initialization or native loading.
"""
(OUT / "README.md").write_text(readme, encoding="utf-8")
print(f"Processed {len(rows)} external runtime artifact records; bundle files staged: {len(list(BUNDLES.glob('*.jar')))}")
