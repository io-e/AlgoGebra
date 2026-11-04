<!-- CLAUDE_V1_3 -->
# CDC — External Computation Engines for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/02-01_Wims_Integration/Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md` |
| Version | CLAUDE_V1_3 |
| Scope | **Engine layer only** (offline subprocess execution). WIMS integration (grading, submission, help templates, resolution tree) is in `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md`. |
| Status | **Post-audit revision** — incorporates Grok audit findings A-18, A-22, A-23, A-24, A-27 and owner decisions Q5–Q7 |
| Date | 2026-11-04 |
| Supersedes | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_2.md` |
| Reviews | Grok Bot PR #59, Codex review at `63f2190`, consolidated in `Consolidated_Review_Grok_Codex_CLAUDE_V1.md`, Grok audit `Audit_Specs_Wims_GBOT_v1.md` |
| Decisions | `Decisions_External_Engines_GROK_V1.md` (D-ENG-01..05, all closed), `Decisions_PARI_Forbidden_GROK_V1.md` (BUG-006), `Decision_Open_Points_Sprint3_CLAUDE_V1.md` (D-S01/D-S02), `QA_WIMS_Integration_Owner_ALF_V2.md` (Q-W1..Q-W9, OD-1..OD-4) |
| Depends on | V2 scenario X-04, `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` |
| Source ref | `D:\ALF_ZGit\02-wims4win\src\Interfaces\` (WIMS C interface wrappers) |
| JVM baseline | Java 21 (RQ-1, Debian RCPTT/AUT); Java 25 tested on Windows. `ProcessBuilder` usage is 21-compatible. |

---

## 1. Goal

Bring WIMS computation engines into AlgoGebra as **standalone external services**, without requiring the full WIMS server stack (Apache, `wims.cgi`, OEF framework, chroot, session management).

**This CDC covers the offline subprocess engine layer only.** The scope is:
- Engine discovery, invocation, security filtering, output parsing
- Per-engine specs (Pari/GP, Maxima, Gnuplot, GAP)
- Phase 1 (Windows subprocess proof) and Phase 2 (Linux validation)

**Out of scope** (separate WIMS CDC):
- Connected mode (WIMS server grading, submission protocol)
- Help templates and resolution tree (Q-W9)
- Exercise evaluation and formative feedback contracts
- LLM/RAG integration (Phase 3)

**Mode priority (owner decision Q-W2, OD-2):** Offline first. Local engines run on the student's machine via `SubprocessEngine`. This supersedes the earlier statement in `Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1 that engines run only on the WIMS server.

---

## 2. Engine inventory and priority

### EE-01: Implementation order (owner decision)

| Priority | Engine | Blocking? |
|---|---|---|
| **1st** | Pari/GP | Yes — first slice |
| **2nd** | Maxima | Yes |
| **3rd** | Gnuplot | Yes |
| **Optional** | GAP | No — does not block the others |

### EE-02: MVP engines

| Engine | Domain | WIMS interface | Command | License |
|---|---|---|---|---|
| **Pari/GP** | Number theory, arithmetic, polynomials, matrices | `src/Interfaces/pari.c` | `gp -f -q` | GPL v2 |
| **Maxima** | General symbolic CAS (derivatives, integrals, limits, simplification) | `src/Interfaces/maxima.c` | `maxima` | GPL v2 |
| **GAP** | Discrete algebra, group theory, combinatorics | `src/Interfaces/gap.c` | `gap.sh -T -n` (Linux) / `gap.exe -T -n` (Windows via Cygwin `gap_command`, DLL path) | GPL v2 |
| **Gnuplot** | 2D/3D function plots, image generation | (WIMS calls directly, no C interface) | `gnuplot` | Gnuplot license (BSD-like) |

### EE-03: Text processing layer

| Tool | Role | Runtime dependency? |
|---|---|---|
| **Python** | OEF→JSON conversion (`oef2course_GROK_V1.py`, suite 19). Data processing, notebook integration. | **Conversion-time only.** Not required at RCP engine runtime. |
| **Perl** | Raw OEF interpretation when exercises are not pre-converted to JSON. | **Optional.** Not required for the MVP (OEF is pre-converted by Python). Required only if raw OEF is interpreted at runtime — not in this slice. |

