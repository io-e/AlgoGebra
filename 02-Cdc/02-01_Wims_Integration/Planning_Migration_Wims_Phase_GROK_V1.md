<!-- GROK_V1 -->
# Phase — Migration into WIMS (post–AlgoGebra client)

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1 |
| Trigger | Owner: AlgoGebra-side **devs finished**; switch to **WIMS migration** |
| Prior phase | WA-9 client + live proof — closed for engineering (owner merges remain) |
| Canonical WIMS plan | `io-e/wims4win` → `AlgoGebra_Wims_Integration/Plan_Dev_AlgoGebra_Integration_CLAUDE_V2.md` |
| Hook branch | `feat/algogebra-wims-integration` @ `4ae4d86` (GB-W5 installer wired) |
| Spec / CDC | `Cdc_WIMS_Integration_AlgoGebra_*` V2+ · `Spec_WIMS_Message_Integration_*` |

---

## 0. What is finished (AlgoGebra lane)

| Deliverable | Evidence |
|---|---|
| JSON hook Option A (`algogebra_json.phtml` + `answer.phtml`) | wims4win + Debian #64 |
| `HttpWimsClient` WA-9 (`cmd=new`→`reply`, cp1252, 3-way HTML) | **PR [#67](https://github.com/io-e/AlgoGebra/pull/67)** OPEN |
| Live Debian proof | **PR [#66](https://github.com/io-e/AlgoGebra/pull/66)** |
| Fixture replay suites | 21/22/23 green on `9177a5a` |

**Owner housekeeping (not blocking WIMS packaging start):** merge or park #67, #66, #64, #65; leave #48/#63 on their own track.

**GBot:** may keep `:18431` + auto-`wimslogd` up for Migration_Wims smoke; tear down only on owner ask.

---

## 1. Phase goal — “migration dans WIMS”

Ship the AlgoGebra JSON hook as a **first-class, reproducible part of the WIMS / wims4win product**, not a one-off patched runtime:

1. **Packaging** — every new runtime tree includes the hook (Track D / GB-W5 completion).  
2. **Install story** — Windows + Debian documented one-liners; backups; uninstall.  
3. **Upstream hygiene** — minimal diff to `answer.phtml`; license/provenance notes (EUPL client ↔ GPL WIMS).  
4. **Recette** — Track E e2e on a **delivered** runtime (issue wims4win #3), not only spike trees.  
5. **Optional later** — institutional / Sand Migration_Wims class workflows (beyond OEF module smoke).

AlgoGebra RCP work (**#48**, **#63**) stays **out of this phase** unless owner reassigns.

---

## 2. Agent split

| Agent | Owns |
|---|---|
| **Claude / Migration_Wims (wims4win)** | Track D packaging polish, docs, license notes, runtime deliverable (#3), hook review vs upstream |
| **Grok Bot (Debian)** | Rebuild/install from packaging; parity smoke; optional Track E server e2e |
| **Grok Build (AlgoGebra docs)** | Phase board, CDC/Spec sync (cp1252, int grade), handoffs |
| **Codex** | Idle on WA-9 unless #67 needs fixes; #48/#63 only if owner asks |
| **Owner** | Merge #67 (and evidence PRs as desired); prioritize wims4win #3 / Track D |

---

## 3. Ordered backlog — WIMS migration

### P0 — productize the hook in wims4win

| ID | Action | Owner | Done when |
|---|---|---|---|
| **MW-P1** | Confirm `build-runtime-tree.sh` always installs hook (`4ae4d86`); run one full or incremental runtime rebuild that embeds it | Claude / Migration_Wims | New tree contains `algogebra_json.phtml` + patched `answer.phtml` without manual PS1 |
| **MW-P2** | Document install/uninstall for Windows (`install_*.ps1`) and Debian (`install_*.sh`) in wims4win README or `AlgoGebra_Wims_Integration/README` | Claude | One page + commands |
| **MW-P3** | Close wims4win **issue #3** enough for recette: ship `public_html` + modules needed for OEF hook smoke | Claude | Artifact or tree path published |
| **MW-P4** | License / provenance note: GPL WIMS templates + AlgoGebra hook; EUPL client consumes JSON only | Claude + Grok docs | Short NOTICE in `AlgoGebra_Wims_Integration/` |

### P1 — validation on packaged runtime

| ID | Action | Owner | Done when |
|---|---|---|---|
| **MW-V1** | GBot: install from **packaged** tree (not hand-patched spike); smoke 00006/00076 + `été` | GBot | Evidence pack |
| **MW-V2** | Point AlgoGebra live client (#67) at that tree once; confirm same grades as #66 | GBot | TAP / short report |
| **MW-V3** | Track C leftovers: schema examples frozen in wims4win docs matching Spec | Claude | Examples committed |

### P2 — institutional Migration_Wims (later)

| ID | Action |
|---|---|
| **MW-I1** | Port hook into Sand / full WIMS class+sheet environment if required beyond OEF module |
| **MW-I2** | Teacher packaging: OEF + help sidecar + AlgoGebra activity (CDC teacher annex) |
| **MW-I3** | Retire or rewrite parked AlgoGebra PRs #40–#42 (D-S01 mock) after #67 lands |

---

## 4. Explicit non-goals (this phase)

- Re-opening WA-9 design (`adm/raw`, `cmd=getresult`, UTF-8 forms)  
- Force-rebasing GBot evidence branches  
- Merging #67 without owner  
- Blocking on #48 / #63  

---

## 5. Critical path

```
Owner: optional merge #67
        │
        ▼
MW-P1…P4  wims4win packaging + docs + #3   ←── primary now
        │
        ▼
MW-V1…V2  GBot smoke on packaged runtime
        │
        ▼
MW-I*     institutional Migration_Wims (if still needed)
```

---

## 6. Paste briefs

### Migration_Wims / Claude (wims4win)

> AlgoGebra client phase done. Productize hook: verify `build-runtime-tree.sh` install path (`4ae4d86`), README install/uninstall, advance issue #3 runtime deliverable, add GPL/EUPL provenance note. Do not redesign the JSON contract.

### GBot

> Stand by for packaged-runtime smoke (MW-V1). Leave `:18431` / wimslogd as-is until owner says stop. No force-rebase on #57/#58.

### Codex

> WA-9 is PR #67 — wait for owner. Do not start WIMS packaging. #48/#63 only if reassigned.

---

## 7. Related files

| Path | Role |
|---|---|
| `Plan_Dev_AlgoGebra_Integration_CLAUDE_V2.md` (wims4win) | Tracks A–E |
| `Planning_GBot_Codex_Next_GROK_V1.md` | Prior AlgoGebra board (superseded for active WIMS work by **this** file) |
| `Handoff_GBot_WA9_Live_Resmoke_GROK_V1.md` | Historical live re-smoke |
| PRs #64–#67 | Evidence + client |

---

*End of `Planning_Migration_Wims_Phase_GROK_V1.md`.*
