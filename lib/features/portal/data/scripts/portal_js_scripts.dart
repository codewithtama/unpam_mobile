import 'dart:convert';

/// Kumpulan skrip JavaScript yang diinjeksikan ke dalam WebView Mentari & MyUnpam.
/// Disimpan sebagai konstanta kompilasi statis untuk menghemat alokasi memori Dart VM
/// dan menghindari overhead interpolasi string berulang pada thread UI.
class PortalJsScripts {
  PortalJsScripts._();

  /// Skrip optimasi scrolling 120 FPS dan penghapusan tap highlight di Android.
  static const String fpsOptimization = r'''
    (function() {
      try {
        var style = document.getElementById('__unpam_smooth_120fps');
        if (!style) {
          style = document.createElement('style');
          style.id = '__unpam_smooth_120fps';
          style.textContent = `
            html, body {
              -webkit-overflow-scrolling: touch !important;
              scroll-behavior: smooth !important;
              overscroll-behavior-y: contain !important;
            }
            * {
              -webkit-tap-highlight-color: transparent !important;
            }
          `;
          document.head.appendChild(style);
        }
      } catch(e) {}

      var lastAtTop = null;
      function syncScroll() {
        try {
          if (window.ScrollSyncChannel) {
            var atTop = (window.scrollY || document.documentElement.scrollTop || 0) <= 2;
            if (atTop !== lastAtTop) {
              lastAtTop = atTop;
              window.ScrollSyncChannel.postMessage(atTop ? 'true' : 'false');
            }
          }
        } catch(e) {}
      }
      window.removeEventListener('scroll', syncScroll);
      window.addEventListener('scroll', syncScroll, { passive: true });
      syncScroll();
    })();
  ''';

  /// Skrip pencegatan unduhan dokumen PDF, kartu ujian, KRS, dan KHS akademik.
  static const String downloadInterceptor = r'''
    (function() {
      if (window.__campusDownloadInterceptorInstalled) return;
      window.__campusDownloadInterceptorInstalled = true;

      function toAbsoluteUrl(u) {
        try {
          return new URL(u, window.location.href).href;
        } catch(e) {
          return u;
        }
      }

      function isDocumentUrl(u) {
        if (!u || typeof u !== 'string') return false;
        var low = u.toLowerCase().trim();
        if (low.startsWith('blob:')) return true;
        if (low.startsWith('data:application/pdf') ||
            low.startsWith('data:application/octet-stream') ||
            low.startsWith('data:binary/octet-stream')) return true;
        if (low.indexOf('.pdf') !== -1 ||
            low.indexOf('.docx') !== -1 ||
            low.indexOf('.xlsx') !== -1 ||
            low.indexOf('.pptx') !== -1 ||
            low.indexOf('.zip') !== -1 ||
            low.indexOf('.rar') !== -1) return true;
        if (low.indexOf('pluginfile.php') !== -1 ||
            low.indexOf('/mod/resource/view.php') !== -1 ||
            low.indexOf('forcedownload=1') !== -1 ||
            low.indexOf('export=pdf') !== -1 ||
            low.indexOf('format=pdf') !== -1 ||
            low.indexOf('type=pdf') !== -1 ||
            low.indexOf('download=pdf') !== -1 ||
            low.indexOf('output=pdf') !== -1 ||
            low.indexOf('view=pdf') !== -1 ||
            low.indexOf('as=pdf') !== -1 ||
            low.indexOf('cetak=pdf') !== -1 ||
            low.indexOf('cetak=1') !== -1 ||
            low.indexOf('print=1') !== -1 ||
            low.indexOf('export=1') !== -1 ||
            low.indexOf('download=1') !== -1) return true;
        if (low.indexOf('cetak_uts') !== -1 ||
            low.indexOf('cetak_uas') !== -1 ||
            low.indexOf('kartu_uts') !== -1 ||
            low.indexOf('kartu_uas') !== -1 ||
            low.indexOf('kartu_ujian') !== -1 ||
            low.indexOf('kartuujian') !== -1 ||
            low.indexOf('jadwal_ujian/cetak') !== -1 ||
            low.indexOf('cetak_krs') !== -1 ||
            low.indexOf('cetak_khs') !== -1 ||
            low.indexOf('cetak_transkrip') !== -1 ||
            low.indexOf('cetak_kartu') !== -1 ||
            low.indexOf('cetak_tagihan') !== -1 ||
            low.indexOf('cetak_kwitansi') !== -1 ||
            low.indexOf('cetak_spm') !== -1 ||
            low.indexOf('krs_cetak') !== -1 ||
            low.indexOf('khs_cetak') !== -1 ||
            low.indexOf('uts_cetak') !== -1 ||
            low.indexOf('uas_cetak') !== -1 ||
            low.indexOf('/krs/cetak') !== -1 ||
            low.indexOf('/khs/cetak') !== -1 ||
            low.indexOf('/uts/cetak') !== -1 ||
            low.indexOf('/uas/cetak') !== -1 ||
            low.indexOf('/ujian/cetak') !== -1 ||
            low.indexOf('/transkrip/cetak') !== -1 ||
            low.indexOf('/kartu/cetak') !== -1 ||
            low.indexOf('/cetak/') !== -1 ||
            low.indexOf('/print/') !== -1 ||
            low.indexOf('/download/') !== -1) return true;
        return false;
      }

      var originalWindowOpen = window.open;
      window.open = function(url, target, features) {
        if (url) {
          var absUrl = toAbsoluteUrl(url);
          if (isDocumentUrl(absUrl) || isDocumentUrl(url)) {
            if (window.CampusDownloadChannel) {
              window.CampusDownloadChannel.postMessage(absUrl);
              return null;
            }
          }
        }
        return originalWindowOpen ? originalWindowOpen.call(window, url, target, features) : null;
      };

      document.addEventListener('click', function(ev) {
        var el = ev.target;
        while (el && el.tagName !== 'A' && el.tagName !== 'BUTTON' && el.tagName !== 'INPUT' && el !== document.body) {
          el = el.parentElement;
        }
        if (!el || el === document.body) return;

        // 1. Tag <a>
        if (el.tagName === 'A') {
          var href = el.getAttribute('href') || el.href || '';
          var absHref = toAbsoluteUrl(href);
          var downloadAttr = el.getAttribute('download');
          var onclickAttr = el.getAttribute('onclick') || '';
          var text = (el.innerText || el.textContent || '').toLowerCase().trim();

          var isDoc = downloadAttr !== null ||
                      isDocumentUrl(absHref) ||
                      isDocumentUrl(href) ||
                      isDocumentUrl(onclickAttr) ||
                      ((text.indexOf('cetak') !== -1 || text.indexOf('download') !== -1 || text.indexOf('unduh') !== -1 || text.indexOf('print') !== -1) &&
                       (text.indexOf('uts') !== -1 || text.indexOf('uas') !== -1 || text.indexOf('krs') !== -1 || text.indexOf('khs') !== -1 || text.indexOf('kartu') !== -1 || text.indexOf('pdf') !== -1 || text.indexOf('ujian') !== -1));

          if (isDoc && window.CampusDownloadChannel && absHref && !absHref.startsWith('javascript:')) {
            ev.preventDefault();
            ev.stopPropagation();
            window.CampusDownloadChannel.postMessage(absHref);
            return;
          }
        }

        // 2. Tag <button> atau <input type="submit" / "button">
        if (el.tagName === 'BUTTON' || (el.tagName === 'INPUT' && (el.type === 'submit' || el.type === 'button'))) {
          var form = el.form || el.closest('form');
          if (form) {
            return;
          }

          var btnUrl = el.getAttribute('data-url') || el.getAttribute('data-href') || '';
          var absBtnUrl = btnUrl ? toAbsoluteUrl(btnUrl) : '';
          var text = (el.innerText || el.value || '').toLowerCase().trim();

          var isDocBtn = (absBtnUrl && isDocumentUrl(absBtnUrl)) ||
                         ((text.indexOf('cetak') !== -1 || text.indexOf('download') !== -1 || text.indexOf('unduh') !== -1 || text.indexOf('print') !== -1) &&
                          (text.indexOf('uts') !== -1 || text.indexOf('uas') !== -1 || text.indexOf('krs') !== -1 || text.indexOf('khs') !== -1 || text.indexOf('kartu') !== -1 || text.indexOf('pdf') !== -1 || text.indexOf('ujian') !== -1));

          if (isDocBtn && window.CampusDownloadChannel && absBtnUrl) {
            ev.preventDefault();
            ev.stopPropagation();
            window.CampusDownloadChannel.postMessage(absBtnUrl);
            return;
          }
        }
      }, true);
    })();
  ''';

