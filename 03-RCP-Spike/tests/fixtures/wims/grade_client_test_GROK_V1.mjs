// WA-9 contract tests: the loopback mock speaks cmd=new/reply plus the WIMS JSON-comment hook.
import { createRequire } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';
import http from 'node:http';
import { fileURLToPath } from 'node:url';
import { start } from './mock_wims_cgi_GROK_V1.mjs';
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../..');
const C = createRequire(import.meta.url)(path.join(repo, 'wims/course-activity-template/wims-grade-client_GROK_V1.js'));
const log = path.join(os.tmpdir(), 'wims-mock-' + process.pid + '.jsonl');
process.env.WIMS_MOCK_LOG = log;
const server = await start(0);
const endpoint = 'http://127.0.0.1:' + server.address().port + '/wims/wims.cgi';
const module = 'H6/test/oef2html.fr';
// Use short-lived HTTP/1.1 sockets in this Windows test harness; Node's global
// undici keep-alive teardown can trip a libuv assertion when the mock closes.
globalThis.fetch = (url, init = {}) => new Promise((resolve, reject) => {
  const req = http.request(url, { method: init.method || 'GET', headers: init.headers, agent: false }, res => {
    const chunks = [];
    res.on('data', c => chunks.push(c));
    res.on('end', () => {
      const body = Buffer.concat(chunks);
      resolve({ status: res.statusCode, headers: { get: name => res.headers[String(name).toLowerCase()] || null },
        arrayBuffer: async () => body.buffer.slice(body.byteOffset, body.byteOffset + body.byteLength),
        text: async () => body.toString('utf8') });
    });
  });
  req.on('error', reject);
  if (init.body) req.write(init.body);
  req.end();
});
let n = 0, fail = 0;
const ok = (id, condition, detail = '') => { n++; if (!condition) fail++; console.log(`${condition ? 'ok' : 'not ok'} ${n} - ${id}${detail ? ' :: ' + detail : ''}`); };
const entries = () => fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse) : [];
const last = () => entries().at(-1);
try {
  const s = await C.createSession({ endpoint, module, exo: '00006', lang: 'fr' });
  let rec = last();
  ok('WA9-new-session-and-reply-field', !!s.sessionId && s.answerFields.includes('reply1'));
  ok('WA9-new-command-no-hook', rec.method === 'GET' && rec.cmd === 'new' && rec.module === module && rec.exo === '00006' && !rec.special_parm, JSON.stringify(rec));

  let result = await C.submitAnswers(s, { reply1: '2' }); rec = last();
  ok('WA9-right-grade-one', result.grade === 1 && result.answers[0].correct && result.answers[0].id === 'reply1', JSON.stringify(result));
  ok('WA9-reply-only-hook-and-session', rec.method === 'POST' && rec.cmd === 'reply' && rec.special_parm === 'algogebra_json' && rec.session === s.sessionId);
  ok('WA9-real-reply-field-not-ans1', rec.values.reply1[0] === '2' && !Object.hasOwn(rec.values, 'ans1'), JSON.stringify(rec.keys));

  const wrong = await C.submitAnswers(s, { reply1: '0' });
  ok('WA9-wrong-grade-zero', wrong.grade === 0 && !wrong.answers[0].correct && wrong.answers[0].given === '0');

  const sc = await C.createSession({ endpoint, module, exo: '00076', lang: 'fr' });
  const checkbox = await C.submitAnswers(sc, { reply1: ['3', '5'] }); rec = last();
  ok('WA9-checkbox-multiple-values', checkbox.grade === 1 && checkbox.answers[0].given === '3,5' && rec.values.reply1.join(',') === '3,5');

  const noHookSession = await C.createSession({ endpoint, module, exo: '00006', lang: 'fr' });
  const noHookBody = C.formEncode([['session', noHookSession.sessionId], ['module', module], ['cmd', 'reply'], ['reply1', '2']]);
  const noHook = await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=windows-1252' }, body: noHookBody });
  const noHookHtml = await noHook.text();
  ok('WA9-no-hook-no-leak', !noHookHtml.includes('ALGOGEBRA_JSON_BEGIN'));
  let noJson = false; try { C.parseHookResponse(200, noHookHtml); } catch (e) { noJson = /NO_JSON_BLOCK/.test(e.message); }
  ok('WA9-missing-marker-is-explicit-error', noJson);

  ok('WA9-windows1252-form-encoding', C.formEncode([['reply1', 'été']]) === 'reply1=%E9t%E9');
  ok('WA9-unrepresentable-character-rejected', (() => { try { C.formEncode([['reply1', '→']]); return false; } catch { return true; } })());
  ok('WA9-unknown-field-rejected-before-post', await (async () => {
    const before = entries().length; try { await C.submitAnswers(s, { ans1: '2' }); return false; }
    catch (e) { return /unknown WIMS answer field/.test(e.message) && entries().length === before; }
  })());
  ok('WA9-module-traversal-rejected', await (async () => {
    try { await C.createSession({ endpoint, module: '../adm/raw', exo: '00006' }); return false; }
    catch (e) { return /module/.test(e.message); }
  })());

  let malformed = false; try { C.parseHookResponse(200, '<!-- ALGOGEBRA_JSON_BEGIN {"grade":1 ALGOGEBRA_JSON_END -->'); }
  catch { malformed = true; }
  ok('WA9-malformed-json-rejected', malformed);
  let badGrade = false; try { C.parseHookResponse(200, '<!-- ALGOGEBRA_JSON_BEGIN {"grade":2,"answers":[]} ALGOGEBRA_JSON_END -->'); }
  catch { badGrade = true; }
  ok('WA9-grade-range-enforced', badGrade);
  let badAnswer = false; try { C.parseHookResponse(200, '<!-- ALGOGEBRA_JSON_BEGIN {"grade":1,"answers":[{"id":"ans1","correct":true,"score":1}]} ALGOGEBRA_JSON_END -->'); }
  catch { badAnswer = true; }
  ok('WA9-answer-id-schema-enforced', badAnswer);

  const source = fs.readFileSync(path.join(repo, 'wims/course-activity-template/wims-grade-client_GROK_V1.js'), 'utf8');
  ok('WA9-safe-text-rendering', !/\.innerHTML\s*=/.test(source) && /textContent/.test(source));
  ok('WA9-no-local-grading', !/(?<![-\w])grade\s*=\s*[^=]/.test(source.replace(/\/\/.*$/gm, '')));
} catch (e) {
  ok('WA9-test-exception', false, e.stack || String(e));
} finally {
  const closed = new Promise(resolve => server.close(resolve));
  if (server.closeAllConnections) server.closeAllConnections();
  await closed;
  fs.rmSync(log, { force: true });
}
console.log(`# grade client: ${n - fail} PASS, ${fail} FAIL`);
process.exit(fail ? 1 : 0);
