# License and attribution map

This repository contains imported code, resources, documentation, and project materials under different licenses. This file is a preliminary map, not legal advice or a completed third-party license audit.

## Components

- **`geogebra-source/`**: snapshot of GeoGebra at the revision recorded in `geogebra-source/UPSTREAM.md`. GeoGebra states that its source code is licensed under EUPL 1.2. GeoGebra language files, documentation, UI images/styles, installers, and web services may be subject to separate terms; follow the current [GeoGebra license page](https://www.geogebra.org/license). Preserve all file-level copyright and license headers.
- **AlgoGebra-authored software code**: intended license is **AGPL-3.0-only** when such code is added and explicitly marked. The EUPL 1.2 compatibility appendix includes AGPL-3.0 for qualifying combined works, but that does not erase upstream notices or override other component licenses. See the [official EUPL compatibility guidance](https://interoperable-europe.ec.europa.eu/collection/eupl/licence-compatibility-permissivity-reciprocity-and-interoperability).
- **`migration/`**: imported architecture documents, reports, and analysis scripts. No blanket license is asserted here for every document; retain any source-specific notices and obtain explicit licensing decisions before reusing them.
- **Third-party code/resources** in GeoGebra or its build/runtime graph retain their own applicable licenses. This repository does not relicense them under AGPL.
- **`MIT-Initial-Repository.txt`** preserves the MIT license file present in the initial `io-e/AlgoGebra` repository commit. Its scope is limited to the original repository materials to which that grant applied; it does not apply to imported GeoGebra or migration contents.

## Before a release

Complete a file/resource and dependency license inventory, verify all notices and attribution, decide the license for project documentation, and review whether any CC BY-NC-SA or other restricted material is included in the distributed product. Public source availability does not itself change a component's license.