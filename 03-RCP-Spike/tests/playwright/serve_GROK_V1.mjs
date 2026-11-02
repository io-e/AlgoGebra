// GROK_V1 - static server for W-09 Playwright (cross-platform, no deps).
// Serves <repo>/web-host; /courses/* falls back to <repo>/courses; /GeoGebra/* from $GGB_WAR_DIR if set
// (the WAR stays out of git: stage it as web-host/GeoGebra link/junction OR set GGB_WAR_DIR=<geogebra>/source/web/web/war).
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url)); const repo = path.resolve(here, '../../..');
const root = path.join(repo, 'web-host'); const port = Number(process.env.W09_PORT || 4173);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.gif': 'image/gif', '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.txt': 'text/plain', '.woff2': 'font/woff2' };
function pick(u) {
  const rel = decodeURIComponent(u.split('?')[0]).replace(/^\/+/, '');
  const cands = [];
  if (rel.startsWith('GeoGebra/') && process.env.GGB_WAR_DIR) cands.push(path.join(process.env.GGB_WAR_DIR, rel.slice(9)));
  cands.push(path.join(root, rel));
  if (rel.startsWith('courses/')) cands.push(path.join(repo, rel));
  return cands.find(f => { try { return fs.statSync(f).isFile(); } catch { return false; } });
}
http.createServer((req, res) => {
  if (req.url.includes('..')) { res.writeHead(400).end(); return; }
  const f = pick(req.url === '/' ? '/course-host.html' : req.url);
  if (!f) { res.writeHead(404).end('not found'); return; }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
}).listen(port, '127.0.0.1', () => console.log(`W-09 server http://127.0.0.1:${port} root=${root} war=${process.env.GGB_WAR_DIR || '(web-host/GeoGebra)'}`));
