#!/usr/bin/env bash
# launch.sh - Linux port of launch.ps1 (GROK_V1).
# Usage: launch.sh [--headless] [--boot-delegate-jogamp] [--print-java] [-Course <path> | --course <path> | --course=<path>]
# -Course (P0, design 03-RCP-Spike/docs/Design_LaunchSh_Course_Flag_GROK_V1.md): validated + canonicalized BEFORE Java discovery,
#   passed as -Dggbplus.course=<realpath>. Env: GGBPLUS_COURSE (fallback), GGBPLUS_COURSE_ROOT (optional allow-root),
#   GGBPLUS_LAUNCH_DRYRUN=1 (print final java argv, start nothing). Launcher checks are a convenience gate; the Java
#   validator (toRealPath on OPEN targets) stays authoritative.
# Exit codes: 3 no image, 4 no Java >= MIN (BUG-017), 64 usage, 65 not .json / > 1 MB, 66 missing/unreadable/not a file, 77 outside root.
set -euo pipefail
HEADLESS=false; BOOT=false; PRINT_JAVA=false; COURSE=""; COURSE_SET=false
die() { echo "launch.sh: $2" >&2; exit "$1"; }
set_course() { $COURSE_SET && die 64 "-Course given more than once"; [ -n "$1" ] || die 64 "-Course needs a value"; COURSE="$1"; COURSE_SET=true; }
while (($#)); do case "$1" in
  --headless) HEADLESS=true;; --boot-delegate-jogamp) BOOT=true;; --print-java) PRINT_JAVA=true;;
  -Course|--course) (($# >= 2)) || die 64 "$1 needs a value"; set_course "$2"; shift;;
  --course=*) set_course "${1#--course=}";;
  *) echo "launch.sh: warning: ignoring unknown argument '$1'" >&2;;
esac; shift; done
$COURSE_SET || { [ -n "${GGBPLUS_COURSE:-}" ] && COURSE="$GGBPLUS_COURSE" && COURSE_SET=true; } || true
COURSE_REAL=""
if $COURSE_SET; then
  [[ "$COURSE" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]] && die 64 "course must be a local file, not a URL: $COURSE"
  COURSE_REAL="$(realpath -e -- "$COURSE" 2>/dev/null)" || die 66 "course file not found: $COURSE"
  [ -f "$COURSE_REAL" ] && [ -r "$COURSE_REAL" ] || die 66 "course is not a readable regular file: $COURSE_REAL"
  [[ "$COURSE_REAL" == *.json ]] || die 65 "course must be a .json file: $COURSE_REAL"
  [ "$(stat -c %s -- "$COURSE_REAL")" -le 1048576 ] || die 65 "course file exceeds 1 MB: $COURSE_REAL"
  if [ -n "${GGBPLUS_COURSE_ROOT:-}" ]; then ROOT_REAL="$(realpath -e -- "$GGBPLUS_COURSE_ROOT" 2>/dev/null)" || die 77 "GGBPLUS_COURSE_ROOT not found: $GGBPLUS_COURSE_ROOT"
    [[ "$COURSE_REAL" == "${ROOT_REAL%/}/"* ]] || die 77 "course outside GGBPLUS_COURSE_ROOT ($ROOT_REAL): $COURSE_REAL"; fi
fi
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
    echo "launch.sh: GGB_JAVA/JAVA='$explicit' is not a usable Java >= $MIN (${TRIED[*]})" >&2; exit 4; fi
  for d in "$IMAGE/jre" "$IMAGE/jdk"; do try_java "$d/bin/java" "bundled" && return 0; done
  [ -n "${JAVA_HOME:-}" ] && try_java "$JAVA_HOME/bin/java" "JAVA_HOME" && return 0
  if command -v mise >/dev/null 2>&1; then local mw; mw="$(mise where java 2>/dev/null || true)"
    if [ -n "$mw" ]; then try_java "$mw/bin/java" "mise" && return 0
      # F-1 (GROK_V1): a mise-pinned Java below MIN is skipped; say so instead of silently using another JDK
      echo "launch.sh: warning: mise-pinned Java at $mw is below $MIN (${TRIED[${#TRIED[@]}-1]:-unusable}); continuing discovery" >&2; fi; fi
  for d in $(ls -d "$HOME"/.local/share/mise/installs/java/* /usr/lib/jvm/* /opt/java/* 2>/dev/null | sort -rV); do try_java "$d/bin/java" "system" && return 0; done
  command -v java >/dev/null 2>&1 && try_java "$(command -v java)" "PATH" && return 0
  echo "launch.sh: no Java >= $MIN found. Set GGB_JAVA=/path/to/bin/java or JAVA_HOME, or install a JDK (e.g. apt install openjdk-25-jre, or 'mise use java@25')." >&2
  [ ${#TRIED[@]} -gt 0 ] && printf '  tried: %s\n' "${TRIED[@]}" >&2
  exit 4; }
find_java
$PRINT_JAVA && { echo "JAVA=$JAVA SOURCE=$JAVA_SRC MAJOR=$JAVA_MAJOR MIN=$MIN"; exit 0; }
DRY="${GGBPLUS_LAUNCH_DRYRUN:-0}"
RUN="$(date +%Y%m%d-%H%M%S)-$$"; CFG="$IMAGE/configuration/runtime-$RUN"
if [ "$DRY" != 1 ]; then mkdir -p "$CFG" "$IMAGE/logs"
  cp -r "$IMAGE/configuration/config.ini" "$IMAGE/configuration/org.eclipse.equinox.simpleconfigurator" "$CFG/"; fi
CP="$(ls "$IMAGE"/launcher/*.jar "$IMAGE"/natives/*.jar 2>/dev/null | tr '\n' ':' || true)"
ARGS=(--add-exports java.base/java.lang=ALL-UNNAMED --add-exports java.desktop/sun.awt=ALL-UNNAMED
  --add-exports java.desktop/sun.java2d=ALL-UNNAMED --enable-native-access=ALL-UNNAMED --add-modules=ALL-SYSTEM
  "-Dosgi.install.area=file:$IMAGE/" -Declipse.application=org.geogebra.plus.host.geogebraplusApp
  -Declipse.product=org.geogebra.plus.host.geogebraplus "-Dggbplus.runId=$RUN" "-Dggbplus.headless=$HEADLESS")
$BOOT && ARGS+=(-Dorg.osgi.framework.bootdelegation=com.jogamp.*,jogamp.* -Dosgi.parentClassloader=app -Dggbplus.jogampBootDelegation=true)
[ -n "$COURSE_REAL" ] && ARGS+=("-Dggbplus.course=$COURSE_REAL")
CMD=("$JAVA" "${ARGS[@]}" -cp "$CP" org.eclipse.equinox.launcher.Main -configuration "$CFG" -data "$IMAGE/workspace-$RUN"
  -application org.geogebra.plus.host.geogebraplusApp -consoleLog -noSplash)
if [ "$DRY" = 1 ]; then echo "DRYRUN argc=${#CMD[@]}"; printf 'ARG %s\n' "${CMD[@]}"; exit 0; fi
[ -n "$COURSE_REAL" ] && echo "Run $RUN course $COURSE_REAL sha256 $(sha256sum -- "$COURSE_REAL" | cut -d' ' -f1)"
echo "Run $RUN log $IMAGE/logs/launch-$RUN.log"
"${CMD[@]}" 2>&1 | tee "$IMAGE/logs/launch-$RUN.log"