  /// Skrip pendeteksi keberadaan elemen form login pada halaman aktif.
  static const String detectLoginForm = r'''
    (function() {
      var uUrl = window.location.href.toLowerCase();
      var isLoginUrl = uUrl.indexOf('login') !== -1 ||
                       uUrl.indexOf('sso') !== -1 ||
                       uUrl.indexOf('auth') !== -1 ||
                       uUrl === 'https://my.unpam.ac.id/' ||
                       uUrl === 'https://my.unpam.ac.id';

      // 1. Cek token login Mentari (JWT di localStorage)
      var hasMentariToken = false;
      try {
        var acc = window.localStorage.getItem('access');
        hasMentariToken = !!(acc && acc !== 'null' && acc !== 'undefined' && acc !== '""');
      } catch(e) {}

      // 2. Cek indikator akun aktif di Moodle / MyUnpam
      var hasProfileIndicator = hasMentariToken || 
        !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');

      // 3. Cek form login nyata (wajib ada elemen input password dan username)
      var p = document.querySelector('input[name="password"], input[type="password"], input#password, input[name="pass"], input#pass, input[name*="password" i], input[placeholder*="pass" i], input[placeholder*="sandi" i]');
      var u = document.querySelector('input[name="username"], input#username, input[autocomplete="username"], input[name="user"], input[name="identity"], input#identity, input[name="nim"], input#nim, input[name="user_id"], input#user_id, input[name="email"], input#email, input[name="login"], input[placeholder*="nim" i], input[placeholder*="username" i], input[placeholder*="identitas" i]');
      if (!u && p) {
        var form = p.closest('form');
        if (form) {
          u = form.querySelector('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
        }
      }
      if (!u && p) {
        var allInputs = Array.from(document.querySelectorAll('input'));
        var pIdx = allInputs.indexOf(p);
        if (pIdx > 0) {
          for (var k = pIdx - 1; k >= 0; k--) {
            var typ = (allInputs[k].type || 'text').toLowerCase();
            if (typ === 'text' || typ === 'email' || typ === 'number' || typ === '') {
              u = allInputs[k];
              break;
            }
          }
        }
      }

      var hasLoginForm = !!(u && p);

      return JSON.stringify({
        hasLoginForm: hasLoginForm,
        isLoginUrl: isLoginUrl,
        hasProfileIndicator: hasProfileIndicator
      });
    })();
  ''';

