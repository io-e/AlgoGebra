<!-- GROK_V1 — SUPERSEDED by Questions_RCP_Testing_Owner_GROK_V1_1.md (RQ-1 overridden: Java 21 default) -->
# Owner questions — Hybrid RCP testing (SWTBot + RCPTT) — ARCHIVE

| Field | Value |
|---|---|
| Document | `02-Cdc/Questions_RCP_Testing_Owner_GROK_V1.md` |
| Status | **SUPERSEDED** — use **`Questions_RCP_Testing_Owner_GROK_V1_1.md`** |
| Version | GROK_V1 |
| Date | 2026-11-01 |
| Source plan | `02-Cdc/Plan_RCP_Testing_SWTBot_RCPTT_CLAUDE_V1.md` §9 (RQ-1..3) |
| Delivery | Commit `6baf1d4` (already on `origin/feat/external-engines`) |

---

## Correct order (do not invert)

1. **Lock RQ-1..3** (this file) — unblocks how RCPTT/SWTBot are laid out and run.
2. **Codex X-T8 — Windows GWT WAR** under `web-host/GeoGebra/` using  
   `:web:gwtCompile :web:copyHtml :web:mergeDeploy` (PR #5 lesson; standard deploy fails on Gradle 9.4.1).  
   → Unblocks **Playwright W-09 browser execution**.
3. **Codex CourseTreePanel (WP2-06)** behind `-Dggbplus.course` (trig/CAS only; matrix CMD skipped until BUG-014).  
   → Unblocks **D-11** SWTBot/RCPTT and mechanical `S_D-11_*`.
4. **Claude** — keep Playwright scaffold; run suite after step 2; expand RCPTT ECL after step 3.
5. **Grok Bot** — mirror WAR on Debian; Firefox when available; run Playwright + D-11 under Xvfb after steps 2–3.
6. **PR #3–#6** — review only until owner flips no-merge.

Playwright scaffold and RCPTT skeletons in `6baf1d4` are **not** evidence of PASS until steps 2–3 land.

---

## RQ-1 — Java 21 fallback for RCPTT

**Question:** Accept Java 21 fallback for RCPTT if Java 25 AUT injection fails?

| | |
|---|---|
| **Recommended** | **Yes.** Product/SWTBot stay on Java 25; RCPTT AUT may use Temurin 21 when injection fails. Document the JDK used in every evidence row. |
| **Answer** | ~~Yes — Java 21 fallback~~ → **OVERRIDDEN:** see V1_1 — **Java 21 is the default** for RCPTT. |
| **Date / by** | 2026-11-01 / superseded |

---

## RQ-2 — SWTBot test location

**Question:** Should SWTBot tests live in `03-RCP-Spike/host/tests/` or a top-level `tests/` directory?

| | |
|---|---|
| **Recommended** | **`03-RCP-Spike/host/tests/`** — next to the host bundle under test; keeps Tycho/MANIFEST with the product host; avoids a second top-level test tree. |
| **Answer** | **`03-RCP-Spike/host/tests/`** |
| **Date / by** | 2026-11-01 / Owner via “do all in correct order” (Grok recorded) |

---

## RQ-3 — RCPTT runner install model

**Question:** RCPTT runner: download per-run (CI) or pre-installed (developer workstation)?

| | |
|---|---|
| **Recommended** | **Hybrid.** Developer workstation: pre-installed pinned RCPTT (path via `-RcpttRunner` / env). CI: download the **same pinned version** per job into the workspace cache. Never “latest”. |
| **Answer** | **Hybrid** — pre-installed for developers; pinned download for CI. |
| **Date / by** | 2026-11-01 / Owner via “do all in correct order” (Grok recorded) |

---

## Quick locks

| Id | Topic | Answer |
|---|---|---|
| RQ-1 | Java 21 for RCPTT | **OVERRIDDEN → V1_1: Java 21 default** |
| RQ-2 | SWTBot path | **`03-RCP-Spike/host/tests/`** |
| RQ-3 | RCPTT runner | **hybrid pin** |

If any answer is wrong, edit this file and bump to `Questions_RCP_Testing_Owner_GROK_V1_1.md`.

---

## Agent checklist after this lock

| Agent | Next concrete action |
|---|---|
| **Codex** | (1) WAR → `web-host/GeoGebra/`; (2) host tests dir scaffold under `host/tests/`; (3) WP2-06 CourseTreePanel |
| **Claude** | After WAR: run Playwright; settle SEC-G1..G3; do not relocate SWTBot off `host/tests/` |
| **Grok Bot** | After WAR mirror: Playwright on Debian; keep PR #3–#6 unmerged |
