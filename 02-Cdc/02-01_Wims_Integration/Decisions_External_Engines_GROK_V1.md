# GROK_V1

# Decisions: external WIMS engines

Date: 2026-10-29.

Fills §7 of `02-Cdc\Cdc_External_Engines_AlgoGebra_CLAUDE_V1.md`. GIAC stays the GeoGebra CAS, as in `Decisions_GIAC_Complet_WIMS_GROK_V1.md`.

## D-ENG-01 — Java subprocesses

**Choice: A.** Each engine is a Java `ProcessBuilder` wrapper. Do not compile the WIMS C interfaces, and do not call them through JNI.

Copy the small reusable pieces from `D:\ALF_ZGit\02-wims4win\src\Interfaces\`: the header strings, the illegal-command lists, the quit strings, and the output cleanup. Leave `libwims.h`, `wp_spawn`, chroot, and `wims.cgi` behind.

The wrappers implement `ExternalComputeService` and register as OSGi services. A result written back into a figure is one-shot. It is not an `AlgoElement`. `common` is not edited.

## D-ENG-02 — Pre-installed binaries for the MVP

**Choice: A.** The product does not ship Pari, Maxima, GAP, or Gnuplot. It looks them up on `PATH`. `isAvailable()` is false when the binary is missing, and the activity says which engine is missing. No silent fallback to another CAS.

Do not bundle the binaries and do not download them on first use. Docker is rejected.

Order of the first slice: Pari/GP, then Maxima, then Gnuplot. GAP is optional and does not block that slice. Its install is hundreds of megabytes and only group-theory activities need it.

## D-ENG-03 — WIMS command filters, plus a timeout

**Choice: A for the MVP.** Port `illegal[]` / `check_parm()` into Java and run them before the process starts. Kill the process on timeout.

No security (option C) is rejected. An OS sandbox (options B and D) is not part of this slice. School deployments may add one later. String filters are the same protection WIMS uses. They are not a proof that a student cannot escape the engine.

Offline mode still does not run `wims.cgi`. It runs the local engine only.

## D-ENG-04 — Gnuplot writes a PNG file

**Choice: A.** Gnuplot runs with an explicit output file under the product temp directory. AlgoGebra reads that PNG and deletes it after the activity no longer needs it. Do not pipe raw PNG bytes through the same stdout parser as Pari and Maxima.

GeoGebra’s own 2D and 3D views stay GeoGebra. Gnuplot is only for a WIMS exercise whose plot command is Gnuplot syntax. POV-Ray and Fly are out of this slice.

## D-ENG-05 — GIAC inside the kernel, Maxima only when the exercise says so

**Choice: A.** The Algebra view and the CAS view call GIAC. A WIMS exercise that names Maxima, Pari, or GAP calls that engine. The same expression may be legal in both. The activity, not the host, picks the engine.

Option B is rejected because WIMS exercises depend on Maxima syntax. Option C is rejected because it would replace GIAC and would require edits in `common`.

## Perl

Perl is not one of the four compute engines. It is required only for the OEF reader, when an activity is stored as OEF. It is not started for a CAS command. Python stays the notebook tool. It is not a substitute for Perl on OEF files.

## Not in this decision

Octave, POV-Ray, and a full offline scorer. Connected mode still sends the submission to WIMS for the grade. Offline scoring waits until the Java wrappers match WIMS output on a written fixture set.
