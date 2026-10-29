<!-- GROK_V1 -->
# tests/results — local, git-ignored

Run_All writes each run to `results/<runid>/` (`<yyyyMMdd_HHmmss>-<host>`); single suites write to `results/` unless `RESULTS_DIR` is set.
Nothing here is tracked. Reviewed runs are exported to `../../evidence/<YYYYMMDD>-<os>-<who>-<runid>/` with a sha256 MANIFEST
(`Run_All_GROK_V1.ps1 -ExportEvidence <name>`). Archive routine full logs as CI artifacts or keep them locally by run ID.
