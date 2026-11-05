# GROK_V1 — GB-W3/W4/W8 HTTP smoke against Debian WIMS (stdlib only)
import json, re, sys, urllib.request, urllib.parse, pathlib
BASE = "http://127.0.0.1:18431/wims/wims.cgi"
MOD = "H6/test/oef2html.fr"
OUT = pathlib.Path(sys.argv[1])
EXI = pathlib.Path("/workspace/grok-g1/gv_wimsrt/public_html/modules/H6/test/oef2html.fr/Exindex")
RX = re.compile(r"<!--\s*ALGOGEBRA_JSON_BEGIN\s*(.*?)\s*ALGOGEBRA_JSON_END\s*-->", re.S)
def get(params, tag):
    url = BASE + "?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=120) as r:
        raw = r.read(); ct = r.headers.get("Content-Type", "")
    (OUT/"raw"/(tag+".html")).write_bytes(raw)
    return raw, ct, url
def setexo(x):
    EXI.write_text("!set exolist  =!char 1 to -2 of %s,\n!set titlelist=!char 1 to -2 of %s,\n!set exototal =!itemcnt $exolist\n" % (x, x), encoding="latin-1")
cases = [("00006","wrong",{"reply1":"0"},0.0),("00006","right",{"reply1":"2"},1.0),
         ("00076","wrong",{"reply1":"1"},0.0),("00076","right",{"reply1":"3, 5"},1.0)]
rows=[]; log=[]
def new(x, tag):
    setexo(x)
    raw, ct, url = get(dict(module=MOD,cmd="new",exo=x,qnum=1,qcmlevel=1,intro_expert="yes",intro_sol=1,intro_good=1,intro_feed=1,lang="fr"), tag)
    log.append((tag, url, ct))
    m = re.search(rb'name="session" value="([^"]+)"', raw)
    assert b"ALGOGEBRA_JSON_BEGIN" not in raw
    return m.group(1).decode() if m else None
for x, kind, fields, eg in cases:
    tag = "%s_%s" % (x, kind)
    sid = new(x, tag+"_new")
    p = dict(session=sid, cmd="reply", module=MOD, special_parm="algogebra_json"); p.update(fields)
    raw, ct, url = get(p, tag+"_reply"); log.append((tag+"_reply", url, ct))
    enc = (re.search(r"charset=([\w-]+)", ct) or re.search(r"charset=([\w-]+)", raw[:2000].decode("latin-1"))).group(1)
    html = raw.decode(enc, "replace")
    r = dict(case=tag, sid=sid, present=False, valid=False, grade_ok=False, ids_ok=False, echo_ok=False, correct_ok=False, ascii=None)
    m = RX.search(html)
    if m:
        r["present"]=True; body=m.group(1)
        (OUT/"json"/(tag+".json")).write_text(body, encoding="utf-8")
        r["ascii"]=all(ord(c)<128 for c in body)
        try:
            d=json.loads(body); r["valid"]=True; r["json"]=d
            r["grade_ok"]=abs(float(d["grade"])-eg)<1e-6
            r["ids_ok"]=all(a["id"].startswith(("reply","choice")) for a in d["answers"]) and d["answers"][0]["id"]=="reply1"
            r["echo_ok"]=d["answers"][0]["given"].replace(" ","")==fields["reply1"].replace(" ","")
            r["correct_ok"]=all(a["correct"]==(eg==1.0) and isinstance(a["correct"],bool) for a in d["answers"])
        except Exception as e: r["err"]=repr(e)
    rows.append(r)
# GB-W4 negative
neg=[]
for x, val in (("00006","2"),("00076","3, 5")):
    sid = new(x, "neg_%s_new"%x)
    raw, ct, url = get(dict(session=sid,cmd="reply",module=MOD,reply1=val), "neg_%s_reply"%x); log.append(("neg_"+x, url, ct))
    neg.append(dict(case="neg_"+x, marker_absent=b"ALGOGEBRA_JSON" not in raw, graded=b"answer_analysis" in raw))
json.dump(dict(rows=rows, neg=neg, http=log), open(OUT/"results.json","w"), indent=1, ensure_ascii=False)
for r in rows: print({k:v for k,v in r.items() if k!="json"}, json.dumps(r.get("json")))
for n in neg: print(n)
for l in log: print(l[0], l[2])
