<!-- GROK_V1 -->
# Note — Maths-et-tiques GGB `Tangent(Point, Conic)` restore (Codex repair)

| Field | Value |
|---|---|
| Date | 2026-11-04 |
| Author tag | GROK_V1 (acceptance note) |
| Repair author | Codex |
| Product | GeoGebraPlus RCP r12 · GeoGebra `5.4.934.0` · Java 25 · Windows x86_64 |
| Status | **Accepted as content workaround** — not an RCP/Equinox defect |

## Finding (accepted)

Load-time error dialogs on four Maths-et-tiques constructions come from **saved `Tangent(Point, Conic)` nodes**:

| File | Failing construction (report) |
|---|---|
| `Cone_01.ggb` | `Tangent(S, ε)` |
| `Cone_section_01.ggb` | `Tangent(S, ε)` |
| `Cylindre_01.ggb` | tangents at `E_1` / `E_2` |
| `Cylindre_section_01.ggb` | tangents at `E_1` / `E_2` |

The same errors reproduce on a **plain-classpath GeoGebraPanel baseline**, including a **2D-only** run. That **rules out** Equinox packaging, native loading, and the RCP host as the cause.

`Tangent(Point, Conic)` is documented GeoGebra syntax. The precise upstream **restore/serialize** defect on pinned `5.4.934.0` is **not isolated**. Do not treat the originals as proven-malformed.

Manual references: [Tangent](https://geogebra.github.io/docs/manual/en/commands/Tangent/), [Polar](https://geogebra.github.io/docs/manual/en/commands/Polar/).

## Workaround (Codex)

Originals **untouched**. Dynamic corrected copies replace saved `Tangent` with equivalent:

- external point: `Polar(point, conic)` → `Intersect` → `Line` per tangent  
- point on conic: `Polar` as the tangent line  

Hidden helpers; display kept close to original; dependencies kept dynamic (not frozen lines).

### Local paths (uncommitted test artifacts)

```text
03-RCP-Spike/tests/results/maths-et-tiques-ggb-r12-20261104/repaired-experiment/
  REPAIR_REPORT.md
  final-repair-manifest.csv
  final-copies/          ← *_repaired.ggb + verify/polished PNGs
  final-verification/
```

Absolute tip used by Codex:

`D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike\tests\results\maths-et-tiques-ggb-r12-20261104\repaired-experiment\final-copies\`

### Manifest snapshot (all four OK)

| Corrected | dialogCount | openStatus | pngExport | tangentCommandsRemaining |
|---|---|---|---|---|
| `Cone_01_repaired.ggb` | 0 | OK | true | 0 |
| `Cone_section_01_repaired.ggb` | 0 | OK | true | 0 |
| `Cylindre_01_repaired.ggb` | 0 | OK | true | 0 |
| `Cylindre_section_01_repaired.ggb` | 0 | OK | true | 0 |

Full hashes: `final-repair-manifest.csv`.

### Validation coverage

| Check | Result |
|---|---|
| Reopen in RCP r12, no `_DIALOG`, Equinox exit 0 | All four |
| PNG export | All four |
| Dynamic: move `S`, tangent equations change | **`Cone_01` only** |
| Dynamic mouse-test on the other three | **Not done** |

## Implications for AlgoGebra

1. **Do not** open an RCP Gate B / natives bug for these dialogs.
2. Course / demo packs that ship these figures should use the **repaired** copies (or wait for an upstream restore fix).
3. Optional later: promote `final-copies/*.ggb` into tracked fixtures + smoke; optional GitHub/`states.yaml` upstream-defect tracker for `Tangent(Point, Conic)` restore on `5.4.934.0`.
4. Optional: motion-test the three files that only had reopen/export coverage.

## Out of scope here

- No commit of `results/…` binaries or logs (local artifacts).
- No `common` / host edits.
- No claim that Polar rewrite is bit-identical to upstream `Tangent` in every edge case.

---

*End of `Note_MathsEtTiques_Tangent_Repair_GROK_V1.md`.*