  /// Skrip perekam kredensial login pengguna untuk disimpan ke Biometric Vault.
  static const String loginCapture = r'''
    (function() {
      if (window._unpamBioCaptureAttached) return;
      window._unpamBioCaptureAttached = true;

      var lastTypedNim = '';
      var lastTypedPass = '';
      var successNotified = false;

      function findInputs() {
        var p = document.querySelector('input[type="password"], input[name="password"], input#password, input[name="pass"], input#pass, input[name*="password" i], input[placeholder*="pass" i], input[placeholder*="sandi" i]');
        var u = document.querySelector('input[name="username"], input#username, input[autocomplete="username"], input[name="user"], input[name="identity"], input#identity, input[name="nim"], input#nim, input[name="user_id"], input#user_id, input[name="email"], input#email, input[name="login"], input[placeholder*="nim" i], input[placeholder*="username" i], input[placeholder*="identitas" i]');

        if (!u && p) {
          var container = p.closest('form') || p.closest('[role="form"]') || p.parentElement;
          if (container) {
            u = container.querySelector('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
          }
        }
        if (!u && p) {
          var all = Array.from(document.querySelectorAll('input'));
          var pIndex = all.indexOf(p);
          if (pIndex > 0) {
            for (var i = pIndex - 1; i >= 0; i--) {
              var t = (all[i].type || 'text').toLowerCase();
              if (t === 'text' || t === 'email' || t === 'number' || t === '') {
                u = all[i];
                break;
              }
            }
          }
        }
        return { u: u, p: p };
      }

      function readAndCache() {
        var inputs = findInputs();
        if (inputs.u && inputs.u.value) lastTypedNim = inputs.u.value.trim();
        if (inputs.p && inputs.p.value) lastTypedPass = inputs.p.value.trim();

        if (lastTypedNim && lastTypedPass && window.BiometricCaptureChannel) {
          window.BiometricCaptureChannel.postMessage(JSON.stringify({
            event: 'CREDENTIALS_TYPED',
            nim: lastTypedNim,
            password: lastTypedPass
          }));
        }
      }

      function hasAuthToken() {
        try {
          var acc = window.localStorage.getItem('access');
          if (acc && acc !== 'null' && acc !== 'undefined' && acc !== '""' && acc.length > 20) {
            return true;
          }
        } catch(e) {}
        return false;
      }

      function hasProfileDom() {
        return !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');
      }

      function notifySuccess() {
        if (successNotified) return;
        readAndCache();
        if (lastTypedNim && lastTypedPass && window.BiometricCaptureChannel) {
          successNotified = true;
          window.BiometricCaptureChannel.postMessage(JSON.stringify({
            event: 'LOGIN_SUCCESS',
            nim: lastTypedNim,
            password: lastTypedPass
          }));
        }
      }

      document.addEventListener('input', readAndCache, true);
      document.addEventListener('change', readAndCache, true);
      document.addEventListener('blur', readAndCache, true);

      function onSubmitOrClick() {
        readAndCache();
        var polls = 0;
        var timer = setInterval(function() {
          polls++;
          if (hasAuthToken() || hasProfileDom()) {
            clearInterval(timer);
            notifySuccess();
          } else if (polls >= 20) {
            clearInterval(timer);
          }
        }, 500);
      }

      document.addEventListener('submit', onSubmitOrClick, true);
      document.addEventListener('click', function(e) {
        var t = e.target;
        if (t && (t.matches('button, button *, input[type="submit"], [role="button"]') || t.closest('button, [role="button"]'))) {
          onSubmitOrClick();
        }
      }, true);

      try {
        var origSet = window.localStorage.setItem;
        window.localStorage.setItem = function(k, v) {
          origSet.apply(this, arguments);
          if ((k === 'access' || k === 'token') && v && v !== 'null' && v.length > 20) {
            setTimeout(notifySuccess, 300);
          }
        };
      } catch(e) {}

      readAndCache();
    })();
  ''';

