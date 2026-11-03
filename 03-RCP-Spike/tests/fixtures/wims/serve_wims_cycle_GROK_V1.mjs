// GROK_V1 — G-16 same-origin server: WIMS activity template + web-host assets + courses + GeoGebra WAR + LOCAL MOCK of the D-S01 WIMS CGI.
// /                       -> wims/course-activity-template/course-activity_GROK_V1.html
// /<file>                 -> wims/course-activity-template/<file>, else web-host/<file>; /courses/* -> <repo>/courses
// /GeoGebra/*             -> $GGB_WAR_DIR (self-hosted WAR, not in git)      /wims/wims.cgi -> mock (fixtures/wims/mock_wims_cgi_GROK_V1.mjs)
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
import { handler as wims } from './mock_wims_cgi_GROK_V1.mjs';
const here = path.dirname(fileURLToPath(import.meta.url)); const repo = path.resolve(here, '../../../..');
const tpl = path.join(repo, 'wims/course-activity-template'); const web = path.join(repo, 'web-host');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.gif': 'image/gif', '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.txt': 'text/plain', '.woff2': 'font/woff2' };
function pick(u) {
  const rel = decodeURIComponent(u.split('?')[0]).replace(/^\/+/, '') || 'course-activity_GROK_V1.html';
  const c = [];
  if (rel.startsWith('GeoGebra/') && process.env.GGB_WAR_DIR) c.push(path.join(process.env.GGB_WAR_DIR, rel.slice(9)));
  c.push(path.join(tpl, rel), path.join(web, rel));
  if (rel.startsWith('courses/')) c.push(path.join(repo, rel));
  return c.find(f => { try { return fs.statSync(f).isFile(); } catch { return false; } });
}
export function start(port = 0) {
  return new Promise(r => {
    const s = http.createServer((req, res) => {
      if (req.url.includes('..')) { res.writeHead(400).end(); return; }
      wims(req, res, () => {
        const f = pick(req.url); if (!f) { res.writeHead(404).end('not found'); return; }
        res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
      });
    });
    s.listen(port, '127.0.0.1', () => r(s));
  });
}
