#!/usr/bin/env python3
# GROK_V1 - GB-R2 fidelity metrics + GB-R3 engine signals over corpus 300 (tip of feat/grok-sprint3-plan-v1-1)
import json, re, subprocess, sys, os, csv, collections
lst, tool, outdir, ev = sys.argv[1:5]
os.makedirs(outdir, exist_ok=True)
ENG = collections.OrderedDict([
 ('wims', r'\bwims\s*\('), ('slib', r'\bslib\s*\('), ('pari', r'\bpari\s*\('), ('maxima', r'\bmaxima\s*\('),
 ('octave', r'\boctave\s*\('), ('yacas', r'\byacas\s*\('), ('gap', r'\bgap\s*\('), ('m2', r'\bm2\s*\('),
 ('scilab', r'\bscilab\s*\('), ('gp_file', r'gp\s+-f'), ('draw', r'\bdraw\s*\('), ('shuffle', r'\bshuffle\s*\('),
 ('pari_kw', r'\\pari\b'), ('maxima_kw', r'\\maxima\b')])
CAS = ['pari','maxima','octave','yacas','gap','m2','scilab','gp_file','pari_kw','maxima_kw']
rows=[]; tot=collections.Counter(); files=collections.Counter(); warn_nonnum=0; fails=0
for i,f in enumerate(open(lst).read().split()):
    o=os.path.join(outdir,f'c{i+1:03d}.json')
    p=subprocess.run([sys.executable,tool,f,'-o',o],capture_output=True,text=True)
    nn=sum('not numeric' in l for l in p.stderr.splitlines()); warn_nonnum+=nn
    r={'file':f,'rc':p.returncode,'warn_not_numeric':nn,'warn_other':sum(('warning' in l and 'not numeric' not in l) for l in p.stderr.splitlines())}
    ct=collections.Counter(); hint=eng=unres=steps=0
    if p.returncode==0:
        d=json.load(open(o))
        def walk(n):
            global hint,eng,unres,steps
            for c in n.get('children',[]) or []:
                steps+=1
                if 'check' in c: ct[c['check'].get('type','?')]+=1
                ds=c.get('description','') or ''
                if 'Hint:' in ds: hint+=1
                if 'engine' in c or 'engine' in (c.get('check') or {}): eng+=1
                if re.search(r'\$[A-Za-z_]', ds+c.get('title','')): unres+=1
                walk(c)
        for t in d.get('tree',[]): walk(t)
    else: fails+=1
    src=open(f,encoding='latin-1').read()
    for k,rx in ENG.items():
        n=len(re.findall(rx,src)); r['eng_'+k]=n; tot[k]+=n; files[k]+=n>0
    r.update(steps=steps,value_equals=ct['value_equals'],object_exists=ct['object_exists'],other_checks=sum(v for k,v in ct.items() if k not in('value_equals','object_exists')),
             hint_steps=hint,engine_steps=eng,unresolved_dollar_steps=unres,
             any_cas=int(any(r['eng_'+k] for k in CAS)),any_runtime_param=int(any(r['eng_'+k] for k in ['wims','slib','pari','maxima','octave','yacas','gap','m2','scilab'])))
    rows.append(r)
with open(os.path.join(ev,'gbr2_gbr3_per_file_GROK_V1.csv'),'w',newline='') as fh:
    w=csv.DictWriter(fh,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
S=lambda k: sum(r[k] for r in rows); F=lambda k: sum(r[k]>0 for r in rows)
with open(os.path.join(ev,'gbr2_fidelity_summary_GROK_V1.tsv'),'w') as fh:
    fh.write('metric\tcount\tfiles\n')
    for k in ['steps','value_equals','object_exists','other_checks','hint_steps','engine_steps','unresolved_dollar_steps','warn_not_numeric','warn_other']:
        fh.write(f'{k}\t{S(k)}\t{F(k)}\n')
    fh.write(f'convert_failures\t{fails}\t{fails}\n')
with open(os.path.join(ev,'gbr3_engine_signals_GROK_V1.tsv'),'w') as fh:
    fh.write('signal\tcalls\tfiles\n')
    for k in ENG: fh.write(f'{k}\t{tot[k]}\t{files[k]}\n')
    fh.write(f'ANY_named_CAS\t-\t{S("any_cas")}\nANY_runtime_param(wims/slib/CAS)\t-\t{S("any_runtime_param")}\n')
print(open(os.path.join(ev,'gbr2_fidelity_summary_GROK_V1.tsv')).read()); print(open(os.path.join(ev,'gbr3_engine_signals_GROK_V1.tsv')).read())
