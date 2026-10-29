#!/usr/bin/env bash
# test-engines.sh - Debian/Linux port of test-engines.ps1 (engine bundles only).
# Author: Grok Bot (GROK_V1). Builds the 5 external-engine bundles and runs
# EngineAcceptanceTest against gp/maxima/gnuplot on PATH. No GeoGebra jars needed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
JAVA_HOME="${JAVA_HOME:-$(ls -d /workspace/AlgoGebra/jdk/jdk-21* 2>/dev/null | head -1)}"
JAVAC="$JAVA_HOME/bin/javac"; JAVA="$JAVA_HOME/bin/java"; JAR="$JAVA_HOME/bin/jar"
OUT="$ROOT/host/build"; ENG="$ROOT/engines"; mkdir -p "$OUT"
OSGI="$OUT/osgi.core-8.0.0.jar"
[ -f "$OSGI" ] || curl -fsSL -o "$OSGI" https://repo1.maven.org/maven2/org/osgi/osgi.core/8.0.0/osgi.core-8.0.0.jar
build() { # label srcdir manifest jar cp
  local cls="$OUT/$1-classes"; mkdir -p "$cls"
  "$JAVAC" -encoding UTF-8 --release 21 ${5:+-cp "$5"} -d "$cls" $(find "$ENG/$2" -name '*.java')
  "$JAR" cfm "$4" "$ENG/$3" -C "$cls" .; echo "Built $4"
}
API="$OUT/org.geogebra.plus.compute.api_0.1.0.jar"; RT="$OUT/org.geogebra.plus.compute.runtime_0.1.0.jar"
PARI="$OUT/org.geogebra.plus.engine.pari_0.1.0.jar"; MAX="$OUT/org.geogebra.plus.engine.maxima_0.1.0.jar"
GNU="$OUT/org.geogebra.plus.engine.gnuplot_0.1.0.jar"
build compute-api api/src api/META-INF/MANIFEST.MF "$API" ""
build compute-runtime runtime/src runtime/META-INF/MANIFEST.MF "$RT" "$API"
CP="$API:$RT:$OSGI"
build engine-pari pari/src pari/META-INF/MANIFEST.MF "$PARI" "$CP"
build engine-maxima maxima/src maxima/META-INF/MANIFEST.MF "$MAX" "$CP"
build engine-gnuplot gnuplot/src gnuplot/META-INF/MANIFEST.MF "$GNU" "$CP"
TC="$OUT/engine-test-classes"; mkdir -p "$TC"
ECP="$API:$RT:$PARI:$MAX:$GNU:$OSGI"
"$JAVAC" -encoding UTF-8 --release 21 -cp "$ECP" -d "$TC" $(find "$ENG" -path '*/test/*' -name '*.java')
"$JAVA" -cp "$TC:$ECP" org.geogebra.plus.engine.tests.EngineAcceptanceTest
