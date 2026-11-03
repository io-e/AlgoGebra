<!-- CLAUDE_V1_1 -->
# CDC — External Computation Engines for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/Cdc_External_Engines_AlgoGebra_CLAUDE_V1_1.md` |
| Version | CLAUDE_V1_1 |
| Status | **Decisions closed** — ready for Codex implementation |
| Date | 2026-10-29 |
| Supersedes | `Cdc_External_Engines_AlgoGebra_CLAUDE_V1.md` |
| Decisions | `Decisions_External_Engines_GROK_V1.md` (all 5 closed, option A each) |
| Depends on | V2 scenario X-04, `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` |
| Source ref | `D:\ALF_ZGit\02-wims4win\src\Interfaces\` (WIMS C interface wrappers) |

---

## 1. Goal

Bring WIMS computation engines into AlgoGebra as **standalone external services**, without requiring the full WIMS server stack (Apache, `wims.cgi`, OEF framework, chroot, session management).

Two modes:
- **Connected mode:** WIMS server grades. AlgoGebra runs engines locally for interactive exploration.
- **Offline mode:** AlgoGebra runs everything locally, including exercise validation. WIMS format compatibility but no WIMS runtime dependency.

---

## 2. Engine inventory and priority

### Implementation order (owner decision)

| Priority | Engine | Blocking? |
|---|---|---|
| **1st** | Pari/GP | Yes — first slice |
| **2nd** | Maxima | Yes |
| **3rd** | Gnuplot | Yes |
| **Optional** | GAP | No — does not block the others |

### MVP engines

| Engine | Domain | WIMS interface | Command | License |
|---|---|---|---|---|
| **Pari/GP** | Number theory, arithmetic, polynomials, matrices | `src/Interfaces/pari.c` | `gp -f -q` | GPL v2 |
| **Maxima** | General symbolic CAS (derivatives, integrals, limits, simplification) | `src/Interfaces/maxima.c` | `maxima` | GPL v2 |
| **GAP** | Discrete algebra, group theory, combinatorics | `src/Interfaces/gap.c` | `gap.sh -T -n` (Linux) / `gap.exe -T -n` (Windows) | GPL v2 |
| **Gnuplot** | 2D/3D function plots, image generation | (WIMS calls directly, no C interface) | `gnuplot` | Gnuplot license (BSD-like) |

### Text processing layer (cross-cutting, required)

| Tool | Role | Notes |
|---|---|---|
| **Perl** | OEF exercise parsing, WIMS text processing, regex-heavy transformations | WIMS uses Perl extensively for exercise template processing. **Required** for any mode that reads/writes OEF format. Complements Python (data/ML) and Java (host). |
| **Python** | Data processing, notebook integration, ML-based validation | Already in the ecosystem (conda `quiz_env` for OEF interpreter). |

Perl is the **OEF reader**, not a fifth compute engine. It is a required text-processing dependency for OEF format compatibility. Both connected and offline modes need it when handling WIMS exercises.

### Phase 2+ (future)

| Engine | Domain | Notes |
|---|---|---|
| **Octave** | Numerical computing (MATLAB-compatible) | `src/Interfaces/octave.c` exists. Heavy install (~500 MB). |
| **POV-Ray** | 3D ray-tracing visualization | No WIMS C interface. Direct subprocess. |
| **Fly** | 2D geometric image generation | WIMS-specific. May not be needed if GeoGebra 2D covers it. |
| **TeX/LaTeX** | Mathematical typesetting | Already in GeoGebra (JLaTeXMath). May need `pdflatex` for document generation. |

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

### Key pieces to extract (per engine)

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
| OEF framework | Exercise format is read by Perl (text processing layer), not by the engine interfaces |
| `libwims.h` / `wimsdef.h` | WIMS internal utilities — replaced by Java equivalents (D-ENG-01) |
| Session management | AlgoGebra manages its own sessions |
| `wp_spawn` / `wp_chan` | WIMS platform abstraction — replaced by Java `ProcessBuilder` (D-ENG-01) |

---

## 4. AlgoGebra integration architecture

### 4.1 The "External Computation Service" pattern

Per V2 binding decision: domain algorithms are **external computation services**, not native `AlgoElement` subclasses. A result that comes back into a figure is **one-shot**. It is not an `AlgoElement`, and `common` is not edited.

```
┌─────────────────────────────────────────────────────────┐
│  AlgoGebra Host (Java / Equinox)                        │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ExternalComputeService interface                  │  │
│  │    eval(String command, ComputeContext ctx)         │  │
│  │      → ComputeResult (string | image | error)      │  │
│  │    getCapabilities() → Set<Capability>              │  │
│  │    isAvailable() → boolean                          │  │
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
│  Missing binary → error, not fallback to another CAS     │
└─────────────────────────────────────────────────────────┘
```

### 4.2 What goes into the GeoGebra kernel vs. the host

| Layer | What | Where | Edits `common`? |
|---|---|---|---|
| **Kernel** | `AlgoElement` subclasses, construction objects | `common` | **NO** — binding decision |
| **Host** | `ExternalComputeService`, engine subprocess management | AlgoGebra host bundle | No — new code |
| **Bridge** | Writing a computation result back into a construction | Activity contract (X-04) | No — uses public API |

**Critical distinction:** An external computation result written via API is **not** a native dependent construction object. The construction does not auto-update when inputs change. That requires an `AlgoElement`, which requires editing `common` (forbidden). The external computation is a **one-shot evaluation**.

### 4.3 CAS engine roles (D-ENG-05, closed)

| Engine | Role | When it runs |
|---|---|---|
| **GIAC** | Native CAS — Algebra View, CAS View | Always. GeoGebra kernel uses GIAC via JNI. |
| **Maxima** | External CAS — WIMS exercises that name `maxima` | Only when a WIMS exercise specifies Maxima as its engine. |
| **Pari/GP** | External CAS — WIMS exercises that name `pari` | Only when a WIMS exercise specifies Pari/GP. |

GIAC runs the Algebra and CAS views. Maxima, Pari, or GAP runs **only when the WIMS exercise names that engine**. No overlap, no fallback.

### 4.4 How WIMS grading connects

```
Connected mode:
  Student interacts with AlgoGebra (local engines for exploration)
       │
       ▼
  Student submits answer
       │
       ▼
  AlgoGebra sends submission to WIMS server (HTTP)
       │
       ▼
  WIMS evaluates (its own engine instances) and returns grade
       │
       ▼
  AlgoGebra displays grade + feedback

