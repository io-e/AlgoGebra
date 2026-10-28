#!/usr/bin/env python3
"""Read-only Java package ownership audit for GeoGebra desktop/shared modules."""
from __future__ import annotations

import collections
import csv
import pathlib
import re
import sys

repo = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else r"D:\ALF_ZGit\G1_Geogebra_Migration")
outdir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else r"D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc")
modules = {
    "common": "source/shared/common/src/main/java",
    "common-jre": "source/shared/common-jre/src/main/java",
    "renderer-base": "source/shared/renderer-base/src/main/java",
    "editor-base": "source/shared/editor-base/src/main/java",
    "canvas-base": "source/shared/canvas-base/src/main/java",
    "keyboard-base": "source/shared/keyboard-base/src/main/java",
    "keyboard-scientific": "source/shared/keyboard-scientific/src/main/java",
    "ggbjdk": "source/shared/ggbjdk/src/main/java",
    "giac-jni": "source/shared/giac-jni/src/main/java",
    "xr-base": "source/shared/xr-base/src/main/java",
    "desktop": "source/desktop/desktop/src/main/java",
    "canvas-desktop": "source/desktop/canvas-desktop/src/main/java",
    "editor-desktop": "source/desktop/editor-desktop/src/main/java",
    "renderer-desktop": "source/desktop/renderer-desktop/src/main/java",
    "jogl2": "source/desktop/jogl2/src/main/java",
}
pkg_re = re.compile(rb"^\s*package\s+([\w.]+)\s*;", re.MULTILINE)
owners: dict[str, dict[str, list[str]]] = collections.defaultdict(lambda: collections.defaultdict(list))
file_counts: dict[str, int] = {}
unparsed: list[str] = []

for module, relroot in modules.items():
    srcroot = repo / relroot
    files = sorted(srcroot.rglob("*.java")) if srcroot.exists() else []
    file_counts[module] = len(files)
    for path in files:
        with path.open("rb") as stream:
            head = stream.read(8192)
        match = pkg_re.search(head)
        if match:
            package = match.group(1).decode("ascii")
            owners[package][module].append(path.relative_to(repo).as_posix())
        else:
            unparsed.append(path.relative_to(repo).as_posix())

split = {p: m for p, m in owners.items() if len(m) > 1}
outdir.mkdir(parents=True, exist_ok=True)
tsv_path = outdir / "Audit_A_Package_Ownership_CODEX_V1.tsv"
with tsv_path.open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream, delimiter="\t")
    writer.writerow(["package", "module", "class_count", "split_with", "severity", "classes_source_files"])
    for package in sorted(owners):
        by_module = owners[package]
        split_with = ",".join(sorted(by_module)) if len(by_module) > 1 else ""
        severity = "HIGH" if len(by_module) > 1 else "NONE"
        for module in sorted(by_module):
            files = sorted(by_module[module])
            writer.writerow([package, module, len(files), split_with, severity,
                             ";".join(pathlib.PurePosixPath(f).name for f in files)])

md_path = outdir / "Audit_A_Package_Ownership_CODEX_V1.md"
lines = [
    "# Task A — Java Package Ownership Audit",
    "",
    "**Scope:** shared + desktop source modules in GeoGebra; read-only scan of `src/main/java`.",
    f"**Repository:** `{repo}`",
    "**Command:** `python .claude/audit_package_ownership.py D:\\ALF_ZGit\\G1_Geogebra_Migration D:\\ALF_Agents\\G1_Geogebra_Migration\\02-Cdc`",
    f"**Modules scanned:** {len(modules)}; **Java source files:** {sum(file_counts.values())}; **unique packages:** {len(owners)}; **split packages:** {len(split)}.",
    f"**Full raw map:** `Audit_A_Package_Ownership_CODEX_V1.tsv`.",
    "",
    "## Source file counts by module",
    "",
    "| Module | Java source files |",
    "|---|---:|",
]
for module, count in file_counts.items():
    lines.append(f"| `{module}` | {count} |")
lines += ["", "## Split package findings", ""]
if split:
    lines += ["| Package | Modules | Class files by module |", "|---|---|---|"]
    for package, by_module in sorted(split.items()):
        details = "<br>".join(f"`{m}`: {', '.join(pathlib.PurePosixPath(x).name for x in sorted(files))}"
                              for m, files in sorted(by_module.items()))
        lines.append(f"| `{package}` | {', '.join(f'`{m}`' for m in sorted(by_module))} | {details} |")
else:
    lines.append("No split packages found.")
lines += ["", "## Vendored/non-GeoGebra packages in `common`", "",
          "| Package | Classes |", "|---|---:|"]
third_party = [(p, len(m["common"])) for p, m in sorted(owners.items())
               if "common" in m and not p.startswith("org.geogebra")]
for package, count in third_party:
    lines.append(f"| `{package}` | {count} |")
lines += ["", "## Root package class listings", "",
          "Only files whose declared package is exactly `org.geogebra.common` are listed here.", ""]
for module in ("common", "common-jre", "canvas-base"):
    files = owners.get("org.geogebra.common", {}).get(module, [])
    lines.append(f"- `{module}` ({len(files)}): " + (", ".join(pathlib.PurePosixPath(x).name for x in sorted(files)) or "none"))
lines += ["", "## Interpretation and limitations", "",
          "- This is package ownership from source declarations, not a full OSGi resolver result.",
          "- All packages shared by modules are flagged; confirm the exact emitted jars and runtime co-deployment before choosing a fix.",
          "- A bundle wrapper does not by itself solve a true split package or define a stable plugin API.",
          "- No source files were modified.", ""]
if unparsed:
    lines += ["## Java files without a parsed package declaration", ""] + [f"- `{x}`" for x in unparsed] + [""]
md_path.write_text("\n".join(lines), encoding="utf-8")
print(f"Modules: {len(modules)}; Java files: {sum(file_counts.values())}; packages: {len(owners)}; split packages: {len(split)}")
print(f"Wrote {md_path}")
print(f"Wrote {tsv_path}")
