# G-06 OEF -> course.json converter (GROK_V1)

Tool `03-RCP-Spike/tools/oef2course_GROK_V1.py` (python3, stdlib only), suite `19_Test_OefConverter_GROK_V1.ps1` (planning name S_WP7-02_OefConverter).

| Run | PASS | FAIL | SKIP |
|---|---|---|---|
| fixtures | 15 | 0 | 1 (OC-16 needs OEF_CORPUS) |
| fixtures + 300 real WIMS OEF from the box (OEF_CORPUS) | 16 | 0 | 0 |

Corpus (300 files sampled from /workspace/wims-full + WIMS-modules; list in corpus_list_GROK_V1.txt, files not committed): 300 converted, 300 schema-valid (Test-Json -SchemaFile).
Answer coverage: value_equals 16, object_exists 1824 (most WIMS answers are clickfill/dragfill/menu/case/\format or symbolic maxima/pari expressions -> not auto-checkable numerically); 24 draw primitives translated to safe GeoGebra CMDs.
Limits: no maxima/pari/slib evaluation; flydraw only segment/line/point/circle/arrow; random params fixed by --seed (formative only).
