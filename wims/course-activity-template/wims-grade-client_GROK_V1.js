// WA-9 / G-15 — WIMS OEF client. WIMS owns evaluation; this client never grades.
// Flow: cmd=new -> discover session + replyN/choiceN form fields -> cmd=reply
// with special_parm=algogebra_json -> extract the JSON comment emitted by the hook.
(function (root, factory) {
  var api = factory();
  if (typeof module === 'object' && module.exports) { module.exports = api; }
  else { root.WimsGradeClient = api; }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  var DEFAULT_ENDPOINT = '/wims/wims.cgi';
  var DEFAULT_TIMEOUT_MS = 15000;
  var MODULE_RE = /^[A-Za-z0-9_.\-/]{1,160}$/;
  var EXO_RE = /^[A-Za-z0-9_.-]{1,64}$/;
  var FIELD_RE = /^(?:reply|choice)[1-9][0-9]*$/;

  function cp1252Byte(ch) {
    var n = ch.codePointAt(0);
    if (n <= 0x7f || (n >= 0xa0 && n <= 0xff)) { return n; }
    var special = { 0x20ac:0x80,0x201a:0x82,0x0192:0x83,0x201e:0x84,0x2026:0x85,0x2020:0x86,
      0x2021:0x87,0x02c6:0x88,0x2030:0x89,0x0160:0x8a,0x2039:0x8b,0x0152:0x8c,0x017d:0x8e,
      0x2018:0x91,0x2019:0x92,0x201c:0x93,0x201d:0x94,0x2022:0x95,0x2013:0x96,0x2014:0x97,
      0x02dc:0x98,0x2122:0x99,0x0161:0x9a,0x203a:0x9b,0x0153:0x9c,0x017e:0x9e,0x0178:0x9f };
    if (Object.prototype.hasOwnProperty.call(special, n)) { return special[n]; }
    throw new Error('answer contains a character not representable in Windows-1252');
  }
  function formEncode(pairs) {
    function enc(s) {
      var out = '';
      for (var ch of String(s)) {
        if (ch === ' ') { out += '+'; continue; }
        var b = cp1252Byte(ch);
        out += (b >= 0x41 && b <= 0x5a) || (b >= 0x61 && b <= 0x7a) ||
          (b >= 0x30 && b <= 0x39) || [0x2a,0x2d,0x2e,0x5f].includes(b)
          ? String.fromCharCode(b) : '%' + b.toString(16).toUpperCase().padStart(2, '0');
      }
      return out;
    }
    return pairs.map(function (p) { return enc(p[0]) + '=' + enc(p[1]); }).join('&');
  }
  function decodeResponse(response) {
    return response.arrayBuffer().then(function (buf) {
      var ct = response.headers && response.headers.get ? (response.headers.get('content-type') || '') : '';
      var m = /charset\s*=\s*["']?([^;"'\s]+)/i.exec(ct);
      var charset = m ? m[1].toLowerCase() : 'utf-8';
      if (charset === 'iso-8859-1') { charset = 'windows-1252'; }
      try { return new TextDecoder(charset, { fatal: false }).decode(buf); }
      catch (_) { return new TextDecoder('utf-8', { fatal: false }).decode(buf); }
    });
  }
  function attr(tag, name) {
    var re = new RegExp('(?:^|\\s)' + name + '\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))', 'i');
    var m = re.exec(tag); return m ? (m[1] || m[2] || m[3] || '') : null;
  }
  function parseNewPage(html) {
    var session = null, fields = [];
    var inputs = String(html).match(/<(?:input|select|textarea)\b[^>]*>/gi) || [];
    inputs.forEach(function (tag) {
      var name = attr(tag, 'name'), value = attr(tag, 'value');
      if (name === 'session' && value) { session = value; }
      if (name && FIELD_RE.test(name) && fields.indexOf(name) < 0) { fields.push(name); }
    });
    if (!session) { throw new Error('WIMS cmd=new response has no session field'); }
    if (!fields.length) { throw new Error('WIMS cmd=new response has no replyN/choiceN fields'); }
    return { sessionId: session, answerFields: fields };
  }
  function validatePayload(data) {
    if (!data || typeof data !== 'object' || Array.isArray(data)) { throw new Error('hook JSON is not an object'); }
    if (typeof data.grade !== 'number' || !Number.isFinite(data.grade) || data.grade < 0 || data.grade > 1) {
      throw new Error('hook grade missing or outside 0..1');
    }
    if (!Array.isArray(data.answers)) { throw new Error('hook answers is not an array'); }
    data.answers.forEach(function (a) {
      if (!a || typeof a !== 'object' || !FIELD_RE.test(a.id || '') || typeof a.correct !== 'boolean' ||
          typeof a.score !== 'number' || !Number.isFinite(a.score) || a.score < 0 || a.score > 1) {
        throw new Error('hook answer has invalid id/correct/score');
      }
      ['feedback', 'expected', 'given'].forEach(function (k) {
        if (a[k] != null && typeof a[k] !== 'string') { throw new Error('hook answer ' + k + ' is not text'); }
      });
    });
    if (data.feedback != null && typeof data.feedback !== 'string') { throw new Error('hook feedback is not text'); }
    return { ok: true, grade: data.grade, seed: data.seed, answers: data.answers,
      feedback: data.feedback || '', via: 'wims-hook' };
  }
  function parseHookResponse(status, text) {
    if (status < 200 || status >= 300) { throw new Error('WIMS answered HTTP ' + status); }
    var m = /ALGOGEBRA_JSON_BEGIN\s*([\s\S]*?)\s*ALGOGEBRA_JSON_END/.exec(String(text || ''));
    if (!m) { throw new Error('NO_JSON_BLOCK: WIMS reply has no AlgoGebra JSON hook block'); }
    var data;
    try { data = JSON.parse(m[1].trim()); }
    catch (_) { throw new Error('WIMS AlgoGebra JSON block is malformed'); }
    return validatePayload(data);
  }
  function request(endpoint, params, method, opts) {
    var fetchFn = opts.fetch || (typeof fetch !== 'undefined' ? fetch : null);
    if (!fetchFn) { return Promise.reject(new Error('fetch unavailable')); }
    var url = new URL(endpoint || DEFAULT_ENDPOINT, (typeof location !== 'undefined' ? location.href : 'http://localhost/'));
    var init = { method: method, credentials: 'same-origin', redirect: 'error',
      headers: { 'Accept': 'text/html' }, signal: opts.signal };
    if (method === 'GET') {
      Object.keys(params).forEach(function (k) { url.searchParams.set(k, params[k]); });
    } else {
      init.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=windows-1252';
      init.body = formEncode(params);
    }
    return fetchFn(url.toString(), init).then(function (r) {
      return decodeResponse(r).then(function (text) {
        if (r.status < 200 || r.status >= 300) { throw new Error('WIMS answered HTTP ' + r.status); }
        return text;
      });
    });
  }
  function withTimeout(opts, fn) {
    var ctl = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = ctl ? setTimeout(function () { ctl.abort(); }, opts.timeoutMs || DEFAULT_TIMEOUT_MS) : null;
    return fn(ctl && ctl.signal).then(function (v) { if (timer) clearTimeout(timer); return v; }, function (e) {
      if (timer) clearTimeout(timer);
      if (e && e.name === 'AbortError') { throw new Error('WIMS did not answer in time'); }
      throw e;
    });
  }
  function createSession(opts) {
    opts = opts || {};
    var module = String(opts.module || ''), exo = String(opts.exo || ''), endpoint = opts.endpoint || DEFAULT_ENDPOINT;
    if (!MODULE_RE.test(module) || module.includes('..')) { return Promise.reject(new Error('WIMS module missing or invalid')); }
    if (!EXO_RE.test(exo)) { return Promise.reject(new Error('WIMS exercise number missing or invalid')); }
    return withTimeout(opts, function (signal) {
      return request(endpoint, { module: module, cmd: 'new', exo: exo, lang: opts.lang || 'en' }, 'GET',
        Object.assign({}, opts, { signal })).then(function (html) {
          var parsed = parseNewPage(html);
          return Object.assign(parsed, { endpoint: endpoint, module: module, exo: exo });
        });
    });
  }
  function submitAnswers(session, answers, opts) {
    opts = opts || {}; answers = answers || {};
    if (!session || !session.sessionId || !session.module || !Array.isArray(session.answerFields)) {
      return Promise.reject(new Error('WIMS session is invalid'));
    }
    var names = Object.keys(answers);
    if (!names.length) { return Promise.reject(new Error('no WIMS answers supplied')); }
    var pairs = [['session', session.sessionId], ['module', session.module], ['cmd', 'reply'],
      ['special_parm', 'algogebra_json']];
    for (var i = 0; i < names.length; i++) {
      var name = names[i], values = Array.isArray(answers[name]) ? answers[name] : [answers[name]];
      if (!FIELD_RE.test(name) || !session.answerFields.includes(name)) {
        return Promise.reject(new Error('unknown WIMS answer field: ' + name));
      }
      if (!values.length) { return Promise.reject(new Error('empty value list for ' + name)); }
      values.forEach(function (v) { pairs.push([name, String(v)]); });
    }
    return withTimeout(opts, function (signal) {
      return request(session.endpoint || opts.endpoint || DEFAULT_ENDPOINT, pairs, 'POST',
        Object.assign({}, opts, { signal })).then(function (html) {
          return parseHookResponse(200, html);
        });
    });
  }
  function render(output, result) {
    if (!output) { return; }
    output.replaceChildren();
    if (!result.ok) {
      output.className = 'wims-error';
      var err = output.ownerDocument.createElement('div'); err.textContent = 'WIMS submission failed: ' + result.error;
      output.appendChild(err); return;
    }
    output.className = 'wims-ok';
    var overall = output.ownerDocument.createElement('div');
    overall.textContent = 'WIMS grade: ' + Math.round(result.grade * 100) + '%'; output.appendChild(overall);
    result.answers.forEach(function (a) {
      var row = output.ownerDocument.createElement('div');
      row.textContent = a.id + ': ' + (a.correct ? 'correct' : 'incorrect') + ' (' + a.score + ')' +
        (a.feedback ? ' — ' + a.feedback : ''); output.appendChild(row);
    });
    if (result.feedback) { var fb = output.ownerDocument.createElement('div'); fb.textContent = result.feedback; output.appendChild(fb); }
  }
  function attach(o) {
    if (!o || !o.button) { return; }
    var provider = o.answerProvider;
    o.button.disabled = !o.module || !o.exo || typeof provider !== 'function';
    if (o.button.disabled) {
      render(o.output, { ok: false, error: !o.module || !o.exo
        ? 'WIMS module/exercise is not configured' : 'WIMS reply-field mapping is not configured' });
      return;
    }
    o.button.addEventListener('click', function () {
      o.button.disabled = true;
      withTimeout(o, function () { return createSession(o); })
        .then(function (session) { return Promise.resolve(provider(o.api, session)).then(function (answers) {
          return submitAnswers(session, answers, o);
        }); })
        .then(function (result) { render(o.output, result); }, function (e) {
          render(o.output, { ok: false, error: e.message || String(e) });
        }).then(function () { o.button.disabled = false; });
    });
  }
  return { createSession: createSession, submitAnswers: submitAnswers, parseNewPage: parseNewPage,
    parseHookResponse: parseHookResponse, formEncode: formEncode, render: render, attach: attach,
    DEFAULT_ENDPOINT: DEFAULT_ENDPOINT, DEFAULT_TIMEOUT_MS: DEFAULT_TIMEOUT_MS };
});
