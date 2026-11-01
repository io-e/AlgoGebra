// CLAUDE_V1_1 — GeoGebraPlus course tree controller (web host)
// GROK_V1_1 — W-09 comment tweak; CT-SEC-01: interim denylist until allowed-commands.json (D-COURSE-01)
// Security target: Spec_Course_Security_CLAUDE_V1.md §1.4 string allowlist from Commands enum
// Threading: setErrorDialogsActive(false/true) around each step per Study V1_2 §2.4
// CAS readiness: use evalCommandCAS for the arithmetic smoke check (G-07); never the algebra CMD path

'use strict';

var courseTree = (function () {
  var STEP_TIMEOUT_MS = 10000;

  // INTERIM (CT-SEC-01): denylist only. Replace with allowlist from allowed-commands.json (Codex WP9-02).
  var BLOCKED_COMMANDS = [
    'Execute', 'RunClickScript', 'RunUpdateScript', 'ExportImage',
    'StartRecord', 'PlaySound', 'ReadText', 'StartAnimation',
    'Delete', 'Rename', 'Pan', 'ZoomIn', 'ZoomOut',
    'CenterView', 'SetPerspective', 'SetValue'
  ];

  // §2.2: OPEN path rejected patterns
  var PATH_REJECT_RE = /(?:^[a-zA-Z]:[/\\])|(?:^\/)|(?:^\\\\)|(?:\.\.)|(?:^https?:)|(?:^\/\/)/;

  var api = null;
  var model = null;
  var flatSteps = [];
  var currentIndex = -1;
  var stepResults = {};
  var busy = false;

  // ── API ──

  function setApi(ggbApi) { api = ggbApi; }

  function verifyCasReady(ggbApi, callback) {
    var attempts = 0;
    var check = setInterval(function () {
      attempts++;
      try {
        var result = ggbApi.evalCommandCAS('1+1', '');
        if (result === '2') {
          clearInterval(check);
          callback();
          return;
        }
      } catch (e) { /* CAS not ready */ }
      if (attempts > 30) {
        clearInterval(check);
        setStatus('Warning: CAS not available. Some steps may fail.', 'info');
        callback();
      }
    }, 500);
  }

  function enable() {
    document.getElementById('btn-run').disabled = false;
    document.getElementById('btn-check').disabled = false;
  }

  // ── Course loading ──

  function loadCourse(url) {
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error('Failed to load course: ' + r.status);
      return r.json();
    }).then(function (data) {
      if (data.schemaVersion !== '1.0') {
        setStatus('Unsupported schema version: ' + data.schemaVersion, 'fail');
        return;
      }
      model = data;
      flatSteps = [];
      stepResults = {};
      document.getElementById('course-title').textContent = data.course || '';
      var root = document.getElementById('tree-root');
      root.innerHTML = '';
      renderChapters(data.tree, root, 0);
      if (flatSteps.length > 0) selectStep(0);
    }).catch(function (err) {
      setStatus('Load error: ' + err.message, 'fail');
    });
  }

  // ── Tree rendering ──

  function renderChapters(chapters, parentEl, depth) {
    for (var i = 0; i < chapters.length; i++) {
      var ch = chapters[i];
      var li = document.createElement('li');
      li.setAttribute('role', 'treeitem');

      var btn = document.createElement('button');
      btn.className = 'tree-node';
      btn.textContent = ch.title;

      if (ch.children && ch.children.length > 0) {
        btn.setAttribute('aria-expanded', 'true');
        btn.addEventListener('click', toggleChapter);
        li.appendChild(btn);

        var ul = document.createElement('ul');
        ul.setAttribute('role', 'group');
        renderSteps(ch.children, ul, depth + 1);
        li.appendChild(ul);
      } else {
        li.appendChild(btn);
      }

      parentEl.appendChild(li);
    }
  }

  function renderSteps(steps, parentEl, depth) {
    if (depth > 4) return; // max 5 levels
    for (var i = 0; i < steps.length; i++) {
      var step = steps[i];
      var li = document.createElement('li');
      li.setAttribute('role', 'treeitem');

      var idx = flatSteps.length;
      flatSteps.push(step);

      var btn = document.createElement('button');
      btn.className = 'tree-node';
      btn.setAttribute('data-step-index', idx);

      var icon = document.createElement('span');
      icon.className = 'status-icon pending';
      icon.setAttribute('aria-hidden', 'true');
      icon.textContent = '○'; // ○
      btn.appendChild(icon);

      var label = document.createTextNode(' ' + step.title);
      btn.appendChild(label);

      btn.addEventListener('click', onStepClick);

      // C-10: keyboard navigation
      btn.addEventListener('keydown', onStepKeydown);

      li.appendChild(btn);

      if (step.children && step.children.length > 0) {
        btn.setAttribute('aria-expanded', 'true');
        var ul = document.createElement('ul');
        ul.setAttribute('role', 'group');
        renderSteps(step.children, ul, depth + 1);
        li.appendChild(ul);
      }

      parentEl.appendChild(li);
    }
  }

  function toggleChapter(e) {
    var btn = e.currentTarget;
    var expanded = btn.getAttribute('aria-expanded') === 'true';
    btn.setAttribute('aria-expanded', String(!expanded));
    var group = btn.nextElementSibling;
    if (group) group.style.display = expanded ? 'none' : '';
  }

  // ── Step selection ──

  function onStepClick(e) {
    var idx = parseInt(e.currentTarget.getAttribute('data-step-index'), 10);
    if (!isNaN(idx)) selectStep(idx);
  }

  function selectStep(idx) {
    if (idx < 0 || idx >= flatSteps.length) return;
    // Deselect previous
    var prev = document.querySelector('.tree-node[aria-selected="true"]');
    if (prev) prev.setAttribute('aria-selected', 'false');

    currentIndex = idx;
    var step = flatSteps[idx];
    var btn = document.querySelector('[data-step-index="' + idx + '"]');
    if (btn) {
      btn.setAttribute('aria-selected', 'true');
      btn.focus();
    }

    document.getElementById('step-description').textContent = step.description || '';
    document.getElementById('btn-run').disabled = !step.actions || step.actions.length === 0;
    document.getElementById('btn-check').disabled = !step.check;
  }

  // ── C-10: Keyboard navigation (WAI-ARIA tree pattern) ──

  function onStepKeydown(e) {
    var allBtns = Array.prototype.slice.call(
      document.querySelectorAll('#tree-root .tree-node[data-step-index]')
    );
    var curIdx = allBtns.indexOf(e.currentTarget);

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (curIdx < allBtns.length - 1) allBtns[curIdx + 1].click();
        break;
      case 'ArrowUp':
        e.preventDefault();
        if (curIdx > 0) allBtns[curIdx - 1].click();
        break;
      case 'Home':
        e.preventDefault();
        if (allBtns.length) allBtns[0].click();
        break;
      case 'End':
        e.preventDefault();
        if (allBtns.length) allBtns[allBtns.length - 1].click();
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        runCurrentStep();
        break;
    }
  }

  // ── Security checks ──

  function extractCommandName(value) {
    var m = value.match(/^([A-Za-z_]\w*)\s*\(/);
    return m ? m[1] : null;
  }

  var MAX_SEQUENCE_ITER = 10000;

  function isCommandBlocked(value) {
    var name = extractCommandName(value);
    if (!name) return false; // assignment or expression — allowed
    if (BLOCKED_COMMANDS.indexOf(name) >= 0) return true;
    // Check nested blocked commands
    for (var i = 0; i < BLOCKED_COMMANDS.length; i++) {
      if (value.indexOf(BLOCKED_COMMANDS[i] + '(') >= 0) return true;
    }
    // V1_1: Sequence size limit (Grok Bot finding)
    var seqMatch = value.match(/Sequence\s*\([^,]+,[^,]+,[^,]+,\s*(\d+)\s*\)/);
    if (seqMatch && parseInt(seqMatch[1], 10) > MAX_SEQUENCE_ITER) return true;
    return false;
  }

  function isOpenPathSafe(path) {
    if (PATH_REJECT_RE.test(path)) return false;
    if (!path.toLowerCase().endsWith('.ggb')) return false;
    return true;
  }

  // ── Directive execution ──

  function executeDirective(action) {
    var directive = action.directive;
    var value = action.value;

    switch (directive) {
      case 'CMD':
        if (isCommandBlocked(value)) {
          setStatus('Blocked command: ' + value, 'fail');
          return false;
        }
        var ok = api.evalCommand(value);
        if (!ok) setStatus('Command failed: ' + value, 'fail');
        return ok;

      case 'CAS':
        var result = api.evalCommandCAS(value, '');
        if (!result || result === '?') {
          setStatus('CAS returned no result for: ' + value, 'fail');
          return false;
        }
        setStatus('CAS: ' + value + ' = ' + result, 'info');
        return true;

      case 'VAL':
        var val = api.getValueString(value);
        setStatus(value + ' = ' + val, 'info');
        return true;

      case 'OPEN':
        if (!isOpenPathSafe(value)) {
          setStatus('Blocked path: ' + value, 'fail');
          return false;
        }
        return loadGgbFile(value, action.trustedGgb || false);

      case 'SAVE':
        setStatus('SAVE not implemented in web host', 'info');
        return true;

      case 'PNG':
        setStatus('PNG export not implemented in web host', 'info');
        return true;

      default:
        setStatus('Unknown directive: ' + directive, 'fail');
        return false;
    }
  }

  function loadGgbFile(relativePath, trusted) {
    // Fetch the .ggb as base64 and inject
    var courseDir = (model && model._courseDir) || 'courses/';
    fetch(courseDir + relativePath).then(function (r) {
      if (!r.ok) throw new Error('File not found: ' + relativePath);
      return r.arrayBuffer();
    }).then(function (buf) {
      var bytes = new Uint8Array(buf);
      var binary = '';
      for (var i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
      var b64 = btoa(binary);
      api.setBase64(b64);
      setStatus('Loaded: ' + relativePath, 'info');
    }).catch(function (err) {
      setStatus('OPEN failed: ' + err.message, 'fail');
    });
    return true;
  }

  // ── Step execution ──

  function runCurrentStep() {
    if (busy || currentIndex < 0) return;
    var step = flatSteps[currentIndex];
    if (!step.actions || step.actions.length === 0) return;

    busy = true;
    setBusy(true);
    api.setErrorDialogsActive(false);

    var idx = 0;
    var allOk = true;
    var timer = setTimeout(function () {
      setStatus('Step timed out', 'fail');
      finish(false);
    }, STEP_TIMEOUT_MS);

    function next() {
      if (idx >= step.actions.length) {
        clearTimeout(timer);
        finish(allOk);
        return;
      }
      try {
        var ok = executeDirective(step.actions[idx]);
        if (!ok) allOk = false;
      } catch (e) {
        setStatus('Error: ' + e.message, 'fail');
        allOk = false;
      }
      idx++;
      setTimeout(next, 50); // yield between actions
    }

    function finish(success) {
      api.setErrorDialogsActive(true);
      busy = false;
      setBusy(false);
      markStep(currentIndex, success ? 'done' : 'error');
      if (success) setStatus('Step completed', 'pass');
    }

    next();
  }

  // ── Check execution ──

  function checkCurrentStep() {
    if (busy || currentIndex < 0) return;
    var step = flatSteps[currentIndex];
    if (!step.check) return;

    var check = step.check;
    var pass = false;

    try {
      switch (check.type) {
        case 'object_exists':
          pass = api.exists(check.variable);
          break;

        case 'value_equals':
          var val = api.getValue(check.variable);
          var tol = check.tolerance || 0.001;
          pass = Math.abs(val - check.expected) <= tol;
          break;

        case 'value_range':
          var rangeVal = api.getValue(check.variable);
          pass = rangeVal >= check.expected.min && rangeVal <= check.expected.max;
          break;

        case 'cas_equals':
          var casResult = api.evalCommandCAS(check.variable, '');
          pass = casResult === check.expected;
          break;

        default:
          setStatus('Unknown check type: ' + check.type, 'fail');
          return;
      }
    } catch (e) {
      setStatus('Check error: ' + e.message, 'fail');
      markStep(currentIndex, 'error');
      return;
    }

    markStep(currentIndex, pass ? 'pass' : 'fail');

    var feedback = check.feedback;
    if (feedback) {
      setStatus(pass ? feedback.pass : feedback.fail, pass ? 'pass' : 'fail');
    } else {
      setStatus(pass ? 'Check passed' : 'Check failed', pass ? 'pass' : 'fail');
    }
  }

  // ── Navigation ──

  function nextStep() {
    if (currentIndex < flatSteps.length - 1) selectStep(currentIndex + 1);
  }

  function resetConstruction() {
    if (!api) return;
    api.reset();
    stepResults = {};
    var icons = document.querySelectorAll('#tree-root .status-icon');
    for (var i = 0; i < icons.length; i++) {
      icons[i].className = 'status-icon pending';
      icons[i].textContent = '○';
    }
    setStatus('Construction reset', 'info');
    if (flatSteps.length > 0) selectStep(0);
  }

  // ── UI helpers ──

  function markStep(idx, state) {
    stepResults[idx] = state;
    var btn = document.querySelector('[data-step-index="' + idx + '"]');
    if (!btn) return;
    var icon = btn.querySelector('.status-icon');
    if (!icon) return;
    icon.className = 'status-icon ' + (state === 'pass' || state === 'done' ? 'pass' : state === 'fail' || state === 'error' ? 'fail' : 'pending');
    icon.textContent = state === 'pass' || state === 'done' ? '✓' : state === 'fail' || state === 'error' ? '✗' : '○';
  }

  function setStatus(msg, cls) {
    var bar = document.getElementById('status-bar');
    bar.textContent = msg;
    bar.className = cls ? 'status-' + cls : '';
  }

  function setBusy(isBusy) {
    document.getElementById('btn-run').disabled = isBusy;
    document.getElementById('btn-check').disabled = isBusy;
  }

  // ── Button wiring ──

  document.addEventListener('DOMContentLoaded', function () {
    var btnRun = document.getElementById('btn-run');
    var btnCheck = document.getElementById('btn-check');
    var btnNext = document.getElementById('btn-next');
    var btnReset = document.getElementById('btn-reset');

    if (btnRun) btnRun.addEventListener('click', runCurrentStep);
    if (btnCheck) btnCheck.addEventListener('click', checkCurrentStep);
    if (btnNext) btnNext.addEventListener('click', nextStep);
    if (btnReset) btnReset.addEventListener('click', resetConstruction);
  });

  return {
    setApi: setApi,
    verifyCasReady: verifyCasReady,
    enable: enable,
    loadCourse: loadCourse,
    executeDirective: executeDirective,
    isCommandBlocked: isCommandBlocked,
    isOpenPathSafe: isOpenPathSafe
  };
})();