  /// Membangun skrip pengisian form login otomatis biometrik secara aman.
  static String buildBiometricLoginScript({
    required String nim,
    required String password,
    required bool isMyUnpam,
  }) {
    return '''
      (function(nimVal, passVal, isMyUnpamFlag) {
        function fillInputElement(input, val) {
          if (!input) return false;
          try { input.focus(); } catch(e) {}
          var prevVal = input.value;

          var proto = Object.getPrototypeOf(input);
          var desc = Object.getOwnPropertyDescriptor(proto, 'value');
          if (!desc || !desc.set) {
            desc = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
          }
          if (desc && desc.set) {
            desc.set.call(input, val);
          } else {
            input.value = val;
          }

          try { input.setAttribute('value', val); } catch(e) {}

          if (input._valueTracker) {
            input._valueTracker.setValue(prevVal + '_force_react_sync_');
          }

          var eventOptions = { bubbles: true, composed: true, cancelable: true };
          input.dispatchEvent(new Event('input', eventOptions));
          input.dispatchEvent(new Event('change', eventOptions));

          var reactPropsKey = Object.keys(input).find(function(k) { return k.startsWith('__reactProps\$'); });
          if (reactPropsKey && input[reactPropsKey]) {
            var props = input[reactPropsKey];
            if (typeof props.onChange === 'function') {
              try {
                props.onChange({
                  target: input,
                  currentTarget: input,
                  bubbles: true,
                  preventDefault: function() {},
                  stopPropagation: function() {}
                });
              } catch(e) {}
            }
          }
          return true;
        }

        function findUsernameInputs() {
          var list = [];
          var selectors = [
            'input[name="username"]',
            'input#username',
            'input[name="identity"]',
            'input#identity',
            'input[name="nim"]',
            'input#nim',
            'input[name="user_id"]',
            'input#user_id',
            'input[name="userid"]',
            'input#userid',
            'input[name="npm"]',
            'input#npm',
            'input[name="mhs_nim"]',
            'input#mhs_nim',
            'input[name="user"]',
            'input[name="email"]',
            'input#email',
            'input[autocomplete="username"]',
            'input[name="login"]',
            'input[placeholder*="nim" i]',
            'input[placeholder*="username" i]',
            'input[placeholder*="identitas" i]',
            'input[placeholder*="email" i]'
          ];
          selectors.forEach(function(sel) {
            document.querySelectorAll(sel).forEach(function(el) {
              if (!list.includes(el)) list.push(el);
            });
          });

          var passInputs = document.querySelectorAll('input[type="password"], input[name="password"], input#password, input[name="pass"], input#pass, input[name*="password" i]');
          passInputs.forEach(function(passEl) {
            var parentForm = passEl.closest('form');
            if (parentForm) {
              var candidates = parentForm.querySelectorAll('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
              candidates.forEach(function(el) {
                var name = (el.name || '').toLowerCase();
                var id = (el.id || '').toLowerCase();
                var ph = (el.placeholder || '').toLowerCase();
                if (name.includes('search') || id.includes('search') || ph.includes('cari')) return;
                if (name.includes('csrf') || name.includes('token') || name.includes('captcha')) return;
                if (!list.includes(el)) list.push(el);
              });
            }
          });

          return list;
        }

        function findPasswordInputs() {
          var list = [];
          var selectors = [
            'input[name="password"]',
            'input[type="password"]',
            'input#password',
            'input[name="pass"]',
            'input#pass',
            'input[name*="password" i]',
            'input[name*="pass" i]',
            'input[autocomplete="current-password"]',
            'input[autocomplete="password"]',
            'input[placeholder*="pass" i]',
            'input[placeholder*="kata sandi" i]',
            'input[placeholder*="sandi" i]'
          ];
          selectors.forEach(function(sel) {
            document.querySelectorAll(sel).forEach(function(el) {
              if (!list.includes(el)) list.push(el);
            });
          });
          return list;
        }

        var bodyText = (document.body ? (document.body.innerText || document.body.textContent || '') : '').toLowerCase();
        var isRedirectScreen = bodyText.indexOf('konfirmasi redirect') !== -1 ||
                               bodyText.indexOf('lanjutkan ke my unpam') !== -1 ||
                               bodyText.indexOf('apakah anda ingin melanjutkan ke aplikasi berikut') !== -1;
        if (isRedirectScreen) {
          var buttons = Array.from(document.querySelectorAll('a, button, input[type="button"], input[type="submit"], [role="button"], div[role="button"]'));
          var proceedBtn = buttons.find(function(b) {
            var t = (b.innerText || b.value || b.textContent || '').trim().toLowerCase();
            var h = (b.href || '').toLowerCase();
            return t.indexOf('lanjutkan ke my unpam') !== -1 ||
                   (t.indexOf('lanjutkan') !== -1 && t.indexOf('unpam') !== -1) ||
                   t.indexOf('lanjutkan') !== -1 ||
                   h.indexOf('my.unpam.ac.id') !== -1;
          });
          if (proceedBtn) {
            try {
              proceedBtn.focus();
              proceedBtn.click();
              proceedBtn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
              return JSON.stringify({ status: 'clicked_proceed_button' });
            } catch(e) {}
          }
          window.location.href = 'https://my.unpam.ac.id/';
          return JSON.stringify({ status: 'redirecting_to_login' });
        }

        var uList = findUsernameInputs();
        var pList = findPasswordInputs();

        if (uList.length === 0 || pList.length === 0) {
          var currentUrl = window.location.href.toLowerCase();
          var isAtKnownPortalLogin = currentUrl.indexOf('login') !== -1 ||
                                     currentUrl.indexOf('sso') !== -1 ||
                                     currentUrl.indexOf('auth') !== -1 ||
                                     currentUrl.indexOf('my.unpam.ac.id') !== -1;
          if (!isAtKnownPortalLogin) {
            var targetLogin = isMyUnpamFlag ? 'https://my.unpam.ac.id/' : 'https://mentari.unpam.ac.id/login';
            window.location.href = targetLogin;
            return JSON.stringify({ status: 'redirecting_to_login' });
          }
          return JSON.stringify({ status: 'inputs_not_found', uCount: uList.length, pCount: pList.length });
        }

        uList.forEach(function(u) { fillInputElement(u, nimVal); });
        pList.forEach(function(p) { fillInputElement(p, passVal); });

        setTimeout(function() {
          uList.forEach(function(u) {
            try { u.dispatchEvent(new Event('blur', { bubbles: true, composed: true })); } catch(e) {}
          });
          pList.forEach(function(p) {
            try { p.dispatchEvent(new Event('blur', { bubbles: true, composed: true })); } catch(e) {}
          });

          setTimeout(function() {
            var turnstileInput = document.querySelector('input[name="cf-turnstile-response"]');
            var hasTurnstileWidget = !!(turnstileInput || document.querySelector('iframe[src*="cloudflare"], iframe[src*="turnstile"], .cf-turnstile'));
            var turnstileSolved = turnstileInput ? (turnstileInput.value && turnstileInput.value.length > 10) : false;

            if (hasTurnstileWidget && !turnstileSolved) {
              return;
            }

            var submitBtn = null;
            for (var i = 0; i < pList.length; i++) {
              var form = pList[i].closest('form');
              if (form) {
                submitBtn = form.querySelector('button[type="submit"], input[type="submit"], button#loginbtn, input#loginbtn, .btn-primary, .btn-login, button.btn-block');
                if (submitBtn) break;
              }
            }
            if (!submitBtn) {
              submitBtn = document.querySelector('button[type="submit"], input[type="submit"], button#loginbtn, input#loginbtn, .btn-primary, .btn-login, button.btn-block');
            }
            if (!submitBtn) {
              var allBtns = Array.from(document.querySelectorAll('button, input[type="button"], a.btn, [role="button"]'));
              submitBtn = allBtns.find(function(b) {
                var txt = (b.textContent || b.value || '').trim().toLowerCase();
                return txt === 'masuk' || txt === 'login' || txt === 'log in' || txt === 'sign in';
              });
            }

            if (submitBtn) {
              submitBtn.focus();
              submitBtn.click();
              submitBtn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
              var btnPropsKey = Object.keys(submitBtn).find(function(k) { return k.startsWith('__reactProps\$'); });
              if (btnPropsKey && submitBtn[btnPropsKey] && typeof submitBtn[btnPropsKey].onClick === 'function') {
                try {
                  submitBtn[btnPropsKey].onClick({
                    preventDefault: function() {},
                    stopPropagation: function() {},
                    target: submitBtn,
                    currentTarget: submitBtn
                  });
                } catch(e) {}
              }
            } else {
              var form = document.querySelector('form#login, form[action*="login"]') || (pList[0] ? pList[0].closest('form') : null);
              if (form) {
                form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
                try { form.submit(); } catch(e) {}
              }
            }
          }, 200);
        }, 250);

        return JSON.stringify({
          status: 'filled_and_submitting',
          uCount: uList.length,
          pCount: pList.length
        });
      })(${jsonEncode(nim)}, ${jsonEncode(password)}, $isMyUnpam);
    ''';
  }

