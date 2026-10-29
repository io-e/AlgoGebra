#!/usr/bin/env bash
# launch.sh - Linux port of launch.ps1 (GROK_V1). Usage: launch.sh [--headless] [--boot-delegate-jogamp]
set -euo pipefail
IMAGE="${IMAGE:-$(cd "$(dirname "$0")" && pwd)}"
[ -d "$IMAGE/bundles" ] || IMAGE=/workspace/AlgoGebra/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64
JAVA="${JAVA:-$(ls -d /workspace/AlgoGebra/jdk/jdk-25* | head -1)/bin/java}"
HEADLESS=false; BOOT=false
for a in "$@"; do case "$a" in --headless) HEADLESS=true;; --boot-delegate-jogamp) BOOT=true;; esac; done
RUN="$(date +%Y%m%d-%H%M%S)-$$"; CFG="$IMAGE/configuration/runtime-$RUN"; mkdir -p "$CFG" "$IMAGE/logs"
cp -r "$IMAGE/configuration/config.ini" "$IMAGE/configuration/org.eclipse.equinox.simpleconfigurator" "$CFG/"
CP="$(ls "$IMAGE"/launcher/*.jar "$IMAGE"/natives/*.jar | tr '\n' ':')"
ARGS=(--add-exports java.base/java.lang=ALL-UNNAMED --add-exports java.desktop/sun.awt=ALL-UNNAMED
  --add-exports java.desktop/sun.java2d=ALL-UNNAMED --enable-native-access=ALL-UNNAMED --add-modules=ALL-SYSTEM
  "-Dosgi.install.area=file:$IMAGE/" -Declipse.application=org.geogebra.plus.host.geogebraplusApp
  -Declipse.product=org.geogebra.plus.host.geogebraplus "-Dggbplus.runId=$RUN" "-Dggbplus.headless=$HEADLESS")
$BOOT && ARGS+=(-Dorg.osgi.framework.bootdelegation=com.jogamp.*,jogamp.* -Dosgi.parentClassloader=app -Dggbplus.jogampBootDelegation=true)
echo "Run $RUN log $IMAGE/logs/launch-$RUN.log"
"$JAVA" "${ARGS[@]}" -cp "$CP" org.eclipse.equinox.launcher.Main -configuration "$CFG" -data "$IMAGE/workspace-$RUN" \
  -application org.geogebra.plus.host.geogebraplusApp -consoleLog -noSplash 2>&1 | tee "$IMAGE/logs/launch-$RUN.log"