### Phase 2+ (future engines)

| Engine | Domain | Notes |
|---|---|---|
| **Octave** | Numerical computing (MATLAB-compatible) | `src/Interfaces/octave.c` exists. Heavy install (~500 MB). |
| **POV-Ray** | 3D ray-tracing visualization | No WIMS C interface. Direct subprocess. |
| **Fly** | 2D geometric image generation | WIMS-specific. May not be needed if GeoGebra 2D covers it. |
| **TeX/LaTeX** | Mathematical typesetting | Already in GeoGebra (JLaTeXMath). May need `pdflatex` for document generation. |

### Not planned (owner decision Q5)

| Engine | WIMS interface | Status |
|---|---|---|
| **yacas** | `src/Interfaces/yacas.c` | Exercises naming `yacas` → `gradable: false` offline |
| **m2** (Macaulay2) | `src/Interfaces/m2.c` | Exercises naming `m2` → `gradable: false` offline |
| **scilab** | `src/Interfaces/scilab.c` | Exercises naming `scilab` → `gradable: false` offline |

---

## 3. How WIMS wraps engines — the existing pattern

Each WIMS C interface (`pari.c`, `maxima.c`, `gap.c`) follows an identical pattern:

```
┌────────────────────────────────────────────────────────┐
│  WIMS Interface (C binary, e.g. wims/bin/pari)         │
│                                                         │
│  1. Security check: strip dangerous commands            │
│     (file I/O, system calls, plot, load, debug)         │
│                                                         │
│  2. Header injection: math aliases + settings           │
│     Pari: ln→log, pi→Pi, sec(x)=1/cos(x), etc.        │
│     Maxima: display2d:false, nolabels:true, etc.        │
│     GAP: (minimal header)                               │
│                                                         │
│  3. Spawn engine subprocess via pipe                    │
│     wp_spawn(&chan, arg, inf, outf, errf, iso, ...)     │
│                                                         │
│  4. Send: header + dynamic setup + user command + quit  │
│                                                         │
│  5. Read stdout, parse output:                          │
│     - Strip prompts ("? ", "gap> ", "(%i...")            │
│     - Make output one-line per result                    │
│     - Strip trailing zeros, remove matrix wrapping       │
│                                                         │
│  6. Print cleaned result to stdout                      │
└────────────────────────────────────────────────────────┘
```

### EE-04: Key pieces to extract (per engine)

| Component | Location in wims4win | Purpose | Reusable? |
|---|---|---|---|
| **Header string** | `char header[]` in `pari.c`, `maxima.c`, `gap.c` | Math aliases (ln→log, pi→Pi, etc.) | Yes — copy verbatim |
| **Dynamic setup** | `dynsetup()` | Precision, random seed, series length | Yes — parameterize |
| **Security filter** | `check_parm()` + `illegal[]` + `illpart[]` | Block dangerous commands | Yes — essential for student mode |
| **Output parser** | `output()` | Strip prompts, normalize output format | Yes — adapt to Java |
| **Quit string** | `char *quitstring` | How to tell the engine to exit | Yes — copy verbatim |
| **Command name** | `char *nameofcmd` | Binary + flags | Yes — platform-dependent |

### What we do NOT need from WIMS

| WIMS component | Why not needed |
|---|---|
| `wims.cgi` | AlgoGebra is the host, not a CGI |
| Apache / HTTP | No web server for local engine calls |
| `chroot` / sandboxing | AlgoGebra uses WIMS command filters + process timeout (D-ENG-03). OS sandbox is later. |
| OEF framework | OEF→JSON conversion is done at build/conversion time by Python (`oef2course_GROK_V1.py`), not at engine runtime |
| `libwims.h` / `wimsdef.h` | WIMS internal utilities — replaced by Java equivalents (D-ENG-01) |
| Session management | AlgoGebra manages its own sessions |
| `wp_spawn` / `wp_chan` | WIMS platform abstraction — replaced by Java `ProcessBuilder` (D-ENG-01) |

