<!-- GROK_V1_1 -->
# Owner questions — Hybrid RCP testing (SWTBot + RCPTT) — V1_1

| Field | Value |
|---|---|
| Document | **`02-Cdc/Questions_RCP_Testing_Owner_GROK_V1_1.md`** |
| Supersedes | `Questions_RCP_Testing_Owner_GROK_V1.md` |
| Version | GROK_V1_1 |
| Date | 2026-11-01 |
| Status | **RQ-1 overridden** (owner “yes Override” + Grok Bot PR #8 view) |
| Grok Bot | [PR #8](https://github.com/io-e/AlgoGebra/pull/8) — RCPTT documents Java **17–22** only |

---

## RQ-1 — Java for RCPTT (**OVERRIDDEN**)

**Original question:** Accept Java 21 fallback for RCPTT if Java 25 AUT injection fails?

**Best answer (adopted):** Use **Java 21 as the default** for RCPTT on Debian (and anywhere RCPTT runs), not merely a fallback.

| | |
|---|---|
| **Why** | RCPTT documents support for Java **17–22**. Java 25 is outside that range. Grok Bot already has both JDKs. |
| **Product / SWTBot** | Stay on **Java 25**. |
| **RCPTT AUT / runner** | **Java 21 default.** Evidence rows must record `java -version` for the RCPTT process. |
| **Answer** | **Java 21 = default for RCPTT.** Java 25 is not the RCPTT runtime. |
| **Date / by** | 2026-11-01 / Owner override + Grok Bot recommendation |

---

## RQ-2 — SWTBot test location (unchanged)

| **Answer** | **`03-RCP-Spike/host/tests/`** |

---

## RQ-3 — RCPTT runner install model (unchanged)

| **Answer** | **Hybrid** — pre-installed pinned RCPTT for developers; same pin downloaded in CI. |

---

## Quick locks (V1_1)

| Id | Topic | Answer |
|---|---|---|
| RQ-1 | RCPTT Java | **Java 21 default** (not fallback-only) |
| RQ-2 | SWTBot path | **`03-RCP-Spike/host/tests/`** |
| RQ-3 | RCPTT runner | **hybrid pin** |

---

## Correct order (unchanged)

1. RQ locks (this file) — **done**
2. Codex **X-T8** WAR → Playwright browser
3. Codex **WP2-06** CourseTreePanel → D-11 / RCPTT ECL
4. Grok Bot G-T2..G-T4 after WAR + panel
5. No merge of PR #3–#8 until owner flips no-merge

Orchestrator note: `Run_RCP_Tests_CLAUDE_V1.ps1` should prefer `JAVA_HOME` / a dedicated `RCPTT_JAVA_HOME` pointing at **21** when `-Phase RCPTT`.
