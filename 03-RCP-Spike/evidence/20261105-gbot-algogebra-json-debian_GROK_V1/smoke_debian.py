# Debian port of test_algogebra_json_GROK_V1.py: runs Linux wims CGI, saves evidence.
import json, os, re, subprocess, sys, importlib.util
from pathlib import Path
spec=importlib.util.spec_from_file_location("t","/workspace/mw-algogebra/w4w/AlgoGebra_Wims_Integration/tests/test_algogebra_json_GROK_V1.py")
t=importlib.util.module_from_spec(spec); spec.loader.exec_module(t)
RT=Path(os.environ.get("WIMS_HOME","/workspace/mw-algogebra/debwims")); CGI=RT/"public_html"/"wims"
EV=Path(sys.argv[1]); EV.mkdir(parents=True,exist_ok=True)
SRC=Path("/workspace/mw-algogebra/w4w/tools/oef-validation/html/exemples/sources")
mod=RT/"public_html/modules/H6/test/oef2html.fr"
def raw(q):
    env=dict(os.environ,REQUEST_METHOD="GET",QUERY_STRING=q,REMOTE_ADDR="127.0.0.1",SERVER_NAME="localhost",SERVER_PORT="80",SCRIPT_NAME="/wims/wims.cgi",HTTP_HOST="localhost",HTTP_ACCEPT_LANGUAGE="fr",HTTP_USER_AGENT="smoke_debian")
    return subprocess.run([str(CGI)],cwd=str(RT/"public_html"),env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=120).stdout
def page(q,tag):
    b=raw(q); (EV/(tag+".html")).write_bytes(b)
    m=re.search(rb"charset=([\w-]+)",b[:600]); return b.decode(m.group(1).decode() if m else "utf-8","replace"), b
for n in ("00006","00076"): t.install_def(RT/"bin/oef2wims", SRC/(n+".oef"), mod/"def")
t.set_seed(mod/"var.proc",1)
M=t.MODULE; NEW="module=%s&cmd=new&exo=%s&qnum=1&qcmlevel=1&intro_expert=yes&intro_sol=1&intro_good=1&intro_feed=1&lang=fr"
rows=[]; ok=True
cases=[("00006","wrong",{"reply1":"0"},0.0),("00006","right",{"reply1":"2"},1.0),("00076","wrong",{"reply1":"1"},0.0),("00076","right",{"reply1":"3, 5"},1.0)]
for exo,kind,fields,g in cases:
  for hook in (True,False):
    t.set_exindex(mod,exo); tag="%s_%s_%s"%(exo,kind,"hook" if hook else "nohook")
    p,_=page(NEW%(M,exo),tag+"_new"); sm=re.search(r'name="session" value="([^"]+)"',p)
    if not sm: rows.append((tag,"FAIL no session")); ok=False; continue
    q="session=%s&cmd=reply&module=%s"%(sm.group(1),M)+("&special_parm=algogebra_json" if hook else "")
    for k,v in fields.items(): q+="&%s=%s"%(k,t.quote(v))
    h,b=page(q,tag+"_reply"); cs=re.search(rb"charset=([\w-]+)",b[:600])
    if hook:
      try:
        d=t.extract_json(h); t.check_payload(d,g); assert d["answers"][0]["id"]=="reply1"
        blk=re.search(rb"ALGOGEBRA_JSON_BEGIN(.*?)ALGOGEBRA_JSON_END",b,re.S).group(1)
        asc=all(c<128 for c in blk)
        (EV/(tag+".json")).write_text(json.dumps(d,indent=1,ensure_ascii=True))
        rows.append((tag,"PASS grade=%s answers=%s ascii_block=%s charset=%s"%(d["grade"],json.dumps(d["answers"]),asc,cs and cs.group(1).decode())))
      except Exception as e: rows.append((tag,"FAIL %r"%e)); ok=False
    else:
      leak="ALGOGEBRA_JSON_BEGIN" in h; graded="answer_analysis" in h
      rows.append((tag,("PASS" if (not leak and graded) else "FAIL")+" leak=%s graded=%s"%(leak,graded))); ok&= (not leak and graded)
out="\n".join("%s\t%s"%r for r in rows)+"\n"+("ALL PASS" if ok else "SOME FAIL")
(EV/"results.txt").write_text(out+"\n"); print(out); sys.exit(0 if ok else 1)
