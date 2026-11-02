# Course Security Q2–Q4 Implementation — Windows Validation

| Field | Value |
|---|---|
| Date | 2026-11-02 |
| Branch | `feat/course-security-q2-q4` |
| Base | `bdfd306` (`feat/external-engines`, after PR #11) |
| Platform | Windows 11 24H2 x64 (build 26100) |
| Java | Eclipse Temurin 21.0.12.1 x64 |
| Scope | Owner decisions Q2–Q4 from GitHub issue #17; Q1 is already implemented separately in PR #9 (`6c32896`) |

## Implementation

- **Q2 — `.ggb` opening:** untrusted `OPEN` is rejected until archive/script scanning exists. Explicitly trusted files require an SWT confirmation before loading; the warning states that embedded scripts are not scanned. This is a warning boundary, not a sandbox or a claim that the file is safe.
- **Q3 — `Sequence`:** post-parse validation requires statically evaluable, finite bounds and a non-zero finite step. The implementation caps each `Sequence` at 1,000 iterations and estimated nested output at 10,000 generated items per directive. It rejects invalid/dynamic bounds, excessive work, expression depth above 256, or more than 10,000 AST nodes. Near-limit use (800+) produces a warning. No unsafe UI-thread timeout/interruption is claimed.
- **Q4 — result states:** validation uses `ACCEPT`, `ACCEPT_WITH_WARNING`, and `REJECT`. A rejected action aborts step execution during preflight; warnings are surfaced and cannot convert rejection into acceptance.

## Validation evidence

| Check | Command / result |
|---|---|
| Course model + policy unit tests | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\03-RCP-Spike\test-course-model.ps1 -JavaHome 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot' -BundleRoot 'D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike'` — **27 PASS, 0 FAIL** (CourseModel 9/0; policy 18/0) |
| RCP host/product build | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\03-RCP-Spike\build.ps1 -JavaHome 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot' -GeoGebraSourceRoot 'D:\ALF_ZGit\G1_Geogebra_Migration\source'` — **exit 0**; 50 D-03 inputs unchanged; build output includes the host and engine bundles |
| Whitespace/conflict check | `git diff --check` — **PASS** |

Raw output is in this folder: `course-policy-tests.log`, `rcp-build.log`, and `java-version.txt`. `SHA256SUMS.txt` records their hashes and this report's hash.

## Limits / follow-up

- No attended SWT dialog test was run; the trusted-file confirmation is compile/build validated, not visually exercised.
- No live GeoGebra integration smoke ran a parsed `Sequence` command. Unit tests cover the pure limit/boundary helpers and result states; dynamic AST rejection is implemented but was not directly exercised by a live GeoGebra parser test. The RCP build verifies compilation.
- The `.ggb` archive scanner remains unimplemented. Untrusted files therefore remain blocked, and trusted files remain warning-gated.
- These controls are policy checks, **not an OS sandbox**. No merge was performed.
