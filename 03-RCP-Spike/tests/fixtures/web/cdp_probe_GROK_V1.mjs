// usage: node --experimental-websocket cdp_shot.mjs <port> <url> <png> <waitMs>
import { writeFileSync } from 'fs';
const [port, url, png, wait] = process.argv.slice(2);
const t = await (await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`, { method: 'PUT' })).json();
const ws = new WebSocket(t.webSocketDebuggerUrl); let id = 0; const pend = {};
const send = (method, params = {}) => new Promise(r => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method, params })); });
ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id && pend[d.id]) pend[d.id](d.result); };
await new Promise(r => ws.onopen = r);
const deadline = Date.now() + Number(wait); let txt = '';
while (Date.now() < deadline) {
  const r = await send('Runtime.evaluate', { expression: "document.getElementById('probe-result') ? document.getElementById('probe-result').textContent : ''", returnByValue: true });
  txt = r?.result?.value || ''; if (txt.startsWith('RESULT')) break; await new Promise(r => setTimeout(r, 1000));
}
await new Promise(r => setTimeout(r, 1500));
const s = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(png, Buffer.from(s.data, 'base64'));
console.log(txt || 'NO_RESULT'); process.exit(0);
