<!-- GROK_V1 -->
# Decision — GAP security filter matching (Java adapter)

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Decisions_GAP_Filter_Match_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Status | **LOCKED** — owner choice after Grok Bot G-B4 note on #61 |
| Implementer | **Codex** when adding the Java GAP `SubprocessEngine` adapter |
| Related | D-ENG-03, `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md`, PR #60 / #61 fixtures |

---

## Decision

**Match forbidden GAP names as whole words only** (case rules as for Pari `AGB_ILLEGAL`), **not** WIMS `gap.c` substring-anywhere matching.

| Item | Choice |
|---|---|
| Forbidden name list | Prefer the same *names* as WIMS `illegal[]` / `illpart[]` where applicable |
| Match semantics | **Whole-word** (narrower than WIMS) |
| Rejected alternative | Copy WIMS substring match (would block legitimate identifiers such as `ToString`) |
| Acceptable hybrid | Same name list + whole-word match — this decision |

**Rationale:** Soft parity (D-WIMS-T01) allows Java to be **stricter**, not looser. Blocking `ToString` and similar is a false positive that hurts real exercises. Document the deviation next to the GAP filter table in the engines CDC when the adapter lands.

**Minimum Java GAP fixture slice (Grok Bot G-B4):** 13 cases from `ee_fixture_set_F_GROK_V1.json` when the adapter exists.

---

## Companion locks (same session)

| Topic | Lock |
|---|---|
| Pari `read` / `readvec` / `readstr` | **Keep** BUG-006 **V1_1** — AlgoGebra rejects even if WIMS allows |
| EE-P2d wording | Claude errata: any leftover “byte-identical” → soft parity; cite V1_1 in Engines V1_3 |

---

*End of `Decisions_GAP_Filter_Match_GROK_V1.md`.*
