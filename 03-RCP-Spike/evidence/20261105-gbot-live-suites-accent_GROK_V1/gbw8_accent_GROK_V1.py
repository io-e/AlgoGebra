# GROK_V1 GB-W8: accented answer via cmd=new -> cmd=reply&special_parm=algogebra_json; decode cp1252, extract, json.loads
import re, json, urllib.request, urllib.parse
B="http://127.0.0.1:18431/wims/wims.cgi"; M="H6/test/oef2html.fr"; O="/workspace/grok-g1/ev_live/"
open("/workspace/grok-g1/gv_wimsrt/public_html/modules/H6/test/oef2html.fr/Exindex","w").write("!set exolist  =!char 1 to -2 of gbw8acc,\n!set titlelist=!char 1 to -2 of gbw8acc,\n!set exototal =!itemcnt $exolist\n")
RX=re.compile(r"<!--\s*ALGOGEBRA_JSON_BEGIN\s*(.*?)\s*ALGOGEBRA_JSON_END\s*-->", re.S)
def get(q,t):
    r=urllib.request.urlopen(B+"?"+q,timeout=120); b=r.read(); open(O+"raw/"+t+".html","wb").write(b); return b, r.headers["Content-Type"]
res=[]
for tag,val,enc,method in [("right_cp1252","été","cp1252","GET"),("right_cp1252_upper","ÉTÉ","cp1252","GET"),("wrong_cp1252","février","cp1252","GET"),
                           ("right_utf8","été","utf-8","GET"),("wrong_utf8","février","utf-8","GET"),("right_utf8_post","été","utf-8","POST")]:
    b,_=get(urllib.parse.urlencode(dict(module=M,cmd="new",exo="gbw8acc",qnum=1,qcmlevel=1,intro_expert="yes",lang="fr")),"w8acc_%s_new"%tag)
    sid=re.search(rb'name="session" value="([^"]+)"',b).group(1).decode()
    q="session=%s&cmd=reply&module=%s&special_parm=algogebra_json&reply1=%s"%(sid,M,urllib.parse.quote(val.encode(enc)))
    if method=="POST":
        rq=urllib.request.Request(B,data=q.encode(),headers={"Content-Type":"application/x-www-form-urlencoded; charset=UTF-8"}); r=urllib.request.urlopen(rq,timeout=120); raw=r.read(); ct=r.headers["Content-Type"]; open(O+"raw/w8acc_%s_reply.html"%tag,"wb").write(raw)
    else: raw,ct=get(q,"w8acc_%s_reply"%tag)
    html=raw.decode("cp1252","replace"); m=RX.search(html); d=None; err=None
    rb=re.search(rb"ALGOGEBRA_JSON_BEGIN\s*(.*?)\s*ALGOGEBRA_JSON_END",raw,re.S)
    if rb: open(O+"json/w8acc_%s.bin"%tag,"wb").write(rb.group(1))
    try: d=json.loads(m.group(1)) if m else None
    except Exception as e: err=repr(e)
    a=d["answers"][0] if d else {}
    gb=re.search(rb'"given":"([^"]*)"',rb.group(1)).group(1) if rb else None
    eb=re.search(rb'"expected":"([^"]*)"',rb.group(1)).group(1) if rb else None
    r=dict(case=tag,sent=val,enc=enc,method=method,sent_bytes=val.encode(enc).hex(),ct=ct,json_present=bool(m),parses=d is not None,err=err,
           grade=d and d["grade"],correct=a.get("correct"),given=a.get("given"),expected=a.get("expected"),
           given_bytes=gb.hex() if gb else None,expected_bytes=eb.hex() if eb else None,
           retry_page="sûr".encode("cp1252") in raw or b"compr\xe9hensible" in raw, answer_analysis=b"answer_analysis" in raw)
    res.append(r); print(r)
json.dump(res,open(O+"gbw8_results.json","w"),indent=1,ensure_ascii=False)
