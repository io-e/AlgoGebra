// WA-9 mock of the WIMS OEF HTTP contract (not a WIMS server).
// cmd=new creates a session/form; cmd=reply grades only the replyN/choiceN fields.
// The JSON comment is emitted only when special_parm=algogebra_json is present.
import http from 'node:http';
import fs from 'node:fs';

const sessions = new Map();
let nextSession = 1;
function decodeFormPart(s) {
  const bytes = [];
  for (let i = 0; i < s.length; i++) {
    if (s[i] === '+') { bytes.push(0x20); }
    else if (s[i] === '%' && /^[0-9a-f]{2}$/i.test(s.slice(i + 1, i + 3))) {
      bytes.push(parseInt(s.slice(i + 1, i + 3), 16)); i += 2;
    } else {
      const c = s.charCodeAt(i); if (c > 0x7f) throw new Error('non-ASCII octet must be percent-encoded'); bytes.push(c);
    }
  }
  return new TextDecoder('windows-1252').decode(new Uint8Array(bytes));
}
function parseForm(s) {
  const result = new Map();
  for (const pair of s.split('&')) {
    if (!pair) continue;
    const i = pair.indexOf('='), k = decodeFormPart(i < 0 ? pair : pair.slice(0, i));
    const v = decodeFormPart(i < 0 ? '' : pair.slice(i + 1));
    if (!result.has(k)) result.set(k, []); result.get(k).push(v);
  }
  return result;
}
function first(p, name) { return p.has(name) ? p.get(name)[0] : null; }
function safeLog(record) {
  if (process.env.WIMS_MOCK_LOG) fs.appendFileSync(process.env.WIMS_MOCK_LOG, JSON.stringify(record) + '\n');
}
function html(res, body, status = 200) {
  res.writeHead(status, { 'Content-Type': 'text/html; charset=windows-1252' }); res.end(body);
}
export function handler(req, res, next) {
  if (!req.url.startsWith('/wims/wims.cgi')) return next ? next() : (res.writeHead(404), res.end());
  let raw = '';
  req.on('data', c => { raw += c; if (raw.length > 2e6) req.destroy(); });
  req.on('end', () => {
    try {
      const params = req.method === 'GET' ? parseForm(new URL(req.url, 'http://localhost').search.slice(1)) : parseForm(raw);
      const cmd = first(params, 'cmd'), module = first(params, 'module'), exo = first(params, 'exo');
      const rec = { method: req.method, cmd, module, exo, session: first(params, 'session'),
        special_parm: first(params, 'special_parm'), keys: [...params.keys()], values: Object.fromEntries(params) };
      safeLog(rec);
      if (module !== 'H6/test/oef2html.fr') return html(res, '<html>unknown OEF module</html>', 400);
      if (cmd === 'new' && req.method === 'GET') {
        const sid = 'MOCKSESSION' + String(nextSession++).padStart(4, '0') + '.1';
        const fields = exo === '00076'
          ? '<input type="checkbox" name="reply1" value="3"><input type="checkbox" name="reply1" value="5">'
          : '<input type="text" name="reply1" value="">';
        sessions.set(sid, { module, exo, fields: ['reply1'] });
        return html(res, '<html><form name="replyform"><input type="hidden" name="session" value="' + sid +
          '"><input type="hidden" name="module" value="' + module + '">' + fields + '</form></html>');
      }
      if (cmd !== 'reply' || req.method !== 'POST') return html(res, '<html>unsupported WIMS command</html>', 400);
      const sid = first(params, 'session'), session = sessions.get(sid);
      if (!session || session.module !== module) return html(res, '<html>invalid session</html>', 400);
      const submitted = [...params.keys()].filter(k => /^(reply|choice)[1-9][0-9]*$/.test(k));
      if (!submitted.length || submitted.some(k => !session.fields.includes(k))) return html(res, '<html>invalid answer field</html>', 400);
      const values = submitted.flatMap(k => params.get(k));
      const expected = session.exo === '00076' ? ['3', '5'] : ['2'];
      const correct = values.length === expected.length && values.every((v, i) => v === expected[i]);
      const answer = { id: submitted[0], correct, score: correct ? 1 : 0, feedback: '',
        expected: expected.join(','), given: values.join(',') };
      const score = correct ? 1 : 0;
      if (session.exo === '00099') return html(res, '<html><div class="answer_analysis">hook not installed</div></html>');
      if (first(params, 'special_parm') !== 'algogebra_json') return html(res, '<html><div class="answer_analysis">graded by WIMS</div></html>');
      const feedback = session.exo === '00007' ? '<img src=x onerror="window.__xss=1">' : '';
      const payload = { grade: score, seed: 1, answers: [answer], feedback };
      return html(res, '<html><div class="answer_analysis">WIMS grading</div><!-- ALGOGEBRA_JSON_BEGIN\n' +
        JSON.stringify(payload) + '\nALGOGEBRA_JSON_END --></html>');
    } catch (e) { return html(res, '<html>bad form: ' + String(e.message) + '</html>', 400); }
  });
}
export function start(port = 0) {
  return new Promise(resolve => {
    const server = http.createServer((req, res) => handler(req, res));
    server.listen(port, '127.0.0.1', () => resolve(server));
  });
}
if (process.argv[1] && process.argv[1].endsWith('mock_wims_cgi_GROK_V1.mjs')) {
  start(Number(process.env.WIMS_MOCK_PORT || 4180)).then(s =>
    console.log('mock WIMS OEF CGI on http://127.0.0.1:' + s.address().port + '/wims/wims.cgi'));
}
