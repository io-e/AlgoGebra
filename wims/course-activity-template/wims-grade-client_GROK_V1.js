// GROK_V1 — G-15 (WP7-03) WIMS grade callback client, owner decision D-S01 (02-Cdc/Decision_Open_Points_Sprint3_CLAUDE_V1.md).
// Sends the construction to the WIMS CGI by HTTP POST; WIMS computes and records the grade (server-side only).
// The client never computes, rounds into, or sends a grade: it only shows WIMS's answer as formative feedback.
// Request (verbatim D-S01): POST <endpoint>, application/x-www-form-urlencoded,
//   module=adm/class/sheet&job=getresult&exercise=<id>&ans1=<construction_base64>
// Response (D-S01): JSON { "grade": <number 0..1>, "feedback": "<text>" }. Anything else is an error, never a grade.
// Works in browsers (window.WimsGradeClient) and Node >= 18 (module.exports) for tests; fetch is injectable.
(function (root, factory) {
  var api = factory();
  if (typeof module === 'object' && module.exports) { module.exports = api; } else { root.WimsGradeClient = api; }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  var DEFAULT_ENDPOINT = '/wims/wims.cgi';
  var DEFAULT_TIMEOUT_MS = 15000;
  // Proposed default (open question Q-W3, 02-Cdc/WIMS_Open_Questions_GROK_V1.md): 1 MiB of base64. Configurable per call (maxAnsBytes).
  var DEFAULT_MAX_ANS_BYTES = 1024 * 1024;
  var B64_RE = /^[A-Za-z0-9+/]*={0,2}$/;
  var EXERCISE_RE = /^[A-Za-z0-9_.\-\/]{1,128}$/;

  function buildBody(exercise, base64, maxAnsBytes) {
    var max = typeof maxAnsBytes === 'number' && maxAnsBytes > 0 ? maxAnsBytes : DEFAULT_MAX_ANS_BYTES;
    if (!EXERCISE_RE.test(String(exercise || ''))) { throw new Error('WIMS exercise id missing or invalid'); }
    var b = String(base64 || '').replace(/\s+/g, '');
    if (!b || !B64_RE.test(b) || b.length % 4 !== 0) { throw new Error('construction is not valid base64'); }
    if (b.length > max) { throw new Error('construction too large for submission (' + b.length + ' > ' + max + ' bytes)'); }
    var p = new URLSearchParams();
    p.set('module', 'adm/class/sheet'); p.set('job', 'getresult'); p.set('exercise', String(exercise)); p.set('ans1', b);
    return p.toString();
  }

  // ---- HTML ADAPTER (GROK_V1, PROPOSAL — open question Q-W1, NOT part of D-S01) ----
  // Stock wims.cgi answers HTML. Until the owner decides on a WIMS-side JSON adapter, the client can OPTIONALLY
  // (opts.htmlAdapter === true; default OFF) read the D-S01 result from a machine-readable marker in the HTML page:
  //   <script type="application/json" id="wims-result">{"grade":0.8,"feedback":"..."}</script>
  // or <div id="wims-result" data-grade="0.8" data-feedback="..."></div>.
  // No marker => error, never a guessed grade (no scraping of free text / scores in prose).
  function decodeEntities(t) {
    return String(t).replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
  }
  function extractFromHtml(text) {
    var m = /<script[^>]*\bid=["']wims-result["'][^>]*>([\s\S]*?)<\/script>/i.exec(text || '');
    if (m && /type=["']application\/json["']/i.test(m[0])) { try { return JSON.parse(m[1]); } catch (e) { return null; } }
    var d = /<[a-z]+[^>]*\bid=["']wims-result["'][^>]*>/i.exec(text || '');
    if (!d) { return null; }
    var g = /\bdata-grade=["']([^"']*)["']/i.exec(d[0]); var f = /\bdata-feedback=["']([^"']*)["']/i.exec(d[0]);
    if (!g || !/^\s*-?\d+(\.\d+)?\s*$/.test(g[1])) { return null; }
    return { grade: Number(g[1]), feedback: f ? decodeEntities(f[1]) : '' };
  }
  // ---- end HTML ADAPTER ----

  function parseResult(status, contentType, text, opts) {
    if (status === 413) { return { ok: false, error: 'WIMS rejected the construction as too large (HTTP 413)' }; }
    if (status < 200 || status >= 300) { return { ok: false, error: 'WIMS answered HTTP ' + status }; }
    var data;
    try { data = JSON.parse(text); } catch (e) {
      if (opts && opts.htmlAdapter === true) {
        data = extractFromHtml(text);
        if (!data) { return { ok: false, error: 'WIMS answered HTML without a wims-result marker (HTML adapter)' }; }
        return validate(data, 'html-adapter');
      }
      var kind = /html/i.test(contentType || '') || /^\s*</.test(text || '') ? 'HTML' : 'non-JSON';
      return { ok: false, error: 'WIMS answered ' + kind + ', not the D-S01 JSON result' };
    }
    return validate(data, 'json');
  }

  function validate(data, via) {
    if (!data || typeof data !== 'object' || Array.isArray(data)) { return { ok: false, error: 'WIMS result is not a JSON object' }; }
    var g = data.grade;
    if (typeof g !== 'number' || !isFinite(g) || g < 0 || g > 1) { return { ok: false, error: 'WIMS grade missing or outside 0..1' }; }
    var f = data.feedback == null ? '' : data.feedback;
    if (typeof f !== 'string') { return { ok: false, error: 'WIMS feedback is not text' }; }
    return { ok: true, grade: g, feedback: f, via: via };
  }

  function submit(opts) {
    var fetchFn = opts.fetch || (typeof fetch !== 'undefined' ? fetch : null);
    if (!fetchFn) { return Promise.resolve({ ok: false, error: 'fetch unavailable' }); }
    var body;
    try { body = buildBody(opts.exercise, opts.base64, opts.maxAnsBytes); } catch (e) { return Promise.resolve({ ok: false, error: e.message }); }
    var ctl = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = ctl ? setTimeout(function () { ctl.abort(); }, opts.timeoutMs || DEFAULT_TIMEOUT_MS) : null;
    return fetchFn(opts.endpoint || DEFAULT_ENDPOINT, {
      method: 'POST', credentials: 'same-origin', redirect: 'error',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'Accept': opts.htmlAdapter === true ? 'application/json, text/html;q=0.5' : 'application/json' },
      body: body, signal: ctl ? ctl.signal : undefined
    }).then(function (r) {
      return r.text().then(function (t) { return parseResult(r.status, r.headers.get('content-type'), t, opts); });
    }, function (e) {
      return { ok: false, error: e && e.name === 'AbortError' ? 'WIMS did not answer in time' : 'network error: ' + (e && e.message) };
    }).then(function (res) { if (timer) { clearTimeout(timer); } return res; });
  }

  function render(output, res) {
    if (!output) { return; }
    output.textContent = ''; // never innerHTML: feedback comes from the server
    var line = output.ownerDocument.createElement('div');
    if (res.ok) {
      output.className = 'wims-ok';
      line.textContent = 'Grade recorded by WIMS: ' + Math.round(res.grade * 100) + '%';
      var fb = output.ownerDocument.createElement('div');
      fb.className = 'wims-feedback';
      fb.textContent = 'WIMS feedback (formative): ' + res.feedback;
      output.appendChild(line); output.appendChild(fb);
    } else {
      output.className = 'wims-error';
      line.textContent = 'WIMS submission failed: ' + res.error;
      output.appendChild(line);
    }
  }

  function attach(o) {
    if (!o || !o.button) { return; }
    o.button.disabled = !o.exercise;
    if (!o.exercise) { render(o.output, { ok: false, error: 'no WIMS exercise configured' }); return; }
    o.button.addEventListener('click', function () {
      o.button.disabled = true;
      var b64 = '';
      try { b64 = o.api.getBase64(); } catch (e) { b64 = ''; }
      submit({ endpoint: o.endpoint, exercise: o.exercise, base64: b64, fetch: o.fetch, timeoutMs: o.timeoutMs,
        maxAnsBytes: o.maxAnsBytes, htmlAdapter: o.htmlAdapter === true })
        .then(function (res) { render(o.output, res); o.button.disabled = false; });
    });
  }

  return { buildBody: buildBody, parseResult: parseResult, submit: submit, render: render, attach: attach,
    DEFAULT_ENDPOINT: DEFAULT_ENDPOINT,
    DEFAULT_MAX_ANS_BYTES: DEFAULT_MAX_ANS_BYTES, DEFAULT_TIMEOUT_MS: DEFAULT_TIMEOUT_MS, extractFromHtml: extractFromHtml };
});
