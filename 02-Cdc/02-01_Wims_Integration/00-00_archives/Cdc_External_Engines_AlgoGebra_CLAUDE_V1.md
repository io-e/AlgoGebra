<!-- CLAUDE_V1 -->
# CDC — External Computation Engines for AlgoGebra

| Field | Value |
|---|---|
| Document | `02-Cdc/Cdc_External_Engines_AlgoGebra_CLAUDE_V1.md` |
| Version | CLAUDE_V1 |
| Status | Draft — owner decisions required (§7) |
| Date | 2026-10-29 |
| Depends on | V2 scenario X-04, `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` |
| Source ref | `D:\ALF_ZGit\02-wims4win\src\Interfaces\` (WIMS C interface wrappers) |

---

## 1. Goal

Bring WIMS computation engines into AlgoGebra as **standalone external services**, without requiring the full WIMS server stack (Apache, `wims.cgi`, OEF framework, chroot, session management).

Two modes:
- **Connected mode:** WIMS server grades. AlgoGebra runs engines locally for interactive exploration.
- **Offline mode:** AlgoGebra runs everything locally, including exercise validation. WIMS format compatibility but no WIMS runtime dependency.

---

## 2. Engine inventory

### MVP (all four)

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

Perl is not an optional engine — it is a **required text-processing dependency** for OEF format compatibility. Both connected and offline modes need it when handling WIMS exercises.

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
| `chroot` / sandboxing | AlgoGebra uses OS-level process isolation (or none in trusted mode) |
| OEF framework | Exercise format is separate from engine integration |
| `libwims.h` / `wimsdef.h` | WIMS internal utilities — replace with Java equivalents |
| Session management | AlgoGebra manages its own sessions |
| `wp_spawn` / `wp_chan` | WIMS platform abstraction — replace with Java `ProcessBuilder` |

---

## 4. AlgoGebra integration architecture

### 4.1 The "External Computation Service" pattern

Per V2 binding decision: domain algorithms are **external computation services**, not native `AlgoElement` subclasses. The pattern is:

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
│  │    - ProcessBuilder with stdin/stdout pipes         │  │
│  │    - Header injection (from WIMS header strings)    │  │
│  │    - Security filter (from WIMS illegal[] lists)    │  │
│  │    - Output parser (from WIMS output() functions)   │  │
│  │    - Timeout + process cleanup                      │  │
│  └────────────┬──────────────────────────────────────┘  │
│               │                                          │
│  ┌────────────▼──┐  ┌──────────┐  ┌──────┐  ┌────────┐│
│  │ PariGPEngine  │  │ Maxima   │  │ GAP  │  │Gnuplot ││
│  │ header, parse │  │ Engine   │  │Engine│  │Engine  ││
│  └───────────────┘  └──────────┘  └──────┘  └────────┘│
│                                                          │
│  Engine binaries: installed separately, path configured  │
└─────────────────────────────────────────────────────────┘
```

### 4.2 What goes into the GeoGebra kernel vs. the host

| Layer | What | Where | Edits `common`? |
|---|---|---|---|
| **Kernel** | `AlgoElement` subclasses, construction objects | `common` | **NO** — binding decision |
| **Host** | `ExternalComputeService`, engine subprocess management | AlgoGebra host bundle | No — new code |
| **Bridge** | Writing a computation result back into a construction | Activity contract (X-04) | No — uses public API |

**Critical distinction:** An external computation result written via API is **not** a native dependent construction object. The construction does not auto-update when inputs change. That requires an `AlgoElement`, which requires editing `common` (forbidden). The external computation is a **one-shot evaluation**.

### 4.3 How WIMS grading connects

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

### 5.1 Pari/GP

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

### 5.2 Maxima

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

### 5.3 GAP

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

### 5.4 Gnuplot

| Item | Value |
|---|---|
| Binary | `gnuplot` |
| Header | `set terminal png size 800,600` (configurable) |
| Dynamic setup | Output filename, ranges, style |
| Security filter | Block: `system`, `shell`, `!` prefix |
| Output parsing | Result is an image file (PNG), not text. Different pattern from the other three. |
| Quit | `\nexit\n` |
| Test command | `plot sin(x)` → produces PNG file |
| Install size | ~10 MB |

