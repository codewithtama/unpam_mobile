import 'dart:convert';

class MyUnpamScripts {
  static const String tokenChannel = 'PortalTokenChannel';
  static const String statusChannel = 'SsoStatusChannel';

  static const String tokenSniffer = r'''
(function() {
  if (window.__portalTokenSniffer) {
    window.__portalTokenSniffer();
    return;
  }

  function report(token) {
    if (!token) return;
    token = token.toString().trim().replace(/^Bearer\s+/i, '').replace(/["']/g, '');
    if (token.length <= 20 || !window.PortalTokenChannel) return;
    window.PortalTokenChannel.postMessage(JSON.stringify({ host: location.hostname, token: token }));
  }

  var jwtPattern = /eyJ[\w-]+\.[\w-]+\.[\w-]+/;

  function inspect(val) {
    if (!val || typeof val !== 'string') return;
    var match = val.match(jwtPattern);
    if (match) report(match[0]);
  }

  function scan() {
    try {
      inspect(localStorage.getItem('access_token'));
      for (var i = 0; i < localStorage.length; i++) inspect(localStorage.getItem(localStorage.key(i)));
      for (var j = 0; j < sessionStorage.length; j++) inspect(sessionStorage.getItem(sessionStorage.key(j)));
    } catch (e) {}
  }

  window.__portalTokenSniffer = scan;

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

  scan();
  setInterval(scan, 1500);
})();
''';

  static const String pageState = r'''
(function() {
  var url = location.href.toLowerCase();
  var hasPassword = !!document.querySelector('input[type="password"]');
  var isOtp = url.indexOf('otp') !== -1 || !!document.querySelector('input[name*="otp" i]');
  return JSON.stringify({
    host: location.hostname,
    isLogin: hasPassword || isOtp || url.indexOf('/login') !== -1,
    ready: document.readyState === 'complete'
  });
})();
''';

  static const String satuUnpamNavigator = r'''
(function() {
  if (window.__satuNavigatorAttached) return;
  window.__satuNavigatorAttached = true;

  function status(s) {
    if (window.SsoStatusChannel) window.SsoStatusChannel.postMessage(s);
  }

  function stripBlankTargets() {
    document.querySelectorAll('a[target="_blank"]').forEach(function(a) { a.removeAttribute('target'); });
  }

  function confirmRedirect() {
    var body = ((document.body && (document.body.innerText || document.body.textContent)) || '').toLowerCase();
    if (body.indexOf('konfirmasi redirect') === -1 && body.indexOf('lanjutkan ke my unpam') === -1 && body.indexOf('apakah anda ingin melanjutkan') === -1) return false;
    var btn = Array.from(document.querySelectorAll('a, button, input[type="button"], input[type="submit"], [role="button"]')).find(function(b) {
      var t = (b.innerText || b.value || b.textContent || '').trim().toLowerCase();
      return t.indexOf('lanjutkan') !== -1 || (b.href || '').toLowerCase().indexOf('my.unpam.ac.id') !== -1;
    });
    if (!btn) return false;
    status('clicked_proceed');
    btn.click();
    return true;
  }

  function openMyUnpam() {
    var url = location.href.toLowerCase();
    if (url.indexOf('login') !== -1 || url.indexOf('otp') !== -1) return false;
    stripBlankTargets();
    var nodes = document.querySelectorAll('a, button, [role="button"], div.card, div.app, div[onclick], tr, td, p, span');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var href = (el.getAttribute('href') || '').toLowerCase();
      var onclick = (el.getAttribute('onclick') || '').toLowerCase();
      var text = (el.innerText || el.textContent || '').trim().toLowerCase();
      if (href.indexOf('my.unpam.ac.id') !== -1 || onclick.indexOf('my.unpam.ac.id') !== -1 ||
          text === 'my unpam' || text === 'myunpam' || text === 'my unpam s1' || text === 'portal my unpam') {
        status('clicked_myunpam');
        el.click();
        return true;
      }
    }
    return false;
  }

  stripBlankTargets();
  if (confirmRedirect()) return;
  setInterval(confirmRedirect, 1000);
  setTimeout(openMyUnpam, 1500);
  setInterval(openMyUnpam, 3000);
})();
''';

  static String fillLogin(String nim, String password) => '''
(function(nim, pass) {
  if (!nim || !document.querySelector('input[type="password"]')) return;

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

  function findUser(passInput) {
    var direct = document.querySelector('input[name="username"], input#username, input[name="nim"], input#nim, input[autocomplete="username"], input[name="identity"]');
    if (direct) return direct;
    var scope = passInput.closest('form') || document;
    return Array.from(scope.querySelectorAll('input[type="text"], input[type="email"], input[type="number"], input:not([type])'))
      .find(function(el) { return !/search|csrf|token|captcha/i.test((el.name || '') + (el.id || '')); });
  }

  function findSubmit(passInput) {
    var scope = passInput.closest('form') || document;
    var btn = scope.querySelector('button[type="submit"], input[type="submit"]');
    if (btn) return btn;
    return Array.from(document.querySelectorAll('button, input[type="button"], [role="button"]')).find(function(b) {
      var t = (b.textContent || b.value || '').trim().toLowerCase();
      return t === 'masuk' || t === 'login' || t === 'log in' || t === 'sign in';
    });
  }

  var passInput = document.querySelector('input[type="password"]');
  var userInput = findUser(passInput);
  if (userInput && userInput.value !== nim) setValue(userInput, nim);
  if (pass && passInput.value !== pass) setValue(passInput, pass);
  if (!pass || window.__satuAutoSubmitted) return;

  var attempts = 0;
  var timer = setInterval(function() {
    attempts++;
    var turnstile = document.querySelector('input[name="cf-turnstile-response"]');
    var hasWidget = !!(turnstile || document.querySelector('.cf-turnstile, iframe[src*="challenges.cloudflare.com"]'));
    var solved = turnstile && turnstile.value && turnstile.value.length > 10;
    if ((hasWidget && !solved) && attempts < 40) return;
    clearInterval(timer);
    if (hasWidget && !solved) return;
    if (window.__satuAutoSubmitted) return;
    var btn = findSubmit(passInput);
    if (!btn || btn.disabled) return;
    window.__satuAutoSubmitted = true;
    if (window.SsoStatusChannel) window.SsoStatusChannel.postMessage('auto_submitted');
    btn.click();
  }, 500);
})(${jsonEncode(nim)}, ${jsonEncode(password)});
''';
}
