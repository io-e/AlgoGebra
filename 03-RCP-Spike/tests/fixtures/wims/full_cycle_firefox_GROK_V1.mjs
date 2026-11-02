// GROK_V1 — G-16 (WP7-04) full exercise cycle in Firefox (Playwright library), Debian/Xvfb or headless:
// template page -> GeoGebra web applet + course tree -> run steps -> Check -> Submit to WIMS (local D-S01 mock) -> grade/feedback shown.
// Env: PLAYWRIGHT_NODE_MODULES (dir containing playwright), GGB_WAR_DIR (WAR), OUT_DIR (screenshots + request log).
import { createRequire } from 'node:module'; import path from 'node:path'; import fs from 'node:fs';
import { start } from './serve_wims_cycle_GROK_V1.mjs';
const out = process.env.OUT_DIR || '.'; fs.mkdirSync(out, { recursive: true });
const log = path.join(out, 'wims_mock_requests.jsonl'); fs.rmSync(log, { force: true }); process.env.WIMS_MOCK_LOG = log;
const { firefox } = createRequire(path.join(process.env.PLAYWRIGHT_NODE_MODULES, 'x.js'))('playwright');
const srv = await start(0); const base = 'http://127.0.0.1:' + srv.address().port;
let n = 0, fail = 0; const ok = (id, c, d = '') => { n++; if (!c) fail++; console.log(`${c ? 'ok' : 'not ok'} ${n} - ${id}${d ? ' :: ' + d : ''}`); };
const browser = await firefox.launch({ headless: process.env.HEADED ? false : true });
const external = [];
async function openPage(ex) {
  const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
  page.on('request', r => { const u = new URL(r.url()); if (!['127.0.0.1', 'localhost'].includes(u.hostname) && !u.protocol.startsWith('data') && !u.protocol.startsWith('blob')) external.push(r.url()); });
  await page.goto(`${base}/?wims_exercise=${ex}`);
  await page.waitForFunction(() => window.ggbApplet && typeof window.ggbApplet.getBase64 === 'function', null, { timeout: 90000 });
  await page.locator('#tree-root [role="treeitem"]').first().waitFor({ timeout: 30000 });
  return page;
}
try {
  const page = await openPage('ok-trig-1');
  const items = await page.locator('#tree-root [role="treeitem"]').count();
  ok('FC-01-tree-rendered', items >= 5, `${items} tree items`);
  ok('FC-02-submit-enabled', await page.locator('#btn-wims-submit').isEnabled());
  const steps = page.locator('#tree-root [role="treeitem"]');
  await steps.first().click(); await page.locator('#btn-run').click(); await page.waitForTimeout(800);
  await steps.nth(1).click(); await page.locator('#btn-run').click(); await page.waitForTimeout(1000);
  const objs = await page.evaluate(() => [window.ggbApplet.exists('O'), window.ggbApplet.getObjectNumber()]);
  ok('FC-03-steps-ran', objs[0] === true && objs[1] >= 2, `O exists=${objs[0]} objects=${objs[1]}`);
  await page.locator('#btn-check').click({ trial: false }).catch(() => {}); await page.waitForTimeout(500);
  const status = (await page.locator('#status-bar').textContent()) || '';
  ok('FC-04-check-formative', /Check (passed|failed)/i.test(status), `status-bar: ${status.trim().slice(0, 80)}`);
  await page.screenshot({ path: path.join(out, 'G16_before_submit.png') });
  await page.locator('#btn-wims-submit').click();
  await page.locator('#wims-result.wims-ok').waitFor({ timeout: 20000 });
  const res = (await page.locator('#wims-result').innerText()).replace(/\s+/g, ' ');
  ok('FC-05-grade-from-wims-shown', /Grade recorded by WIMS: 80%/.test(res) && /formative/.test(res), res);
  await page.screenshot({ path: path.join(out, 'G16_after_submit.png') });
  const reqs = fs.readFileSync(log, 'utf8').trim().split('\n').map(JSON.parse); const r = reqs[reqs.length - 1];
  ok('FC-06-request-D-S01', r.method === 'POST' && r.module === 'adm/class/sheet' && r.job === 'getresult' && r.exercise === 'ok-trig-1' && /x-www-form-urlencoded/.test(r.ct), JSON.stringify({ m: r.module, j: r.job, e: r.exercise, ct: r.ct }));
  ok('FC-07-ans1-is-live-ggb', r.ans1Zip === true && r.ans1Len > 1000, `ans1 ${r.ans1Len} base64 chars, zip=${r.ans1Zip}`);
  ok('FC-08-no-grade-sent-by-client', !r.keys.some(k => /grade|score/i.test(k)), r.keys.join(','));
  await page.close();
  const p2 = await openPage('html-trig-1');
  await p2.locator('#btn-wims-submit').click(); await p2.locator('#wims-result.wims-error').waitFor({ timeout: 20000 });
  const e2 = await p2.locator('#wims-result').innerText();
  ok('FC-09-stock-wims-html-is-error', /HTML, not the D-S01 JSON/.test(e2), e2.trim());
  await p2.screenshot({ path: path.join(out, 'G16_html_response_error.png') }); await p2.close();
  const p3 = await openPage('xss-trig-1');
  await p3.locator('#btn-wims-submit').click(); await p3.locator('#wims-result.wims-ok').waitFor({ timeout: 20000 }); await p3.waitForTimeout(500);
  const x = await p3.evaluate(() => [window.__xss === 1, document.querySelectorAll('#wims-result img').length]);
  ok('FC-10-feedback-not-executed', x[0] === false && x[1] === 0, `xss=${x[0]} img=${x[1]}`); await p3.close();
  const p4 = await browser.newPage(); await p4.goto(`${base}/`); await p4.waitForTimeout(3000);
  ok('FC-11-no-exercise-submit-disabled', !(await p4.locator('#btn-wims-submit').isEnabled()), (await p4.locator('#wims-result').innerText()).trim()); await p4.close();
  ok('FC-12-no-external-requests', external.length === 0, external.slice(0, 3).join(' '));
} catch (e) { ok('FC-EXC', false, String(e).slice(0, 300)); }
await browser.close(); srv.close();
console.log(`# full cycle: ${n - fail} PASS, ${fail} FAIL`); process.exit(fail ? 1 : 0);
