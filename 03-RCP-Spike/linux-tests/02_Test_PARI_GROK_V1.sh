#!/usr/bin/env bash
# GROK_V1 - PARI/GP: direct CLI reference (WIMS marker method) vs AlgoGebra engine. BUG-001 expected FAIL until fixed.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 02_PARI
command -v gp >/dev/null || tf_bail "gp not on PATH"
tools_build
while IFS=$'\t' read -r id cmd exp; do
  r="$(ref_pari "$cmd")"; tf_eq "$id-direct" "$r" "$exp" P1
  eng pari 30 "$cmd"; tf_eq "$id-engine" "$ENG_OUT" "$exp" P0
done < <(grep -v '^#' "$FIX/pari_GROK_V1.tsv")
tf_end
