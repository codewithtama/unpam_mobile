import 'dart:convert';

class MentariScripts {
  static const String tokenChannel = 'MentariTokenChannel';
  static const String fetchChannel = 'MentariFetchChannel';
  static const String statusChannel = 'MentariStatusChannel';

  static const String tokenSniffer = r'''
(function() {
  if (window.__mentariTokenSnifferAttached) return;
  window.__mentariTokenSnifferAttached = true;

  function report(token) {
    if (!token) return;
    token = token.toString().trim().replace(/^Bearer\s+/i, '').replace(/["']/g, '');
    if (token.length <= 15 || !window.MentariTokenChannel) return;
    try {
      window.MentariTokenChannel.postMessage(JSON.stringify({
        host: location.hostname,
        token: token,
        url: location.href
      }));
    } catch (e) {}
  }

  var jwtPattern = /eyJ[\w-]+\.[\w-]+\.[\w-]+/;

  function inspect(val) {
    if (!val || typeof val !== 'string') return;
    var match = val.match(jwtPattern);
    if (match) {
      report(match[0]);
      return;
    }
    // Cek jika val adalah JSON yang berisi token
    if (val.indexOf('{') !== -1 && (val.indexOf('token') !== -1 || val.indexOf('jwt') !== -1)) {
      try {
        var obj = JSON.parse(val);
        if (obj && (obj.token || obj.access_token || obj.jwt)) {
          report(obj.token || obj.access_token || obj.jwt);
        }
      } catch (e) {}
    }
  }

  function scanStorage() {
    try {
      inspect(localStorage.getItem('access_token'));
      inspect(localStorage.getItem('token'));
      inspect(localStorage.getItem('jwt'));
      inspect(localStorage.getItem('user'));
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        inspect(localStorage.getItem(k));
      }
      for (var j = 0; j < sessionStorage.length; j++) {
        var sk = sessionStorage.key(j);
        inspect(sessionStorage.getItem(sk));
      }
    } catch (e) {}
  }

  try {
    var setItem = Storage.prototype.setItem;
    Storage.prototype.setItem = function(k, v) {
      setItem.apply(this, arguments);
      if (typeof v === 'string') inspect(v);
    };
  } catch (e) {}

  try {
    var setHeader = XMLHttpRequest.prototype.setRequestHeader;
    XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
      if (header && header.toLowerCase() === 'authorization') inspect(String(value));
      return setHeader.apply(this, arguments);
    };
  } catch (e) {}

  try {
    var origFetch = window.fetch;
    window.fetch = function(input, init) {
      try {
        var h = (init && init.headers) || (input && typeof input === 'object' ? input.headers : null);
        var auth = null;
        if (h && typeof h.get === 'function') auth = h.get('Authorization');
        else if (Array.isArray(h)) h.forEach(function(p) { if (p[0] && p[0].toLowerCase() === 'authorization') auth = p[1]; });
        else if (h) auth = h['Authorization'] || h['authorization'];
        if (auth) inspect(String(auth));
      } catch (e) {}
      return origFetch.apply(this, arguments);
    };
  } catch (e) {}

  scanStorage();
  setInterval(scanStorage, 1500);
})();
''';

  static String fillLogin(String nim, String password) => '''
(function(nim, pass) {
  if (!nim) return;

  function setValue(input, val) {
    if (!input || !val) return;
    try { input.focus(); } catch (e) {}
    var desc = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(input), 'value') ||
        Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
    var prev = input.value;
    if (desc && desc.set) desc.set.call(input, val); else input.value = val;
    if (input._valueTracker) input._valueTracker.setValue(prev + '_sync');
    ['input', 'change', 'blur'].forEach(function(type) {
      input.dispatchEvent(new Event(type, { bubbles: true, composed: true }));
    });
  }

  function findUser() {
    return document.querySelector('input[name="username"], input#username, input[name="nim"], input#nim, input[autocomplete="username"], input[name="identity"], input[type="text"]');
  }

  function findPass() {
    return document.querySelector('input[type="password"], input[name="password"], input#password');
  }

  function findSubmit() {
    var buttons = Array.from(document.querySelectorAll('button, input[type="submit"], input[type="button"], [role="button"]'));
    return buttons.find(function(b) {
      var t = (b.textContent || b.value || '').trim().toLowerCase();
      return t === 'masuk' || t === 'login' || t === 'sign in' || t === 'log in';
    });
  }

  var userInput = findUser();
  var passInput = findPass();
  if (userInput && userInput.value !== nim) setValue(userInput, nim);
  if (passInput && pass && passInput.value !== pass) setValue(passInput, pass);
  if (!pass || window.__mentariAutoSubmitted) return;

  var attempts = 0;
  var timer = setInterval(function() {
    attempts++;
    var turnstile = document.querySelector('input[name="cf-turnstile-response"]');
    var hasWidget = !!(turnstile || document.querySelector('.cf-turnstile, iframe[src*="challenges.cloudflare.com"]'));
    var solved = turnstile && turnstile.value && turnstile.value.length > 10;
    if ((hasWidget && !solved) && attempts < 40) return;
    clearInterval(timer);
    if (hasWidget && !solved) return;
    if (window.__mentariAutoSubmitted) return;
    var btn = findSubmit();
    if (!btn || btn.disabled) return;
    window.__mentariAutoSubmitted = true;
    if (window.MentariStatusChannel) window.MentariStatusChannel.postMessage('auto_submitted');
    btn.click();
  }, 500);
})(${jsonEncode(nim)}, ${jsonEncode(password)});
''';

  static const String scrapeCoursesFromDom = r'''
(function() {
  try {
    var courses = [];
    var seen = {};

    // 1. Ekstrak dari link berformat /u-courses/{kode_course}
    var links = document.querySelectorAll('a[href*="/u-courses/"]');
    links.forEach(function(a) {
      var href = a.getAttribute('href') || '';
      var parts = href.split('/u-courses/');
      if (parts.length > 1) {
        var code = parts[1].split('?')[0].split('#')[0].replace(/\/$/, '');
        var title = (a.innerText || a.textContent || '').trim();
        if (code && !seen[code]) {
          seen[code] = true;
          courses.push({
            kode_course: code,
            coursename: title || code,
            idnumber: code
          });
        }
      }
    });

    // 2. Ekstrak dari Mui Card & Course Card containers
    if (courses.length === 0) {
      var cards = document.querySelectorAll('.MuiPaper-root, .dashboard-card, div[class*="MuiCard"]');
      cards.forEach(function(card) {
        var link = card.querySelector('a[href*="/u-courses/"]') || card.querySelector('a');
        if (!link) return;
        var href = link.getAttribute('href') || '';
        var match = href.match(/\/u-courses\/([^\/?#]+)/);
        if (match) {
          var code = match[1];
          if (seen[code]) return;
          seen[code] = true;
          var titleEl = card.querySelector('h5, h6, .MuiTypography-h6, .MuiTypography-subtitle1, .MuiTypography-root');
          var title = titleEl ? titleEl.innerText.trim() : code;
          courses.push({
            kode_course: code,
            coursename: title,
            idnumber: code
          });
        }
      });
    }

    return JSON.stringify(courses);
  } catch (e) {
    return JSON.stringify([]);
  }
})();
''';
}
