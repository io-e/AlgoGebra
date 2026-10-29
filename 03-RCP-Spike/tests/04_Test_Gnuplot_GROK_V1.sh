#!/usr/bin/env bash
# GROK_V1 - Gnuplot: PNG 800x600 rendering via direct CLI and engine, artefact cleanup.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 04_Gnuplot
command -v gnuplot >/dev/null || tf_bail "gnuplot not on PATH"
tools_build
d="$(mktemp -d)"; gnuplot -e "set terminal pngcairo size 800,600; set output '$d/s.png'; plot sin(x)" 2>/dev/null
f="$(file -b "$d/s.png" 2>/dev/null)"; tf_ok GNU-01-direct-png "$([[ "$f" == "PNG image data, 800 x 600"* ]] && echo true || echo false)" "$f"
rm -rf "$d"; tf_ok GNU-02-direct-cleanup "$([ ! -e "$d" ] && echo true || echo false)" "removed $d"
for c in "plot sin(x)" "plot sin(x), cos(x)" "splot x*y"; do eng gnuplot 30 "$c"; IFS=$'\t' read -r p n dim del <<< "$ENG_OUT"
  tf_ok "GNU-engine-[$c]" "$([ "$ENG_KIND" = ART ] && [ "$dim" = 800x600 ] && [ "${n:-0}" -gt 1000 ] && echo true || echo false)" "kind=$ENG_KIND size=${n:-} dim=${dim:-} ${ENG_MS}ms" P0
  tf_ok "GNU-cleanup-[$c]" "$([ "${del:-}" = true ] && [ ! -e "${p:-/nonexistent}" ] && echo true || echo false)" "deletedAfterClose=${del:-} path=${p:-}" P1; done
tf_end
