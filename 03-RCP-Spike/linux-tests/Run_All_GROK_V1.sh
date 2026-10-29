#!/usr/bin/env bash
# Moved 2026-10-29 from tests/ (test pack is now .ps1-only, pwsh runner); kept as the Debian bash twin.
# GROK_V1 - Run_All aggregator (cf. Claude Run_All_Tests_CLAUDE_V1.ps1): runs 01..08 in child processes,
# parses "PASS: n FAIL: n SKIP: n", writes results/Run_All_<ts>_GROK_V1.csv + summary .md; exit 0 if no FAIL, 1 otherwise.
# Usage: Run_All_GROK_V1.sh [--skip-rcp]
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; RES="$HERE/../tests/results"; mkdir -p "$RES"; TS="$(date +%Y%m%d_%H%M%S)"
CSV="$RES/Run_All_${TS}_GROK_V1.csv"; MD="$RES/Run_All_${TS}_GROK_V1.md"; echo "suite,pass,fail,skip,rc,status,log" > "$CSV"
TP=0; TF=0; TS_=0
echo "================================================================"; echo "  AlgoGebra engines + RCP test pack (GROK_V1)"; echo "  Date: $(date -Is)  Host: $(hostname)"; echo "================================================================"
for s in "$HERE"/0[1-8]_Test_*_GROK_V1.sh; do n="$(basename "$s" _GROK_V1.sh)"
  if [ "${1:-}" = --skip-rcp ] && [[ "$n" == 08_* ]]; then echo "SKIP $n (--skip-rcp)"; continue; fi
  log="$RES/${n}_GROK_V1.log"; bash "$s" > "$log" 2>&1; rc=$?
  read -r p f k < <(grep -oE 'PASS: [0-9]+ FAIL: [0-9]+ SKIP: [0-9]+' "$log" | tail -1 | awk '{print $2,$4,$6}'); p=${p:-0}; f=${f:-0}; k=${k:-0}
  st=PASS; [ "$f" -gt 0 ] && st=FAIL; [ "$rc" -eq 2 ] && st=BAIL
  TP=$((TP+p)); TF=$((TF+f)); TS_=$((TS_+k)); echo "$n,$p,$f,$k,$rc,$st,$(basename "$log")" >> "$CSV"
  printf '  [%s] %-28s %3d pass %3d fail %3d skip (rc=%d)\n' "$st" "$n" "$p" "$f" "$k" "$rc"; done
G="MET"; [ "$TF" -gt 0 ] && G="NOT MET"
{ echo "<!-- GROK_V1 -->"; echo "# Run_All results $TS"; echo; echo "Host: $(hostname), $(. /etc/os-release; echo "$PRETTY_NAME"), $(uname -r)"; echo; echo '| Suite | Pass | Fail | Skip | rc | Status |'; echo '|---|---|---|---|---|---|'
  tail -n +2 "$CSV" | awk -F, '{printf "| %s | %s | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5,$6}'; echo; echo "**TOTAL: $TP pass, $TF fail, $TS_ skip — GATE: $G**"; } > "$MD"
echo "TOTAL: $TP pass, $TF fail, $TS_ skip"; echo "GATE: $G"; echo "Results: $CSV"
[ "$TF" -gt 0 ] && exit 1 || exit 0
