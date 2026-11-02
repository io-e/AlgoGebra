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
  var MAX_ANS_BYTES = 5 * 1024 * 1024; // client-side guard; the WIMS-side limit is not decided in D-S01
  var B64_RE = /^[A-Za-z0-9+/]*={0,2}$/;
  var EXERCISE_RE = /^[A-Za-z0-9_.\-\/]{1,128}$/;

  function buildBody(exercise, base64) {
    if (!EXERCISE_RE.test(String(exercise || ''))) { throw new Error('WIMS exercise id missing or invalid'); }
    var b = String(base64 || '').replace(/\s+/g, '');
    if (!b || !B64_RE.test(b) || b.length % 4 !== 0) { throw new Error('construction is not valid base64'); }
    if (b.length > MAX_ANS_BYTES) { throw new Error('construction too large for submission (' + b.length + ' bytes)'); }
    var p = new URLSearchParams();
    p.set('module', 'adm/class/sheet'); p.set('job', 'getresult'); p.set('exercise', String(exercise)); p.set('ans1', b);
    return p.toString();
  }

  function parseResult(status, contentType, text) {
    if (status < 200 || status >= 300) { return { ok: false, error: 'WIMS answered HTTP ' + status }; }
    var data;
    try { data = JSON.parse(text); } catch (e) {
      var kind = /html/i.test(contentType || '') || /^\s*</.test(text || '') ? 'HTML' : 'non-JSON';
      return { ok: false, error: 'WIMS answered ' + kind + ', not the D-S01 JSON result' };
    }
    if (!data || typeof data !== 'object' || Array.isArray(data)) { return { ok: false, error: 'WIMS result is not a JSON object' }; }
    var g = data.grade;
    if (typeof g !== 'number' || !isFinite(g) || g < 0 || g > 1) { return { ok: false, error: 'WIMS grade missing or outside 0..1' }; }
    var f = data.feedback == null ? '' : data.feedback;
    if (typeof f !== 'string') { return { ok: false, error: 'WIMS feedback is not text' }; }
    return { ok: true, grade: g, feedback: f };
  }

  function submit(opts) {
    var fetchFn = opts.fetch || (typeof fetch !== 'undefined' ? fetch : null);
    if (!fetchFn) { return Promise.resolve({ ok: false, error: 'fetch unavailable' }); }
    var body;
    try { body = buildBody(opts.exercise, opts.base64); } catch (e) { return Promise.resolve({ ok: false, error: e.message }); }
    var ctl = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = ctl ? setTimeout(function () { ctl.abort(); }, opts.timeoutMs || DEFAULT_TIMEOUT_MS) : null;
    return fetchFn(opts.endpoint || DEFAULT_ENDPOINT, {
      method: 'POST', credentials: 'same-origin', redirect: 'error',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'Accept': 'application/json' },
      body: body, signal: ctl ? ctl.signal : undefined
    }).then(function (r) {
      return r.text().then(function (t) { return parseResult(r.status, r.headers.get('content-type'), t); });
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
      submit({ endpoint: o.endpoint, exercise: o.exercise, base64: b64, fetch: o.fetch, timeoutMs: o.timeoutMs })
        .then(function (res) { render(o.output, res); o.button.disabled = false; });
    });
  }

  return { buildBody: buildBody, parseResult: parseResult, submit: submit, render: render, attach: attach,
    DEFAULT_ENDPOINT: DEFAULT_ENDPOINT };
});