Offline mode:
  AlgoGebra runs exercise locally
  Local engines evaluate student answers
  Local scoring (exercise-defined criteria)
  No WIMS server needed
```

---

## 5. Per-engine MVP spec

### 5.1 Pari/GP (1st slice)

| Item | Value |
|---|---|
| Binary | `gp -f -q` (Windows: `gp.exe -f -q`) |
| Header | WIMS `pari.c` header: 30 aliases (ln→log, pi→Pi, sec, csc, lg, etc.) |
| Dynamic setup | `\p <precision>`, `\ps <serieslength>`, `setrand(<seed>)` |
| Security filter | Block: `plot`, `write`, `help`. Block escape commands (`\` except `\\`, `\v`, `\p`). |
| Output parsing | Strip `? ` prompts, strip `Good bye!`, one-line per result, remove `Mat()` / `Vecsmall()` wrapping, strip trailing zeros |
| Quit | `\nquit\n` |
| Test command | `factor(2^64-1)` → `[3, 1; 5, 1; 17, 1; 257, 1; 641, 1; 65537, 1; 6700417, 1]` |
| Install size | ~20 MB (Windows binary from pari.math.u-bordeaux.fr) |

### 5.2 Maxima (2nd slice)

| Item | Value |
|---|---|
| Binary | `maxima` (Windows: `maxima.bat` or MSYS2 `maxima`) |
| Header | WIMS `maxima.c` header: `display2d:false`, `nolabels:true`, 20+ aliases |
| Dynamic setup | `fpprec:<precision>` |
| Security filter | Block: `system`, `save`, `load`, `file`, `debug`, `plot`, `batch`, `demo` |
| Output parsing | Strip `(%i` / `(%o` labels, collapse multi-line output |
| Quit | `\nquit();\n` |
| Test command | `diff(sin(x^2), x);` → `2*x*cos(x^2)` |
| Install size | ~100 MB (includes SBCL/CLISP Lisp runtime) |

### 5.3 Gnuplot (3rd slice)

| Item | Value |
|---|---|
| Binary | `gnuplot` |
| Header | `set terminal png size 800,600` (configurable) |
| Dynamic setup | Output filename, ranges, style |
| Security filter | Block: `system`, `shell`, `!` prefix |
| Output | PNG file written to temp directory. AlgoGebra reads the image (D-ENG-04). GeoGebra's own 2D/3D views stay GeoGebra. |
| Quit | `\nexit\n` |
| Test command | `plot sin(x)` → produces PNG file |
| Install size | ~10 MB |

### 5.4 GAP (optional, does not block others)

| Item | Value |
|---|---|
| Binary | `gap.sh -T -n` (Linux) / `gap.exe -T -n` (Windows) |
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

| Step | Deliverable | Acceptance |
|---|---|---|
| 1a | `SubprocessEngine` abstract class: Java `ProcessBuilder`, stdin/stdout pipe, timeout, process kill | Unit test with a mock engine |
| 1b | `PariGPEngine` with WIMS header + security filter + output parser | `factor(2^64-1)` returns correct result |
| 1c | `MaximaEngine` with WIMS header + security filter + output parser | `diff(sin(x^2), x)` returns `2*x*cos(x^2)` |
| 1d | `GnuplotEngine` with PNG output capture | `plot sin(x)` produces valid PNG |
| 1e | Engine discovery: check if binary exists on PATH, report availability | `isAvailable()` returns true/false per engine. Missing binary = error, not fallback. |
| 1f | (Optional) `GAPEngine` with WIMS header + security filter + output parser | `Size(SymmetricGroup(5))` returns `120` |

### Phase 2: Linux validation (Grok Bot)

| Step | Deliverable |
|---|---|
| 2a | Install Pari/GP, Maxima, GAP, Gnuplot on Debian |
| 2b | Run the same test commands as Phase 1 via the WIMS C interfaces (existing `bin/pari`, `bin/maxima`, `bin/gap`) |
| 2c | Run the same test commands via AlgoGebra's Java `SubprocessEngine` on Linux |
| 2d | Compare output: WIMS C interface vs. AlgoGebra Java subprocess (must match) |

### Phase 3: AlgoGebra host integration (Codex)

| Step | Deliverable |
|---|---|
| 3a | `ExternalComputeService` OSGi interface in host bundle |
| 3b | Engine bundles register as services |
| 3c | Host UI: "Compute" panel or input bar extension that routes to engines |
| 3d | Activity contract (X-04): write computation result into GeoGebra construction via public API (one-shot) |

### Phase 4: WIMS connected mode (Codex + Grok Bot)

| Step | Deliverable |
|---|---|
| 4a | Submission contract: AlgoGebra sends student answer to WIMS server |
| 4b | WIMS evaluates and returns grade + feedback |
| 4c | AlgoGebra displays grade in the UI |
| 4d | Grok Bot: end-to-end test with a real WIMS exercise on Debian |

---

## 7. Owner decisions (all closed)

All five decisions were closed on 2026-10-29. Full rationale in `Decisions_External_Engines_GROK_V1.md`.

| Decision | Choice | Summary |
|---|---|---|
| **D-ENG-01** | **A. Java ProcessBuilder** | Copy WIMS headers, illegal-command lists, and output cleanup. Do not compile the WIMS C interfaces. |
| **D-ENG-02** | **A. Pre-installed on PATH** | Product does not bundle or download engines. Missing binary = error, not fallback. |
| **D-ENG-03** | **A. Port WIMS command filters** | Port filters to Java + kill process on timeout. OS sandbox is later, not this slice. |
| **D-ENG-04** | **A. Gnuplot writes PNG** | AlgoGebra reads the temp file. GeoGebra's own 2D/3D views stay GeoGebra. |
| **D-ENG-05** | **A. GIAC for kernel, others for WIMS** | GIAC runs Algebra/CAS views. Maxima/Pari/GAP run only when the WIMS exercise names that engine. |

---

## 8. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Engine binary not installed on student machine | High | Feature unavailable | Clear error messages. `isAvailable()` check at startup. Install guide per platform. |
| Maxima version mismatch (WIMS expects specific version) | Medium | Wrong results for edge cases | Pin supported versions. Test against WIMS exercise corpus. |
| GAP install too large (~500 MB) for casual users | Medium | User won't install | GAP is optional. Only needed for group theory courses. |
| Security filter bypass in offline mode | Low | Student executes arbitrary code | Port WIMS filters + add OS-level sandboxing for institutional deployments (later). |
| Output parsing differences between WIMS C and Java rewrite | Medium | WIMS exercises grade incorrectly in offline mode | Phase 2 Grok Bot comparison test: WIMS C output vs. Java output for same inputs. |
| Engine subprocess hangs (infinite loop in student expression) | Medium | AlgoGebra freezes | Timeout + process kill (D-ENG-03). |

---

## 9. Relation to other documents

| Document | Relation |
|---|---|
| `Decisions_External_Engines_GROK_V1.md` | Owner decisions for this CDC (all 5 closed). |
| `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` | GIAC is the **native** CAS (JNI). This CDC covers **external** engines (subprocess). Different integration patterns. |
| V2 scenario X-04 | "External computation service connects to kernel." This CDC implements the service side. |
| V2 scenario X-01–X-03 | Activity contracts. The `ExternalComputeService` interface is part of the compute contract. |
| `Gate_Decision_D-04_D-05_GROK_V1.md` | D-05 (GIAC native loading) is a prerequisite. External engines are Phase 2+. |
| wims4win `src/Interfaces/` | Source of the security filters, headers, and output parsers. GPL v2 — must track license implications for the AlgoGebra product. |
