import json,copy,sys,glob,subprocess,tempfile,os
from jsonschema import Draft202012Validator as V
C='/workspace/AlgoGebra/wt_gv/02-Cdc/'
H=json.load(open(C+'Schema_Help_Template_JSON_CLAUDE_V1.json')); S=json.load(open(C+'Schema_Course_JSON_CLAUDE_V1.json'))
V.check_schema(H); V.check_schema(S); print('both schemas are valid draft 2020-12')
ex=json.load(open(C+'Example_Help_Template_CLAUDE_V1.json')); vh=V(H); vs=V(S)
def r(name,inst,v): e=[f"{'/'.join(map(str,x.absolute_path))}: {x.message[:110]}" for x in v.iter_errors(inst)]; print(f'{name}: {"VALID" if not e else "INVALID"}',e[:3])
r('E1 example as committed',ex,vh)
e2=copy.deepcopy(ex); e2.pop('$comment'); r('E2 example without $comment',e2,vh)
e3=copy.deepcopy(e2); e3['title']['fr-FR']='x'; r('E3 BCP47 key fr-FR',e3,vh)
st={"title":{"en":"t"},"explanation":{"en":"e"}}; d=copy.deepcopy(st); cur=d
for i in range(6): n=copy.deepcopy(st); cur['children']=[n]; cur=n
e4=copy.deepcopy(e2); e4['content']['steps']=[d]; r('E4 helpStep nested 7 levels (doc says max 3)',e4,vh)
e5=copy.deepcopy(e2); e5['defaults']={'zz':1}; e5['variables']=['a']; r('E5 defaults key not in variables',e5,vh)
e6=copy.deepcopy(e2); e6['defaults']['M']=[[1,2],[3,4]]; r('E6 matrix-valued OEF variable',e6,vh)
e7=copy.deepcopy(e2); e7['content']['steps'][0]['actions'][0]={'directive':'CMD','value':'Delete(x)'} ; r('E7 helpAction arbitrary command (allowlist not in schema)',e7,vh)
base={"schemaVersion":"1.0","course":"c","tree":[{"title":"t","children":[{"title":"s"}]}]}
def step(**k): b=copy.deepcopy(base); b['tree'][0]['children'][0].update(k); return b
r('C1 step help template only',step(help={'template':'aide.json'}),vs)
r('C2 step help template+inline (description says "at least one")',step(help={'template':'aide.json','inline':{'fr':'x'}}),vs)
r('C3 step help variables only',step(help={'variables':{'a':3}}),vs)
r('C4 step engine octave (wims4win has octave)',step(engine='octave'),vs)
r('C5 step help.explanations/llm per Q-W9 §9.6',step(help={'template':'a.json','explanations':{'fr':'x'}}),vs)
r('C6 step transform per Q-W9 §9.6',step(transform={'operation':'derive'}),vs)
r('C7 check type engine_check (GAP-5)',step(check={'type':'engine_check'}),vs)
# converter output vs V1_1
conv='/workspace/AlgoGebra/wt-gv-tip/03-RCP-Spike/tools/oef2course_GROK_V1.py'; fs=[l.strip() for l in open('/tmp/clist.txt')]
ok=0
for f in fs:
    fd,j=tempfile.mkstemp(suffix='.json'); os.close(fd); subprocess.run(['python3',conv,f,'-o',j],capture_output=True)
    ok+= not list(vs.iter_errors(json.load(open(j)))); os.unlink(j)
print(f'C8 corpus300 converter outputs valid against Course schema V1_1: {ok}/{len(fs)}')
