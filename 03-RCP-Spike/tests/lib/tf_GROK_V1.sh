# GROK_V1 - shared bash test framework for the AlgoGebra engine/RCP test pack.
# Modelled on Claude's TestFramework_CLAUDE_V1.ps1 (WIMS4win): TAP lines, priorities,
# PASS/FAIL/SKIP counters, "PASS: n FAIL: n SKIP: n" summary parsed by Run_All, per-suite CSV.
# Exit codes: 0 all pass, 1 any FAIL, 2 BAIL OUT (environment missing).
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPIKE_DIR="$(cd "$TESTS_DIR/.." && pwd)"
BASE="${ALGOGEBRA_BASE:-/workspace/AlgoGebra}"
JAVA_HOME="${JAVA_HOME:-$(ls -d "$BASE"/jdk/jdk-21* 2>/dev/null | head -1)}"
IMAGE="${IMAGE:-$BASE/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64}"
FIX="$TESTS_DIR/fixtures"; RES="${RESULTS_DIR:-$TESTS_DIR/results}"; mkdir -p "$RES"
TOOLS_OUT="$SPIKE_DIR/host/build/test-tools"
_P=0; _F=0; _S=0; _N=0; _SUITE=""
tf_init() { _SUITE="$1"; _CSV="$RES/${1}_GROK_V1.csv"; echo "suite,num,id,status,priority,detail,ts" > "$_CSV"
  echo "# Suite: $1"; echo "# Started: $(date -Is)"; echo "# Host: $(hostname) / $(. /etc/os-release; echo "$PRETTY_NAME") / $(uname -m)"; echo; }
_row() { local d="${4//\"/\"\"}"; echo "$_SUITE,$_N,$1,$2,$3,\"$d\",$(date -Is)" >> "$_CSV"; }
tf_ok() { # id cond(0/1 as shell status: pass "true"/"false") detail prio
  local id="$1" cond="$2" det="$3" pr="${4:-P1}"; _N=$((_N+1))
  if [ "$cond" = true ]; then _P=$((_P+1)); echo "ok $_N - [$pr] $id :: $det"; _row "$id" PASS "$pr" "$det"
  else _F=$((_F+1)); echo "not ok $_N - [$pr] $id :: $det"; _row "$id" FAIL "$pr" "$det"; fi; }
