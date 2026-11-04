#!/usr/bin/env python3
"""GV-3/GV-4/GV-6: count OEF constructs + converter output per file over a list of OEF files."""
import json, re, subprocess, sys, csv, collections, tempfile, os
conv, lst, out = sys.argv[1], sys.argv[2], sys.argv[3]
files=[l.strip() for l in open(lst) if l.strip()]
DIR=['hint','help','feedback','solution','remark','condition','conditions','steps','nextstep','embed','reply','choice','answer','plot','draw','precision','computeanswer','format','statement']
eng=re.compile(r'\b(pari|maxima|yacas|wims|slib|draw|teximg|gp|octave|giac|gap|mathfont|shuffle)\s*\(')
ansre=re.compile(r'\\answer\{[^}]*\}\{[^}]*\}\{type=([a-zA-Z]+)')
rows=[]; agg=collections.Counter(); engagg=collections.Counter(); typeagg=collections.Counter(); engfiles=collections.Counter()
for f in files:
    t=open(f,'rb').read().decode('latin-1')
    t2="\n".join(l for l in t.splitlines() if not l.lstrip().startswith('%%'))
    c={d:len(re.findall(r'\\'+d+r'\s*\{',t2)) for d in DIR}
    e=collections.Counter(m.group(1) for m in eng.finditer(t2))
    types=collections.Counter(m.group(1) for m in ansre.finditer(t2))
    fd,j=tempfile.mkstemp(suffix='.json'); os.close(fd)
    p=subprocess.run(['python3',conv,f,'-o',j],capture_output=True,text=True)
    ve=oe=ce=0
    try:
        d=json.load(open(j))
        for ch in d['tree']:
            for s in ch['children']:
                ty=s.get('check',{}).get('type')
                ve+=ty=='value_equals'; oe+=ty=='object_exists'
    except Exception: pass
    os.unlink(j)
    gap1=int(c['hint']+c['help']+c['feedback']+c['solution']+c['remark']>0)
    gap2=int(any(e[k] for k in ('pari','maxima','yacas','gp','octave','giac','gap')))
    gap3=int(gap2 or any(types[k] for k in ('algexp','formal','function','litexp','equation','aset','fset','wlist','matrix','sigunits','units','vector','range','set')))
    gap5=int(oe>0)
    rows.append(dict(file=f,rc=p.returncode,value_equals=ve,object_exists=oe,gap1=gap1,gap2=gap2,gap3=gap3,gap4=1,gap5=gap5,**{'n_'+k:v for k,v in c.items()},engines=';'.join(f'{k}:{v}' for k,v in sorted(e.items())),types=';'.join(f'{k}:{v}' for k,v in sorted(types.items()))))
    for k,v in c.items():
        agg[k]+=v; agg['files_'+k]+=v>0
    for k,v in e.items(): engagg[k]+=v; engfiles[k]+=1
    typeagg.update(types)
with open(out,'w',newline='') as fh:
    w=csv.DictWriter(fh,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print('files',len(rows),'rc0',sum(r['rc']==0 for r in rows))
for g in ['gap1','gap2','gap3','gap4','gap5']: print(g,sum(r[g] for r in rows))
print('value_equals',sum(r['value_equals'] for r in rows),'object_exists',sum(r['object_exists'] for r in rows))
print('files with >=1 value_equals', sum(r['value_equals']>0 for r in rows), 'files all-numeric', sum(r['value_equals']>0 and r['object_exists']==0 for r in rows))
print('directives (occurrences / files):'); [print(f'  \\{k}: {agg[k]} / {agg["files_"+k]}') for k in DIR]
print('engine calls (occ / files):'); [print(f'  {k}(): {engagg[k]} / {engfiles[k]}') for k,_ in engagg.most_common()]
print('answer types:', dict(typeagg.most_common()))
