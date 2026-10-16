import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/ai_provider.dart';
import 'ai_assistant_screen.dart';
import 'ai_paraphrase_screen.dart';
import '../providers/biometric_provider.dart';
import '../widgets/biometric_vault_sheet.dart';
import '../core/services/update_checker_service.dart';
import '../widgets/update_dialog.dart';

class PortalWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const PortalWebViewScreen({
    super.key,
    this.initialUrl = 'https://mentari.unpam.ac.id/',
  });

  @override
  State<PortalWebViewScreen> createState() => _PortalWebViewScreenState();
}

class _PortalWebViewScreenState extends State<PortalWebViewScreen> {
  late final WebViewController _controller;
  int _currentNavIndex = 0;
  int _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _pageTitle = 'Mentari UNPAM';
  String _currentUrl = '';
  bool _canGoBack = false;
  DateTime? _lastBackPressTime;
  Offset? _fabOffset;
  bool _isDraggingFab = false;
  bool _isLoginPageDetected = false;
  bool _isLoggedOutDetected = false;
  bool _hasAutoLoggedInCurrentSession = false;
  bool _pendingAutoLoginAfterLoad = false;
  final UpdateCheckerService _updateChecker = UpdateCheckerService();

  bool _isAtTop = true;
  bool _wasAtTopOnDown = true;
  double _pullDistance = 0.0;
  bool _isPulling = false;
  bool _isRefreshing = false;
  bool _hasHapticed = false;
  double? _dragStartY;
  double? _dragStartX;
  static const double _refreshTriggerDistance = 80.0;

