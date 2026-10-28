#!/usr/bin/env python3
"""Summarize Bnd-generated package headers for the 12 production bundles."""
from __future__ import annotations

import pathlib
import re
import subprocess
import zipfile

ROOT = pathlib.Path(r"D:\ALF_Agents\G1_Geogebra_Migration")
OUT = ROOT / "02-Cdc" / "Bnd_Equinox_Resolution_Win64"
BUNDLES = OUT / "bundles"
BND = ROOT / ".claude" / "bnd-cli-7.4.0.jar"
JAVA = pathlib.Path(r"C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\java.exe")
MODULES = [
    "common", "common-jre", "renderer-base", "editor-base", "canvas-base",
    "keyboard-base", "giac-jni", "desktop", "canvas-desktop",
    "editor-desktop", "renderer-desktop", "jogl2",
]
BSN_PREFIX = "org.geogebra.migration."
rows = []

def manifest(path: pathlib.Path) -> dict[str, str]:
    with zipfile.ZipFile(path) as jar:
        body = jar.read("META-INF/MANIFEST.MF").decode("utf-8", "replace")
    body = re.sub(r"\r?\n[ \t]", "", body)
    headers = {}
    for line in body.splitlines():
        if ": " in line:
            k, v = line.split(": ", 1)
            headers[k.lower()] = v.strip()
    return headers

def package_counts(path: pathlib.Path) -> tuple[int, int]:
    cmd = [str(JAVA), "-jar", str(BND), "print", "--impexp", str(path)]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if result.returncode:
        raise RuntimeError(f"Bnd print failed for {path}: {result.stdout}")
    section = result.stdout.split("[IMPEXP]", 1)[-1]
    counts = {"imports": 0, "exports": 0}
    active = None
    for line in section.splitlines():
        label = line.strip()
        if label == "Import-Package":
            active = "imports"
        elif label == "Export-Package":
            active = "exports"
        elif label.startswith("["):
            active = None
        elif active and line.startswith("  ") and label:
            counts[active] += 1
    return counts["exports"], counts["imports"]

for module in MODULES:
    candidates = []
    for path in BUNDLES.glob("org.geogebra.migration.*-5.4.934.0.jar"):
        hdr = manifest(path)
        bsn = hdr.get("bundle-symbolicname", "").split(";", 1)[0]
        if bsn.startswith(BSN_PREFIX):
            # Resolve naming ambiguity by checking the module-specific pattern.
            if module == "common" and bsn.endswith(".common"):
                candidates.append(path)
            elif module == "common-jre" and bsn.endswith(".common.jre"):
                candidates.append(path)
            elif module == "renderer-base" and bsn.endswith(".renderer.base"):
                candidates.append(path)
            elif module == "editor-base" and bsn.endswith(".editor.base"):
                candidates.append(path)
            elif module == "canvas-base" and bsn.endswith(".canvas.base"):
                candidates.append(path)
            elif module == "keyboard-base" and bsn.endswith(".keyboard.base"):
                candidates.append(path)
            elif module == "giac-jni" and bsn.endswith(".giac.jni"):
                candidates.append(path)
            elif module == "desktop" and bsn == "org.geogebra.migration.desktop":
                candidates.append(path)
            elif module == "canvas-desktop" and bsn.endswith(".desktop.canvas"):
                candidates.append(path)
            elif module == "editor-desktop" and bsn.endswith(".desktop.editor"):
                candidates.append(path)
            elif module == "renderer-desktop" and bsn.endswith(".desktop.renderer"):
                candidates.append(path)
            elif module == "jogl2" and bsn.endswith(".desktop.jogl2"):
                candidates.append(path)
    if len(candidates) != 1:
        raise RuntimeError(f"Expected one bundle for {module}, found {candidates}")
    path = candidates[0]
    hdr = manifest(path)
    exports, imports = package_counts(path)
    rows.append((
        module,
        hdr.get("bundle-symbolicname", "").split(";", 1)[0],
        hdr.get("bundle-version", ""),
        str(exports),
        str(imports),
        hdr.get("fragment-host", ""),
        "yes" if "bundle-nativecode" in hdr else "no",
        path.name,
    ))

path = OUT / "manifest-summary.tsv"
with path.open("w", encoding="utf-8", newline="") as stream:
    stream.write("module\tbsn\tbundle_version\texport_package_count\timport_package_count\tfragment_host\tbundle_native_code\tbundle_jar\n")
    for row in rows:
        stream.write("\t".join(row) + "\n")
print(f"Summarized {len(rows)} production bundles to {path}")
