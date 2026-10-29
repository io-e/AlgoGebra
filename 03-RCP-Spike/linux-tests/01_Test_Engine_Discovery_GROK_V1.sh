#!/usr/bin/env bash
# GROK_V1 - AlgoGebra test pack (Debian). Modelled on Claude's WIMS4win *_CLAUDE_V1.ps1 suites.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 01_Engine_Discovery
tools_build
for b in gp maxima gnuplot; do p="$(command -v $b || true)"; tf_ok "DISC-$b-path" "$([ -n "$p" ] && echo true || echo false)" "path=${p:-absent}" P0; done
v="$(echo 'print(version())' | gp -f -q 2>/dev/null)"; tf_ok DISC-gp-version "$([ -n "$v" ] && echo true || echo false)" "gp version()=$v / $(gp --version-short 2>/dev/null)"
v="$(maxima --version 2>/dev/null | tail -1)"; tf_ok DISC-maxima-version "$([[ "$v" == Maxima* ]] && echo true || echo false)" "$v"
v="$(gnuplot --version 2>/dev/null)"; tf_ok DISC-gnuplot-version "$([[ "$v" == gnuplot* ]] && echo true || echo false)" "$v"
v="$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"; tf_ok DISC-java-21 "$([[ "$v" == *'"21.'* ]] && echo true || echo false)" "$v" P0
for e in pari:2+3 maxima:2+3 gnuplot:"plot x"; do eng "${e%%:*}" 30 "${e#*:}"; tf_ok "DISC-engine-${e%%:*}-spawn" "$([ "$ENG_KIND" != ERR ] && echo true || echo false)" "kind=$ENG_KIND ${ENG_MS}ms" P0; done
tf_end
