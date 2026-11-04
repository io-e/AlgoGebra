# Windows EE-P1 Verification

- Code under test: `60fc43e` on `feat/engine-subprocess-p1` (PR #60)
- Date: 2026-11-04
- OS: Windows 11 x64
- Java: Temurin JDK 21.0.12
- Engines: PARI/GP 2.19.0; Maxima 5.49.0; Gnuplot 6.0 patchlevel 3
- Engine executable directories were added to PATH for this PowerShell process only.
- Result: **21 PASS / 0 FAIL / 0 SKIP**.

The clean PR worktree lacks generated RCP bundle, platform, and native directories, so the product-oriented `test-engines.ps1` build wrapper cannot run there. For this verification, the dependency-free engine acceptance harness was compiled directly with `javac --release 21`; OSGi `Activator.java` files were excluded because bundle dependencies are not needed by the engine harness. The harness exercised the PARI factorization and malformed-input case, Maxima derivative, Gnuplot PNG signature and dimensions, negative filters, all three empty-output guards, and subprocess timeout/missing-binary behavior.

See `EngineAcceptanceTest.log` for the complete console output.

## Parity scope

This EE-P1 run verifies engine acceptance behavior; it is not a WIMS cross-engine parity certification. EE-P2d fixture comparisons follow D-WIMS-T01: compare computed values and require Java rejection behavior to be at least as strict as WIMS C. Byte-identical stdout is not the acceptance criterion.
