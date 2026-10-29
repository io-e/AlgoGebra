#!/usr/bin/env bash
# GROK_V1 - CAS equivalence GIAC (javagiac JNI from the RCP image) vs PARI engine vs Maxima engine (cf. Claude run_equiv_pc.ps1).
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 07_CAS_Equivalence
tools_build
while IFS=$'\t' read -r id g p m exp; do
  if r="$(ref_giac "$g" 2>&1)"; then tf_eq "$id-giac" "$r" "$exp" P1; else tf_skip "$id-giac" "GIAC JNI unavailable: ${r:0:80}"; fi
  if [ "$p" = - ]; then tf_skip "$id-pari" "not applicable"; else eng pari 30 "$p"; tf_eq "$id-pari" "$ENG_OUT" "$exp"; fi
  if [ "$m" = - ]; then tf_skip "$id-maxima" "not applicable"; else eng maxima 60 "$m"; tf_eq "$id-maxima" "$ENG_OUT" "$exp"; fi
done < <(grep -v '^#' "$FIX/equiv_GROK_V1.tsv")
tf_end
