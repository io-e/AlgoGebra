# Windows EE-P1 Verification

- Code under test: 60fc43e on eat/engine-subprocess-p1 (PR #60)
- Date: 2026-11-04
- OS: Microsoft Windows 10.0.26100
- Java: openjdk version "21.0.12.1" 2026-08-18 LTS (Temurin JDK 21.0.12)
- Engines: PARI/GP 2.19.0; Maxima 5.49.0; Gnuplot 6.0 patchlevel 3
- Engine executables were added to PATH for this PowerShell process only.
- Result: **21 PASS / 0 FAIL / 0 SKIP**.

The clean PR worktree has no generated RCP undles/, platform/, or 
atives/ directories, so the product-oriented 	est-engines.ps1 build wrapper cannot run there. For this verification, the dependency-free engine acceptance harness was compiled directly with javac --release 21; OSGi Activator.java files were excluded because OSGi bundle dependencies are not needed by the engine harness. The harness exercised the PARI factorization and malformed-input case, Maxima derivative, Gnuplot PNG signature/dimensions, all negative filters, all three empty-output guards, and subprocess timeout/missing-binary behavior.

See EngineAcceptanceTest.log for the complete console output.