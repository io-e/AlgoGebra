<!-- CLAUDE_V1 — Evidence rule checklist (WP6-08) -->
<!-- Paste this block into scenario script headers. Source: AGENTS.md evidence rule. -->

# Evidence checklist (AGENTS.md rule)

Every executed scenario row must record **all** of the following, or it stays NOT RUN:

| # | Field | Example | How to get |
|---|---|---|---|
| 1 | **Date** | 2026-11-01T14:30+01:00 | `Get-Date -Format o` |
| 2 | **Commit** | `ed77a9f` | `git rev-parse --short HEAD` |
| 3 | **OS** | Windows 11 10.0.26100 / Debian 12.8 | `[Environment]::OSVersion` or `uname -a` |
| 4 | **Java/browser** | JDK 21.0.12+101 / Chrome 131 | `java -version` or browser UA |
| 5 | **Fixture hash** | `sha256:abc123...` | `Get-FileHash -Algorithm SHA256` |
| 6 | **Command** | `launch.ps1 -Course courses/trig.json` | Exact invocation |
| 7 | **Expected** | "O exists → true" | From spec or cheat sheet |
| 8 | **Actual** | "O exists → true" | From run output |
| 9 | **Log path** | `evidence/20261101-D-11-win/*.log` | Relative to repo |

## PowerShell header template

```powershell
# Evidence: date=$(Get-Date -Format o) commit=$(git rev-parse --short HEAD)
#   os=$([Environment]::OSVersion.VersionString) pwsh=$($PSVersionTable.PSVersion)
#   java=(& java -version 2>&1 | Select-Object -First 1)
#   image=$env:IMAGE pin=375db7faf54 version=5.4.934.0
```

## Rules

- Do NOT convert SKIP/BLOCKED into PASS.
- Do NOT backdate evidence.
- A scenario with missing fields stays NOT RUN regardless of the test result.
- Log files go under `03-RCP-Spike/evidence/<date>-<scenario>-<host>/`.
