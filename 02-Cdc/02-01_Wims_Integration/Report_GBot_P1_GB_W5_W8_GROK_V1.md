<!-- GROK_V1 -->
# Report — GBot P1: GB-W5, GB-W7, GB-W8, GB-E1

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1 |
| Executor | Grok Build (Windows CGI + wims4win draft); Debian live suites deferred |
| Policy | Draft only — **no merges** |
| wims4win | `feat/algogebra-wims-integration` @ `4ae4d86` |
| Evidence | `03-RCP-Spike/evidence/20261105-gbot-p1-gb-w5-w8_GROK_V1/` |
| Probe JSON | `out_probe_gbot_p1_report_GROK_V1.json` (also under wims4win `AlgoGebra_Wims_Integration/tests/`) |

---

## Summary

| ID | Result | Notes |
|---|---|---|
| **GB-W5** | **DONE (draft)** | `tools/build-runtime-tree.sh` installs hook via `install_algogebra_hook_GROK_V1.sh` |
| **GB-W7** | **PARTIAL** | Windows CGI probes + client rules recorded; **live Debian suites 21–23 still for GBot box** |
| **GB-W8** | **DONE (partial accent)** | Charset `windows-1252` + decode path recorded; accented-**correct** answer **UNVERIFIED** |
| **GB-E1** | **DONE** | #57 / #58 rechecked vs tip `9d67b57` — both **behind**; comments posted; no merge |

**wimslogd:** **stopped** (`wimslogd_running: false`). **Not restarted.** Do not start unless owner confirms it is needed.

---

## GB-W5 — `build-runtime-tree.sh`

| Change | Path |
|---|---|
| Hook installer (bash) | `AlgoGebra_Wims_Integration/runtime_patch/install_algogebra_hook_GROK_V1.sh` |
| Called from packaging | `tools/build-runtime-tree.sh` (after site conf, before `wims-runtime.tgz`) |
| Existing Windows installer | `install_algogebra_hook_GROK_V1.ps1` (unchanged) |

Rebuild of a full runtime tarball was **not** re-run here (long compile). Installer is wired so the next `build-runtime-tree.sh` run embeds the hook. Manual install on current `wims-runtime-oef` was already present from prior work.

---

## GB-W7 / GB-W8 — probe results (Windows direct CGI)

Runtime: `…/Reprise_Wims_Grok/wims-runtime-oef`, WIMS **4.33a**, hook in `answer.phtml`.

### Invalid-answer vs missing hook (no new status block)

| Case | JSON block | `answer_analysis` | Sure / incomplete UI |
|---|---|---|---|
| Non-numeric reply **with** `special_parm=algogebra_json` | **absent** | absent | **present** (`Êtes-vous sûr` / `exo_formCheck`) |
| Graded wrong numeric **without** `special_parm` | **absent** | **present** | absent |
| Graded wrong/right numeric **with** `special_parm` | **present** | present | absent |

**Client rule (no new JSON `status` without approval):**

1. `ALGOGEBRA_JSON_BEGIN` present → hook fired; use `grade` / `answers`.  
2. Absent + `answer_analysis` → reply graded but hook off/missing.  
3. Absent + sure/incomplete UI → WIMS did **not** finish grading this POST; treat as retry page, **not** as missing-hook grade.

### Encoding

| Item | Value |
|---|---|
| Page `Content-Type` charset | **`windows-1252`** |
| JSON decode | Decode CGI body with that charset → extract comment → `json.loads` |
| Accented typed | `été` (UTF-8 percent-encoding in query) |
| Accented result | Hits sure/incomplete UI; **no JSON** on numeric fixture |
| Accented-correct OEF | **UNVERIFIED** (00006/00076 are numeric/checkbox) |

### Grade type

| Case | Observed JSON | Python type |
|---|---|---|
| Wrong | `{"grade": 0}` | `int` |
| Right | `{"grade": 1}` | `int` |

**Client rule:** accept JSON **numbers** `0` and `1`; do **not** require decimals (`0.0`) or strings (`"0"`).

### `given` value

| Student typed | `answers[].given` in JSON |
|---|---|
| `"  2  "` | `"2"` |

**Rule:** WIMS applies `!singlespace` (then escapes). **Do not** present `given` as the exact text the student typed.

### Suites 21–23

| Scope | Status |
|---|---|
| This Windows run | Hook CGI probes only (not Playwright full cycle) |
| Live Debian + hook | **Deferred** to GBot Debian box (GB-W7 remainder) |
| Mock baseline | Prior residual: suite 21/22 PASS on #40/#41; suite 23 env-sensitive |

---

## GB-E1 — PRs #57 / #58 vs tip

Tip: `origin/feat/external-engines` @ **`9d67b57`** (includes #49, #60, #61).

| PR | Base still | Behind tip | mergeable (API) | Action |
|---|---|---|---|---|
| **#57** gap-fill l10n | `4e13b83` | **~24 commits** | UNKNOWN at check time | Rebase onto tip before review/merge; **no merge** |
| **#58** suite 15 web | `4e13b83` | **~24 commits** | MERGEABLE/CLEAN vs old base | Rebase onto tip; evidence may need refresh; **no merge** |

Comments posted on both PRs with this status.

---

## Follow-ups for Debian GBot

1. Pull wims4win `4ae4d86`; install hook on `wims-full` if not already.  
2. Re-run GB-W3/W4 smokes on `http://127.0.0.1:18431/wims/wims.cgi`.  
3. Finish **GB-W7**: suites 21–23 vs **live** hook; list WA-9 gaps.  
4. Optional: one OEF with accented **correct** answer for GB-W8 closure.  
5. Keep **wimslogd stopped** unless owner asks otherwise.

---

*End of `Report_GBot_P1_GB_W5_W8_GROK_V1.md`.*
