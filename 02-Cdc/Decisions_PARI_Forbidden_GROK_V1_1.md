<!-- GROK_V1_1 -->
# Decision — PARI/GP forbidden commands (BUG-006) — GROK_V1_1

| Field | Value |
|---|---|
| Document | `02-Cdc/Decisions_PARI_Forbidden_GROK_V1_1.md` |
| Supersedes (additive) | `Decisions_PARI_Forbidden_GROK_V1.md` (V1 remains the base list + rationale) |
| Date | 2026-11-04 |
| Status | **LOCKED** — owner accepted extension after Grok Bot EE-P2 evidence on #61 |
| Scope | `PariGPEngine` `AGB_ILLEGAL` (+ matching sandbox fixtures) |
| Implementer | **Codex** on PR #60 follow-up (or stacked commit); Grok Bot re-verifies on Debian |

---

## What V1 already blocks

`system`, `extern`, `externstr`, `fileextern`, `install`, `eval` — whole-word, case-insensitive, before process start → `COMMAND_REJECTED`. See V1 for rationale (secure mode gaps, `eval` rebuild).

---

## Extension (2026-11-04) — file-read APIs

**Decision:** Add these names to **`AGB_ILLEGAL`** with the same whole-word match rules as V1:

| Name | Why |
|---|---|
| `read` | Loads file contents into GP |
| `readvec` | Reads a file into a vector |
| `readstr` | Reads a file as strings |

**Evidence:** Grok Bot EE-P2 refresh on #61 — `read("/etc/hostname")` returned host contents through **both** WIMS C and AlgoGebra Java. Soft parity (D-WIMS-T01) does not require matching that hole; AlgoGebra must be **stricter**.

**Same pattern as V1:** WIMS `pari.c` `illegal[]` stays empty / unchanged in the ported `WIMS_*` tables. The extra block is **AlgoGebra-only** (`AGB_ILLEGAL`), documented deviation.

**Cost accepted:** Legitimate offline exercises that need `read("…")` of teacher-bundled data files will fail until a later allowlisted path API exists. MVP prefers fail-closed.

---

## Not claimed

This still does **not** make PARI a sandbox. Resource exhaustion, other GP features, and OS isolation remain out of MVP (unchanged from V1 §“Not a sandbox claim”). Remove the V1 sentence that listed `read` / `readstr` / `readvec` as “remaining risks” — they are now filtered in AlgoGebra.

---

## Implementation checklist (Codex)

1. Add `read`, `readvec`, `readstr` to `AGB_ILLEGAL` in `PariGPEngine`.
2. Unit tests: each name, mixed case, `alias(r,read)`, and a benign math command still ACCEPT.
3. Sandbox pack: new SBX rows (or extend `sandbox_GROK_V1.tsv`) expecting `COMMAND_REJECTED` for the three names + `read("/etc/hostname")`.
4. Note in #60 PR body; do **not** merge without owner review.
5. Grok Bot: re-run the Pari attack slice of fixture set F after the fix lands.

---

## Related

- D-ENG-03 (`Decisions_External_Engines_GROK_V1.md`)
- D-WIMS-T01 soft parity (`Decisions_WIMS_CDC_Open_Points_Owner_GROK_V1.md`)
- EE-P2 evidence: PR [#61](https://github.com/io-e/AlgoGebra/pull/61), fixture `ee_fixture_set_F_GROK_V1.json`

---

*End of `Decisions_PARI_Forbidden_GROK_V1_1.md`.*
