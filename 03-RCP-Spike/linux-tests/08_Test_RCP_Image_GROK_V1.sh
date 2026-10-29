#!/usr/bin/env bash
# GROK_V1 - RCP Linux image smoke under Xvfb: D-02 50/50 resolved, 3 engines available=true, GIAC Expand[(x+1)^2].
set -uo pipefail
. "$(dirname "$0")/lib/tf_GROK_V1.sh"
tf_init 08_RCP_Image
[ -x "$IMAGE/launch.sh" ] || tf_bail "Linux image not built: $IMAGE (run 03-RCP-Spike/build.sh)"
command -v xvfb-run >/dev/null || tf_bail "xvfb-run missing"
L="$RES/08_headless.log"; timeout 120 xvfb-run -a -s "-screen 0 1600x1000x24" "$IMAGE/launch.sh" --headless > "$L" 2>&1
tf_ok RCP-01-d02-50-resolved "$(grep -q 'found=50, ACTIVE=0, RESOLVED=50, unresolved/other=0' "$L" && grep -q 'D-02 PASS' "$L" && echo true || echo false)" "$(grep -o 'found=50.*resolveBundles=[a-z]*' "$L" | head -1)" P0
for e in pari maxima gnuplot; do tf_ok "RCP-02-$e-available" "$(grep -q "external engine $e; available=true" "$L" && echo true || echo false)" "$(grep "external engine $e" "$L" | head -1 | sed 's/.*engine //')" P0; done
U="$RES/08_ui.log"; ( timeout 120 xvfb-run -a -s "-screen 0 1600x1000x24" "$IMAGE/launch.sh" > "$U" 2>&1 ) & pid=$!
for i in $(seq 1 110); do grep -q 'D-05 3D view initialized\|D-05 CAS FAILED\|3D view initialized' "$U" 2>/dev/null && break; sleep 1; done
pkill -f "ggbplus.runId" 2>/dev/null; wait $pid 2>/dev/null
tf_ok RCP-03-giac-native "$(grep -q 'D-05 GIAC native loaded=true' "$U" && echo true || echo false)" "$(grep -o 'libjavagiac64.so' "$U" | head -1)" P0
tf_ok RCP-04-giac-expand "$(grep -q 'D-05 CAS ASSERTION PASS' "$U" && echo true || echo false)" "$(grep 'D-05 CAS result' "$U" | sed 's/.*result: //')" P0
tf_ok RCP-05-jogl-3d "$(grep -q '3D view initialized=true' "$U" && echo true || echo false)" "$(grep -o '3D point command accepted=[a-z]*; 3D view initialized=[a-z]*' "$U")" P1
tf_end
