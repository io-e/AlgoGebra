# GROK_V1 — malicious course corpus (WP9-03 / G-05)
For `02-Cdc/Spec_Course_Security_CLAUDE_V1.md`. Run: `pwsh -File 03-RCP-Spike/tests/16_Test_CourseSecurity_GROK_V1.ps1`.
- `courses/*.json` — one case each; `corpus_manifest_GROK_V1.tsv` gives layer, schema validity and expected verdict (51 cases).
- `ggb-src/<name>/` — text sources zipped to `<name>.ggb` at run time (no binaries committed); `link_outside.ggb` symlink and T-10 (>1 MB) are generated.
- Schema layer runs now (Test-Json). Validator/scanner layers are SKIP `pending WP9-02/04` until Codex sets
  `COURSE_VALIDATOR="<cmd>"` (called as `<cmd> <course.json>`, first stdout token `ACCEPT|ACCEPT_WITH_WARNING|REJECT`).
- Findings for the spec: **SPEC-GAP-1** §3.1 `containsScriptElements` misses `<ggbscript val="...">` (GeoGebra ScriptType xml name; T-29);
  **SPEC-GAP-2** `Sequence` (TABLE_LIST) is allowed but has no size/time limit (T-21); **SPEC-GAP-3** §2.1 `normalize()` + `startsWith` does not catch a symlink escaping the course dir, use `toRealPath()` (T-27).
  Also: Slider/Checkbox/SetColor/SetFixed are TABLE_SCRIPTING at pin 375db7f (allowed only via the explicit override list).
