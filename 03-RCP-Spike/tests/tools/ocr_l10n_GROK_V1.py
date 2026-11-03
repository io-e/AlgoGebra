# GROK_V1 - OCR raw-key / expected-label check for GeoGebra panes (rapidocr). Usage: python ocr_l10n_GROK_V1.py <lang en|fr> <out.json> <png>...
import sys, json, re
from rapidocr_onnxruntime import RapidOCR
lang, out, pngs = sys.argv[1], sys.argv[2], sys.argv[3:]
RAW = ['AlgebraWindow','DrawingPad','InputLabel','GraphicsView3D']
EXPECT = {'en': {'Algebra':r'\bAlgebra\b','Graphics':r'(?<!3D )\bGraphics\b','Input':r'\bInput\b','3D Graphics':r'3D\s*Graphics'},
          'fr': {'Algèbre':r'Alg[èe]bre','Graphique':r'\bGraphique\b','Saisie':r'\bSaisie\b','Graphique 3D':r'Graphique\s*3D'}}[lang]
OPT = {'en': {'Opt:Rounding':r'Rounding','Opt:Labeling':r'Label(l)?ing','Opt:Font Size':r'Font\s*Size','Opt:Language':r'Language'},
       'fr': {'Opt:Arrondi':r'Arrondi','Opt:Étiquetage':r'[ÉE]tiquetage','Opt:Taille des caractères':r'Taille\s*des\s*caract','Opt:Langue':r'Langue'}}[lang]
eng = RapidOCR(); texts = {}
for p in pngs:
    r, _ = eng(p); texts[p] = [t[1] for t in (r or [])]
alltext = '\n'.join(t for v in texts.values() for t in v)
raw = [k for k in RAW if k.lower() in alltext.replace(' ','').lower()]
camel = sorted({m for m in re.findall(r'\b[A-Z][a-z]+[A-Z][A-Za-z0-9]+\b', alltext)})
found = {k: bool(re.search(v, alltext)) for k, v in EXPECT.items()}
for p in pngs:
    if 'menu-Options' in p:
        t = '\n'.join(texts[p]); tag = p.rsplit('menu-', 1)[1].split('.')[0]
        for k, v in OPT.items(): found[tag + '/' + k] = bool(re.search(v, t))
res = {'lang': lang, 'rawKeysFound': raw, 'camelCaseTokens': camel, 'expected': found, 'pass': not raw and all(found.values()), 'texts': texts}
json.dump(res, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(json.dumps({k: res[k] for k in ['lang','rawKeysFound','camelCaseTokens','expected','pass']}, ensure_ascii=False))
