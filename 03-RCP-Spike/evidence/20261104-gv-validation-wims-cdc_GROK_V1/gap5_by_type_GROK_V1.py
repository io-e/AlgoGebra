import json,re,subprocess,sys,tempfile,os,collections,csv
conv,lst=sys.argv[1],sys.argv[2]; A=collections.Counter(); F=collections.Counter(); only=collections.Counter(); rows=[]
for f in [l.strip() for l in open(lst)]:
    fd,j=tempfile.mkstemp(suffix='.json'); os.close(fd); subprocess.run(['python3',conv,f,'-o',j],capture_output=True)
    d=json.load(open(j)); os.unlink(j); ts=collections.Counter()
    for ch in d['tree']:
        for s in ch['children']:
            if s.get('check',{}).get('type')=='object_exists':
                m=re.search(r"type '([^']*)'",s.get('description','')); ts[m.group(1) if m else '?']+=1
    for t,n in ts.items(): A[t]+=n; F[t]+=1
    if len(ts)==1: only[next(iter(ts))]+=1
    rows.append((f,';'.join(f'{k}:{v}' for k,v in sorted(ts.items()))))
print('type,answers_object_exists,files_affected,files_where_only_blocker')
for t,n in A.most_common(): print(f'{t},{n},{F[t]},{only[t]}')
print('TOTAL answers',sum(A.values()),'files',sum(1 for r in rows if r[1]))
csv.writer(open('gap5_per_file_GROK_V1.csv','w')).writerows([('file','object_exists_types')]+rows)