  /// Membangun skrip injeksi balasan forum diskusi ke Atto / TinyMCE / Textarea.
  static String buildForumReplyScript(String replyText) {
    return '''
      (function(replyText) {
        var injected = false;

        // 1. Coba Atto Editor (Moodle)
        var attoEl = document.querySelector('.editor_atto_content, [contenteditable="true"]');
        if (attoEl) {
          attoEl.focus();
          attoEl.innerHTML = '<p>' + replyText.replace(/\\n\\n/g, '</p><p>').replace(/\\n/g, '<br>') + '</p>';
          attoEl.dispatchEvent(new Event('input', { bubbles: true }));
          attoEl.dispatchEvent(new Event('change', { bubbles: true }));
          attoEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
          injected = true;
        }

        // 2. Coba TinyMCE
        if (!injected && window.tinymce && window.tinymce.activeEditor) {
          try {
            window.tinymce.activeEditor.setContent('<p>' + replyText.replace(/\\n\\n/g, '</p><p>').replace(/\\n/g, '<br>') + '</p>');
            injected = true;
          } catch(e) {}
        }

        // 3. Coba textarea standar
        if (!injected) {
          var textareas = document.querySelectorAll('textarea');
          for (var i = 0; i < textareas.length; i++) {
            var ta = textareas[i];
            if (ta.offsetParent !== null) {
              ta.focus();
              ta.value = replyText;
              ta.dispatchEvent(new Event('input', { bubbles: true }));
              ta.dispatchEvent(new Event('change', { bubbles: true }));
              ta.scrollIntoView({ behavior: 'smooth', block: 'center' });
              injected = true;
              break;
            }
          }
          if (!injected && textareas.length > 0) {
            textareas[0].focus();
            textareas[0].value = replyText;
            textareas[0].dispatchEvent(new Event('input', { bubbles: true }));
            textareas[0].dispatchEvent(new Event('change', { bubbles: true }));
            textareas[0].scrollIntoView({ behavior: 'smooth', block: 'center' });
            injected = true;
          }
        }

        return injected;
      })(${jsonEncode(replyText)})
    ''';
  }

  /// Skrip pemindaian dan ekstraksi butir soal kuis pilihan ganda dari DOM Moodle LMS.
  static const String extractQuizQuestions = r'''
    (function() {
      var results = [];
      var blocks = document.querySelectorAll('.que, .question, .soal, fieldset, .form-group, .quiz-item');

      if (blocks.length > 0) {
        for (var i = 0; i < blocks.length; i++) {
          var block = blocks[i];
          var radios = block.querySelectorAll('input[type="radio"]');
          if (radios.length === 0) continue;

          var qTextEl = block.querySelector('.qtext, .question-text, .formulation .content, legend, h3, h4');
          var qText = qTextEl ? qTextEl.innerText.trim() : block.innerText.split('\n')[0].trim();
          if (!qText || qText.length < 5) continue;

          var opts = [];
          for (var j = 0; j < radios.length; j++) {
            var r = radios[j];
            var label = block.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : 'Opsi ' + String.fromCharCode(65 + j);

            r.setAttribute('data-unpam-q', results.length.toString());
            r.setAttribute('data-unpam-opt', j.toString());

            opts.push({
              optionIndex: j,
              optionId: r.id || '',
              radioName: r.name || '',
              optionText: optText
            });
          }

          if (opts.length > 1) {
            results.push({
              index: results.length,
              originalIndex: i,
              questionText: qText,
              options: opts
            });
          }
        }
      }

      if (results.length === 0) {
        var allRadios = document.querySelectorAll('input[type="radio"]');
        var groupMap = {};
        allRadios.forEach(function(r) {
          var name = r.getAttribute('name') || 'default_quiz_group';
          if (!groupMap[name]) groupMap[name] = [];
          groupMap[name].push(r);
        });

        var gIdx = 0;
        for (var gName in groupMap) {
          var list = groupMap[gName];
          if (list.length < 2) continue;
          var parent = list[0].closest('form, div, fieldset') || list[0].parentElement;
          var qText = parent ? parent.innerText.substring(0, 300).trim() : 'Soal #' + (gIdx + 1);

          var opts = [];
          list.forEach(function(r, oIdx) {
            var label = document.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : 'Opsi ' + String.fromCharCode(65 + oIdx);
            r.setAttribute('data-unpam-q', gIdx.toString());
            r.setAttribute('data-unpam-opt', oIdx.toString());

            opts.push({
              optionIndex: oIdx,
              optionId: r.id || '',
              radioName: gName,
              optionText: optText
            });
          });

          results.push({
            index: gIdx,
            originalIndex: gIdx,
            questionText: qText,
            options: opts
          });
          gIdx++;
        }
      }

      return JSON.stringify(results);
    })()
  ''';

  /// Membangun skrip penandaan/pemilihan opsi jawaban kuis di WebView.
  static String buildHighlightQuizScript({
    required List<Map<String, dynamic>> solutions,
    required bool autoSelect,
  }) {
    return '''
      (function(solutionsJson, autoSelect) {
        var solutions = JSON.parse(solutionsJson);
        var highlighted = 0;

        solutions.forEach(function(sol) {
          var qIdx = sol.index;
          var optIdx = sol.correctOptionIndex;

          var radio = document.querySelector('input[type="radio"][data-unpam-q="' + qIdx + '"][data-unpam-opt="' + optIdx + '"]');
          if (!radio && sol.optionId) {
            radio = document.getElementById(sol.optionId);
          }

          if (radio) {
            if (autoSelect) {
              radio.checked = true;
              radio.dispatchEvent(new Event('change', { bubbles: true }));
              radio.dispatchEvent(new Event('click', { bubbles: true }));
            }

            var container = radio.closest('.form-check, .r0, .r1, label, div.answer, li') || radio.parentElement;
            if (container) {
              container.style.backgroundColor = '#E8F5E9';
              container.style.border = '2px solid #2E7D32';
              container.style.borderRadius = '8px';
              container.style.padding = '8px 12px';
              container.style.margin = '4px 0';
              container.style.transition = 'all 0.3s ease';

              var oldBadge = container.querySelector('.unpam-ai-badge');
              if (!oldBadge) {
                var badge = document.createElement('span');
                badge.className = 'unpam-ai-badge';
                badge.innerText = ' [Rekomendasi The PAMs AI]';
                badge.style.color = '#2E7D32';
                badge.style.fontWeight = 'bold';
                badge.style.fontSize = '12px';
                badge.style.marginLeft = '8px';
                container.appendChild(badge);
              }
              highlighted++;
            }
          }
        });

        return highlighted;
      })(${jsonEncode(jsonEncode(solutions))}, ${autoSelect ? 'true' : 'false'})
    ''';
  }