---

## 6. Implementation plan

### Phase 1: Windows subprocess proof (Codex)

| Step | Deliverable | Acceptance |
|---|---|---|
| 1a | `SubprocessEngine` abstract class: `ProcessBuilder`, stdin/stdout pipe, timeout, cleanup | Unit test with a mock engine |
| 1b | `PariGPEngine` with WIMS header + security filter + output parser | `factor(2^64-1)` returns correct result |
| 1c | `MaximaEngine` with WIMS header + security filter + output parser | `diff(sin(x^2), x)` returns `2*x*cos(x^2)` |
| 1d | `GAPEngine` with WIMS header + security filter + output parser | `Size(SymmetricGroup(5))` returns `120` |
| 1e | `GnuplotEngine` with PNG output capture | `plot sin(x)` produces valid PNG |
| 1f | Engine discovery: check if binary exists on PATH, report availability | `isAvailable()` returns true/false per engine |

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
| 3d | Activity contract (X-04): write computation result into GeoGebra construction via public API |

### Phase 4: WIMS connected mode (Codex + Grok Bot)

| Step | Deliverable |
|---|---|
| 4a | Submission contract: AlgoGebra sends student answer to WIMS server |
| 4b | WIMS evaluates and returns grade + feedback |
| 4c | AlgoGebra displays grade in the UI |
| 4d | Grok Bot: end-to-end test with a real WIMS exercise on Debian |

---

## 7. Owner decisions required

### D-ENG-01: Reuse WIMS C interfaces or rewrite in Java?

**Context:** The WIMS C interfaces (`pari.c`, `maxima.c`, `gap.c`) are battle-tested but depend on `libwims.h`, `wimsdef.h`, `wp_spawn`, chroot, and WIMS's process isolation layer. They also have WIMS-specific features (multi-exec, pid management, chroot).

| Option | Pros | Cons |
|---|---|---|
| **A. Rewrite in Java** (recommended) | No C compilation needed. Runs anywhere Java runs. No WIMS dependencies. `ProcessBuilder` is standard. Security filters and output parsers are ~50 lines each — small rewrite. | Must maintain Java versions separately from WIMS updates. |
| **B. Compile WIMS C interfaces standalone** | Proven code. Exact WIMS-compatible behavior. | Requires C compiler on build machine. Must strip WIMS dependencies (`libwims.h`, `wp_spawn`). Platform-specific binaries. Two languages in the stack. |
| **C. Extract WIMS C interfaces as a shared library** | Call from Java via JNI. Best of both worlds? | Massive over-engineering. JNI for a subprocess launcher is absurd. |

### D-ENG-02: Engine binary distribution

**Context:** Pari/GP, Maxima, GAP, and Gnuplot must be installed on the user's machine. AlgoGebra doesn't ship them.

| Option | Pros | Cons |
|---|---|---|
| **A. Require pre-installed engines** (recommended for MVP) | Simple. User or sysadmin installs via package manager or installer. AlgoGebra discovers via PATH. | Burden on the user. Different install procedures per OS. |
| **B. Bundle engine binaries in the product** | Zero-config for users. | Huge download (Maxima ~100 MB, GAP ~500 MB). Licensing complexity (each engine has its own license). Version management. |
| **C. Download on first use** | Smaller initial install. | Requires internet. Where to host? Version pinning? |
| **D. Docker/container per engine** | Isolated. Reproducible. | Docker dependency. Overkill for desktop. |

### D-ENG-03: Security model for offline student mode

**Context:** In connected mode, WIMS server evaluates — WIMS handles security. In offline mode, AlgoGebra runs engines locally. The WIMS C interfaces have security filters (block `system`, `file`, `plot`, etc.).