---

## 4. AlgoGebra integration architecture

### 4.1 The "External Computation Service" pattern

Per V2 binding decision: domain algorithms are **external computation services**, not native `AlgoElement` subclasses. A result that comes back into a figure is **one-shot**. It is not an `AlgoElement`, and `common` is not edited.

```
┌─────────────────────────────────────────────────────────┐
│  AlgoGebra (Java / Equinox)                              │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  org.geogebra.plus.compute.api (OSGi bundle)      │  │
│  │                                                     │  │
│  │  ExternalComputeService interface                   │  │
│  │    eval(String command, ComputeContext ctx)          │  │
│  │      → ComputeResult (string | image | error)       │  │
│  │    getCapabilities() → Set<Capability>               │  │
│  │    isAvailable() → boolean                           │  │
│  └────────────┬──────────────────────────────────────┘  │
│               │                                          │
│  ┌────────────▼──────────────────────────────────────┐  │
│  │  SubprocessEngine (abstract)                       │  │
│  │    - Java ProcessBuilder with stdin/stdout pipes    │  │
│  │    - Header injection (from WIMS header strings)    │  │
│  │    - Security filter (ported WIMS illegal[] lists)  │  │
│  │    - Output parser (ported WIMS output() functions) │  │
│  │    - Timeout + process kill on hang                  │  │
│  └────────────┬──────────────────────────────────────┘  │
│               │                                          │
│  ┌────────────▼──┐  ┌──────────┐  ┌──────┐  ┌────────┐│
│  │ PariGPEngine  │  │ Maxima   │  │ GAP  │  │Gnuplot ││
│  │ (1st slice)   │  │ (2nd)    │  │(opt) │  │(3rd)   ││
│  └───────────────┘  └──────────┘  └──────┘  └────────┘│
│                                                          │
│  Engine binaries: pre-installed on PATH (D-ENG-02)       │
│  Missing binary → error for grading (D-ENG-02)           │
│  Missing binary → Phase 2 WIMS fallback (Q-W6)           │
└─────────────────────────────────────────────────────────┘
```

**Engine availability rules (D-ENG-02 + Q-W6):**
- **Grading (offline):** missing engine binary = error. No silent fallback. The student/teacher is told which engine is missing and how to install it.
- **Interactive exploration:** **Phase 2.** Requires a WIMS compute endpoint (see WIMS CDC WI-24). MVP shows "engine not installed" error.

### 4.2 What goes into the GeoGebra kernel vs. the compute API

| Layer | What | Where | Edits `common`? |
|---|---|---|---|
| **Kernel** | `AlgoElement` subclasses, construction objects | `common` | **NO** — binding decision |
| **Compute API** | `ExternalComputeService` interface, `ComputeResult` | `org.geogebra.plus.compute.api` bundle | No — new code |
| **Engine bundles** | `PariGPEngine`, `MaximaEngine`, etc. | Separate OSGi bundles, register as services | No — new code |
| **Bridge** | Writing a computation result back into a construction | Activity contract (X-04) | No — uses public API |

**Critical distinction:** An external computation result written via API is **not** a native dependent construction object. The construction does not auto-update when inputs change. That requires an `AlgoElement`, which requires editing `common` (forbidden). The external computation is a **one-shot evaluation**.

### 4.3 CAS engine roles (D-ENG-05, closed)

| Engine | Role | When it runs |
|---|---|---|
| **GIAC** | Native CAS — Algebra View, CAS View | Always. GeoGebra kernel uses GIAC via JNI. |
| **Maxima** | External CAS — WIMS exercises that name `maxima` | Only when a WIMS exercise specifies Maxima as its engine. |
| **Pari/GP** | External CAS — WIMS exercises that name `pari` | Only when a WIMS exercise specifies Pari/GP. |

GIAC runs the Algebra and CAS views. Maxima, Pari, or GAP runs **only when the WIMS exercise names that engine**. No overlap, no fallback between CAS engines.

### 4.4 Connected mode (deferred)

