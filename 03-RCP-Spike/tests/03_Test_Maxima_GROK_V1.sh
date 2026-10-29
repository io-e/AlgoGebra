#!/usr/bin/env bash
# GROK_V1 - Maxima: direct CLI reference (WIMS marker method) vs AlgoGebra engine. BUG-002 expected FAIL until fixed.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 03_Maxima
command -v maxima >/dev/null || tf_bail "maxima not on PATH"
tools_build
while IFS=$'\t' read -r id cmd exp; do
  r="$(ref_maxima "$cmd;")"; tf_eq "$id-direct" "$r" "$exp" P1
  eng maxima 60 "$cmd"; tf_eq "$id-engine" "$ENG_OUT" "$exp" P0
done < <(grep -v '^#' "$FIX/maxima_GROK_V1.tsv")
tf_end
