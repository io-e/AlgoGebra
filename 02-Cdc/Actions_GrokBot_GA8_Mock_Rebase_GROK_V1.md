<!-- GROK_V1 -->
# Grok Bot — G-A8 unlocked: implement WIMS mock rebase (no merge)

| Field | Value |
|---|---|
| Document | `02-Cdc/Actions_GrokBot_GA8_Mock_Rebase_GROK_V1.md` |
| Version | GROK_V1 |
| Date | 2026-11-04 |
| Audience | **Grok Bot** (Debian) |
| Owner unlock | Implement mock rebase on a **new branch**; **do not merge** |
| Spec | `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md` (D-WIMS-G01) |
| Related PRs | #40 / #41 / #42 (leave unmerged; base work off tip or stacked branch) |

---

## Context (already landed)

| PR | Result |
|---|---|
| #60 | **MERGED** — EE-P1 engines (`c593c8d`) |
| #61 | **MERGED** — EE-P2 Linux soft-parity evidence (`9d67b57`) |
| #62 | **MERGED** — GV residual GB-R2..R5 (`ba4529b`) |
| #49 | **MERGED** — suite 09 hygiene (`04d88b8`) |
| #48 / #33 | Still **paused** |

---

## Do this (G-A8 / G-C1 implement)

### Goal

Replace the Phase-2 **mock CGI** shape used by suites 21–23:

- **Old (wrong):** `module=adm/class/sheet` + `job=getresult`  
- **New (CDC V2 / D-WIMS-G01):** stock OEF play **`cmd=new` → `cmd=reply`**, plus JSON grade via a hook such as `special_parm=algogebra_json` (or equivalent documented in the design)

### Steps

1. **Branch** from current `feat/external-engines` tip (or a docs tip if mocks live only on #40–#42 branches):  
   `feat/grok-ga8-wims-mock-new-reply` (name flexible).
2. **Implement** mock server + suite fixtures so 21 / 22 / (23 if WAR available) exercise `cmd=new` / `cmd=reply` + JSON response matching Q-W4 `answers[]` / grade fields from CDC V2.
3. **Do not** patch real wims4win / L2-1 production adapter in this PR unless already scoped — this unlock is the **AlgoGebra mock + tests**.
4. Open a **review-only PR** into `feat/external-engines`. Title must say **no merge**.
5. Run suites 21–23 on Debian; attach TAP + evidence folder + SHA256SUMS.
6. Short design note in the PR body linking CDC V2 WI-21/WI-22 and D-WIMS-G01.

### Out of scope

- Merging #40 / #41 / #42  
- Merging this new PR  
- #48 / #33  
- Live L2-1 WIMS module (`special_parm` in real `scripts/oef`) — optional follow-up; mock may simulate the hook without shipping the WIMS patch

### Done when

- New PR URL posted on #34  
- Suites 21–22 green on the new mock (23 if feasible)  
- PR body states **no merge without owner review**

---

## Paste brief — Grok Bot

> **G-A8 unlocked (implement, no merge).** Branch from `feat/external-engines` tip. Rebase suites 21–23 mocks from fake `job=getresult` to CDC V2 **`cmd=new`/`reply` + JSON hook** (D-WIMS-G01). Open review-only PR; attach Debian TAP. Do **not** merge #40–#42 or this PR. #48/#33 stay paused. Spec: `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md`. Brief: `Actions_GrokBot_GA8_Mock_Rebase_GROK_V1.md`.

---

*End of `Actions_GrokBot_GA8_Mock_Rebase_GROK_V1.md`.*
