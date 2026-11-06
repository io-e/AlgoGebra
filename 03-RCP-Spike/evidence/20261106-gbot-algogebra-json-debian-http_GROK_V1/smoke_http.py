#!/usr/bin/env python3
import json, os, re, sys, urllib.parse, urllib.request
from pathlib import Path

BASE = sys.argv[1].rstrip("/")
EV = Path(sys.argv[2])
EV.mkdir(parents=True, exist_ok=True)
MODULE = "H6/test/oef2html.fr"
BEGIN = "ALGOGEBRA_JSON_BEGIN"
END = "ALGOGEBRA_JSON_END"

def fetch(query, tag):
    url = BASE + "?" + query
    req = urllib.request.Request(url, headers={"Accept-Language": "fr", "User-Agent": "mw-http-smoke"})
    with urllib.request.urlopen(req, timeout=120) as r:
        raw = r.read()
        ctype = r.headers.get("Content-Type", "")
    (EV / (tag + ".html")).write_bytes(raw)
    m = re.search(r"charset=([\w-]+)", ctype, re.I)
    enc = m.group(1) if m else "utf-8"
    return raw.decode(enc, "replace"), raw, ctype

def extract(html):
    m = re.search(r"<!--\s*" + BEGIN + r"\s*(.*?)\s*" + END + r"\s*-->", html, re.S)
    if not m:
        raise AssertionError("JSON comment block not found")
    return json.loads(m.group(1).strip())

NEW = "module=%s&cmd=new&exo=%s&qnum=1&qcmlevel=1&intro_expert=yes&intro_sol=1&intro_good=1&intro_feed=1&lang=fr"
cases = [
    ("00006", "wrong", {"reply1": "0"}, 0.0),
    ("00006", "right", {"reply1": "2"}, 1.0),
    ("00076", "wrong", {"reply1": "1"}, 0.0),
    ("00076", "right", {"reply1": "3, 5"}, 1.0),
]
rows = []
ok = True
for exo, kind, fields, g in cases:
    for hook in (True, False):
        tag = f"{exo}_{kind}_{'hook' if hook else 'nohook'}"
        page, _, _ = fetch(NEW % (MODULE, exo), tag + "_new")
        sm = re.search(r'name="session" value="([^"]+)"', page)
        if not sm:
            rows.append((tag, "FAIL no session"))
            ok = False
            continue
        q = f"session={sm.group(1)}&cmd=reply&module={MODULE}"
        if hook:
            q += "&special_parm=algogebra_json"
        for k, v in fields.items():
            q += f"&{k}={urllib.parse.quote(v)}"
        html, raw, ctype = fetch(q, tag + "_reply")
        if hook:
            try:
                d = extract(html)
                assert "answers" in d and d["answers"]
                assert d["answers"][0]["id"] == "reply1"
                assert abs(float(d["grade"]) - g) < 1e-6, d["grade"]
                blk = re.search(rb"ALGOGEBRA_JSON_BEGIN(.*?)ALGOGEBRA_JSON_END", raw, re.S).group(1)
                ascii_ok = all(c < 128 for c in blk)
                (EV / (tag + ".json")).write_text(json.dumps(d, indent=1, ensure_ascii=True))
                rows.append((tag, f"PASS grade={d['grade']} id={d['answers'][0]['id']} ascii={ascii_ok} ctype={ctype}"))
            except Exception as e:
                rows.append((tag, f"FAIL {e!r}"))
                ok = False
        else:
            leak = BEGIN in html
            graded = "answer_analysis" in html
            status = "PASS" if (not leak and graded) else "FAIL"
            rows.append((tag, f"{status} leak={leak} graded={graded}"))
            ok &= (not leak and graded)
out = "\n".join(f"{a}\t{b}" for a, b in rows) + "\n" + ("ALL PASS" if ok else "SOME FAIL")
(EV / "results.txt").write_text(out + "\n")
print(out)
sys.exit(0 if ok else 1)
