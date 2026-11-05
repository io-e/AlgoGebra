#!/bin/bash
# Install AlgoGebra JSON hook into a WIMS tree (Linux). Idempotent; keeps answer.phtml.bak_pre_algogebra.
# Usage: install_algogebra_hook.sh <wims_root> <runtime_patch_dir>
set -e
W=$1; P=$2; OEF=$W/public_html/scripts/oef; A=$OEF/answer.phtml
[ -f "$A" ] && [ -f "$P/algogebra_json.phtml" ] || { echo "missing answer.phtml or hook" >&2; exit 1; }
cp "$P/algogebra_json.phtml" "$OEF/algogebra_json.phtml"
if grep -q 'GROK_V1 AlgoGebra JSON hook' "$A"; then echo "already patched"; exit 0; fi
[ -f "$A.bak_pre_algogebra" ] || cp -p "$A" "$A.bak_pre_algogebra"
python3 - "$A" <<'PY'
import re,sys
p=sys.argv[1]; t=open(p,'rb').read()
pat=re.compile(rb'(!!end of \.answer_analysis\r?\n</div>\r?\n)(!!presentsol=1 deprecated)')
nl=b'\r\n' if b'\r\n' in t else b'\n'
ins=nl.join([b'!! GROK_V1 AlgoGebra JSON hook (special_parm=algogebra_json)',b'!if $special_parm=algogebra_json',b'<!-- ALGOGEBRA_JSON_BEGIN',b'!read oef/algogebra_json.phtml',b'ALGOGEBRA_JSON_END -->',b'!endif'])+nl
n,c=pat.subn(lambda m:m.group(1)+ins+m.group(2),t,count=1)
if c!=1: sys.exit("injection pattern did not match")
open(p,'wb').write(n)
PY
echo "patched $A"
