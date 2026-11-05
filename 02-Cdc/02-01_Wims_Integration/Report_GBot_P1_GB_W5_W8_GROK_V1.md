<!-- GROK_V1_1 -->
# Report — GBot P1: GB-W5, GB-W7, GB-W8, GB-E1

| Field | Value |
|---|---|
| Date | 2026-11-05 |
| Version | GROK_V1_1 |
| Executor | Grok Build (Windows CGI + wims4win) + **Grok Bot Debian** ([#64](https://github.com/io-e/AlgoGebra/pull/64)) |
| Policy | Draft / evidence only — **no merges** |
| wims4win | `feat/algogebra-wims-integration` @ `4ae4d86` |
| Debian evidence PR | **#64** @ `da6d1a4` (`grok/gbot-algogebra-json-debian`) |
| Windows evidence | `03-RCP-Spike/evidence/20261105-gbot-p1-gb-w5-w8_GROK_V1/` |
| Debian evidence | `…/20261105-gbot-algogebra-json-debian_GROK_V1/` + `…/20261105-gbot-live-suites-accent_GROK_V1/` |
| Companion | `Report_GBot_AlgoGebra_JSON_Debian_GROK_V1.md` (on #64) |

---

## Summary

| ID | Result | Notes |
|---|---|---|
| **GB-W5** | **DONE (draft)** | Installer + `build-runtime-tree.sh`; Debian parity byte-identical (#64 A.1) |
| **GB-W7** | **DONE on Debian** | Live suites 21–23 (#64 A.2). Codex gaps **G1–G10** in A.3 / § below |
| **GB-W8** | **VERIFIED** | Accented correct on Debian (`été` cp1252 → grade 1). UTF-8 submit wrong (#64 A.4) |
| **GB-E1** | **DONE** | #57 / #58 behind tip; comments posted; no merge |

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

### Suites 21–23 — **DONE on Debian** (see #64)

| Suite | Live result | Notes |
|---|---|---|
| **21** template | **14/0/0** | Static; still asserts D-S01 wording (Codex G9) |
| **22** grade client | **19/9/0** | Live HTML ≠ mock JSON; fails are WA-9 contract gaps (G1–G8) |
| **23** full cycle | **4/2/0** | FC-01..04 pass; FC-05 timeout — client still posts D-S01 `job=getresult` (G10) |

Evidence: `03-RCP-Spike/evidence/20261105-gbot-live-suites-accent_GROK_V1/tap/` on **PR #64**.

### GB-W8 accent — **VERIFIED** on Debian (#64 A.4)

| Case | Result |
|---|---|
| `été` / `ÉTÉ` sent as **cp1252** | grade **1**, JSON present, `given`/`expected` raw cp1252 bytes |
| `été` sent as **UTF-8** (GET or POST) | grade **0** (mojibake `Ã©tÃ©`) — WIMS does not honour UTF-8 form charset |
| Client rule | Percent-encode `replyN` in **windows-1252**; Spec §5 UTF-8 claim needs Claude correction |

### Codex gap list from GB-W7 (WA-9) — copy of #64 A.3

| # | Mock / suite assumes | Real WIMS + hook |
|---|---|---|
| G1 | `job=getresult` single POST | `cmd=new` → session → `cmd=reply` |
| G2 | no session | parse + resend `session` |
| G3 | `exercise` / `ans1` | `exo` / `replyN`/`choiceN` |
| G4 | no trigger | `special_parm=algogebra_json` on reply only |
| G5 | raw JSON body | HTML + `ALGOGEBRA_JSON_*` comment; `{grade,seed,answers[],feedback}` |
| G6 | HTML ⇒ error only | 3-way: JSON / `answer_analysis` / retry UI |
| G7 | UTF-8 JSON.parse | page + reply **cp1252** |
| G8 | mock 413/500/timeouts | stay mock-only |
| G9 | suite 21 D-S01 README asserts | reword for `new`/`reply` |
| G10 | suite 23 asserts `adm/class/sheet` | assert `cmd=reply` + `special_parm` + `replyN` |

---

## GB-E1 — PRs #57 / #58 vs tip

Tip: `origin/feat/external-engines` @ **`9d67b57`** (includes #49, #60, #61).

| PR | Base still | Behind tip | mergeable (API) | Action |
|---|---|---|---|---|
| **#57** gap-fill l10n | `4e13b83` | **~24 commits** | UNKNOWN at check time | Rebase onto tip before review/merge; **no merge** |
| **#58** suite 15 web | `4e13b83` | **~24 commits** | MERGEABLE/CLEAN vs old base | Rebase onto tip; evidence may need refresh; **no merge** |

Comments posted on both PRs with this status.

---

## Follow-ups

| Who | Action |
|---|---|
| Owner | Review **#64** (evidence-only; no merge required to consume gaps) |
| Codex | WA-9 client rebase using G1–G10 above |
| Claude | Spec §5: reply encoding = **cp1252**, not UTF-8; document integer `grade` |
| GBot | Idle on W5–W8; next board = `Planning_GBot_Codex_Next_GROK_V1.md` |

Keep **wimslogd stopped** unless owner confirms it is needed.

---

*End of `Report_GBot_P1_GB_W5_W8_GROK_V1.md` (GROK_V1_1 — GB-W7/W8 closed via #64).*
