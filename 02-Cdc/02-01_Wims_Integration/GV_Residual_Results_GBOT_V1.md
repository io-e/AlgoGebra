<!-- GBOT_V1 -->
# GV residual results — GB-R2..GB-R5 (G-A2..G-A6), Debian lane

| Field | Value |
|---|---|
| Author | Grok Bot (Debian, grok-bot-vm) |
| Date | 2026-11-04 (Europe/Paris) |
| Handoff | `Handoff_GrokBot_WIMS_GV_Residual_GROK_V1.md` (GROK_V1_1) |
| Base | `origin/feat/grok-sprint3-plan-v1-1` @ `322c723` |
| Evidence | `03-RCP-Spike/evidence/20261104-gv-residual-gb-r2-r5_GROK_V1/` (+ `SHA256SUMS`) |
| Policy | Evidence only. No PR, no merge, no spec/schema edits, no GitHub comments |

## Summary

| Action | Residual | Result | Key numbers |
|---|---|---|---|
| G-A2 (P0) | GB-R2 suite 19 + fidelity | **PASS** | 16/0/0 on `322c723`; 300/300 converted + schema-valid; 1,824/1,840 checks `object_exists` (281 files); GAP-5 still #1 |
| G-A3 (P0) | PR #49 mergeable | **PASS** | `mergeable=true`, `mergeable_state=clean`, rebaseable; head `b9fdc4b` vs base `feat/external-engines` @ `4e13b83`; no conflicts. Not merged |
| G-A4 (P1) | GB-R3 engine signals | **PASS** | 214/300 files compute params at runtime (wims/slib/CAS); 18 name a CAS (pari 16 files/18 calls, maxima 2/3); octave/yacas/gap/m2/scilab = 0 |
| G-A5 (P1) | GB-R4 suites 21–23 (mock) | **PARTIAL** | 21 = 14/0/0 (#40 `0222ce1`), 22 = 28/0/0 (#41 `a30f8ec`); 23 = 0/2/0 (#42 `c9a6dd5`) — **environment**: applet never loaded (see below) |
| G-A6 (P1) | GB-R5 Debian HTTP WIMS | **PASS** | `http://127.0.0.1:18431/wims/wims.cgi`; OEF scored: `cmd=new` → `cmd=reply` gave **10/10** (correct) and **0/10** (wrong). Scoring usable: **Y** |

## G-A2 / GB-R2 — suite 19 on tip + fidelity

- TAP: `19_OefConverter_corpus300_tip322c723_GROK_V1.tap` — **PASS 16 / FAIL 0 / SKIP 0**, OC-16 `files=300 converted=300 schema-valid=300`. Same corpus list as the 49d98f9 run (`corpus300_list_GROK_V1.txt`, copied from `grok/gv-validation-wims-cdc` @ `bf0184b`; all 300 paths still exist).
- Converter `03-RCP-Spike/tools/oef2course_GROK_V1.py` at tip; pwsh 7.4.6.
- Fidelity (`gbr2_fidelity_summary_GROK_V1.tsv`, per file `gbr2_gbr3_per_file_GROK_V1.csv`, script `fidelity_engine_metrics_GROK_V1.py`, seed 1):

| Metric | Count | Files | Gap |
|---|---|---|---|
| steps (children) | 2,140 | 300 | — |
| `check.type == value_equals` | **16** | 13 | numeric fidelity |
| `check.type == object_exists` | **1,824** | **281** | **GAP-5** |
| other check types | 0 | 0 | — |
| steps with `Hint:` in description | 38 | 8 | GAP-1 |
| steps with `engine` key | 0 | 0 | GAP-2 (expected 0, converter not V1_1) |
| steps with unresolved `$var` in title/description | 9 | 9 | GAP-6 symptom (lower bound) |
| `not numeric` warnings | 1,824 | 281 | = object_exists 1:1 |
| other warnings | 0 | 0 | — |
| convert failures | 0 | 0 | — |

- **GAP-5 is still #1 on tip**: 281 files / 1,824 answers, ahead of GAP-6 (214 files), GAP-1 (8 files) and GAP-2 (0 emitted). Unchanged versus 49d98f9 (identical counts), so the per-type breakdown at `bf0184b` still applies (clickfill/dragfill and the choice family lead).

## G-A3 — PR #49

GitHub API (read 2026-11-04 ~10:20 Paris): open, not draft, `mergeable: true`, `rebaseable: true`, `mergeable_state: clean`, 2 commits, 10 files, +72/−3. Base `feat/external-engines` is still at `4e13b83` (the commit merged in by `b9fdc4b`), so nothing has drifted. No action taken.

## G-A4 / GB-R3 — engine signals in corpus 300

Regex count on raw OEF source (`gbr3_engine_signals_GROK_V1.tsv`):

| Signal | Calls | Files |
|---|---|---|
| `wims(` | 1,979 | 208 |
| `slib(` | 117 | 95 |
| `pari(` | 18 | 16 |
| `maxima(` | 3 | 2 |
| `octave(` / `yacas(` / `gap(` / `m2(` / `scilab(` | 0 | 0 |
| `\pari` / `\maxima` / `gp -f` | 0 | 0 |
| `draw(` | 43 | 33 |
| `shuffle(` | 270 | 140 |
| **any named CAS** | — | **18** |
| **any runtime param (wims/slib/CAS)** | — | **214** |

Examples: `wims-full/public_html/modules/adm/tool/coordclick/data/example12.oef` (pari ×2), `.../coordclick/data/example11.oef` (pari ×2), `wims-full/public_html/scripts/model/es/src/chronology.oef` (pari ×1). Module `INDEX` files naming an engine keyword (pari/maxima/octave/yacas) under `wims-full/public_html/modules`: 11.
Note: the corpus is mostly modules/templates; compiled `.def` files also call `!exec maxima` / `!exec pari` (e.g. H6 `00072.def`), so real banks use CAS more than the `.oef` regex shows.

**Verdict:** an `engine` field on steps is *not* justified for the MVP offline help on this corpus (only 18/300 files name a CAS, all pari/maxima). The real blocker is runtime parameters (214/300 = GAP-6), which favours precomputed variants (D-WIMS GAP-6 option) over per-step engine calls.

## G-A5 / GB-R4 — suites 21–23 on #40–#42 heads (mock)

Detached worktrees, read-only, nothing pushed.

| Suite | Branch / head | Result | TAP |
|---|---|---|---|
| 21 WimsTemplate | `feat/grok-g14-wims-template` `0222ce1` | **14/0/0** | `21_WimsTemplate_GROK_V1.tap` |
| 22 WimsGradeClient | `feat/grok-g15-wims-grade-client` `a30f8ec` | **28/0/0** | `22_WimsGradeClient_GROK_V1.tap` |
| 23 WimsFullCycle | `feat/grok-g16-wims-full-cycle` `c9a6dd5` | **0/2/0** (FC-EXC timeout) | `23_WimsFullCycle_GROK_V1.tap` |

Suite 23 cause = environment, not template drift: the pinned Debian GeoGebra WAR (`/workspace/AlgoGebra/webwar/war`) was destroyed when another agent deleted `/workspace/AlgoGebra`. I substituted the official `geogebra-math-apps-bundle` (`GGB_WAR_DIR` staged as `deployggb.js` + `HTML5/5.0/web3d`) with Playwright 1.64.1 / Firefox r1555; the page timed out after 90 s waiting for `window.ggbApplet.getBase64` (applet never initialised). Previous run with the pinned WAR (`20261103-g14-g16-tip-6d62ef4`) was 13/0/0. To close: rebuild the WAR at the pin (gt2 recipe) and rerun 23. Suites 21/22 show no drift.

## G-A6 / GB-R5 — Debian HTTP WIMS

- Inventory: no apache2/lighttpd installed. `/workspace/wims-full` is a source tree (**not compiled**, no `public_html/wims`). Compiled 4.31b binaries exist in `/workspace/wims-ref` (43 MB, no OEF module) and `/workspace/oefc/wims-runtime` (182 MB, has `H6/test/oef2html.fr`).
- Used a **copy** of `/workspace/oefc/wims-runtime` at `/workspace/grok-g1/gv_wimsrt` (sources untouched) behind a 50-line Python CGI front (`gbr5_wims_http/wims_cgi_server_GROK_V1.py`) — no apache, no root, no system changes.
- **URL:** `http://127.0.0.1:18431/wims/wims.cgi`
- **Start:** `python3 /workspace/grok-g1/gv_wims_cgi_server.py /workspace/grok-g1/gv_wimsrt/public_html 18431` (wims spawns its own `wimslogd` from the copy). **Stop:** kill the server and that `wimslogd`. Left **stopped**.
- Probes (`gbr5_wims_http/`): A home 200 `text/html` "WIMS 4.31b"; B `cmd=new&module=H6/test/oef2html.fr&exo=00072` → session + `reply1` field (exercise uses `!exec maxima` + `!exec pari`, both ran); C `cmd=reply&reply1=15.9*x+20.55` → "note de 10 sur 10"; D wrong answer → "note de 0 sur 10"; E `cmd=getresult` → **HTTP 450** (GB-R1 Debian twin agrees with Windows probe).
- **Scoring usable: Y** (anonymous exercise scoring via `cmd=new`/`cmd=reply`, HTML output). Class/`adm/raw` scoring not exercised (no class or `.connections` set up).

## Out of scope / not done

GB-R6 (P2) not run. G-A1/G-A7 handled by the EE-P2 worker. No spec/schema edits; #40–#42 untouched.

## Addendum (2026-11-04 ~10:45 Paris) — G-A5 closed: suite 23 with the rebuilt pinned WAR

**G-A5 / GB-R4 → PASS** (21 = 14/0/0, 22 = 28/0/0, 23 = 13/0/0 ×2).

- **WAR rebuilt** under `/workspace/grok-g1/gv_war_375db7f/` from upstream `geogebra/geogebra` @ `375db7faf5407390bb322165f2414415da8faeda` (shallow fetch), G-T2 recipe: `./gradlew -p source/web :web:gwtCompile :web:copyHtml :web:mergeDeploy --no-daemon`, Temurin 21.0.13+9, Gradle wrapper 9.4.1 → BUILD SUCCESSFUL in 7m35s (63 tasks executed). `GGB_WAR_DIR=.../geogebra/source/web/web/war`.
- **Layout check vs G-T2** (`20261101-143847-gt2-war-debian`): 741 files, same as before; **737/741 byte-identical**, including `deployggb.js` (`55bfe441…`) and `web3d/web3d.nocache.js` (`b4c7254f…`). Only the 4 `*/sworker-locked.js` files differ (build-specific service-worker values).
- **Suite 23** on `feat/grok-g16-wims-full-cycle` @ `c9a6dd5` (detached worktree, read-only), mock CGI, Playwright 1.64.1 / Firefox r1555 headless (no X display needed):
  - run 1: **PASS 13 / FAIL 0 / SKIP 0**
  - run 2: **PASS 13 / FAIL 0 / SKIP 0**
- So the earlier 0/2/0 was caused by the substitute bundle, not by template drift.
- Evidence: `ga5_suite23_war375db7f/` (2 TAPs, build log, full WAR manifest).
