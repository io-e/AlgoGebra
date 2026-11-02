<!-- CLAUDE_V1 -->
# Owner Decisions — Sprint 3 Open Points

| Field | Value |
|---|---|
| Document | `02-Cdc/Decision_Open_Points_Sprint3_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Date | 2026-11-02 |
| Context | Grok Bot Sprint 3 status (#34, #35), spec V1_2 posted |

---

## D-S01 — WIMS compute integration (S-01)

**Decision:** HTTP POST to WIMS CGI.

When PARI/GP, Maxima, or other computation engines are not installed on the student's machine, WIMS acts as the remote computation backend. The client sends the expression or construction state via HTTP POST to the existing WIMS CGI endpoint, and WIMS evaluates using its installed engines.

```
Student client (desktop or web)
  → POST /wims/wims.cgi
      module=adm/class/sheet
      &job=getresult
      &exercise=<id>
      &ans1=<construction_base64>
  ← { "grade": 0.8, "feedback": "..." }
```

Both desktop (Java `HttpClient`) and web (`fetch`) use the same endpoint. WIMS owns the grade; the client displays formative feedback only.

**Unblocks:** G-14 (WIMS template), G-15 (grade callback), G-16 (full cycle).

---

## D-S02 — Lean 4 integration (S-02)

**Decision:** Batch file-based processing.

Lean 4 proof verification is GPU/resource intensive. The integration model is asynchronous:

1. Student exports proof files from the construction
2. Files are submitted to the Lean 4 verification server (batch queue)
3. Results return when the server has capacity
4. No live round-trip — the client polls or receives a notification

This keeps Lean 4 as an external computation service (per architecture binding decision) without requiring real-time resource allocation.

**Unblocks:** Future Lean 4 adapter design (not in current sprint scope).

---

## D-P08 — Acceptance tag

**Decision:** Tag created.

Lightweight git tag `ggb-baseline-v5.4.934.0` on commit `375db7faf54` in the GeoGebra source checkout (`D:\ALF_ZGit\G1_Geogebra_Migration`). VERSION_STRING = `5.4.934.0`.

**P-08 status:** PASS (tag + pin).

---

## D-O02 — License inventory timing

**Decision:** After Gate B closes.

The SBOM / EUPL 1.2 component provenance audit is Gate E. It does not block current development or internal demos. Claude will draft it after Gate B (D-02..D-06) is closed, when the bundle set is stable.

---

## D-TRUSTED-OPEN-UI — Visual check scheduling

**Decision:** Quick check now on r11 image.

Do a fast attended visual check of the trusted-OPEN SWT warning dialog on the current r11 product image, without waiting for #21/#27 to land. Goal: verify the dialog exists and displays correctly, even if other bugs (BUG-014, input focus) are still open.

---

*End of `Decision_Open_Points_Sprint3_CLAUDE_V1.md`.*