  /// Skrip pemindaian dan ekstraksi butir kuesioner evaluasi dosen Mentari.
  static const String extractQuestionnaire = r'''
    (function() {
      var results = [];
      var hasFeedback = false;

      // 1. Deteksi Baris Tabel (Format utama di Mentari Portal)
      var rows = document.querySelectorAll('table tbody tr, table tr');
      if (rows.length > 0) {
        for (var i = 0; i < rows.length; i++) {
          var row = rows[i];
          var radios = row.querySelectorAll('input[type="radio"]');
          if (radios.length === 0) continue;

          var cells = row.querySelectorAll('td, th');
          var qNum = (results.length + 1).toString();
          var qText = '';

          if (cells.length >= 2) {
            var col0 = cells[0].innerText.trim();
            if (/^\d+$/.test(col0)) {
              qNum = col0;
            }
            var col1 = cells[1].innerText.trim();
            var jIdx = col1.indexOf('Jawaban');
            if (jIdx !== -1) {
              qText = col1.substring(0, jIdx).trim();
            } else {
              qText = col1;
            }
          } else {
            var rText = row.innerText.trim();
            var jIdx = rText.indexOf('Jawaban');
            if (jIdx !== -1) {
              qText = rText.substring(0, jIdx).trim();
            } else {
              qText = rText.split('\n')[0].trim();
            }
          }

          if (!qText || qText.length < 3) {
            qText = 'Butir Kuesioner #' + qNum;
          }

          var opts = [];
          for (var j = 0; j < radios.length; j++) {
            var r = radios[j];
            var label = row.querySelector('label[for="' + r.id + '"]') || r.closest('label');
            var optText = '';
            if (label) {
              optText = label.innerText.trim();
            } else if (r.parentElement) {
              optText = r.parentElement.innerText.trim();
            }
            if (!optText || optText === 'Jawaban') {
              optText = (r.value && r.value !== 'on') ? r.value : (j === 0 ? 'Ya' : 'Tidak');
            }
            optText = optText.replace(/^Jawaban\s*/i, '').trim();

            r.setAttribute('data-unpam-kues-q', results.length.toString());
            r.setAttribute('data-unpam-kues-opt', j.toString());

            opts.push({
              optionIndex: j,
              optionId: r.id || '',
              radioName: r.name || '',
              optionText: optText,
              value: r.value || ''
            });
          }

          if (opts.length > 0) {
            results.push({
              index: results.length,
              number: qNum,
              questionText: qText,
              options: opts
            });
          }
        }
      }

      // 2. Fallback jika bukan tabel (grouping by radio name)
      if (results.length === 0) {
        var allRadios = document.querySelectorAll('input[type="radio"]');
        var groupMap = {};
        allRadios.forEach(function(r) {
          var name = r.getAttribute('name') || 'kues_default_group';
          if (!groupMap[name]) groupMap[name] = [];
          groupMap[name].push(r);
        });

        var kIdx = 0;
        for (var kName in groupMap) {
          var list = groupMap[kName];
          if (list.length < 2) continue;
          var parent = list[0].closest('tr, .form-group, .card, div.row, fieldset, li') || list[0].parentElement;
          var qText = parent ? parent.innerText.split('\n')[0].trim() : 'Butir Kuesioner #' + (kIdx + 1);

          var opts = [];
          list.forEach(function(r, oIdx) {
            var label = document.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : (r.value || 'Opsi ' + (oIdx + 1));
            r.setAttribute('data-unpam-kues-q', kIdx.toString());
            r.setAttribute('data-unpam-kues-opt', oIdx.toString());

            opts.push({
              optionIndex: oIdx,
              optionId: r.id || '',
              radioName: kName,
              optionText: optText,
              value: r.value || ''
            });
          });

          results.push({
            index: kIdx,
            number: (kIdx + 1).toString(),
            questionText: qText,
            options: opts
          });
          kIdx++;
        }
      }

      var textareas = document.querySelectorAll('textarea');
      if (textareas.length > 0) {
        hasFeedback = true;
        textareas[0].setAttribute('data-unpam-kues-feedback', '1');
      }

      return JSON.stringify({
        questions: results,
        hasFeedbackField: hasFeedback
      });
    })()
  ''';

  /// Membangun skrip pengisian dan penandaan evaluasi kuesioner.
  static String buildHighlightQuestionnaireScript({
    required List<Map<String, dynamic>> answers,
    required String feedback,
    required bool autoCheck,
  }) {
    final payload = {
      'answers': answers,
      'feedback': feedback,
    };

    return '''
      (function(payloadJson, autoCheck) {
        var payload = JSON.parse(payloadJson);
        var answers = payload.answers || [];
        var feedback = payload.feedback || '';
        var filled = 0;

        answers.forEach(function(item) {
          var qIdx = item.index;
          var optIdx = item.optionIndex;

          var radio = document.querySelector('input[type="radio"][data-unpam-kues-q="' + qIdx + '"][data-unpam-kues-opt="' + optIdx + '"]');
          if (radio) {
            if (autoCheck) {
              radio.checked = true;
              radio.dispatchEvent(new Event('input', { bubbles: true }));
              radio.dispatchEvent(new Event('change', { bubbles: true }));
              radio.dispatchEvent(new Event('click', { bubbles: true }));
            }

            var row = radio.closest('tr, .form-group, .card, div.row, fieldset, li') || radio.parentElement;
            if (row) {
              row.style.backgroundColor = '#E0F2F1';
              row.style.transition = 'background-color 0.3s ease';

              var oldBadge = row.querySelector('.unpam-kues-badge');
              if (!oldBadge) {
                var badge = document.createElement('span');
                badge.className = 'unpam-kues-badge';
                badge.innerText = ' [✓ Terisi Otomatis]';
                badge.style.color = '#00796B';
                badge.style.fontSize = '12px';
                badge.style.fontWeight = 'bold';
                badge.style.marginLeft = '8px';
                var targetEl = row.querySelector('td:nth-child(2), h4, h5, p, label') || row;
                targetEl.appendChild(badge);
              }
            }
            filled++;
          }
        });

        if (feedback && feedback.trim().length > 0) {
          var ta = document.querySelector('textarea[data-unpam-kues-feedback="1"]') || document.querySelector('textarea');
          if (ta) {
            ta.value = feedback;
            ta.dispatchEvent(new Event('input', { bubbles: true }));
            ta.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }

        return filled;
      })(${jsonEncode(jsonEncode(payload))}, ${autoCheck ? 'true' : 'false'})
    ''';
  }

