// GROK_V1 — local MOCK of the D-S01 WIMS CGI contract for tests (NOT a WIMS server; no real WIMS is available to Grok).
// POST /wims/wims.cgi form: module, job, exercise, ans1 -> JSON {grade, feedback}. Behaviour by exercise id:
//   ok-*      : 200 JSON, grade 0.8 (ans1 must decode to a zip "PK" .ggb, else grade 0)
//   html-*    : 200 text/html (what a stock wims.cgi returns)
//   e500-*    : HTTP 500         slow-*: answers after 3 s        bad-*: grade 7 (out of range)
//   xss-*     : feedback contains <img onerror> markup
// Every request is appended as JSON to $WIMS_MOCK_LOG (if set). Exports start(port) for in-process use.
import http from 'node:http'; import fs from 'node:fs';
export function handler(req, res, next) {
  if (!req.url.startsWith('/wims/wims.cgi')) { return next ? next() : (res.writeHead(404), res.end()); }
  let body = ''; req.on('data', c => { body += c; if (body.length > 8e6) req.destroy(); });
  req.on('end', () => {
    const p = new URLSearchParams(body); const ex = p.get('exercise') || ''; const ans = p.get('ans1') || '';
    const pk = Buffer.from(ans, 'base64').subarray(0, 2).toString('latin1') === 'PK';
    const rec = { method: req.method, ct: req.headers['content-type'] || '', module: p.get('module'), job: p.get('job'), exercise: ex,
      ans1Len: ans.length, ans1Zip: pk, keys: [...p.keys()], at: new Date().toISOString() };
    if (process.env.WIMS_MOCK_LOG) fs.appendFileSync(process.env.WIMS_MOCK_LOG, JSON.stringify(rec) + '\n');
    const json = (o, s = 200) => { res.writeHead(s, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(o)); };
    if (req.method !== 'POST') return json({ error: 'POST only' }, 405);
    if (p.get('module') !== 'adm/class/sheet' || p.get('job') !== 'getresult') return json({ error: 'bad module/job' }, 400);
    if (ex.startsWith('html-')) { res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end('<html><body>WIMS page</body></html>'); }
    if (ex.startsWith('e500-')) return json({ error: 'boom' }, 500);
    if (ex.startsWith('bad-')) return json({ grade: 7, feedback: 'x' });
    if (ex.startsWith('xss-')) return json({ grade: 0.5, feedback: '<img src=x onerror="window.__xss=1">' });
    if (ex.startsWith('slow-')) return setTimeout(() => json({ grade: 0.1, feedback: 'late' }), 3000);
    return json({ grade: pk ? 0.8 : 0, feedback: pk ? 'Construction received; 4 of 5 checks passed.' : 'ans1 is not a .ggb archive' });
  });
}
export function start(port = 0) { return new Promise(r => { const s = http.createServer((q, s2) => handler(q, s2)); s.listen(port, '127.0.0.1', () => r(s)); }); }
if (process.argv[1] && process.argv[1].endsWith('mock_wims_cgi_GROK_V1.mjs')) {
  start(Number(process.env.WIMS_MOCK_PORT || 4180)).then(s => console.log('mock WIMS CGI on http://127.0.0.1:' + s.address().port + '/wims/wims.cgi'));
}
