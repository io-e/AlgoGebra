# Windows packaging smoke — BUG-014 ReTeX fonts

| Field | Value |
|---|---|
| Date | 2026-11-02 |
| Host | Windows 11 x64 (build 10.0.26100), PowerShell 7.6.9 |
| Java | Temurin 21.0.12.1 |
| Source base | `5b0e525` (PR #37 evidence-only; no production source changes) |
| Scope | Static/build-script and font-fragment packaging smoke only |

## Results

- `bash -n 03-RCP-Spike/build.sh`: PASS.
- Renderer resource fragment packaging smoke: PASS; all 46 TTF files match the existing r12 fragment by SHA-256, including `jlm_cmr10.ttf` and `jlm_cmssbx10.ttf`.
- Fragment host is `org.geogebra.migration.desktop.renderer [5.4.934,5.4.935)`.
- `git diff --check`: PASS before PR staging.

## Limits

No Linux build, Equinox runtime, or UI suite was run on this Windows PC. Grok's Debian verification of this fragment-based variant remains required; this evidence does not claim BUG-014 is closed.
