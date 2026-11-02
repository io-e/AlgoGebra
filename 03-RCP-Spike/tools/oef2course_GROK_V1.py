#!/usr/bin/env python3
"""GROK_V1 - G-06 / WP7-02: convert WIMS OEF exercise files to a GeoGebraPlus course.json
(02-Cdc/Schema_Course_JSON_CLAUDE_V1.json, schemaVersion 1.0).

Mapping: course = input set; one OEF file -> one chapter; chapter steps =
  "Statement" (description = statement text; actions = GeoGebra CMDs translated from simple \\draw primitives)
  + one step per \\answer: numeric answers -> value_equals check on object ansN; others -> object_exists (flagged).
Random parameters (random(a..b), random(a,b,c), randint) are fixed with a deterministic seed (--seed), so the course is reproducible;
formative only (grading stays on the server). The converter only EMITS commands from a fixed safe list (no scripting tables).
Exit codes: 0 ok, 64 usage, 65 no convertible content / invalid OEF, 66 input missing.
"""
import argparse, ast, json, math, operator, random, re, sys
from pathlib import Path

SAFE_EMIT = {"Segment", "Line", "Point", "Circle", "Polygon", "Vector"}
LIMITS = dict(title=200, desc=2000, actions=20, chapters=50, steps=100, value=2000)

def read_text(p: Path) -> str:
    b = p.read_bytes()
    for enc in ("utf-8", "cp1252", "latin-1"):
        try: return b.decode(enc)
        except UnicodeDecodeError: pass
    return b.decode("latin-1", "replace")

def strip_comments(t: str) -> str:
    return "\n".join(l for l in t.splitlines() if not l.lstrip().startswith("%%"))

def balanced(t: str, i: int):
    """t[i] == '{' -> (content, index after closing brace)"""
    depth, j = 0, i
    while j < len(t):
        c = t[j]
        if c == "\\" and j + 1 < len(t): j += 2; continue
        if c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: return t[i + 1:j], j + 1
        j += 1
    raise ValueError(f"unbalanced braces at offset {i}")

def commands(t: str):
    """top-level \\name{a}{b}... occurrences in order"""
    out, i = [], 0
    rx = re.compile(r"\\([A-Za-z]+)\s*(?=\{)")
    while True:
        m = rx.search(t, i)
        if not m: break
        name, j, args = m.group(1), m.end(), []
        while j < len(t) and t[j] == "{":
            a, j = balanced(t, j); args.append(a)
            k = j
            while k < len(t) and t[k] in " \t": k += 1
            if k < len(t) and t[k] == "{": j = k
            else: break
        out.append((name, args)); i = j
    return out

_OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul, ast.Div: operator.truediv,
        ast.Pow: operator.pow, ast.USub: operator.neg, ast.UAdd: operator.pos, ast.Mod: operator.mod}
_FUN = {"sqrt": math.sqrt, "abs": abs, "sin": math.sin, "cos": math.cos, "tan": math.tan, "exp": math.exp,
        "ln": math.log, "log": math.log10, "floor": math.floor, "ceil": math.ceil, "round": round}

def safe_eval(expr: str):
    expr = expr.replace("^", "**").strip()
    if not expr or len(expr) > 200: raise ValueError("empty/long")
    def ev(n):
        if isinstance(n, ast.Expression): return ev(n.body)
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)): return n.value
        if isinstance(n, ast.BinOp) and type(n.op) in _OPS:
            l, r = ev(n.left), ev(n.right)
            if isinstance(n.op, ast.Pow) and abs(r) > 64: raise ValueError("pow")
            return _OPS[type(n.op)](l, r)
        if isinstance(n, ast.UnaryOp) and type(n.op) in _OPS: return _OPS[type(n.op)](ev(n.operand))
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id in _FUN and len(n.args) == 1:
            return _FUN[n.func.id](ev(n.args[0]))
        if isinstance(n, ast.Name) and n.id == "pi": return math.pi
        raise ValueError("unsupported")
    return ev(ast.parse(expr, mode="eval"))