tf_eq() { local a b; a="$(norm "$2")"; b="$(norm "$3")"; if [ "$a" = "$b" ]; then tf_ok "$1" true "got=$2" "${4:-P1}"; else tf_ok "$1" false "expected=$3 got=$2" "${4:-P1}"; fi; }
tf_skip() { _N=$((_N+1)); _S=$((_S+1)); echo "ok $_N - [${3:-P1}] $1 # SKIP $2"; _row "$1" SKIP "${3:-P1}" "$2"; }
tf_bail() { echo "BAIL OUT - $1"; echo "PASS: $_P FAIL: $_F SKIP: $_S"; exit 2; }
tf_end() { echo; echo "PASS: $_P FAIL: $_F SKIP: $_S"; echo "# CSV: $_CSV"; [ "$_F" -eq 0 ] && exit 0 || exit 1; }
# Normalisation used for every comparison: strip whitespace, a single outer [ ] pair, Mat( ).
norm() { local s; s="$(printf '%s' "$1" | tr -d ' \t\r')"; s="${s#Mat(}"; [[ "$1" == Mat\(* ]] && s="${s%)}"
  [[ "$s" == \[*\] ]] && s="${s:1:${#s}-2}"; printf '%s' "$s"; }
# --- engine driver (EngineCli_GROK_V1 over the real engine bundles) ---
eng_cp() { local B="$SPIKE_DIR/host/build"; echo "$TOOLS_OUT:$B/org.geogebra.plus.compute.api_0.1.0.jar:$B/org.geogebra.plus.compute.runtime_0.1.0.jar:$B/org.geogebra.plus.engine.pari_0.1.0.jar:$B/org.geogebra.plus.engine.maxima_0.1.0.jar:$B/org.geogebra.plus.engine.gnuplot_0.1.0.jar:$B/osgi.core-8.0.0.jar"; }
tools_build() {
  [ -x "$JAVA_HOME/bin/javac" ] || tf_bail "JDK 21 not found ($JAVA_HOME)"
  [ -f "$SPIKE_DIR/host/build/org.geogebra.plus.engine.pari_0.1.0.jar" ] || (cd "$SPIKE_DIR" && ./test-engines.sh >/dev/null 2>&1 || true)
  [ -f "$SPIKE_DIR/host/build/org.geogebra.plus.engine.pari_0.1.0.jar" ] || tf_bail "engine bundles not built (run 03-RCP-Spike/test-engines.sh)"
  mkdir -p "$TOOLS_OUT"; "$JAVA_HOME/bin/javac" -encoding UTF-8 -d "$TOOLS_OUT" -cp "$(eng_cp)" "$TESTS_DIR"/tools/EngineCli_GROK_V1.java || tf_bail "EngineCli compile failed"; }
# eng <engine> <timeoutSec> <command>  -> sets ENG_KIND (OK/ART/ERR) and ENG_OUT (text, \n kept literal), ENG_RC, ENG_MS
eng() { local t0 line; t0=$(date +%s%3N)
  line="$(printf '%s' "$3" | "$JAVA_HOME/bin/java" -Dfile.encoding=UTF-8 -cp "$(eng_cp)" EngineCli_GROK_V1 "$1" "$2" 2>/dev/null | tail -1)"; ENG_RC=$?
  ENG_MS=$(( $(date +%s%3N) - t0 )); ENG_KIND="${line%%$'\t'*}"; ENG_OUT="${line#*$'\t'}"; }
# --- direct references reproducing WIMS src/Interfaces/common.c: header, then print(start marker),
#     command, print(end marker); keep only the text between the LAST start marker and the end marker. ---
wims_header() { sed -n '/WIMS_HEADER = .*"""$/,/""";/p' "$SPIKE_DIR/engines/$1" | sed '1d;$d' | sed 's/^            //'; }
ref_pari() { local m="Start line pari $$ $RANDOM" e="End line pari $$ $RANDOM"
  { echo '\p 20'; wims_header pari/src/org/geogebra/plus/engine/pari/PariGPEngine.java; printf 'print("%s")\n%s\nprint("%s")\nquit\n' "$m" "$1" "$e"; } \
   | timeout "${2:-30}" gp -f -q 2>&1 | awk -v m="$m" -v e="$e" '$0==m{f=1;o="";next} $0==e{f=0} f{o=o (o==""?"":" ") $0} END{print o}' | sed 's/^ *//;s/ *$//'; }
ref_maxima() { local m="start line maxima $$ $RANDOM" e="end line maxima $$ $RANDOM"
  { echo 'fpprec:20;'; wims_header maxima/src/org/geogebra/plus/engine/maxima/MaximaEngine.java; echo 'display2d:false$'; printf '"%s";\n%s\n"%s";\nquit();\n' "$m" "$1" "$e"; } \
   | timeout "${2:-60}" maxima --very-quiet 2>/dev/null | awk -v m="$m" -v e="$e" '{g=$0; gsub(/"/,"",g)} g==m{f=1;o="";next} g==e{f=0} f && $0!=""{o=o (o==""?"":" ") $0} END{print o}' | sed 's/^ *//;s/ *$//'; }
ref_giac() { local GJ; GJ="$(ls "$IMAGE"/bundles/org.geogebra.migration.shared.giac.jni-*.jar 2>/dev/null | head -1)"
  [ -n "$GJ" ] || return 1; mkdir -p "$TOOLS_OUT/giac"; [ -f "$TOOLS_OUT/giac/libjavagiac64.so" ] || unzip -o -q "$IMAGE"/natives/javagiac-*-natives-linux-amd64.jar -d "$TOOLS_OUT/giac"
  [ -f "$TOOLS_OUT/GiacCli_GROK_V1.class" ] || "$JAVA_HOME/bin/javac" -d "$TOOLS_OUT" -cp "$GJ" "$TESTS_DIR/tools/GiacCli_GROK_V1.java"
  "$JAVA_HOME/bin/java" -Dgiac.lib="$TOOLS_OUT/giac/libjavagiac64.so" -cp "$TOOLS_OUT:$GJ" GiacCli_GROK_V1 "$1"; }
