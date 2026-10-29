#!/usr/bin/env bash
# GROK_V1 - Encoding: UTF-8 in/out (accents, euro) direct vs engine; accented gnuplot title; accented temp path.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 06_Encoding
tools_build
tf_ok ENC-00-fixture-utf8 "$(iconv -f UTF-8 -t UTF-8 "$FIX/encoding_GROK_V1.tsv" >/dev/null 2>&1 && echo true || echo false)" "fixture is valid UTF-8" P0
while IFS=$'\t' read -r id e cmd exp; do
  if [ "$e" = pari ]; then r="$(ref_pari "$cmd")"; else r="$(ref_maxima "$cmd;")"; fi
  tf_eq "$id-$e-direct" "$r" "$exp"
  eng "$e" 60 "$cmd"; tf_eq "$id-$e-engine" "$ENG_OUT" "$exp" P0
done < <(grep -v '^#' "$FIX/encoding_GROK_V1.tsv")
eng gnuplot 30 'plot sin(x) title "sinus é à ü €"'; IFS=$'\t' read -r p n dim del <<< "$ENG_OUT"
tf_ok ENC-10-gnuplot-accented-title "$([ "$ENG_KIND" = ART ] && [ "$dim" = 800x600 ] && echo true || echo false)" "kind=$ENG_KIND dim=${dim:-} ${ENG_OUT:0:120}"
td="$(mktemp -d /tmp/algogébra-é-XXXX)"; ( export TMPDIR="$td"; JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$td" eng pari 30 "2+3"; echo "$ENG_KIND $ENG_OUT" > "$td.res" ) 2>/dev/null
r="$(cat "$td.res")"; tf_ok ENC-11-accented-tmpdir "$([[ "$r" == OK* && "$r" == *5 ]] && echo true || echo false)" "tmp=$td -> ${r//$'\n'/ }"; rm -rf "$td" "$td.res"
tf_end
