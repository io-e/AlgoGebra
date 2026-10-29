#!/usr/bin/env bash
# GROK_V1 - Sandbox: WIMS deny lists (illegal/illpart), no shell execution, no file writes, timeout + process kill.
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 05_Sandbox
tools_build
rm -f /tmp/algogebra_sbx_*
while IFS=$'\t' read -r id e cmd pol; do
  before="$(pgrep -c -x "$( [ $e = pari ] && echo gp || echo $e )" || true)"
  eng "$e" 3 "$cmd"
  case "$pol" in
    REJECT) tf_ok "$id-$e-reject" "$([ "$ENG_KIND" = ERR ] && [[ "$ENG_OUT" == *blocked* || "$ENG_OUT" == *forbid* || "$ENG_OUT" == *not\ allowed* || "$ENG_OUT" == *rejected* ]] && echo true || echo false)" "cmd=$cmd -> $ENG_KIND ${ENG_OUT:0:160}" P0;;
    NOEXEC) tf_ok "$id-$e-noexec" "$([[ "$ENG_OUT" != *uid=* ]] && echo true || echo false)" "cmd=$cmd -> $ENG_KIND ${ENG_OUT:0:160}" P0;;
    TIMEOUT) sleep 1; after="$(pgrep -c -x "$( [ $e = pari ] && echo gp || echo $e )" || true)"
      tf_ok "$id-$e-timeout" "$([ "$ENG_KIND" = ERR ] && [ "$ENG_MS" -lt 15000 ] && echo true || echo false)" "budget=3s elapsed=${ENG_MS}ms -> ${ENG_OUT:0:120}" P0
      tf_ok "$id-$e-killed" "$([ "${after:-0}" -le "${before:-0}" ] && echo true || echo false)" "procs before=$before after=$after" P0;;
  esac
done < <(grep -v '^#' "$FIX/sandbox_GROK_V1.tsv")
w="$(ls /tmp/algogebra_sbx_* 2>/dev/null)"; tf_ok SBX-99-no-files-written "$([ -z "$w" ] && echo true || echo false)" "${w:-none}" P0
tf_end