class Converter:
    def __init__(self, seed: int):
        self.rng = random.Random(seed); self.warnings = []

    def warn(self, f, msg): self.warnings.append(f"{f}: {msg}")

    def subst(self, s: str, env: dict) -> str:
        return re.sub(r"\\([A-Za-z_]\w*)", lambda m: str(env[m.group(1)]) if m.group(1) in env else m.group(0), s)

    def eval_def(self, rhs: str, env: dict):
        rhs = self.subst(rhs, env).strip()
        m = re.fullmatch(r"(?:random|randint|rint)\s*\(\s*(-?[\d.]+)\s*\.\.\s*(-?[\d.]+)\s*\)", rhs)
        if m:
            a, b = sorted((float(m.group(1)), float(m.group(2))))
            return self.rng.randint(int(a), int(b)) if a.is_integer() and b.is_integer() else round(self.rng.uniform(a, b), 4)
        m = re.fullmatch(r"(?:random|randitem)\s*\((.*)\)", rhs, flags=re.S)
        if m and "," in m.group(1):
            items = [x.strip() for x in m.group(1).split(",")]
            v = self.rng.choice(items)
            try: return self.num(safe_eval(v))
            except Exception: return v
        try: return self.num(safe_eval(rhs))
        except Exception: return rhs

    @staticmethod
    def num(v):
        if isinstance(v, float) and v.is_integer() and abs(v) < 1e15: return int(v)
        return round(v, 10) if isinstance(v, float) else v

    def text(self, s: str, env: dict) -> str:
        s = re.sub(r"\\draw\s*\{[^}]*\}\s*\{.*?\}", " [figure] ", s, flags=re.S)
        s = self.subst(s, env)
        s = re.sub(r"\\\((.*?)\)", r"\1", s, flags=re.S)
        s = re.sub(r"<br\s*/?>|</p>|<p[^>]*>", "\n", s, flags=re.I)
        s = re.sub(r"<[^>]+>", "", s)
        s = re.sub(r"\\(?:embed|special|reply)\s*\{[^}]*\}(?:\s*\{[^}]*\})?", "[input]", s)
        s = re.sub(r"[ \t]+", " ", s); s = re.sub(r"\n\s*\n+", "\n", s)
        return s.strip()

    def draw_actions(self, body: str, env: dict, f: str):
        acts, n = [], 0
        for line in self.subst(body, env).splitlines():
            parts = [p.strip() for p in re.split(r"[ ,]+", line.strip()) if p.strip()]
            if not parts: continue
            kind, args = parts[0].lower(), parts[1:]
            nums = []
            for a in args[:4]:  # numeric prefix; trailing colour/size words are ignored
                try: nums.append(self.num(safe_eval(a)))
                except Exception: break
            cmd = None
            if kind in ("segment", "seg") and len(nums) == 4: cmd = f"Segment(({nums[0]}, {nums[1]}), ({nums[2]}, {nums[3]}))"
            elif kind == "line" and len(nums) == 4: cmd = f"Line(({nums[0]}, {nums[1]}), ({nums[2]}, {nums[3]}))"
            elif kind in ("point", "points") and len(nums) >= 2: cmd = f"Point({{{nums[0]}, {nums[1]}}})"
            elif kind == "circle" and len(nums) >= 3: cmd = f"Circle(({nums[0]}, {nums[1]}), {abs(nums[2]) / 2})"  # flydraw: diameter in pixels units ~ approximated
            elif kind == "arrow" and len(nums) == 4: cmd = f"Vector(({nums[0]}, {nums[1]}), ({nums[2]}, {nums[3]}))"
            if cmd:
                assert cmd.split("(")[0] in SAFE_EMIT
                n += 1; acts.append({"directive": "CMD", "value": f"d{n} = {cmd}"})
        if len(acts) > LIMITS["actions"]:
            self.warn(f, f"{len(acts)} draw primitives truncated to {LIMITS['actions']}"); acts = acts[:LIMITS["actions"]]
        return acts

    def chapter(self, path: Path):
        f = path.name; raw = strip_comments(read_text(path)); cmds = commands(raw)
        env, meta, statement, answers, hints, draws = {}, {}, "", [], [], []
        precision = 1000
        for name, args in cmds:
            if name in ("title", "language", "author", "email") and args: meta[name] = args[0].strip()
            elif name in ("integer", "real", "rational", "text", "function", "matrix") and args and "=" in args[0]:
                k, v = args[0].split("=", 1); env[k.strip()] = self.eval_def(v, env)
            elif name == "precision" and args:
                try: precision = max(1, int(safe_eval(args[0])))
                except Exception: pass
            elif name == "statement" and args:
                statement = args[0]
                for dm in re.finditer(r"\\draw\s*\{[^}]*\}\s*\{", statement):
                    body, _ = balanced(statement, dm.end() - 1); draws.append(body)
            elif name == "hint" and args: hints.append(args[0])
            elif name == "answer" and len(args) >= 2: answers.append(args)
        if not statement and not answers: raise ValueError("no \\statement and no \\answer")
        title = self.text(meta.get("title", path.stem), env)[:LIMITS["title"]] or path.stem
        actions = []
        for d in draws: actions += self.draw_actions(d, env, f)
        stmt = {"title": "Statement", "description": (self.text(statement, env) or title)[:LIMITS["desc"]]}
        if actions: stmt["actions"] = actions[:LIMITS["actions"]]
        steps = [stmt]
        hint = (" Hint: " + self.text(hints[0], env)) if hints else ""
        for i, a in enumerate(answers, 1):
            label = self.text(a[0], env) or f"Answer {i}"; typ = (a[2] if len(a) > 2 else "default").replace("type=", "").strip()
            val = self.subst(a[1], env).strip(); var = f"ans{i}"
            step = {"title": f"{i}. {label}"[:LIMITS["title"]]}
            try:
                if typ in ("clickfill", "dragfill", "menu", "case", "puzzle", "click", "checkbox", "radio", "coord", "draw"): raise ValueError(typ)
                exp = self.num(safe_eval(val))
                step["description"] = (f"Type {var} = <your answer> in the input bar, then press Check." + hint)[:LIMITS["desc"]]
                step["check"] = {"type": "value_equals", "variable": var, "expected": exp, "tolerance": max(1.0 / precision, 1e-9),
                                 "feedback": {"pass": "Correct.", "fail": "Not yet - check your computation."}}
            except Exception:
                self.warn(f, f"answer {i} ({typ}) not numeric - emitted as object_exists")
                step["description"] = (f"Create {var} with your answer (type '{typ}' is not auto-checked numerically)." + hint)[:LIMITS["desc"]]
                step["check"] = {"type": "object_exists", "variable": var}
            steps.append(step)
        steps = steps[:LIMITS["steps"]]
        lang = meta.get("language", "")[:2].lower()
        return {"title": title, "children": steps}, (lang if re.fullmatch(r"[a-z]{2}", lang) else None), meta.get("author")

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("inputs", nargs="*"); ap.add_argument("-o", "--output"); ap.add_argument("--title")
    ap.add_argument("--seed", type=int, default=1); ap.add_argument("--report")
    a = ap.parse_args(argv)
    if not a.inputs: print("oef2course: no input files", file=sys.stderr); return 64
    files = []
    for s in a.inputs:
        p = Path(s)
        if p.is_dir(): files += sorted(p.glob("*.oef"))
        elif p.is_file(): files.append(p)
        else: print(f"oef2course: not found: {s}", file=sys.stderr); return 66
    conv, chapters, locales, authors = Converter(a.seed), [], set(), set()
    for p in files[:LIMITS["chapters"]]:
        try:
            ch, lang, au = conv.chapter(p); chapters.append(ch)
            if lang: locales.add(lang)
            if au: authors.add(conv.text(au, {}))
        except Exception as e: conv.warn(p.name, f"skipped: {e}")
    if len(files) > LIMITS["chapters"]: conv.warn("input", f"{len(files)} files, only {LIMITS['chapters']} chapters kept")
    if not chapters:
        print("oef2course: no convertible exercise", file=sys.stderr); [print("  " + w, file=sys.stderr) for w in conv.warnings]; return 65
    course = {"schemaVersion": "1.0",
              "course": (a.title or (chapters[0]["title"] if len(chapters) == 1 else f"OEF course ({len(chapters)} exercises)"))[:LIMITS["title"]],
              "description": f"Converted from WIMS OEF by oef2course_GROK_V1 (seed {a.seed}); formative checks only."}
    if authors: course["author"] = ", ".join(sorted(authors))[:LIMITS["title"]]
    if len(locales) == 1: course["locale"] = locales.pop()
    course["tree"] = chapters
    data = json.dumps(course, ensure_ascii=False, indent=2) + "\n"
    if len(data.encode()) > 1_048_576: print("oef2course: output exceeds 1 MiB", file=sys.stderr); return 65
    (Path(a.output).write_text(data, encoding="utf-8") if a.output else sys.stdout.write(data))
    rep = {"files": len(files), "chapters": len(chapters), "warnings": conv.warnings}
    if a.report: Path(a.report).write_text(json.dumps(rep, ensure_ascii=False, indent=2), encoding="utf-8")
    for w in conv.warnings: print("warning: " + w, file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())
