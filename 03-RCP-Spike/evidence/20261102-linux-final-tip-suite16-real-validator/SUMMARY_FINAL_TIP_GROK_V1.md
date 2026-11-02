# Final-tip Debian run after merge train (GROK_V1)
Tip e2cfff3 (feat/external-engines after #15). Image rebuilt from the tip with build.sh → image-final (includes Codex #18 host). Debian 13, Xvfb, pwsh 7.6.9, JDK 25.0.5 / 21.0.13.
| Run | Evidence | PASS | FAIL | SKIP |
|---|---|---|---|---|
| Run_All suites 01-19 (no 11/13) | 20261102-linux-final-tip-suites-* | 267 | 17 | 61 |
| Run_All -Scenarios (35) | 20261102-linux-final-tip-scenarios-* | 165 | 17 | 42 |
| S_W-09 after test-only fix (codebase regex accepts GeoGebra/web3d from #13) | 20261102-linux-final-tip-w09-fix-* | 15 | 0 | 4 |
| suite 16 with real Codex validator (CourseValidatorCliQ4) | this folder | 134 | 2 | 1 |
| Codex Java tests | this folder | 27 | 0 | 0 |
Known failures (unchanged from before the train): suite 09: 17 (Xvfb keyboard focus, same as the 2026-10-29 Debian baseline); D-11 3 (BUG-014 evalCommand false + CAS empty; persists with the #18 host); P-02/P-04 (BUG-014), P-07 (BUG-010), P-08 (acceptance tag), D-10 (installer), O-02 (licence), O-03 (BUG-016), X-01/X-02 (compute API gaps), X-06 (BUG-015); suite 16: T-45/T-51 near-limit warning (owner decision).
Environment note: engine suites 01-07/12 need 03-RCP-Spike/host/build → linked to the image's host/build for this run (a first run without it bailed; archived at /workspace/AlgoGebra/runs-archive on the box, not committed).
