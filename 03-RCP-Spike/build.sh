#!/usr/bin/env bash
# build.sh - Debian/Linux (linux-gtk-x86_64) port of build.ps1 + install-product.ps1.
# Author: Grok Bot (GROK_V1). Stages a Linux RCP image from:
#   REF_IMAGE   : an installed Windows image (r8) providing the 50 unchanged D-03
#                 OSGi bundles, platform jars and the Equinox launcher (pure Java);
#   GGB_SRC     : GeoGebra upstream checkout at pin 375db7faf54 (resources only);
#   Linux natives (SWT gtk, GlueGen/JOGL linux-amd64, javagiac linux-amd64) from Maven.
# Upstream GeoGebra code and the 50 bundle jars are never modified.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BASE="${ALGOGEBRA_BASE:-/workspace/AlgoGebra}"
REF_IMAGE="${REF_IMAGE:-$BASE/ref-bin/r8}"
GGB_SRC="${GGB_SRC:-$BASE/geogebra/source}"
JAVA_HOME="${JAVA_HOME:-$(ls -d $BASE/jdk/jdk-21* | head -1)}"
IMAGE="${IMAGE:-$BASE/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64}"
NAT="${LINUX_NATIVES:-$BASE/linux-natives}"
JAVAC="$JAVA_HOME/bin/javac"; JAR="$JAVA_HOME/bin/jar"
M=https://repo1.maven.org/maven2
mkdir -p "$NAT"; cd "$NAT"
fetch() { [ -f "$(basename "$1")" ] || curl -fsSLO "$1"; }
fetch $M/org/jogamp/gluegen/gluegen-rt/2.6.0/gluegen-rt-2.6.0-natives-linux-amd64.jar
fetch $M/org/jogamp/jogl/jogl-all/2.6.0/jogl-all-2.6.0-natives-linux-amd64.jar
fetch $M/org/eclipse/platform/org.eclipse.swt.gtk.linux.x86_64/3.135.0/org.eclipse.swt.gtk.linux.x86_64-3.135.0.jar
fetch https://dev.geogebra.org/maven2/fr/ujf-grenoble/javagiac/70501/javagiac-70501-natives-linux-amd64.jar
rm -rf "$IMAGE"; mkdir -p "$IMAGE"/{bundles,platform,launcher,natives,host/build,configuration/org.eclipse.equinox.simpleconfigurator}
cp "$REF_IMAGE"/bundles/*.jar "$IMAGE/bundles/"
cp "$REF_IMAGE"/launcher/*.jar "$IMAGE/launcher/"
for j in "$REF_IMAGE"/platform/*.jar; do case "$j" in *swt.win32*) ;; *) cp "$j" "$IMAGE/platform/";; esac; done
cp "$NAT"/org.eclipse.swt.gtk.linux.x86_64-3.135.0.jar "$IMAGE/platform/org.eclipse.swt.gtk.linux.x86_64_3.135.0.v20260819-1952.jar"
for j in "$REF_IMAGE"/natives/*.jar; do case "$j" in *natives-windows*) ;; *) cp "$j" "$IMAGE/natives/";; esac; done
cp "$NAT"/gluegen-rt-2.6.0-natives-linux-amd64.jar "$NAT"/jogl-all-2.6.0-natives-linux-amd64.jar "$NAT"/javagiac-70501-natives-linux-amd64.jar "$IMAGE/natives/"
[ "$(ls "$IMAGE"/bundles/*.jar | grep -v org.eclipse.osgi_ | wc -l)" = 50 ] || { echo "Expected 50 D-03 bundles"; exit 1; }
OUT="$IMAGE/host/build"; T="$(mktemp -d)"
CP="$(ls "$IMAGE"/bundles/*.jar "$IMAGE"/platform/*.jar "$IMAGE"/natives/*.jar | tr '\n' ':')"
mkdir -p "$T/host"; "$JAVAC" -encoding UTF-8 --release 21 -cp "$CP" -d "$T/host" $(find "$ROOT/host/src" -name '*.java')
"$JAR" cfm "$OUT/org.geogebra.plus.host_0.1.0.jar" "$ROOT/host/META-INF/MANIFEST.MF" -C "$T/host" . -C "$ROOT/host" plugin.xml
"$JAR" cfm "$OUT/org.geogebra.plus.desktop.resources_0.1.0.jar" "$ROOT/host/resources/META-INF/MANIFEST.MF" \
  -C "$GGB_SRC/desktop/desktop/src/main/resources" . -C "$GGB_SRC/shared/common/src/main/resources" .
for f in giac:giac-native gluegen:gluegen-native jogl:jogl-native; do n=${f%%:*}; d=${f#*:}; mkdir -p "$T/$n"
  "$JAVAC" -encoding UTF-8 --release 21 -d "$T/$n" $(find "$ROOT/host/$d/src" -name '*.java')
  "$JAR" cfm "$OUT/org.geogebra.plus.$n.native_0.1.0.jar" "$ROOT/host/$d/META-INF/MANIFEST.MF" -C "$T/$n" .; done
E="$ROOT/engines"; OSGI="$(ls "$IMAGE"/bundles/org.eclipse.osgi_*.jar)"
eb() { mkdir -p "$T/$1"; "$JAVAC" -encoding UTF-8 --release 21 -cp "$3" -d "$T/$1" $(find "$E/$1/src" -name '*.java')
  "$JAR" cfm "$OUT/$2" "$E/$1/META-INF/MANIFEST.MF" -C "$T/$1" .; }
eb api org.geogebra.plus.compute.api_0.1.0.jar "$OSGI"
eb runtime org.geogebra.plus.compute.runtime_0.1.0.jar "$OUT/org.geogebra.plus.compute.api_0.1.0.jar"
ECP="$OUT/org.geogebra.plus.compute.api_0.1.0.jar:$OUT/org.geogebra.plus.compute.runtime_0.1.0.jar:$CP"
for e in pari maxima gnuplot; do eb $e org.geogebra.plus.engine.${e}_0.1.0.jar "$ECP"; done
meta() { unzip -p "$1" META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g'; }
bsn() { meta "$1" | sed -n 's/^Bundle-SymbolicName: *\([^;]*\).*/\1/p' | head -1 | xargs; }
ver() { meta "$1" | sed -n 's/^Bundle-Version: *//p' | head -1 | xargs; }
frag() { meta "$1" | grep -q '^Fragment-Host:'; }
BI="$IMAGE/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"
{ echo '#encoding=UTF-8'; echo '#version=1'
  for j in "$IMAGE"/bundles/*.jar; do case "$j" in *org.eclipse.osgi_*) continue;; esac
    echo "$(bsn "$j"),$(ver "$j"),bundles/$(basename "$j"),4,false"; done
  for j in "$IMAGE"/platform/*.jar; do b=$(bsn "$j"); [ "$b" = org.eclipse.equinox.simpleconfigurator ] && continue
    a=true; frag "$j" && a=false; l=4; [ "$b" = org.eclipse.equinox.common ] && l=2
    echo "$b,$(ver "$j"),platform/$(basename "$j"),$l,$a"; done
  for n in host:true desktop.resources:false giac.native:false gluegen.native:false jogl.native:false compute.api:false compute.runtime:false engine.pari:true engine.maxima:true engine.gnuplot:true; do
    j="$OUT/org.geogebra.plus.${n%%:*}_0.1.0.jar"; echo "$(bsn "$j"),$(ver "$j"),host/build/$(basename "$j"),4,${n#*:}"; done
} > "$BI"
SC="$(ls "$IMAGE"/platform/org.eclipse.equinox.simpleconfigurator_*.jar)"
cat > "$IMAGE/configuration/config.ini" <<INI
# Generated by build.sh (Linux). Installed paths are absolute.
eclipse.application=org.geogebra.plus.host.geogebraplusApp
eclipse.product=org.geogebra.plus.host.geogebraplus
org.eclipse.equinox.simpleconfigurator.configUrl=file:org.eclipse.equinox.simpleconfigurator/bundles.info
osgi.bundles=reference:file:$SC@1:start
osgi.bundles.defaultStartLevel=4
osgi.framework=file:$OSGI
INI
# Same algorithm as build.ps1: "name  sha256" lines sorted by name, joined by LF, hashed.
SET_HASH="$(cd "$IMAGE/bundles" && ls *.jar | grep -v '^org.eclipse.osgi_' | LC_ALL=C sort | while read -r f; do printf '%s  %s\n' "$f" "$(sha256sum "$f" | cut -d' ' -f1)"; done | head -c -1 | sha256sum | cut -d' ' -f1)"
echo "$SET_HASH  50 D-03 installable bundle inputs (excluding system framework)" > "$IMAGE/bnd-input-set.sha256"
cp "$ROOT/launch.sh" "$IMAGE/" 2>/dev/null || true
rm -rf "$T"; echo "Built Linux image: $IMAGE"; cat "$IMAGE/bnd-input-set.sha256"
