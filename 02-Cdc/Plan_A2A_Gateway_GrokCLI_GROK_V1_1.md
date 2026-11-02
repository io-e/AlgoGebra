<!-- GROK_V1_1 -->
# Plan — A2A for Grok CLI → agents (why not v2; gateway shape)

| Field | Value |
|---|---|
| Document | `02-Cdc/Plan_A2A_Gateway_GrokCLI_GROK_V1_1.md` |
| Version | GROK_V1_1 |
| Date | 2026-11-01 |
| Status | Recommendation + owner decisions recorded |
| Supersedes | `02-Cdc/Plan_A2A_Gateway_GrokCLI_GROK_V1.md` |

---

## 1. Why not A2A v2?

**There is no released A2A v2 today.**

| Fact | Detail |
|---|---|
| Current stable | **A2A Protocol v1.0** (Mar 2026), patch **v1.0.1** (May 2026) |
| Negotiation | Header `A2A-Version: 1.0` (Major.Minor only) |
| Roadmap | Community work is on **v1.1** enhancements (task timeline, BiDi streaming, elicitation) — not a v2 break |
| Bifrost | Documents **A2A v1** agents and bindings only |
| If you send `2.0` | Servers that only declare 1.0 return **VersionNotSupportedError** |

So “A2A v2” is either a confusion with:

- **A2A v1.0** (the first stable major after 0.3), or  
- a future major that does **not** exist yet, or  
- another product’s internal “v2”.

**For Grok CLI → Grok Bot / Codex / Claude: target A2A v1.0 (1.x).** Revisit when the AAIF publishes a real 2.0 card/`protocolVersion`.

---

## 2. Proposed final chain (and how to simplify)

Owner sketch:

```
Grok CLI  →  Bifrost  →  agentgateway  →  Grok Bot
```

That is **two A2A-capable gateways in series**. It works, but adds hop latency, double auth, and double failure modes.

### Recommended production shape

```
Grok CLI / Grok Build
        │  A2A v1 (JSON-RPC preferred)
        ▼
   Bifrost (Agent Gateway)
   - virtual keys, budgets, Agent Logs
   - models + MCP + A2A in one place
        │  A2A v1 upstream
        ▼
   Agent Cards
   ├─ grok-bot-debian
   ├─ codex-windows
   └─ claude-specs
```

**Put agentgateway in front of Bifrost only if you need** LF open-source edge policy (Cedar authz, MCP federation, K8s Gateway API) that Bifrost does not cover. Otherwise **pick one gateway**.

| Role | Prefer |
|---|---|
| Control plane + VK + logs for ALF | **Bifrost** |
| Self-host edge / MCP federation / mesh | **agentgateway** |
| Both | Bifrost **or** agentgateway — not both in series for v1 |

Interim (today): GitHub PR comments + `Actions_*_GROK_V1.md` until Agent Cards exist.

**Owner note (2026-11-01):** Final infra intent remains Grok CLI → Bifrost → AgentGateway → Grok Bot (acknowledged as complex). Recommendation stays: start with **Bifrost-only** for A2A v1; add agentgateway later only for a missing edge capability. Decision on one vs two gateways still open.

---

## 3. Protocol split (unchanged)

| Hop | Protocol |
|---|---|
| Grok CLI → other agents | **A2A v1** |
| Each agent → tools | **MCP** |
| Agents → LLMs | OpenAI-compatible via Bifrost (optional) |

---

## 4. Codex status intake (2026-11-01)

Branch: `feat/course-tree-sprint1`  
Remote tip: `04b0c15` (model + BUG-014 triage).  
**Sprint1 deliverables still uncommitted** in worktree  
`D:\ALF_Agents\_worktrees\course-tree-codex-sprint1-20261101`.

| Item | Codex report |
|---|---|
| **X-T8 WAR** | Windows GWT build **succeeded**. Evidence: `03-RCP-Spike/evidence/20261101-windows-x-t8-gwt-war/`. Playwright **not** run yet. |
| **launch.ps1 / PR #8** | `-Course` handling + **suite 18**; **16 checks pass** (align with design; confirm vs 19 planned cases). |
| **WP2-06** | `CourseTreePanel` + directive exec + validation. RCP build OK; model tests **9/9**; policy **9/9**; headless launch loaded sample course. **Attended UI tree still needed**. |

**Unblocks when pushed:** Grok Bot G-T2/G-T3 (WAR), D-11 mechanical + Playwright, suite 18 cross-check on Debian.

---

## 5. Owner decisions (2026-11-01)

| # | Question | Decision |
|---|---|---|
| 1 | Commit + push `feat/course-tree-sprint1`? | **Yes — Ask Codex to push a review-only PR into `feat/external-engines`.** Brief: `02-Cdc/Actions_Codex_Push_Course_Tree_Sprint1_GROK_V1.md`. |
| 2 | One gateway vs Bifrost→agentgateway? | **Still open.** Prefer Bifrost-only for v1; owner may keep the two-hop sketch for later. |
| 3 | After push: Grok Bot Playwright + suite 18 twin; attended D-11? | **Pending** until PR URL exists. |

---

## 6. Related open PRs (context)

Grok Bot already opened parallel PRs into `feat/external-engines` (review-only): #9 suite 18 / launch.sh, #10 Firefox + Mise. Codex sprint1 PR will sit alongside them; merge policy unchanged.
