#!/usr/bin/env bash
# launch.sh - Linux port of launch.ps1 (GROK_V1). Usage: launch.sh [--headless] [--boot-delegate-jogamp] [--print-java]
set -euo pipefail
IMAGE="${IMAGE:-$(cd "$(dirname "$0")" && pwd)}"
[ -d "$IMAGE/bundles" ] || { echo "launch.sh: no RCP image at '$IMAGE' (bundles/ missing); set IMAGE=<image dir>" >&2; exit 3; }
# BUG-017 (GROK_V1): Java discovery, first match with major version >= GGB_JAVA_MIN (default 25 = product runtime, D-10):
#   GGB_JAVA (or legacy JAVA) > bundled $IMAGE/jre|jdk > JAVA_HOME > mise (java) > /usr/lib/jvm/* and /opt/java/* (newest first) > java on PATH
MIN="${GGB_JAVA_MIN:-25}"
java_major() { local v; v="$("$1" -XshowSettings:properties -version 2>&1 | sed -n 's/^ *java.specification.version = //p' | head -1)"
  case "$v" in 1.*) echo "${v#1.}" | cut -d. -f1;; "") echo 0;; *) echo "${v%%.*}";; esac; }
TRIED=()
try_java() { local j="$1" src="$2" m; [ -n "$j" ] && [ -x "$j" ] || { [ -n "$j" ] && [ -e "$j" -o "$src" = GGB_JAVA ] && TRIED+=("$src: $j (not executable)"); return 1; }
  m="$(java_major "$j")"; if [ "$m" -ge "$MIN" ] 2>/dev/null; then JAVA="$j"; JAVA_SRC="$src"; JAVA_MAJOR="$m"; return 0; fi
  TRIED+=("$src: $j (Java $m < $MIN)"); return 1; }
find_java() {
  local explicit="${GGB_JAVA:-${JAVA:-}}"
  if [ -n "$explicit" ]; then try_java "$explicit" "GGB_JAVA" && return 0
    echo "launch.sh: GGB_JAVA/JAVA='$explicit' is not a usable Java >= $MIN (${TRIED[*]})" >&2; exit 69; fi
  for d in "$IMAGE/jre" "$IMAGE/jdk"; do try_java "$d/bin/java" "bundled" && return 0; done
  [ -n "${JAVA_HOME:-}" ] && try_java "$JAVA_HOME/bin/java" "JAVA_HOME" && return 0
  if command -v mise >/dev/null 2>&1; then local mw; mw="$(mise where java 2>/dev/null || true)"; [ -n "$mw" ] && try_java "$mw/bin/java" "mise" && return 0; fi
  for d in $(ls -d "$HOME"/.local/share/mise/installs/java/* /usr/lib/jvm/* /opt/java/* 2>/dev/null | sort -rV); do try_java "$d/bin/java" "system" && return 0; done
  command -v java >/dev/null 2>&1 && try_java "$(command -v java)" "PATH" && return 0
  echo "launch.sh: no Java >= $MIN found. Set GGB_JAVA=/path/to/bin/java or JAVA_HOME, or install a JDK (e.g. apt install openjdk-25-jre, or 'mise use java@25')." >&2
  [ ${#TRIED[@]} -gt 0 ] && printf '  tried: %s\n' "${TRIED[@]}" >&2
  exit 69; }
find_java
for a in "$@"; do [ "$a" = "--print-java" ] && { echo "JAVA=$JAVA SOURCE=$JAVA_SRC MAJOR=$JAVA_MAJOR MIN=$MIN"; exit 0; }; done
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