  /// Skrip pemindaian otomatis konteks halaman (Forum, Kuis, Kuesioner, Modul Dokumen, Tabel Akademik).
  static const String contextualPageDetector = r'''
    (function() {
      if (!window.PageContextChannel) return;

      function toAbsoluteUrl(u) {
        try {
          return new URL(u, window.location.href).href;
        } catch(e) {
          return u || '';
        }
      }

      function scanPageContext() {
        try {
          var href = window.location.href || '';
          var lowHref = href.toLowerCase();

          // 0. Guard: Jangan tampilkan konteks di halaman login
          var passInput = document.querySelector('input[type="password"]');
          var hasProfile = !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');
          if (passInput && passInput.offsetParent !== null && !hasProfile) {
            return {
              type: 'none',
              itemCount: 0,
              label: '',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 1. Prioritas 1: Teks sedang diblok / disorot oleh pengguna
          var sel = window.getSelection ? window.getSelection().toString().trim() : '';
          if (sel && sel.length >= 8) {
            return {
              type: 'selection',
              itemCount: 0,
              label: 'Teks Diblok',
              selectedText: sel.substring(0, 1200),
              documentUrl: '',
              pageUrl: href
            };
          }

          var headingNodes = document.querySelectorAll('h1, h2, h3, h4, .card-title, .page-header-headings, .breadcrumb');
          var headingText = (document.title || '') + ' ';
          for (var h = 0; h < headingNodes.length && h < 12; h++) {
            headingText += (headingNodes[h].innerText || '') + ' ';
          }
          var lowHeading = headingText.toLowerCase();

          // 2. Prioritas 2: Deteksi Kuesioner Dosen vs Kuis Pilihan Ganda
          var allRadios = document.querySelectorAll('input[type="radio"]');
          if (allRadios.length >= 2) {
            var radioGroups = {};
            var likertSignal = 0;
            for (var r = 0; r < allRadios.length; r++) {
              var rad = allRadios[r];
              var gName = rad.getAttribute('name') || ('grp_' + r);
              if (!radioGroups[gName]) radioGroups[gName] = [];
              radioGroups[gName].push(rad);

              var lbl = document.querySelector('label[for="' + rad.id + '"]') || rad.closest('label') || rad.parentElement;
              var lblTxt = lbl ? (lbl.innerText || '').toLowerCase().trim() : '';
              if (lblTxt === 'ya' || lblTxt === 'tidak' ||
                  lblTxt.indexOf('sangat baik') !== -1 ||
                  lblTxt.indexOf('sangat setuju') !== -1 ||
                  lblTxt.indexOf('setuju') !== -1 ||
                  lblTxt.indexOf('kurang baik') !== -1) {
                likertSignal++;
              }
            }

            var groupCount = Object.keys(radioGroups).length;
            var isQuestionnaireKeyword =
              lowHref.indexOf('kuesioner') !== -1 ||
              lowHref.indexOf('kuisioner') !== -1 ||
              lowHref.indexOf('edom') !== -1 ||
              lowHeading.indexOf('kuesioner') !== -1 ||
              lowHeading.indexOf('kuisioner') !== -1 ||
              lowHeading.indexOf('evaluasi dosen') !== -1 ||
              lowHeading.indexOf('angket') !== -1;

            if (groupCount >= 2 && (isQuestionnaireKeyword || likertSignal >= 2)) {
              return {
                type: 'questionnaire',
                itemCount: groupCount,
                label: 'Kuesioner Dosen',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }

            var hasQuizDom = !!document.querySelector('.que, .qtext, .quiz-content, .question-container');
            var isQuizKeyword =
              lowHref.indexOf('quiz') !== -1 ||
              lowHref.indexOf('kuis') !== -1 ||
              lowHref.indexOf('latihan') !== -1 ||
              lowHref.indexOf('pretest') !== -1 ||
              lowHref.indexOf('posttest') !== -1 ||
              lowHeading.indexOf('kuis') !== -1 ||
              lowHeading.indexOf('quiz') !== -1 ||
              lowHeading.indexOf('latihan soal') !== -1 ||
              lowHeading.indexOf('pretest') !== -1 ||
              lowHeading.indexOf('posttest') !== -1;

            if (hasQuizDom || (groupCount >= 1 && isQuizKeyword) || groupCount >= 3) {
              var qDomCount = document.querySelectorAll('.que').length;
              var finalQuizCount = qDomCount > 0 ? qDomCount : groupCount;
              return {
                type: 'quiz',
                itemCount: finalQuizCount,
                label: 'Kuis Pilihan Ganda',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
          } else if (document.querySelectorAll('.que, .qtext, .quiz-content').length > 0) {
            var qCount = document.querySelectorAll('.que, .qtext').length || 1;
            return {
              type: 'quiz',
              itemCount: qCount,
              label: 'Kuis Pilihan Ganda',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 3. Prioritas 3: Deteksi Forum Diskusi Perkuliahan
          var hasForumPost = !!document.querySelector('.forumpost, .discussion-content, .post-content, .forum-thread');
          var isForumKeyword =
            lowHref.indexOf('forum') !== -1 ||
            lowHref.indexOf('diskusi') !== -1 ||
            lowHeading.indexOf('forum') !== -1 ||
            lowHeading.indexOf('diskusi') !== -1 ||
            lowHeading.indexOf('topik diskusi') !== -1;
          var hasReplyEditor = !!document.querySelector('textarea, .tox-edit-area, [contenteditable="true"], .editor_atto_content');

          if (hasForumPost || (isForumKeyword && (hasReplyEditor || document.querySelectorAll('.card-body, article').length > 0))) {
            return {
              type: 'forum',
              itemCount: 1,
              label: 'Forum Diskusi',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 4. Prioritas 4: Deteksi Dokumen / Modul PDF / Tombol Cetak Akademik
          var pdfEmbed = document.querySelector('iframe[src*=".pdf" i], embed[type="application/pdf" i], object[data*=".pdf" i]');
          if (pdfEmbed) {
            var embedSrc = pdfEmbed.getAttribute('src') || pdfEmbed.getAttribute('data') || '';
            return {
              type: 'document',
              itemCount: 1,
              label: 'Unduh Modul PDF',
              selectedText: '',
              documentUrl: embedSrc ? toAbsoluteUrl(embedSrc) : '',
              pageUrl: href
            };
          }

          var prevMarked = document.querySelectorAll('[data-unpam-quick-doc-btn="1"]');
          for (var pm = 0; pm < prevMarked.length; pm++) {
            prevMarked[pm].removeAttribute('data-unpam-quick-doc-btn');
          }

          var clickables = document.querySelectorAll('a[href], button, [role="button"], input[type="button"]');
          for (var c = 0; c < clickables.length; c++) {
            var el = clickables[c];
            if (el.offsetParent === null) continue;
            var rawHref = el.getAttribute('href') || el.getAttribute('data-url') || el.getAttribute('data-href') || '';
            var lowUrl = rawHref.toLowerCase().trim();
            var btnTxt = (el.innerText || el.value || el.getAttribute('title') || '').trim();
            var lowTxt = btnTxt.toLowerCase();

            var isDirectDocUrl =
              lowUrl.indexOf('.pdf') !== -1 ||
              lowUrl.indexOf('.docx') !== -1 ||
              lowUrl.indexOf('.pptx') !== -1 ||
              lowUrl.indexOf('pluginfile.php') !== -1 ||
              lowUrl.indexOf('mod_resource') !== -1 ||
              lowUrl.startsWith('blob:');

            var isPrintOrDocBtn =
              (lowTxt.indexOf('cetak') !== -1 || lowTxt.indexOf('unduh') !== -1 || lowTxt.indexOf('download') !== -1) &&
              (lowTxt.indexOf('krs') !== -1 ||
               lowTxt.indexOf('khs') !== -1 ||
               lowTxt.indexOf('jadwal') !== -1 ||
               lowTxt.indexOf('kartu') !== -1 ||
               lowTxt.indexOf('ujian') !== -1 ||
               lowTxt.indexOf('uts') !== -1 ||
               lowTxt.indexOf('uas') !== -1 ||
               lowTxt.indexOf('modul') !== -1 ||
               lowTxt.indexOf('materi') !== -1 ||
               lowTxt.indexOf('transkrip') !== -1 ||
               lowTxt.indexOf('pdf') !== -1);

            if (isDirectDocUrl || isPrintOrDocBtn) {
              var resolvedDocUrl = '';
              if (rawHref && !lowUrl.startsWith('#') && !lowUrl.startsWith('javascript:')) {
                resolvedDocUrl = toAbsoluteUrl(rawHref);
              } else {
                el.setAttribute('data-unpam-quick-doc-btn', '1');
                resolvedDocUrl = '__DOM_CLICK_DOC_BTN__';
              }

              var cleanLabel = 'Unduh Dokumen PDF';
              if (lowTxt.indexOf('krs') !== -1) cleanLabel = 'Cetak KRS';
              else if (lowTxt.indexOf('khs') !== -1) cleanLabel = 'Cetak KHS';
              else if (lowTxt.indexOf('jadwal') !== -1) cleanLabel = 'Cetak Jadwal';
              else if (lowTxt.indexOf('kartu') !== -1 || lowTxt.indexOf('ujian') !== -1) cleanLabel = 'Cetak Kartu Ujian';
              else if (lowTxt.indexOf('transkrip') !== -1) cleanLabel = 'Cetak Transkrip';
              else if (lowTxt.indexOf('modul') !== -1 || lowTxt.indexOf('materi') !== -1) cleanLabel = 'Unduh Modul';
              else if (btnTxt.length >= 4 && btnTxt.length <= 24) cleanLabel = btnTxt;

              return {
                type: 'document',
                itemCount: 1,
                label: cleanLabel,
                selectedText: '',
                documentUrl: resolvedDocUrl,
                pageUrl: href
              };
            }
          }

          // 5. Prioritas 5: Deteksi Halaman Tabel Akademik (Jadwal, KHS, Presensi, Keuangan)
          var tableRows = document.querySelectorAll('table tbody tr, table tr').length;
          if (tableRows >= 2) {
            if (lowHref.indexOf('jadwal') !== -1 || lowHeading.indexOf('jadwal') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Jadwal Kuliah',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('khs') !== -1 || lowHeading.indexOf('khs') !== -1 || lowHeading.indexOf('hasil studi') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'KHS & Nilai',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('transkrip') !== -1 || lowHeading.indexOf('transkrip') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Transkrip Nilai',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('presensi') !== -1 || lowHref.indexOf('absensi') !== -1 || lowHeading.indexOf('presensi') !== -1 || lowHeading.indexOf('kehadiran') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Presensi Kuliah',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
          }

          return {
            type: 'none',
            itemCount: 0,
            label: '',
            selectedText: '',
            documentUrl: '',
            pageUrl: href
          };
        } catch(e) {
          return {
            type: 'none',
            itemCount: 0,
            label: '',
            selectedText: '',
            documentUrl: '',
            pageUrl: window.location.href || ''
          };
        }
      }

      function emitIfChanged(force) {
        var ctx = scanPageContext();
        var sig = JSON.stringify(ctx);
        if (force || window.__unpamLastContextSig !== sig) {
          window.__unpamLastContextSig = sig;
          window.PageContextChannel.postMessage(sig);
        }
      }

      emitIfChanged(true);

      if (!window.__unpamContextDetectorAttached) {
        window.__unpamContextDetectorAttached = true;
        var debounceTimer = null;
        function scheduleCheck(delayMs) {
          if (debounceTimer) clearTimeout(debounceTimer);
          debounceTimer = setTimeout(function() {
            emitIfChanged(false);
          }, delayMs || 320);
        }

        document.addEventListener('selectionchange', function() {
          scheduleCheck(180);
        }, { passive: true });

        window.addEventListener('popstate', function() {
          scheduleCheck(250);
        }, { passive: true });

        window.addEventListener('hashchange', function() {
          scheduleCheck(250);
        }, { passive: true });

        try {
          var obs = new MutationObserver(function() {
            scheduleCheck(380);
          });
          obs.observe(document.documentElement || document.body, {
            childList: true,
            subtree: true
          });
        } catch(e) {}
      }
    })();
  ''';
}
