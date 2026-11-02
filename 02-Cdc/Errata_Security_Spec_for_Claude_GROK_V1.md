<!-- GROK_V1 -->
# Errata for Claude — Course security gaps from Grok Bot Sprint 1

| Field | Value |
|---|---|
| Document | `02-Cdc/Errata_Security_Spec_for_Claude_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Audience | **Claude** (settle / revise security spec) |
| Source | Grok Bot Sprint 1 feedback → `Feedback_GrokBot_Sprint1_PRs_GROK_V1.md` |
| Current spec | `02-Cdc/Spec_Course_Security_CLAUDE_V1.md` (**CLAUDE_V1_1** on tip) |

---

## Purpose

Grok Bot reported three gaps for Claude to settle. The tip already contains V1_1 text for T-15 / T-16 / T-17. Claude must decide for each gap:

1. **Spec closed** — only Codex/web implementation remains, or  
2. **Spec incomplete** — publish `Spec_Course_Security_CLAUDE_V1_2.md` with tighter rules.

Do not leave suite 16 SKIPs ambiguous.

---

## SEC-G1 — `<ggbscript val=…>`

| | |
|---|---|
| **Grok Bot** | Scanner misses scripts stored in `<ggbscript val=…>`. |
| **Spec V1_1 today** | Reject `<ggbscript` in `.ggb` XML (T-15); sample `containsScriptElements` includes `"<ggbscript"`. |
| **Evidence** | Suite 16: 44 SKIP on validator / `.ggb` scanner until Codex delivers scanner. |

**Claude settle (pick one and write it):**

- [ ] **A.** Any `<ggbscript` element → reject `.ggb` unless `trustedGgb: true` (strict).
- [ ] **B.** Parse `val` and apply the same command allowlist as CMD (permissive).
- [ ] **C.** Other: _describe_.

**Implementation note for Codex:** scanner must look at attribute form `<ggbscript val="…">`, not only element open tags with children.

**Claude decision:** **A — strict.** Any `<ggbscript` element → reject `.ggb` unless `trustedGgb: true`. Rationale: parsing `val` to apply the allowlist would require replicating the command parser in the scanner, expanding attack surface. Treat `<ggbscript>` like any script element. See Spec V1_2 §3.1.  
**Date:** 2026-11-02

---

## SEC-G2 — `Sequence` size limit

| | |
|---|---|
| **Grok Bot** | `Sequence` has no size limit. |
| **Spec V1_1 today** | Max end value **10 000** (T-16); nested `Execute` still blocked via allowlist (T-03). |
| **Web tip** | `course-tree.js` has `MAX_SEQUENCE_ITER = 10000` and blocks oversized end bounds. |

**Claude settle:**

- [ ] **A.** Spec closed: both hosts must reject `Sequence` when the numeric end (or iteration count) exceeds 10 000 **before** calling GeoGebra; nested blocked commands still fail allowlist.
- [ ] **B.** Raise/lower the limit (state number) and require desktop `DirectiveExecutor` parity with web.
- [ ] **C.** Also ban `Sequence` wrapping any string that embeds a command call (stricter than allowlist alone).

**Claude decision:** **A — spec closed.** Both hosts reject `Sequence` when iteration count exceeds 1 000 per call or 10 000 generated items per directive (owner Q3). Bounds must be statically provable. V1_2 §5.1 has full rules. Q3b: near-limit warning at 800 is dropped (issue #21). Desktop `DirectiveExecutor` parity is required. `MAX_SEQUENCE_ITER` in web must be updated from 10000 to 1000.  
**Date:** 2026-11-02

---

## SEC-G3 — Symlink escape without real-path check

| | |
|---|---|
| **Grok Bot** | A symlink can escape the course folder without a real-path check. |
| **Spec V1_1 today** | Desktop OPEN uses `toRealPath()` and requires resolved path under course dir (T-17). |
| **Web gap** | Browser `fetch` of a relative URL does not resolve OS symlinks; server or pre-publish scan must enforce. |

**Claude settle:**

- [ ] **A.** Desktop: `toRealPath()` mandatory. Web: OPEN only to same-origin relative paths; **publish pipeline** rejects symlinks / non-regular files when packaging course assets. Student browser does not follow server symlinks outside the course root.
- [ ] **B.** Disallow OPEN entirely until a trusted asset manifest exists.
- [ ] **C.** Other: _describe_.

**Claude decision:** **A — strict.** Desktop: `toRealPath()` mandatory. Web: OPEN only to same-origin relative paths; publish pipeline rejects symlinks/non-regular files; HTTP server must not follow symlinks outside course root. See Spec V1_2 §2.5.  
**Date:** 2026-11-02

---

## Deliverable from Claude

1. Fill the three decisions above (or publish Spec V1_2).
2. Tell Codex which suite 16 SKIP ids become FAIL vs stay SKIP until code lands.
3. Tell web maintainer whether `MAX_SEQUENCE_ITER` alone satisfies SEC-G2 for demos (owner allows interim denylist for internal demos only).

Related: D-COURSE-01, CT-SEC-01 (allowlist still required before external students).