Connected mode (WIMS server grading) is **deferred** pending the WIMS integration CDC. PRs #40–#42 (D-S01 grade client) are parked as Phase 2 work (owner decision OD-3). The current grade client returns a single `{grade: 0..1, feedback}` object; the WIMS CDC V2 defines the per-answer structured result required by Q-W4 and the stock `cmd=new/reply` + JSON hook approach.

---

## 5. Per-engine MVP spec

### EE-10: Pari/GP (1st slice)

| Item | Value |
|---|---|
| Binary | `gp -f -q` (Windows: `gp.exe -f -q`). Pin version: Debian 2.17.x, Windows from pari.math.u-bordeaux.fr. |
| Header | WIMS `pari.c` header: 30 aliases (ln→log, pi→Pi, sec, csc, lg, etc.) + `default(secure,1)` |
| Dynamic setup | `\p <precision>`, `\ps <serieslength>`, `setrand(<seed>)` |
| Security filter | **Full AGB_ILLEGAL list** (aligned with `Decisions_PARI_Forbidden_GROK_V1.md`, BUG-006): block `plot`, `plotinit`, `write`, `writebin`, `help`, `system`, `extern`, `externstr`, `fileextern`, `install`, `eval`. Block escape commands (`\` except `\\`, `\v`, `\p`). Whole-word match, applied before process spawn. Returns `COMMAND_REJECTED` on match. |
| Output parsing | Strip `? ` prompts, strip `Good bye!`, one-line per result, remove `Mat()` / `Vecsmall()` wrapping, strip trailing zeros. Output is **after the output parser** (post-cleanup). |
| Quit | `\nquit\n` |
| Test command | `factor(2^64-1)` → `[3, 1; 5, 1; 17, 1; 257, 1; 641, 1; 65537, 1; 6700417, 1]` (after output parser, pinned gp version) |
| Failure handling | Empty output on valid input = error (BUG-015 / X-06). Malformed input must not return successful empty output. |
| Install size | ~20 MB (Windows binary from pari.math.u-bordeaux.fr) |

**Security note (D-ENG-03):** Command filters are ported from WIMS and are the same protection WIMS uses. They are **not a sandbox**. A determined attacker may bypass string-level filters. OS-level sandboxing (seccomp, AppArmor) is a separate hardening task for institutional deployments, not part of this slice. See SBX-14..19 for existing test coverage.

### EE-11: Maxima (2nd slice)

| Item | Value |
|---|---|
| Binary | `maxima` (Windows: `maxima.bat` or MSYS2 `maxima`) |
| Header | WIMS `maxima.c` header: `display2d:false`, `nolabels:true`, 20+ aliases |
| Dynamic setup | `fpprec:<precision>` |
| Security filter — `illegal[]` (whole-word) | `system`, `describe`, `example`, `save`, `fassave`, `stringout`, `batcon`, `batcount`, `cursordisp`, `direc`, `readonly`, `with_stdout`, `pscom`, `demo`, `ttyintfun`, `bug` |
| Security filter — `illpart[]` (substring) | `file`, `debug`, `plot`, `load`, `store`, `batch` |
| Output parsing | Strip `(%i` / `(%o` labels, collapse multi-line output |
| Quit | `\nquit();\n` |
| Test command | `diff(sin(x^2), x);` → `2*x*cos(x^2)` |
| Failure handling | Same as EE-10: empty output on valid input = error. |
| Install size | ~100 MB (includes SBCL/CLISP Lisp runtime) |

**Note:** The full `illegal[]` and `illpart[]` lists are from `maxima.c` (source: `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` §2.3). PR #60 code (`MaximaEngine.java` L58-62) already has the complete lists. The previous V1_2 spec had only 8 entries — this V1_3 aligns spec with both WIMS source and Codex implementation.

### EE-12: Gnuplot (3rd slice)

| Item | Value |
|---|---|
| Binary | `gnuplot` |
| Header | `set terminal pngcairo size 800,600` (configurable). Output path forced by host. |
| Dynamic setup | Output filename (host-controlled temp dir), ranges, style |
| Security filter | Block: `system`, `shell`, `!` prefix, `set output`, `set print`, `load`, `call`, `save`, backticks. The host forces the output path — the student cannot redirect output to arbitrary files. |
| Output | PNG file written to host-controlled temp directory. AlgoGebra reads the image and validates PNG magic bytes (D-ENG-04). GeoGebra's own 2D/3D views stay GeoGebra. |
| Quit | `\nexit\n` |
| Test command | `plot sin(x)` → produces valid PNG file (magic bytes check) |
| Install size | ~10 MB |

### EE-13: GAP (optional, does not block others)

| Item | Value |
|---|---|
| Binary | `gap.sh -T -n` (Linux) / `gap.exe -T -n` (Windows via Cygwin — wims4win uses `gap_command` with Cygwin DLL path) |
| Header | Minimal (empty in WIMS) |
| Dynamic setup | None |
| Security filter | Block: `Reread`, `Process`, `Exec`, `Filename`, `SaveWorkspace`, `File`, `Path`, `Read`, `To` |
| Output parsing | Strip `gap> ` prompts, collapse continuation lines (`\\\n`), one-line per result |
| Quit | `\nquit;\n` |
| Test command | `Size(SymmetricGroup(5));` → `120` |
| Install size | ~500 MB (includes GAP packages) |

---

## 6. Implementation plan

### Phase 1: Windows subprocess proof (Codex)

| ID | Deliverable | Done when |
|---|---|---|
| EE-P1a | `SubprocessEngine` abstract class: Java `ProcessBuilder`, stdin/stdout pipe, timeout, process kill | Unit test with a mock engine: start, send command, receive output, timeout kills process |
| EE-P1b | `PariGPEngine` with full AGB_ILLEGAL filter + header + output parser | `factor(2^64-1)` returns correct post-parser result. `system("ls")` returns `COMMAND_REJECTED`. Empty-output on valid input = error. |
| EE-P1c | `MaximaEngine` with WIMS header + full `illegal[]`/`illpart[]` filter + output parser | `diff(sin(x^2), x)` returns `2*x*cos(x^2)`. Blocked commands rejected. |
| EE-P1d | `GnuplotEngine` with host-controlled PNG output | `plot sin(x)` produces valid PNG (magic bytes). `set output "/etc/passwd"` rejected. |
| EE-P1e | Engine discovery: check if binary exists on PATH | `isAvailable()` returns true/false per engine. Missing binary = error message naming the engine. |
| EE-P1f | (Optional) `GAPEngine` with filter + output parser | `Size(SymmetricGroup(5))` returns `120` |

### Phase 2: Linux validation (Grok Bot)

| ID | Deliverable | Done when |
|---|---|---|
| EE-P2a | Install Pari/GP, Maxima, GAP, Gnuplot on Debian | Binaries on PATH, versions pinned and recorded |
| EE-P2b | Run test commands via WIMS C interfaces (`bin/pari`, `bin/maxima`, `bin/gap`) | All EE-P1 test commands produce output via `bin/*`; provenance (wims4win build or Debian `wims` package) recorded |
| EE-P2c | Run same test commands via AlgoGebra Java `SubprocessEngine` on Linux | `EngineAcceptanceTest` green on Debian, Java 21 (RQ-1) |
| EE-P2d | Compare output: WIMS C vs. Java subprocess on fixture set F | Values match on fixture set F (≥20 cases per engine). Rejections at least as strict as WIMS (Java may reject more, not fewer). |

**Fixture set F status:** PR #61 ran 27 cases (Pari 12, Maxima 6, Gnuplot 6, GAP 3). Values identical. Pari and Gnuplot meet ≥20; **Maxima needs ≥14 more cases, GAP needs ≥17 more.** Grok defines and extends fixture set F on next EE-P2 rerun.

### Phase 3: AlgoGebra host integration (Codex)

| ID | Deliverable | Done when |
|---|---|---|
| EE-P3a | `ExternalComputeService` OSGi interface in `compute.api` bundle | Interface compiles, bundle resolves in Equinox |
| EE-P3b | Engine bundles register as OSGi services | `ServiceTracker` finds registered engines at runtime |
| EE-P3c | Host UI: "Compute" panel or input bar extension | Student can type an expression, select engine, see result |
| EE-P3d | Activity contract (X-04): write result into GeoGebra construction | One-shot write via public API, construction object created, not auto-updating |

### Phase 4: WIMS connected mode — DEFERRED

**Deferred** pending the WIMS integration CDC V2. PRs #40–#42 parked (owner decision OD-3). S-01 and S-02 remain NOT RUN.

| ID | Deliverable | Done when | Status |
|---|---|---|---|
| EE-P4a | Submission contract | WIMS CDC V2 defines the wire format (WI-22) | **Deferred** |
| EE-P4b | WIMS evaluation + per-answer results | WIMS CDC V2 defines structured response (Q-W4) | **Deferred** |
| EE-P4c | Grade display in AlgoGebra UI | Course tree renders feedback | **Deferred** |
| EE-P4d | End-to-end test on Debian | Grok Bot: real WIMS exercise, full cycle | **Deferred** |

Offline scoring (exercise-defined criteria, local evaluation) requires the evaluation contract from the WIMS CDC V2. Until that contract is specified, the accepted scope is **engine execution only** (compute a result and return it), not grading.

---

## 7. Owner decisions (all closed)

All five engine decisions were closed on 2026-10-29. Full rationale in `Decisions_External_Engines_GROK_V1.md`. Additional owner decisions from 2026-11-03 in `QA_WIMS_Integration_Owner_ALF_V2.md`.

| Decision | Choice | Summary |
|---|---|---|
| **D-ENG-01** | **A. Java ProcessBuilder** | Copy WIMS headers, illegal-command lists, and output cleanup. Do not compile the WIMS C interfaces. |
| **D-ENG-02** | **A. Pre-installed on PATH** | Product does not bundle or download engines. Missing binary = error for grading, Phase 2 exploration fallback (Q-W6). |
| **D-ENG-03** | **A. Port WIMS command filters** | Port filters to Java + kill process on timeout. Filters are not a sandbox. OS sandbox is later, not this slice. |
| **D-ENG-04** | **A. Gnuplot writes PNG** | AlgoGebra reads the temp file. GeoGebra's own 2D/3D views stay GeoGebra. |
| **D-ENG-05** | **A. GIAC for kernel, others for WIMS** | GIAC runs Algebra/CAS views. Maxima/Pari/GAP run only when the WIMS exercise names that engine. |
| **OD-1** | **Separate CDCs** | This CDC covers the engine layer. WIMS integration (Q-W1..Q-W9) is a separate document. |
| **OD-2** | **Local engines (offline first)** | Supersedes `Decisions_GIAC_Complet_WIMS_GROK_V1.md` §1 ("engines only on WIMS server"). |
| **OD-3** | **PRs #40–#42 parked** | Phase 2 connected mode. Grade client stays single-score until WIMS CDC V2 defines per-answer format. |
| **OD-4** | **GPL v2 deferred to Gate E** | License audit for WIMS-derived code (filter tables, headers) is O-02, Gate E. Noted as risk. |

---

## 8. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| EE-R1 | Engine binary not installed on student machine | High | Feature unavailable | Clear error messages. `isAvailable()` check at startup. Install guide per platform. Q-W6 Phase 2 exploration fallback. |
| EE-R2 | Maxima version mismatch (WIMS expects specific version) | Medium | Wrong results for edge cases | Pin supported versions. Phase 2d fixture comparison. |
| EE-R3 | GAP install too large (~500 MB) for casual users | Medium | User won't install | GAP is optional. Only group-theory courses need it. |
| EE-R4 | Security filter bypass in offline mode | Low | Student executes arbitrary code | WIMS filters are not a sandbox (D-ENG-03). OS sandboxing for institutional deployments is a separate hardening task. |
| EE-R5 | Output parsing differences WIMS C vs. Java | Medium | Offline exercises grade incorrectly | Phase 2d: values match on ≥20 fixtures per engine, rejections at least as strict. |
| EE-R6 | Engine subprocess hangs (infinite loop) | Medium | AlgoGebra freezes | Timeout + process kill (D-ENG-03). |
| EE-R7 | Empty/malformed output on valid input (BUG-015) | Medium | Silent wrong answer | EE-P1b acceptance: empty output on valid input = error, not success. X-06 fail tracked. |
| EE-R8 | GPL v2 obligations from WIMS-derived filter tables and headers | Medium | License conflict with EUPL 1.2 product | Deferred to O-02 / Gate E. Do not distribute until license inventory is complete. |
| EE-R9 | wims4win install on student machines (Shadow PC) | Low | Configuration complexity | Install guide, resource requirements documented (Q-W7). |

---

## 9. Scenario and contract status

| Scenario / Contract | Status | Notes |
|---|---|---|
| X-01 (compute contract) | **Partial** | Missing result-kind contract (string vs image vs error typing) |
| X-02 (revision/stale-result) | **Fail** | No revision or stale-result handling defined |
| X-04 (external compute → kernel) | **Not run** | Depends on Phase 3 host integration |
| X-06 (BUG-015: malformed input) | **Fail** | Malformed PARI input can return successful empty output. EE-P1b adds acceptance criteria. |
| S-01 (WIMS schema/capability) | **Not run** | Deferred to WIMS CDC V2 |
| S-02 (submission) | **Not run** | Deferred to WIMS CDC V2 |

---

## 10. Relation to other documents

| Document | Relation |
|---|---|
| `Cdc_WIMS_Integration_AlgoGebra_CLAUDE_V2.md` | WIMS integration layer. References this CDC for engine invocation. |
| `Decisions_External_Engines_GROK_V1.md` | Owner decisions D-ENG-01..05 (all closed). |
| `Decisions_PARI_Forbidden_GROK_V1.md` | BUG-006 Pari security filter (AGB_ILLEGAL list, SBX-14..19). |
| `QA_WIMS_Integration_Owner_ALF_V2.md` | Owner decisions Q-W1..Q-W9, OD-1..OD-4 (2026-11-03). |
| `Decision_Open_Points_Sprint3_CLAUDE_V1.md` | D-S01 (withdrawn — replaced by L2-1 hook), D-S02 (Lean 4 = batch). |
| `Schema_Course_JSON_CLAUDE_V1_2.json` | Course schema with extended check types, `engine` field, `gradable`, `variants[]`. |
| `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` | GIAC is the **native** CAS (JNI). This CDC covers **external** engines (subprocess). |
| `Gate_Decision_D-04_D-05_GROK_V1_1.md` | D-05 GIAC native loading PASS. External engines are Phase 2+. |
| `Audit_Specs_Wims_GBOT_v1.md` | Grok audit with 34 findings. V1_3 resolves A-18, A-22, A-23, A-24, A-27. |
| V2 scenarios X-01..X-06 | Activity/compute contracts. `ExternalComputeService` is part of the compute contract. |
| wims4win `src/Interfaces/` | Source of the security filters, headers, and output parsers. **GPL v2** — license implications deferred to O-02 / Gate E. |
| `Consolidated_Review_Grok_Codex_CLAUDE_V1.md` | Merged review findings (F-01..F-18, OD-1..OD-4). |
| `Implementation_WIMS_AlgoGebra_from_wims4win_GROK_V1.md` | Grok code audit: exact `illegal[]`/`illpart[]` arrays per engine. |

---

## 11. Audit finding resolution (V1_3)

| Audit finding | Resolution |
|---|---|
| **A-18** (Maxima filter shorter than `maxima.c`) | EE-11: full `illegal[]` (16 entries) + `illpart[]` (6 entries) from IMPL §2.3 |
| **A-22** (EE-P2b/P2c not acceptance criteria) | EE-P2b/P2c reworded with testable pass criteria |
| **A-23** (EE-P2d fixture set F undefined) | EE-P2d: "values match; rejections at least as strict"; fixture gap quantified |
| **A-24** (engine list vs wims4win) | §2: yacas/m2/scilab listed as "not planned" → `gradable: false` |
| **A-27** (GAP Windows via Cygwin) | EE-02/EE-13: Cygwin `gap_command` noted |

---

*End of `Cdc_External_Engines_AlgoGebra_CLAUDE_V1_3.md`.*