  static const String mentariUrl = 'https://mentari.unpam.ac.id/';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _initController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdateSilently();
    });
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setOnScrollPositionChange((change) {
        final atTop = change.y <= 1;
        if (atTop != _isAtTop && mounted) {
          setState(() {
            _isAtTop = atTop;
          });
        }
      })
      ..addJavaScriptChannel(
        'ScrollSyncChannel',
        onMessageReceived: (message) {
          final atTop = message.message == 'true';
          if (atTop != _isAtTop && mounted) {
            setState(() {
              _isAtTop = atTop;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              final nextProgress = progress.clamp(0, 100);
              final nextLoading = nextProgress < 100;
              if ((nextProgress - _progress).abs() < 2 && nextLoading == _isLoading) {
                return;
              }
              setState(() {
                _progress = nextProgress;
                _isLoading = nextLoading;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              final isLogin = url.toLowerCase().contains('login');
              setState(() {
                _currentUrl = url;
                _isLoading = true;
                _hasError = false;
                _isAtTop = true;
                _isLoginPageDetected = isLogin;
                if (!isLogin) {
                  _hasAutoLoggedInCurrentSession = false;
                }
              });
              _updateHistoryState();
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              final title = await _controller.getTitle();
              setState(() {
                _currentUrl = url;
                _isLoading = false;
                _isRefreshing = false;
                if (title != null && title.trim().isNotEmpty) {
                  _pageTitle = title.trim();
                }
              });
              _updateHistoryState();
            }
            _detectLoginForm();
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) _detectLoginForm();
            });
            try {
              await _controller.runJavaScript('''
                (function() {
                  function syncScroll() {
                    try {
                      if (window.ScrollSyncChannel) {
                        var atTop = (window.scrollY || document.documentElement.scrollTop || 0) <= 2;
                        window.ScrollSyncChannel.postMessage(atTop ? 'true' : 'false');
                      }
                    } catch(e) {}
                  }
                  window.removeEventListener('scroll', syncScroll);
                  window.addEventListener('scroll', syncScroll, { passive: true });
                  syncScroll();
                })();
              ''');
            } catch (e) {
              debugPrint('Error injecting scroll sync: \$e');
            }
          },
          onWebResourceError: (error) {
            if (_isRefreshing && mounted) {
              setState(() => _isRefreshing = false);
            }
            // Abaikan error pembatalan navigasi internal WebView
            if (error.errorCode == -999 || error.description.contains('ERR_ABORTED')) {
              return;
            }
            if (mounted && _progress < 30) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            // 1. Eksternal Link: Google Meet, Zoom, WhatsApp, Mail, Tel
            if (url.contains('meet.google.com') ||
                url.contains('zoom.us') ||
                url.contains('wa.me') ||
                url.contains('api.whatsapp.com') ||
                url.startsWith('mailto:') ||
                url.startsWith('tel:')) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

            // 2. Berkas Dokumen Unduhan (PDF, DOCX, PPTX) jika dibuka langsung
            if (url.endsWith('.pdf') ||
                url.endsWith('.docx') ||
                url.endsWith('.pptx') ||
                url.endsWith('.xlsx') ||
                url.contains('/api/file/download/')) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  Future<void> _updateHistoryState() async {
    final canBack = await _controller.canGoBack();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $url')),
          );
        }
      }
    } catch (e) {
      debugPrint('Launch external URL error: $e');
    }
  }

  void _handleBackNavigation(bool didPop, dynamic result) async {
    if (didPop) return;

    if (await _controller.canGoBack()) {
      await _controller.goBack();
      _updateHistoryState();
      return;
    }

    // Jika sudah di root webview, tekan 2x dalam 2 detik untuk keluar
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tekan sekali lagi untuk keluar dari aplikasi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    SystemNavigator.pop();
  }

  void _navigateToUrl(String url) {
    setState(() {
      _currentUrl = url;
      _isLoading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(url));
  }

  void _showAiPowerToolsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asisten Perkuliahan Cerdas',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Halaman: $_pageTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),

                // Opsi 1: AI Forum Diskusi
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  title: const Text(
                    'AI Forum Diskusi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Kaji topik diskusi dosen dan siapkan draf argumen bernalar akademis',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleForumAutoDraft();
                  },
                ),

                // Opsi 2: AI Quiz
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fact_check_rounded, color: Colors.green.shade700, size: 22),
                  ),
                  title: const Text(
                    'AI Quiz',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Kaji butir soal pilihan ganda bersama ulasan konsep dan opsi rujukan',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleLiveQuizSolver();
                  },
                ),

                // Opsi 3: Tanya AI Halaman Ini
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.accentGold, size: 22),
                  ),
                  title: const Text(
                    'Tanya AI Halaman Ini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Kirim teks halaman ke ruang konsultasi akademik UNPAM AI',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _consultWithAi();
                  },
                ),

                // Opsi 4: AI Parafrase Akademik
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_fix_high_rounded, color: Colors.purple.shade700, size: 22),
                  ),
                  title: const Text(
                    'AI Parafrase Akademik',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Parafrase teks tugas atau materi modul agar bebas plagiasi & bernalar ilmiah',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleParaphraseNavigation();
                  },
                ),

                // Opsi 5: Biometric Auto-Login & Brankas Kredensial
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppTheme.accentGold, size: 22),
                  ),
                  title: const Text(
                    'Biometric Auto-Login',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Kelola akun UNPAM terenkripsi & masuk otomatis dengan sidik jari',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    BiometricVaultSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> _handleParaphraseNavigation() async {
    String selectedText = '';
    try {
      final res = await _controller.runJavaScriptReturningResult(
        r'''
        (function() {
          var sel = window.getSelection ? window.getSelection().toString() : '';
          return sel ? sel.trim() : '';
        })()
        ''',
      );
      if (res is String && res.trim().isNotEmpty) {
        String cleaned = res.trim();
        if (cleaned.startsWith('"') && cleaned.endsWith('"') && cleaned.length >= 2) {
          cleaned = cleaned.substring(1, cleaned.length - 1);
          cleaned = cleaned.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
        }
        if (cleaned.length > 5) {
          selectedText = cleaned;
        }
      }
    } catch (e) {
      debugPrint('Selection retrieval failed: $e');
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiParaphraseScreen(
          initialText: selectedText.isNotEmpty ? selectedText : null,
          courseName: _pageTitle,
        ),
      ),
    );
  }

  Future<void> _checkAppUpdateSilently({bool isManual = false}) async {
    try {
      final updateInfo = await _updateChecker.checkForUpdate();
      if (!mounted) return;

      if (updateInfo != null && updateInfo.hasUpdate) {
        UpdateDialog.show(
          context: context,
          updateInfo: updateInfo,
          updateService: _updateChecker,
        );
      } else if (isManual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi sudah menggunakan versi terbaru!'),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (isManual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memeriksa pembaruan: $e')),
        );
      }
    }
  }

  Future<void> _detectLoginForm() async {
    final bool urlHasLogin = _currentUrl.toLowerCase().contains('login');

    try {
      final res = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          var p = document.querySelector('input[type="password"]');
          var form = p ? p.closest('form') : document.querySelector('form#login, form[action*="login"]');
          var u = form 
            ? form.querySelector('input#username, input[name="username"], input[type="text"], input[autocomplete*="user"]')
            : document.querySelector('input#username, input[name="username"], input[autocomplete*="user"], input[type="text"]');
          var isLoginUrl = window.location.href.toLowerCase().indexOf('login') !== -1;
          var isLoggedOut = !!document.querySelector('a[href*="login/index.php"], .logininfo a[href*="login"], .usermenu a[href*="login"]');

          return JSON.stringify({
            hasLoginForm: !!(u && p),
            isLoginUrl: isLoginUrl,
            isLoggedOut: isLoggedOut
          });
        })();
      ''');

      Map<String, dynamic> data = {};
      if (res is String) {
        try {
          String clean = res;
          if (clean.startsWith('"') && clean.endsWith('"') && clean.length >= 2) {
            clean = clean.substring(1, clean.length - 1);
            clean = clean.replaceAll(r'\"', '"');
          }
          data = jsonDecode(clean) as Map<String, dynamic>;
        } catch (_) {}
      }

      final hasForm = data['hasLoginForm'] == true;
      final isLoginUrl = data['isLoginUrl'] == true || urlHasLogin;
      final isLoggedOut = data['isLoggedOut'] == true;
      final isLoginDetected = hasForm || isLoginUrl;

      if (mounted) {
        setState(() {
          _isLoginPageDetected = isLoginDetected;
          _isLoggedOutDetected = isLoggedOut && !isLoginDetected;
        });

        final bioProv = context.read<BiometricProvider>();
        if (bioProv.hasSavedCredentials && bioProv.isAutoLoginEnabled) {
          if (_pendingAutoLoginAfterLoad || (isLoginDetected && !_hasAutoLoggedInCurrentSession)) {
            _hasAutoLoggedInCurrentSession = true;
            _pendingAutoLoginAfterLoad = false;
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                _performBiometricLogin();
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Login form detection error: $e');
      if (mounted && urlHasLogin && !_isLoginPageDetected) {
        setState(() {
          _isLoginPageDetected = true;
        });
      }
    }
  }

  Future<void> _performBiometricLogin() async {
    final bioProv = context.read<BiometricProvider>();
    if (!bioProv.hasSavedCredentials) {
      BiometricVaultSheet.show(context);
      return;
    }

    final creds = await bioProv.getCredentialsForLogin();
    if (creds == null) {
      return;
    }

    final nim = creds['nim'] ?? '';
    final password = creds['password'] ?? '';

    if (nim.isEmpty || password.isEmpty) return;

    try {
      final js = '''
      (function(nimVal, passVal) {
        var p = document.querySelector('input[type="password"]');
        var form = p ? p.closest('form') : document.querySelector('form#login, form[action*="login"]');
        var u = form
          ? form.querySelector('input#username, input[name="username"], input[type="text"], input[autocomplete*="user"]')
          : document.querySelector('input#username, input[name="username"], input[autocomplete*="user"], input[type="text"]');

        if (u && p) {
          u.focus();
          u.value = nimVal;
          u.dispatchEvent(new Event('input', { bubbles: true }));
          u.dispatchEvent(new Event('change', { bubbles: true }));

          p.focus();
          p.value = passVal;
          p.dispatchEvent(new Event('input', { bubbles: true }));
          p.dispatchEvent(new Event('change', { bubbles: true }));

          var btn = (form ? form.querySelector('button[type="submit"], input[type="submit"], button#loginbtn, input#loginbtn') : null)
            || document.querySelector('button#loginbtn, input#loginbtn, button[type="submit"], input[type="submit"]');

          if (btn) {
            setTimeout(function() {
              btn.click();
            }, 120);
            return 'submitted_by_click';
          } else if (form) {
            setTimeout(function() {
              form.submit();
            }, 120);
            return 'submitted_by_form';
          }
          return 'filled_only';
        }

        window.location.href = 'https://mentari.unpam.ac.id/login/index.php';
        return 'redirecting_to_login';
      })(${jsonEncode(nim)}, ${jsonEncode(password)});
      ''';

      final res = await _controller.runJavaScriptReturningResult(js);
      final resStr = res.toString();

      if (mounted) {
        if (resStr.contains('redirecting')) {
          setState(() {
            _pendingAutoLoginAfterLoad = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mengarahkan ke halaman login Mentari...'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mengisi kredensial dan memproses login Mentari...'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Auto-login script injection error: $e');
    }
  }

  void _handleBiometricButtonTap(BiometricProvider bioProv) {
    if (!bioProv.hasSavedCredentials) {
      BiometricVaultSheet.show(context);
      return;
    }

    final isLogin = _isLoginPageDetected || _currentUrl.toLowerCase().contains('login');
    if (isLogin) {
      _performBiometricLogin();
    } else {
      _showBiometricQuickMenu(bioProv);
    }
  }

  void _showBiometricQuickMenu(BiometricProvider bioProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UNPAM Auto-Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Text(
                            'NIM Terdaftar: ${bioProv.savedNim ?? "-"}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.login_rounded, color: AppTheme.accentGold, size: 20),
                  ),
                  title: const Text('Buka Halaman Login & Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Arahkan langsung ke form login Mentari dan verifikasi sidik jari.', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pendingAutoLoginAfterLoad = true;
                    });
                    _navigateToUrl('https://mentari.unpam.ac.id/login/index.php');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  title: const Text('Coba Isi Kredensial di Halaman Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Isi form username & password jika sudah berada di tampilan login.', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _performBiometricLogin();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.settings_outlined, color: AppTheme.textDark, size: 20),
                  ),
                  title: const Text('Kelola Akun & Pengaturan Biometrik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Ubah NIM, ganti password, atau nonaktifkan auto-login.', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    BiometricVaultSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBiometricLoginBanner() {
    return Consumer<BiometricProvider>(
      builder: (ctx, bioProv, _) {
        final hasCreds = bioProv.hasSavedCredentials;
        if (!hasCreds) return const SizedBox.shrink();

        final isLoginPage = _isLoginPageDetected;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoginPage ? 'Form Login Mentari Terdeteksi' : 'Sesi Belum Masuk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'NIM: ${bioProv.savedNim ?? ""}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(48, 36),
                ),
                onPressed: () {
                  if (isLoginPage) {
                    _performBiometricLogin();
                  } else {
                    setState(() {
                      _pendingAutoLoginAfterLoad = true;
                    });
                    _navigateToUrl('https://mentari.unpam.ac.id/login/index.php');
                  }
                },
                icon: const Icon(
                  Icons.login_rounded,
                  size: 16,
                ),
                label: Text(
                  isLoginPage ? 'Login Sidik Jari' : 'Masuk Sekarang',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleForumAutoDraft() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Mengkaji topik diskusi perkuliahan...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    String topicText = '';
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        r'''
        (function() {
          var topic = '';
          var subjectEl = document.querySelector('.forumpost .subject, .discussion-title, .page-header-headings, h1, h2, h3, .card-title');
          if (subjectEl && subjectEl.innerText.trim().length > 3) {
            topic += 'Judul Diskusi: ' + subjectEl.innerText.trim() + '\n\n';
          }

          var contentSelectors = [
            '.forumpost .content',
            '.discussion-content',
            '.post-content',
            '.message-content',
            '.course-content',
            '.card-body',
            'article',
            'main'
          ];
          for (var i = 0; i < contentSelectors.length; i++) {
            var el = document.querySelector(contentSelectors[i]);
            if (el && el.innerText && el.innerText.trim().length > 25) {
              topic += 'Isi Diskusi / Pertanyaan Dosen:\n' + el.innerText.trim().substring(0, 1800);
              break;
            }
          }

          if (topic.trim().length < 10 && document.body) {
            topic = document.body.innerText.substring(0, 800);
          }

          return JSON.stringify({
            topic: topic.trim()
          });
        })()
        ''',
      );

      String extractedStr = raw.toString();
      if (extractedStr.startsWith('"') && extractedStr.endsWith('"')) {
        extractedStr = jsonDecode(extractedStr);
      }
      final parsed = jsonDecode(extractedStr);
      topicText = (parsed['topic'] ?? '').toString().trim();
    } catch (e) {
      debugPrint('Gagal ekstrak topik forum: $e');
    }

    if (topicText.isEmpty || topicText.length < 15) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ditemukan konten topik diskusi pada halaman ini. Pastikan Anda telah membuka halaman utas forum di Mentari.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    String draftResult = '';
    try {
      draftResult = await context.read<AiProvider>().generateForumReply(
        topic: topicText,
        courseName: _pageTitle,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat draf balasan: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    _showForumDraftDialog(draftResult);
  }

  void _showForumDraftDialog(String initialDraft) {
    final draftController = TextEditingController(text: initialDraft);
    bool isInjecting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            title: const Row(
              children: [
                Icon(Icons.forum_rounded, color: AppTheme.primaryBlue, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Forum Diskusi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mata Kuliah: $_pageTitle',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: draftController,
                      maxLines: 9,
                      style: const TextStyle(fontSize: 13, height: 1.45),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                        hintText: 'Tinjau atau sesuaikan tanggapan diskusi Anda...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tanggapan ini dapat langsung disematkan ke kolom komentar perkuliahan atau disalin.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: draftController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teks draf berhasil disalin ke clipboard.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin Teks'),
              ),
              ElevatedButton.icon(
                onPressed: isInjecting
                    ? null
                    : () async {
                        setDialogState(() => isInjecting = true);
                        final success = await _injectForumReply(draftController.text);
                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Tanggapan berhasil disematkan ke kolom komentar forum.'
                                    : 'Kolom input belum terbuka di halaman. Teks telah disalin ke clipboard.',
                              ),
                              backgroundColor: success ? Colors.green.shade800 : Colors.black87,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: isInjecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Sematkan ke Kolom Komentar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _injectForumReply(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    try {
      final raw = await _controller.runJavaScriptReturningResult(
        '''
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
        })(${jsonEncode(text)})
        ''',
      );

      final resStr = raw.toString();
      return resStr == 'true' || resStr == '"true"';
    } catch (e) {
      debugPrint('Gagal inject forum: $e');
      return false;
    }
  }

  Future<void> _handleLiveQuizSolver() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Menelaah butir soal kuis pada lembar perkuliahan...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    List<Map<String, dynamic>> extractedQuestions = [];
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        r'''
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
        ''',
      );

      String extractedStr = raw.toString();
      if (extractedStr.startsWith('"') && extractedStr.endsWith('"')) {
        extractedStr = jsonDecode(extractedStr);
      }
      final List<dynamic> list = jsonDecode(extractedStr);
      extractedQuestions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Gagal ekstrak soal kuis: $e');
    }

    if (extractedQuestions.isEmpty) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ditemukan butir soal kuis pilihan ganda pada halaman ini. Pastikan Anda berada pada halaman kuis Mentari.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    List<Map<String, dynamic>> solutions = [];
    try {
      solutions = await context.read<AiProvider>().solveQuizQuestions(
        questions: extractedQuestions,
        courseName: _pageTitle,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis soal kuis: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    _showQuizSolverDialog(extractedQuestions, solutions);
  }

  void _showQuizSolverDialog(
    List<Map<String, dynamic>> questions,
    List<Map<String, dynamic>> solutions,
  ) {
    bool autoSelectRadio = true;
    bool isApplying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (scrollCtx, scrollController) {
              return Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.fact_check_rounded, color: AppTheme.primaryBlue, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Quiz (${questions.length} Soal)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Mata Kuliah: $_pageTitle',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Bantu tandai opsi rujukan pada lembar kuis',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Switch(
                          value: autoSelectRadio,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (val) {
                            setSheetState(() => autoSelectRadio = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final q = questions[idx];
                        final qText = (q['questionText'] ?? '').toString();
                        final opts = q['options'] as List<dynamic>? ?? [];

                        final sol = solutions.firstWhere(
                          (s) => s['index'] == idx || s['index'] == q['originalIndex'],
                          orElse: () => {
                            'correctOptionIndex': 0,
                            'correctOptionText': '',
                            'reason': 'Analisis rekomendasi AI.',
                          },
                        );

                        final correctOptIdx = (sol['correctOptionIndex'] as num?)?.toInt() ?? 0;
                        final reason = (sol['reason'] ?? '').toString();

                        String chosenText = '';
                        if (correctOptIdx >= 0 && correctOptIdx < opts.length) {
                          chosenText = (opts[correctOptIdx]['optionText'] ?? '').toString();
                        } else {
                          chosenText = (sol['correctOptionText'] ?? '').toString();
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Soal ${idx + 1}: $qText',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rekomendasi Opsi: $chosenText',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                          if (reason.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ulasan Konsep: $reason',
                                              style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isApplying
                                ? null
                                : () async {
                                    setSheetState(() => isApplying = true);
                                    final count = await _highlightQuizInWebview(
                                      solutions: solutions,
                                      autoSelect: autoSelectRadio,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Berhasil menandai $count opsi rujukan pada lembar kuis.',
                                          ),
                                          backgroundColor: Colors.green.shade800,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: isApplying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.highlight_rounded, size: 18),
                            label: const Text(
                              'Tandai di Lembar Kuis',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<int> _highlightQuizInWebview({
    required List<Map<String, dynamic>> solutions,
    required bool autoSelect,
  }) async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        '''
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
                  badge.innerText = ' [Rekomendasi UNPAM AI]';
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
        ''',
      );

      final resStr = raw.toString();
      return int.tryParse(resStr) ?? solutions.length;
    } catch (e) {
      debugPrint('Gagal highlight kuis: $e');
      return 0;
    }
  }

  Future<void> _consultWithAi() async {
    String extracted = '';
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        r'''
        (function() {
          var selectors = ['.soal', '.question', '.quiz-content', '.card-body', 'form', 'article', 'main'];
          for (var i = 0; i < selectors.length; i++) {
            var el = document.querySelector(selectors[i]);
            if (el && el.innerText && el.innerText.trim().length > 15) {
              return el.innerText.trim().substring(0, 1500);
            }
          }
          return document.body ? document.body.innerText.substring(0, 1000) : '';
        })()
        ''',
      );
      extracted = raw.toString();
      if (extracted.startsWith('"') && extracted.endsWith('"')) {
        extracted = jsonDecode(extracted);
      }
    } catch (_) {}

    final buffer = StringBuffer();
    if (extracted.trim().isNotEmpty) {
      buffer.writeln('Saya sedang membuka halaman perkuliahan UNPAM: "$_pageTitle".');
      buffer.writeln('\nBerikut teks soal/tugas/materi yang tampil di layar saya:\n"""\n${extracted.trim()}\n"""');
      buffer.writeln('\nTolong jawab dan jelaskan secara tepat: berikan opsi jawaban yang benar (jika soal kuis) atau solusi kode/uraian (jika tugas), serta jelaskan konsep dasarnya.');
    } else {
      buffer.writeln('Saya sedang mempelajari materi perkuliahan "$_pageTitle" di portal UNPAM.');
      buffer.writeln('Tolong berikan rangkuman konsep penting materi ini dan kisi-kisi pemahaman untuk kuis atau tugas.');
    }

    if (!mounted) return;
    context.read<AiProvider>().setSelectedCourse(_pageTitle);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(initialPrompt: buffer.toString()),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isRefreshing) return;
    _dragStartY = event.position.dy;
    _dragStartX = event.position.dx;
    _wasAtTopOnDown = _isAtTop;
    _isPulling = false;
    _pullDistance = 0.0;
    _hasHapticed = false;

    // Asynchronous double-check scroll position from DOM
    _controller
        .runJavaScriptReturningResult('window.scrollY || document.documentElement.scrollTop || 0;')
        .then((res) {
      final num? y = num.tryParse(res.toString());
      if (y != null && mounted) {
        final atTop = y <= 2;
        if (atTop != _isAtTop) {
          _isAtTop = atTop;
          if (!_isPulling) {
            _wasAtTopOnDown = atTop;
          }
        }
      }
    }).catchError((e) {
      debugPrint('Scroll query error: \$e');
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isRefreshing || _dragStartY == null || _dragStartX == null) return;

    if (!_wasAtTopOnDown || !_isAtTop) {
      if (_isPulling) {
        setState(() {
          _isPulling = false;
          _pullDistance = 0.0;
        });
      }
      return;
    }

    final double deltaY = event.position.dy - _dragStartY!;
    final double deltaX = (event.position.dx - _dragStartX!).abs();

    if (deltaX > deltaY && !_isPulling) {
      return;
    }

    if (deltaY > 0) {
      double calculated = deltaY * 0.52;
      if (calculated > 120.0) {
        calculated = 120.0 + (calculated - 120.0) * 0.25;
      }

      final bool reachedThreshold = calculated >= _refreshTriggerDistance;
      if (reachedThreshold && !_hasHapticed) {
        _hasHapticed = true;
        HapticFeedback.mediumImpact();
      } else if (!reachedThreshold && _hasHapticed) {
        _hasHapticed = false;
      }

      setState(() {
        _isPulling = true;
        _pullDistance = calculated;
      });
    } else {
      if (_isPulling) {
        setState(() {
          _isPulling = false;
          _pullDistance = 0.0;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _handlePointerRelease();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _handlePointerRelease();
  }

  void _handlePointerRelease() {
    _dragStartY = null;
    _dragStartX = null;
    _hasHapticed = false;

    if (_isPulling) {
      if (_pullDistance >= _refreshTriggerDistance) {
        _startRefresh();
      } else {
        setState(() {
          _isPulling = false;
          _pullDistance = 0.0;
        });
      }
    }
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _isPulling = false;
      _pullDistance = 0.0;
      _hasError = false;
    });

    try {
      await _controller.reload();
    } catch (e) {
      debugPrint('WebView reload error: \$e');
    }

    // Safety timeout in case navigation stalls
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _isRefreshing) {
        setState(() => _isRefreshing = false);
      }
    });
  }

  Widget _buildPullToRefreshIndicator() {
    final double topPos;
    if (_isRefreshing) {
      topPos = 16.0;
    } else if (_isPulling) {
      topPos = ((_pullDistance - 38.0) * 0.72).clamp(-50.0, 44.0);
    } else {
      topPos = -60.0;
    }

    return AnimatedPositioned(
      duration: _isPulling ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      top: topPos,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: (_isPulling || _isRefreshing) ? 1.0 : 0.0,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(9),
            child: _isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  )
                : Transform.rotate(
                    angle: (_pullDistance / _refreshTriggerDistance) * 3.14159 * 1.5,
                    child: CircularProgressIndicator(
                      value: (_pullDistance / _refreshTriggerDistance).clamp(0.08, 0.88),
                      strokeWidth: 2.8,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _pullDistance >= _refreshTriggerDistance
                            ? AppTheme.accentGold
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildTopAppBar(),
        body: Column(
          children: [
            // Progress Bar saat loading halaman
            if (_isLoading)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: _progress > 0 ? _progress / 100.0 : 0),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value <= 0 ? null : value,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                ),
              ),



            // Konten Utama: WebView atau Error Fallback & Draggable AI Button
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double buttonWidth = 195.0;
                  const double buttonHeight = 44.0;
                  final double maxW = constraints.maxWidth;
                  final double maxH = constraints.maxHeight;

                  _fabOffset ??= Offset(
                    (maxW - buttonWidth - 16.0).clamp(8.0, maxW),
                    (maxH - buttonHeight - 16.0).clamp(8.0, maxH),
                  );

                  final safeX = _fabOffset!.dx.clamp(8.0, (maxW - buttonWidth - 8.0).clamp(8.0, maxW));
                  final safeY = _fabOffset!.dy.clamp(8.0, (maxH - buttonHeight - 8.0).clamp(8.0, maxH));

                  return Stack(
                    children: [
                      // Konten Utama: WebView dengan gesture listener untuk Pull-to-Refresh
                      Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _onPointerDown,
                        onPointerMove: _onPointerMove,
                        onPointerUp: _onPointerUp,
                        onPointerCancel: _onPointerCancel,
                        child: WebViewWidget(controller: _controller),
                      ),

                      // Floating Pull-to-Refresh Indicator
                      _buildPullToRefreshIndicator(),

                      // Tampilan Offline / Gagal Muat (Dapat juga di-pull untuk refresh)
                      if (_hasError)
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                          child: RefreshIndicator(
                            onRefresh: _startRefresh,
                            color: AppTheme.primaryBlue,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(28),
                              children: [
                                SizedBox(height: maxH * 0.15),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.wifi_off_rounded, size: 52, color: Colors.red.shade400),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Gagal Memuat Halaman',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage.isNotEmpty ? _errorMessage : 'Periksa koneksi internet Anda atau coba muat ulang.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() => _hasError = false);
                                        _startRefresh();
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: const Text('Muat Ulang'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _navigateToUrl(mentariUrl),
                                      icon: const Icon(Icons.home_rounded, size: 18),
                                      label: const Text('Ke Beranda Mentari'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Tombol Mengambang AI Tools (Dapat Digeser Bebas ke Mana Saja)
                      Positioned(
                        left: safeX,
                        top: safeY,
                        child: GestureDetector(
                          onPanStart: (_) {
                            setState(() => _isDraggingFab = true);
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              final nextX = (_fabOffset!.dx + details.delta.dx)
                                  .clamp(8.0, (maxW - buttonWidth - 8.0).clamp(8.0, maxW));
                              final nextY = (_fabOffset!.dy + details.delta.dy)
                                  .clamp(8.0, (maxH - buttonHeight - 8.0).clamp(8.0, maxH));
                              _fabOffset = Offset(nextX, nextY);
                            });
                          },
                          onPanEnd: (_) {
                            setState(() => _isDraggingFab = false);
                          },
                          onPanCancel: () {
                            setState(() => _isDraggingFab = false);
                          },
                          onTap: _showAiPowerToolsMenu,
                          child: AnimatedScale(
                            scale: _isDraggingFab ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Material(
                              elevation: _isDraggingFab ? 10 : 4,
                              borderRadius: BorderRadius.circular(24),
                              shadowColor: AppTheme.primaryBlue.withOpacity(0.5),
                              color: AppTheme.primaryBlue,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _isDraggingFab
                                        ? AppTheme.accentGold
                                        : AppTheme.accentGold.withOpacity(0.5),
                                    width: _isDraggingFab ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: AppTheme.accentGold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'UNPAM AI Tools',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoginPageDetected || _isLoggedOutDetected) _buildBiometricLoginBanner(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    final bool isMentari = _currentUrl.contains('mentari');

    return AppBar(
      elevation: 1,
      backgroundColor: AppTheme.primaryBlue,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _canGoBack
          ? IconButton(
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              onPressed: () async {
                await _controller.goBack();
                _updateHistoryState();
              },
            )
          : Container(
              margin: const EdgeInsets.only(left: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                ),
              ),
            ),
      titleSpacing: _canGoBack ? 0 : 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isMentari ? 'Mentari Portal' : 'UNPAM Mobile',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            isMentari ? 'Portal Akademik Mahasiswa' : 'Universitas Pamulang',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<BiometricProvider>(
          builder: (ctx, bioProv, _) {
            return IconButton(
              tooltip: 'Biometric Auto-Login',
              icon: Icon(
                Icons.fingerprint_rounded,
                color: bioProv.hasSavedCredentials ? AppTheme.accentGold : Colors.white70,
                size: 22,
              ),
              onPressed: () => _handleBiometricButtonTap(bioProv),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
          onSelected: (val) {
            if (val == 'mentari') {
              _navigateToUrl(mentariUrl);
            } else if (val == 'clear_cache') {
              _controller.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache web berhasil dibersihkan')),
              );
            } else if (val == 'check_update') {
              _checkAppUpdateSilently(isManual: true);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'check_update',
              child: Row(
                children: [
                  Icon(Icons.system_update_rounded, size: 18, color: AppTheme.accentGold),
                  SizedBox(width: 10),
                  Text('Cek Pembaruan Aplikasi'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'mentari',
              child: Row(
                children: [
                  Icon(Icons.dashboard_rounded, size: 18, color: AppTheme.primaryLight),
                  SizedBox(width: 10),
                  Text('Buka Mentari Portal'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Bersihkan Cache Web'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentNavIndex,
      backgroundColor: Colors.white,
      elevation: 3,
      indicatorColor: AppTheme.primaryLight.withOpacity(0.15),
      onDestinationSelected: (idx) async {
        if (idx == 0) {
          setState(() => _currentNavIndex = 0);
          _navigateToUrl(mentariUrl);
        } else if (idx == 1) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
          );
          if (mounted) setState(() => _currentNavIndex = 0);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryBlue),
          label: 'Mentari',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.accentGold),
          label: 'UNPAM AI',
        ),
      ],
    );
  }
}
