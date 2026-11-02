# Suite 18 (unified) — Windows evidence (GROK_V1)

- Host: SHADOW-TB64BO9R, Windows 10.0.26100, pwsh 7.6.9
- Head: `6c32896` (PR #9), run from a clean, isolated worktree `D:\ALF_Agents\G1_wt_grok_suite18` per owner Q8 (issue #17); the owner's dirty checkout was not touched. `bundles/`, `launcher/` and `natives/` were copied from the owner's staged 03-RCP-Spike.
- Launcher: `launch.ps1 -NoBuild` with `GGBPLUS_LAUNCH_DRYRUN=1`
- Result: **PASS 17 / FAIL 0 / SKIP 5** (same at `fc81487`)
- Skips:
  - LC-12, LC-13b: cannot create symlinks (needs Developer Mode or admin).
  - LC-17b: the Eclipse JustJ JRE is present on this host, so no-JDK can't be forced without changing `launch.ps1`.
  - LC-18, LC-19: Linux/Xvfb only.
- Exit codes observed: 64 (LC-05/06/11), 65 (LC-09/10), 66 (LC-07/08/17), 77 (LC-13). They match `launch.sh` on Debian (21/0/1).
- Note: one earlier attempt from the owner's checkout at `b34a143` (pre-#11 `launch.ps1`, no dry-run) launched the real app. It was killed and is not counted.