| Option | Pros | Cons |
|---|---|---|
| **A. Port WIMS security filters to Java** (recommended) | Same protection as WIMS. Blocks dangerous commands before they reach the engine. | Must keep in sync with WIMS filter updates. Students may find bypasses not caught by string filtering. |
| **B. OS-level sandboxing** | Strong isolation (AppContainer on Windows, seccomp on Linux). | Complex. Platform-specific. May break engine functionality. |
| **C. No security in offline mode** | Simple. Trust the student. | Unacceptable for institutional deployments. |
| **D. WIMS filters + OS sandboxing** | Defense in depth. | Most complex but most secure. |

### D-ENG-04: How does Gnuplot output reach AlgoGebra?

**Context:** Gnuplot produces images (PNG), not text. This is fundamentally different from Pari/GP, Maxima, and GAP which return text strings.

| Option | Pros | Cons |
|---|---|---|
| **A. Gnuplot writes to temp file, AlgoGebra reads image** (recommended) | Simple. Standard Gnuplot `set output` workflow. | Temp file management. No streaming. |
| **B. Gnuplot pipes PNG to stdout** | No temp file. | Requires `set terminal pngcairo` + stdout pipe. Mixing binary data with text control is fragile. |
| **C. Gnuplot SVG output embedded in a GeoGebra view** | Vector graphics, scalable. | SVG parsing and rendering in Java. More complex. |
| **D. Skip Gnuplot — use GeoGebra's built-in plotting** | No new dependency. | WIMS exercises use Gnuplot syntax. Breaking compatibility. |

### D-ENG-05: How do Maxima and Pari/GP relate to GIAC in AlgoGebra?

**Context:** GIAC is the native CAS (JNI, integrated at Layer 2). Maxima is an external CAS (subprocess). Both can do `diff(sin(x^2), x)`. Which one does AlgoGebra use for what?

| Option | Pros | Cons |
|---|---|---|
| **A. GIAC for kernel, Maxima for WIMS exercises** (recommended) | Clear boundary. GeoGebra's CAS View uses GIAC (unchanged). WIMS exercises that specify `maxima` as the engine get Maxima. No conflict. | Two CAS engines doing similar things. |
| **B. GIAC replaces Maxima** | One CAS engine. Simpler. | WIMS exercises depend on Maxima-specific syntax and behavior. Not 100% compatible. Breaks exercises. |
| **C. Maxima replaces GIAC** | Standard in WIMS world. | Breaks GeoGebra's CAS View (which is built on GIAC). Requires `common` edits (forbidden). |

---

## 8. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Engine binary not installed on student machine | High | Feature unavailable | Clear error messages. `isAvailable()` check at startup. Install guide per platform. |
| Maxima version mismatch (WIMS expects specific version) | Medium | Wrong results for edge cases | Pin supported versions. Test against WIMS exercise corpus. |
| GAP install too large (~500 MB) for casual users | Medium | User won't install | Make GAP optional. Only needed for group theory courses. |
| Security filter bypass in offline mode | Low | Student executes arbitrary code | Port WIMS filters + add OS-level sandboxing for institutional deployments. |
| Output parsing differences between WIMS C and Java rewrite | Medium | WIMS exercises grade incorrectly in offline mode | Phase 2 Grok Bot comparison test: WIMS C output vs. Java output for same inputs. |
| Engine subprocess hangs (infinite loop in student expression) | Medium | AlgoGebra freezes | Timeout + process kill. WIMS already handles this in `common.c`. |

---

## 9. Relation to other documents

| Document | Relation |
|---|---|
| `Cdc_GIAC_Integration_AlgoGebra_CLAUDE_V1.md` | GIAC is the **native** CAS (JNI). This CDC covers **external** engines (subprocess). Different integration patterns. |
| V2 scenario X-04 | "External computation service connects to kernel." This CDC implements the service side. |
| V2 scenario X-01–X-03 | Activity contracts. The `ExternalComputeService` interface is part of the compute contract. |
| `Gate_Decision_D-04_D-05_GROK_V1.md` | D-05 (GIAC native loading) is a prerequisite. External engines are Phase 2+. |
| wims4win `src/Interfaces/` | Source of the security filters, headers, and output parsers. GPL v2 — must track license implications for the AlgoGebra product. |
