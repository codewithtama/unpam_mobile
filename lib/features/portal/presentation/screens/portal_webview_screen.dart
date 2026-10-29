import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import 'package:unpam_mobile/theme/app_theme.dart';
import 'package:unpam_mobile/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:unpam_mobile/features/auth/presentation/providers/biometric_provider.dart';
import 'package:unpam_mobile/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:unpam_mobile/features/ai_assistant/presentation/screens/ai_paraphrase_screen.dart';
import 'package:unpam_mobile/features/ai_assistant/presentation/widgets/mini_ai_overlay_panel.dart';
import 'package:unpam_mobile/features/auth/presentation/widgets/biometric_vault_sheet.dart';
import 'package:unpam_mobile/features/auth/presentation/widgets/biometric_quick_prompt_sheet.dart';
import 'package:unpam_mobile/features/updater/presentation/dialogs/update_dialog.dart';
import 'package:unpam_mobile/features/updater/presentation/dialogs/release_history_dialog.dart';
import 'package:unpam_mobile/features/portal/presentation/widgets/in_page_quick_action_pill.dart';
import 'package:unpam_mobile/features/updater/data/update_checker_service.dart';
import 'package:unpam_mobile/core/services/notification_service.dart';
import 'package:unpam_mobile/core/services/file_download_service.dart';
import 'package:unpam_mobile/core/services/webview_download_bridge.dart';
import 'package:unpam_mobile/features/schedule/domain/models/schedule_model.dart';
import 'package:unpam_mobile/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:unpam_mobile/features/schedule/presentation/screens/schedule_screen.dart';

import '../../data/scripts/portal_js_scripts.dart';
import '../dialogs/forum_draft_dialog.dart';
import '../dialogs/quiz_solver_dialog.dart';
import '../dialogs/questionnaire_solver_dialog.dart';
import '../dialogs/ai_tools_menu_sheet.dart';
import '../dialogs/biometric_quick_menu.dart';
import '../widgets/portal_bottom_nav.dart';
import '../widgets/biometric_login_banner.dart';
import '../widgets/white_screen_recovery_banner.dart';
import '../widgets/minimized_split_ai_pill.dart';
import '../widgets/portal_pull_refresh_indicator.dart';

/// Halaman utama portal perkuliahan terpadu Mentari LMS & MyUnpam SIAKAD.
/// Dilengkapi sistem multi-controller terisolasi, akselerasi render GPU (RepaintBoundary),
/// state listenable berkinerja tinggi, dan asisten AI pintar.
class PortalWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const PortalWebViewScreen({
    super.key,
    this.initialUrl = 'https://mentari.unpam.ac.id/',
  });

  @override
  State<PortalWebViewScreen> createState() => _PortalWebViewScreenState();
}

class _PortalWebViewScreenState extends State<PortalWebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  int _currentNavIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWhiteScreenDetected = false;
  String _errorMessage = '';
  String _pageTitle = 'Mentari Portal';
  String _currentUrl = '';
  bool _canGoBack = false;
  DateTime? _lastBackPressTime;

  // Notifiers untuk gesture & animasi agar tidak merebuild seluruh Scaffold
  final ValueNotifier<Offset?> _fabOffsetNotifier =
      ValueNotifier<Offset?>(null);
  final ValueNotifier<bool> _isDraggingFabNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _splitAiRatioNotifier =
      ValueNotifier<double>(0.46);
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _myUnpamProgressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> _pullDistanceNotifier =
      ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isPullingNotifier = ValueNotifier<bool>(false);

  bool _isSplitAiOpen = false;
  bool _isSplitAiMinimized = false;

  WebPageDetectedContext _mentariDetectedContext = WebPageDetectedContext.empty;
  WebPageDetectedContext _myUnpamDetectedContext = WebPageDetectedContext.empty;
  WebPageDetectedContext get _activeDetectedContext =>
      _currentNavIndex == 1 ? _myUnpamDetectedContext : _mentariDetectedContext;

  bool _isMentariLoginDetected = false;
  bool _isMyUnpamLoginDetected = false;
  bool get _isLoginPageDetected =>
      _currentNavIndex == 1 ? _isMyUnpamLoginDetected : _isMentariLoginDetected;
  set _isLoginPageDetected(bool val) {
    if (_currentNavIndex == 1) {
      _isMyUnpamLoginDetected = val;
    } else {
      _isMentariLoginDetected = val;
    }
  }

  bool _isLoggingOutMyUnpam = false;
  bool _isLoggedOutDetected = false;
  bool _hasAutoLoggedInCurrentSession = false;
  bool _pendingAutoLoginAfterLoad = false;
  bool _isBiometricPromptShowing = false;
  String? _capturedNim;
  String? _capturedPassword;
  final UpdateCheckerService _updateChecker = UpdateCheckerService();
  bool _isCheckingUpdate = false;
  bool _isUpdateDialogShowing = false;
  bool _isHandlingRawPdf = false;
  Timer? _deadlineSnackbarDebounceTimer;
  Timer? _deadlineExtractThrottleTimer;
  bool _hasShownDeadlineSnackbarThisSession = false;
  bool _hasShownScheduleSnackbarThisSession = false;

  static const String _customUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.127 Mobile Safari/537.36';

  bool _isAtTop = true;
  bool _wasAtTopOnDown = true;
  bool _isRefreshing = false;
  bool _hasHapticed = false;
  double? _dragStartY;
  double? _dragStartX;
  static const double _refreshTriggerDistance = 80.0;

  static const String mentariUrl = 'https://mentari.unpam.ac.id/';
  static const String myUnpamUrl = 'https://my.unpam.ac.id/';

  WebViewController? _myUnpamController;
  bool _isMyUnpamLoading = false;
  bool _myUnpamHasError = false;
  String _myUnpamErrorMessage = '';
  String _myUnpamCurrentUrl = '';
  String _myUnpamPageTitle = 'MyUnpam Portal';
  bool _isMyUnpamAtTop = true;

  WebViewController get _activeController =>
      (_currentNavIndex == 1 && _myUnpamController != null)
          ? _myUnpamController!
          : _controller;

  String get _activeUrl => _currentNavIndex == 1
      ? (_myUnpamCurrentUrl.isNotEmpty ? _myUnpamCurrentUrl : myUnpamUrl)
      : _currentUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUrl = widget.initialUrl;
    _initController();

    NotificationService().initialize(
      onUpdateTap: (info) {
        if (mounted && info.hasUpdate && !_isUpdateDialogShowing) {
          _isUpdateDialogShowing = true;
          UpdateDialog.show(
            context: context,
            updateInfo: info,
            updateService: _updateChecker,
          )?.then((_) {
            _isUpdateDialogShowing = false;
          });
        }
      },
      onDeadlineTap: (payload) {
        if (!mounted) return;
        try {
          if (payload != null && payload.isNotEmpty) {
            final decoded = jsonDecode(payload) as Map<String, dynamic>;
            final targetUrl = decoded['url'] as String? ?? '';
            if (targetUrl.isNotEmpty && targetUrl.startsWith('http')) {
              setState(() => _currentNavIndex = 0);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _navigateToUrl(targetUrl);
                }
              });
              return;
            }
          }
        } catch (_) {}
        _openScheduleScreen(initialTabIndex: 2);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _checkAppUpdateSilently();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deadlineSnackbarDebounceTimer?.cancel();
    _deadlineExtractThrottleTimer?.cancel();
    _fabOffsetNotifier.dispose();
    _isDraggingFabNotifier.dispose();
    _splitAiRatioNotifier.dispose();
    _progressNotifier.dispose();
    _myUnpamProgressNotifier.dispose();
    _pullDistanceNotifier.dispose();
    _isPullingNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndRestoreSurfaceOnResume();
      _checkAppUpdateSilently();
    }
  }

  Future<void> _checkAndRestoreSurfaceOnResume() async {
    if (!mounted || _isLoading || _hasError) return;
    try {
      final res =
          await _controller.runJavaScriptReturningResult('document.readyState');
      final str = res.toString().replaceAll('"', '').trim();
      if (str != 'complete' && str != 'interactive') {
        _controller.reload();
      }
    } catch (_) {
      _controller.reload();
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_customUserAgent)
      ..setBackgroundColor(Colors.white)
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
      ..addJavaScriptChannel(
        'BiometricCaptureChannel',
        onMessageReceived: (message) {
          _handleCapturedCredentials(message.message);
        },
      )
      ..addJavaScriptChannel(
        'CampusDownloadChannel',
        onMessageReceived: (message) {
          _handleAcademicFileDownload(message.message);
        },
      )
      ..addJavaScriptChannel(
        WebViewDownloadBridge.channelName,
        onMessageReceived: (message) {
          WebViewDownloadBridge().handlePayloadMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'PageContextChannel',
        onMessageReceived: (message) {
          _handleDetectedPageContext(message.message, isMyUnpam: false);
        },
      )
      ..addJavaScriptChannel(
        'ScheduleChannel',
        onMessageReceived: (message) {
          _handleExtractedSchedule(message.message);
        },
      )
      ..addJavaScriptChannel(
        'DeadlineChannel',
        onMessageReceived: (message) {
          _handleExtractedDeadlines(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            final nextProgress = progress.clamp(0, 100);
            _progressNotifier.value = nextProgress;
            final nextLoading = nextProgress < 100;
            if (nextLoading != _isLoading && mounted) {
              setState(() => _isLoading = nextLoading);
            }
          },
          onUrlChange: (change) {
            final nextUrl = change.url;
            if (nextUrl != null && mounted) {
              final isLogin = nextUrl.toLowerCase().contains('login');
              setState(() {
                _currentUrl = nextUrl;
                if (!isLogin) {
                  _isLoginPageDetected = false;
                }
              });
              _detectLoginForm();
              _injectContextualPageDetectorScript(_controller);
              // Pemicu ekstraksi otomatis saat soft-navigation SPA Mentari
              _tryExtractDeadlines(_controller, nextUrl);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              final isLogin = url.toLowerCase().contains('login');
              setState(() {
                _currentUrl = url;
                _isLoading = true;
                _hasError = false;
                _isWhiteScreenDetected = false;
                _isAtTop = true;
                _mentariDetectedContext = WebPageDetectedContext.empty;
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
            _injectLoginCaptureScript();
            _injectContextualPageDetectorScript(_controller);
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                _detectLoginForm();
                _injectLoginCaptureScript();
                _injectContextualPageDetectorScript(_controller);
              }
            });
            _scheduleWhiteScreenCheck();
            _inject120FpsOptimizationScript(_controller);
            _injectDownloadInterceptorScript(_controller);
            _detectAndInterceptRawPdfInWebView(_controller);
            // Ekstrak deadline dari Mentari secara otomatis
            _tryExtractDeadlines(_controller, url);
          },
          onWebResourceError: (error) {
            if (_isRefreshing && mounted) {
              setState(() => _isRefreshing = false);
            }
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              }
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            final lower = url.toLowerCase();

            // Tangkap download dokumen akademik
            if (FileDownloadService.isDocumentUrl(url)) {
              _handleAcademicFileDownload(url);
              return NavigationDecision.prevent;
            }

            // Izinkan skema internal
            if (url.startsWith('https://mentari.unpam.ac.id') ||
                url.startsWith('http://mentari.unpam.ac.id') ||
                url.startsWith('https://my.unpam.ac.id') ||
                url.startsWith('http://my.unpam.ac.id') ||
                url.startsWith('https://sso.unpam.ac.id') ||
                url.startsWith('http://sso.unpam.ac.id') ||
                lower.startsWith('blob:') ||
                lower.startsWith('data:')) {
              return NavigationDecision.navigate;
            }

            _launchExternalUrl(url);
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setMixedContentMode(MixedContentMode.alwaysAllow);
      androidController.setAllowContentAccess(true);
      androidController.setAllowFileAccess(true);

      try {
        final cookieManager = WebViewCookieManager();
        if (cookieManager.platform is AndroidWebViewCookieManager) {
          (cookieManager.platform as AndroidWebViewCookieManager)
              .setAcceptThirdPartyCookies(androidController, true);
        }
      } catch (e) {
        debugPrint('Third party cookie setup error: $e');
      }

      if (kDebugMode) {
        AndroidWebViewController.enableDebugging(true);
      }
    }

    _controller.loadRequest(Uri.parse(_currentUrl));
  }

  void _handleMyUnpamLogoutNavigation(String url) {
    _isLoggingOutMyUnpam = true;
    setState(() {
      _isMyUnpamLoading = true;
    });
    _myUnpamController?.loadRequest(Uri.parse(url));
  }

  Future<void> _handleSsoRedirectAutoBypass(
      WebViewController controller) async {
    try {
      final res = await controller.runJavaScriptReturningResult(r'''
        (function() {
          var body = document.body ? document.body.innerText.toLowerCase() : '';
          var isRedirect = body.indexOf('konfirmasi redirect') !== -1 ||
                           body.indexOf('lanjutkan ke my unpam') !== -1 ||
                           body.indexOf('apakah anda ingin melanjutkan ke aplikasi berikut') !== -1;
          if (!isRedirect) return false;

          var btns = Array.from(document.querySelectorAll('a, button, input[type="button"], input[type="submit"]'));
          var btn = btns.find(function(b) {
            var t = (b.innerText || b.value || '').trim().toLowerCase();
            return t.indexOf('lanjutkan ke my unpam') !== -1 ||
                   (t.indexOf('lanjutkan') !== -1 && t.indexOf('unpam') !== -1) ||
                   t.indexOf('lanjutkan') !== -1;
          });
          if (btn) {
            btn.click();
            return true;
          }
          return false;
        })();
      ''');
      if (res == true || res == 'true') {
        debugPrint('Auto-bypassed SSO redirect page');
      }
    } catch (e) {
      debugPrint('Error auto-bypassing SSO redirect: $e');
    }
  }

  void _ensureMyUnpamControllerInitialized() {
    if (_myUnpamController != null) return;

    _myUnpamController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_customUserAgent)
      ..setBackgroundColor(Colors.white)
      ..setOnScrollPositionChange((change) {
        final atTop = change.y <= 1;
        if (atTop != _isMyUnpamAtTop && mounted) {
          setState(() {
            _isMyUnpamAtTop = atTop;
          });
        }
      })
      ..addJavaScriptChannel(
        'ScrollSyncChannel',
        onMessageReceived: (message) {
          final atTop = message.message == 'true';
          if (atTop != _isMyUnpamAtTop && mounted) {
            setState(() {
              _isMyUnpamAtTop = atTop;
            });
          }
        },
      )
      ..addJavaScriptChannel(
        'BiometricCaptureChannel',
        onMessageReceived: (message) {
          _handleCapturedCredentials(message.message);
        },
      )
      ..addJavaScriptChannel(
        'CampusDownloadChannel',
        onMessageReceived: (message) {
          _handleAcademicFileDownload(message.message);
        },
      )
      ..addJavaScriptChannel(
        WebViewDownloadBridge.channelName,
        onMessageReceived: (message) {
          WebViewDownloadBridge().handlePayloadMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'PageContextChannel',
        onMessageReceived: (message) {
          _handleDetectedPageContext(message.message, isMyUnpam: true);
        },
      )
      ..addJavaScriptChannel(
        'ScheduleChannel',
        onMessageReceived: (message) {
          _handleExtractedSchedule(message.message);
        },
      )
      ..addJavaScriptChannel(
        'DeadlineChannel',
        onMessageReceived: (message) {
          _handleExtractedDeadlines(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            final nextProgress = progress.clamp(0, 100);
            _myUnpamProgressNotifier.value = nextProgress;
            final nextLoading = nextProgress < 100;
            if (nextLoading != _isMyUnpamLoading && mounted) {
              setState(() => _isMyUnpamLoading = nextLoading);
            }
          },
          onUrlChange: (change) {
            final nextUrl = change.url;
            if (nextUrl != null && mounted) {
              final isLogin = nextUrl.toLowerCase().contains('login') ||
                  nextUrl.toLowerCase().contains('sso');
              setState(() {
                _myUnpamCurrentUrl = nextUrl;
                if (!isLogin) {
                  _isMyUnpamLoginDetected = false;
                }
              });
              _detectLoginForm();
              if (_myUnpamController != null) {
                _injectContextualPageDetectorScript(_myUnpamController!);
                _tryExtractSchedule(_myUnpamController!, nextUrl);
              }
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              final isLogin = url.toLowerCase().contains('login') ||
                  url.toLowerCase().contains('sso');
              setState(() {
                _myUnpamCurrentUrl = url;
                _isMyUnpamLoading = true;
                _myUnpamHasError = false;
                _isMyUnpamAtTop = true;
                _myUnpamDetectedContext = WebPageDetectedContext.empty;
                _isMyUnpamLoginDetected = isLogin;
              });
              _updateHistoryState();
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              final title = await _myUnpamController?.getTitle();
              setState(() {
                _myUnpamCurrentUrl = url;
                _isMyUnpamLoading = false;
                _isRefreshing = false;
                if (title != null && title.trim().isNotEmpty) {
                  _myUnpamPageTitle = title.trim();
                }
              });
              _updateHistoryState();
            }
            if (_myUnpamController != null) {
              _handleSsoRedirectAutoBypass(_myUnpamController!);
              _detectLoginForm();
              _injectLoginCaptureScript();
              _injectContextualPageDetectorScript(_myUnpamController!);
              _inject120FpsOptimizationScript(_myUnpamController!);
              _injectDownloadInterceptorScript(_myUnpamController!);
              _detectAndInterceptRawPdfInWebView(_myUnpamController!);
              // Ekstrak jadwal dari MyUnpam secara otomatis
              _tryExtractSchedule(_myUnpamController!, url);
            }
            final lowerUrl = url.toLowerCase();
            if (_isLoggingOutMyUnpam ||
                lowerUrl.contains('logout') ||
                lowerUrl.contains('keluar') ||
                lowerUrl.contains('signout')) {
              _isLoggingOutMyUnpam = false;
              if (!url.startsWith('https://my.unpam.ac.id')) {
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (mounted && _myUnpamController != null) {
                    _myUnpamController!.loadRequest(Uri.parse('https://my.unpam.ac.id/'));
                  }
                });
              }
            }
          },
          onWebResourceError: (error) {
            if (_isRefreshing && mounted) {
              setState(() => _isRefreshing = false);
            }
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _myUnpamHasError = true;
                  _isMyUnpamLoading = false;
                  _myUnpamErrorMessage = error.description;
                });
              }
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            final lower = url.toLowerCase();

            if (FileDownloadService.isDocumentUrl(url)) {
              _handleAcademicFileDownload(url);
              return NavigationDecision.prevent;
            }

            if (lower.contains('logout') || lower.contains('signout')) {
              _handleMyUnpamLogoutNavigation(url);
              return NavigationDecision.prevent;
            }

            if (url.startsWith('https://my.unpam.ac.id') ||
                url.startsWith('http://my.unpam.ac.id') ||
                url.startsWith('https://sso.unpam.ac.id') ||
                url.startsWith('http://sso.unpam.ac.id') ||
                lower.startsWith('blob:') ||
                lower.startsWith('data:')) {
              return NavigationDecision.navigate;
            }

            _launchExternalUrl(url);
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_myUnpamController!.platform is AndroidWebViewController) {
      final androidController =
          _myUnpamController!.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setMixedContentMode(MixedContentMode.alwaysAllow);
      androidController.setAllowContentAccess(true);
      androidController.setAllowFileAccess(true);

      try {
        final cookieManager = WebViewCookieManager();
        if (cookieManager.platform is AndroidWebViewCookieManager) {
          (cookieManager.platform as AndroidWebViewCookieManager)
              .setAcceptThirdPartyCookies(androidController, true);
        }
      } catch (e) {
        debugPrint('MyUnpam Third party cookie error: $e');
      }
    }

    _myUnpamController!.loadRequest(Uri.parse(myUnpamUrl));
  }

  Future<void> _updateHistoryState() async {
    final canBack = await _activeController.canGoBack();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    if (FileDownloadService.isDocumentUrl(url)) {
      await _handleAcademicFileDownload(url);
      return;
    }
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

    if (await _activeController.canGoBack()) {
      await _activeController.goBack();
      _updateHistoryState();
      return;
    }

    if (_isSplitAiOpen && !_isSplitAiMinimized) {
      if (mounted) {
        setState(() => _isSplitAiMinimized = true);
      }
      return;
    }

    if (_currentNavIndex == 1) {
      setState(() => _currentNavIndex = 0);
      _updateHistoryState();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
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
      if (_currentNavIndex == 1) {
        _myUnpamCurrentUrl = url;
        _isMyUnpamLoading = true;
        _myUnpamHasError = false;
      } else {
        _currentUrl = url;
        _isLoading = true;
        _hasError = false;
        _isWhiteScreenDetected = false;
      }
    });
    _activeController.loadRequest(Uri.parse(url));
  }

  void _scheduleWhiteScreenCheck() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _performWhiteScreenCheck();
    });
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) _performWhiteScreenCheck();
    });
  }

  Future<void> _performWhiteScreenCheck() async {
    if (!mounted || _isLoading || _hasError) return;

    try {
      final res = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          try {
            var body = document.body;
            if (!body) return true;
            var text = (body.innerText || body.textContent || '').trim();
            var interactive = document.querySelectorAll('input, button, a, form, [role="button"]');
            var rootEl = document.getElementById('root') || document.getElementById('app');
            var rootEmpty = rootEl ? (rootEl.children.length === 0 && text.length === 0) : false;
            return (text.length === 0 && interactive.length === 0) || rootEmpty;
          } catch(e) {
            return false;
          }
        })();
      ''');

      final isBlank = res == true || res == 'true';
      if (mounted && isBlank != _isWhiteScreenDetected) {
        setState(() {
          _isWhiteScreenDetected = isBlank;
        });
      }
    } catch (_) {}
  }

  Future<void> _resetMentariSession({bool showMessage = true}) async {
    try {
      await _controller.runJavaScript(r'''
        try {
          window.localStorage.clear();
          window.sessionStorage.clear();
        } catch(e) {}
      ''');
    } catch (_) {}

    try {
      if (_controller.platform is AndroidWebViewController) {
        await (_controller.platform as AndroidWebViewController)
            .clearLocalStorage();
      }
    } catch (_) {}

    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
    } catch (_) {}

    try {
      await _controller.clearCache();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isWhiteScreenDetected = false;
        _hasError = false;
        _isLoading = true;
      });

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child:
                      Text('Cache, cookie, dan sesi Mentari berhasil direset.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    _navigateToUrl(mentariUrl);
  }

  void _showAiPowerToolsMenu() {
    AiToolsMenuSheet.show(
      context: context,
      isMyUnpam: _currentNavIndex == 1,
      pageTitle: _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle,
      isSplitAiActive: _isSplitAiOpen && !_isSplitAiMinimized,
      onToggleSplitAi: _toggleSplitAiOverlay,
      onOpenForumDraft: _handleForumAutoDraft,
      onOpenQuizSolver: _handleLiveQuizSolver,
      onOpenQuestionnaire: _handleQuestionnaireAutoFill,
      onAskPageAi: () => _consultWithAi(openInSplitScreen: true),
      onOpenParaphrase: _handleParaphraseNavigation,
      onOpenBiometricVault: () => BiometricVaultSheet.show(context),
    );
  }

  WebViewController _getControllerForUrl(String targetUrl) {
    final lower = targetUrl.toLowerCase();
    if (lower.contains('my.unpam.ac.id') && _myUnpamController != null) {
      return _myUnpamController!;
    }
    if (lower.contains('mentari.unpam.ac.id')) {
      return _controller;
    }
    return _activeController;
  }

  Future<void> _handleAcademicFileDownload(String url,
      {String? customName}) async {
    if (!mounted || url.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mengunduh berkas perkuliahan...',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 15),
      ),
    );

    if (url.startsWith('data:')) {
      final result =
          await FileDownloadService().saveAndOpenBase64DataUri(url, customName);
      if (!mounted) return;
      _showDownloadResultSnackBar(scaffoldMessenger, result, url);
      return;
    }

    final activeUrl = _currentNavIndex == 1 ? _myUnpamCurrentUrl : _currentUrl;
    String targetUrl = url.trim();

    String? resolvedCustomName = customName;
    if (resolvedCustomName == null && targetUrl.startsWith('blob:')) {
      final titleLower = _pageTitle.toLowerCase();
      if (titleLower.contains('jadwal')) {
        resolvedCustomName = 'Jadwal_Kuliah_ThePAMs';
      } else if (titleLower.contains('krs')) {
        resolvedCustomName = 'Cetak_KRS_ThePAMs';
      } else if (titleLower.contains('khs')) {
        resolvedCustomName = 'Cetak_KHS_ThePAMs';
      } else if (titleLower.contains('ujian') ||
          titleLower.contains('uts') ||
          titleLower.contains('uas')) {
        resolvedCustomName = 'Kartu_Ujian_ThePAMs';
      } else if (titleLower.contains('transkrip')) {
        resolvedCustomName = 'Transkrip_Nilai_ThePAMs';
      }
    }

    if (!targetUrl.startsWith('http://') &&
        !targetUrl.startsWith('https://') &&
        !targetUrl.startsWith('blob:') &&
        !targetUrl.startsWith('data:')) {
      final base = Uri.tryParse(activeUrl);
      if (base != null) {
        targetUrl = base.resolve(targetUrl).toString();
      }
    }

    final targetController = _getControllerForUrl(targetUrl);
    FileDownloadResult result;

    try {
      result = await WebViewDownloadBridge().downloadFile(
        controller: targetController,
        url: targetUrl,
        customName: resolvedCustomName,
      );
    } catch (e) {
      result = FileDownloadResult.failure('Gagal unduh peramban: $e');
    }

    if (!result.isSuccess &&
        !targetUrl.startsWith('blob:') &&
        !targetUrl.startsWith('data:')) {
      final cookies = await FileDownloadService().getSessionCookiesForUrl(
          targetUrl.isNotEmpty ? targetUrl : activeUrl);
      result = await FileDownloadService().downloadAndOpenFile(
        url: targetUrl,
        customFileName: resolvedCustomName,
        explicitCookies: cookies,
        userAgent: _customUserAgent,
        referer: activeUrl,
      );
    }

    if (!mounted) return;
    _showDownloadResultSnackBar(scaffoldMessenger, result, targetUrl);
  }

  void _showDownloadResultSnackBar(
    ScaffoldMessengerState scaffoldMessenger,
    FileDownloadResult result,
    String fallbackUrl,
  ) {
    scaffoldMessenger.hideCurrentSnackBar();

    if (result.isSuccess && result.filePath != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Berkas ${result.fileName ?? "dokumen"} siap!',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.textDark,
          action: SnackBarAction(
            label: 'BUKA',
            textColor: AppTheme.accentGold,
            onPressed: () {
              OpenFilex.open(result.filePath!);
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.amberAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.errorMessage ?? 'Gagal mengunduh berkas perkuliahan.',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade900,
          action: SnackBarAction(
            label: 'BROWSER',
            textColor: Colors.white,
            onPressed: () async {
              final uri = Uri.tryParse(fallbackUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  Future<void> _detectAndInterceptRawPdfInWebView(
      WebViewController controller) async {
    if (_isHandlingRawPdf || !mounted) return;

    try {
      final isPdfRaw = await controller.runJavaScriptReturningResult(r'''
        (function() {
          try {
            var ct = (document.contentType || '').toLowerCase();
            if (ct.indexOf('application/pdf') !== -1 || ct.indexOf('application/octet-stream') !== -1) {
              return true;
            }
            var t = (document.body ? document.body.innerText : '') || (document.documentElement ? document.documentElement.innerText : '');
            var sample = t.substring(0, 100).trim();
            if (sample.indexOf('%PDF-') === 0 || sample.indexOf('%pdf-') === 0) {
              return true;
            }
            var pre = document.querySelector('pre');
            if (pre && pre.innerText && pre.innerText.trim().indexOf('%PDF-') === 0) {
              return true;
            }
            return false;
          } catch(e) {
            return false;
          }
        })()
      ''');

      final bool isPdf =
          isPdfRaw == true || isPdfRaw.toString().trim() == 'true';
      if (!isPdf || !mounted) return;

      _isHandlingRawPdf = true;

      final currentUrl = await controller.currentUrl() ?? '';

      try {
        final canBack = await controller.canGoBack();
        if (canBack && mounted) {
          await controller.goBack();
        }
      } catch (e) {
        debugPrint('Go back error after raw PDF intercept: $e');
      }

      if (mounted && currentUrl.isNotEmpty) {
        await _handleAcademicFileDownload(currentUrl,
            customName: 'Dokumen_Akademik.pdf');
      }
    } catch (e) {
      debugPrint('Error detecting raw PDF: $e');
    } finally {
      _isHandlingRawPdf = false;
    }
  }

  Future<void> _inject120FpsOptimizationScript(
      WebViewController controller) async {
    try {
      await controller.runJavaScript(PortalJsScripts.fpsOptimization);
    } catch (e) {
      debugPrint('Error injecting 120 FPS optimization script: $e');
    }
  }

  Future<void> _injectDownloadInterceptorScript(
      WebViewController controller) async {
    try {
      await controller.runJavaScript(PortalJsScripts.downloadInterceptor);
    } catch (e) {
      debugPrint('Error injecting download interceptor: $e');
    }
  }

  void _handleParaphraseNavigation() {
    final activeTitle = _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiParaphraseScreen(courseName: activeTitle),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Jadwal & Deadline Extractor
  // ──────────────────────────────────────────────────────────────────────────

  /// Dipanggil saat JS scheduleExtractor mengirim hasil scraping dari MyUnpam.
  void _handleExtractedSchedule(String jsonStr, {bool isManualSync = false}) {
    try {
      final schedules = CourseSchedule.listFromJson(jsonStr);
      if (!mounted || schedules.isEmpty) return;
      final provider = context.read<ScheduleProvider>();
      provider.onScheduleExtracted(schedules);
      debugPrint('[ScheduleSync] ${schedules.length} jadwal berhasil di-scrape.');

      // Notifikasi jadwal cukup ditampilkan 1 kali saja per sesi atau bila dipicu manual
      if (!isManualSync && _hasShownScheduleSnackbarThisSession) return;
      _hasShownScheduleSnackbarThisSession = true;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${schedules.length} jadwal kuliah berhasil disinkronkan!'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      debugPrint('[ScheduleSync] Error parse schedule: $e');
    }
  }

  /// Dipanggil saat JS deadlineExtractor mengirim hasil scraping dari Mentari.
  void _handleExtractedDeadlines(String jsonStr, {bool isManualSync = false}) {
    try {
      final deadlines = CourseDeadline.listFromJson(jsonStr);
      if (!mounted || deadlines.isEmpty) return;
      final provider = context.read<ScheduleProvider>();
      provider.onDeadlinesExtracted(deadlines);
      debugPrint('[DeadlineSync] ${deadlines.length} deadline berhasil di-scrape.');

      // Jika bukan sync manual dan notifikasi sudah pernah ditampilkan di sesi ini, jangan tampilkan lagi
      if (!isManualSync && _hasShownDeadlineSnackbarThisSession) {
        return;
      }

      // Debounce notifikasi agar proses background multi-course hanya memunculkan tepat 1 kali SnackBar
      _deadlineSnackbarDebounceTimer?.cancel();
      _deadlineSnackbarDebounceTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (!isManualSync && _hasShownDeadlineSnackbarThisSession) return;
        _hasShownDeadlineSnackbarThisSession = true;

        final totalCount = provider.deadlines.length;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $totalCount deadline/tugas berhasil diperbarui!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      });
    } catch (e) {
      debugPrint('[DeadlineSync] Error parse deadline: $e');
    }
  }

  /// Ekstrak jadwal dari halaman MyUnpam jika URL relevan.
  Future<void> _tryExtractSchedule(WebViewController controller, String url) async {
    final lower = url.toLowerCase();
    final isSchedulePage = lower.contains('jadwal') ||
        lower.contains('schedule') ||
        lower.contains('krs') ||
        (lower.contains('my.unpam.ac.id') &&
            !lower.contains('login') &&
            !lower.contains('sso'));
    if (!isSchedulePage) return;
    try {
      final result = await controller
          .runJavaScriptReturningResult(PortalJsScripts.scheduleExtractor);
      final jsonStr = result.toString();
      if (jsonStr.isNotEmpty && jsonStr != 'null' && jsonStr != '[]') {
        _handleExtractedSchedule(jsonStr);
      }
    } catch (e) {
      debugPrint('[ScheduleExtractor] Error: $e');
    }
  }

  /// Ekstrak deadline dari halaman Mentari jika URL relevan dengan proteksi throttling.
  void _tryExtractDeadlines(WebViewController controller, String url) {
    final lower = url.toLowerCase();
    final isRelevant = lower.contains('mentari.unpam.ac.id') &&
        !lower.contains('login') &&
        !lower.contains('pluginfile') &&
        !lower.contains('theme/');
    if (!isRelevant) return;

    _deadlineExtractThrottleTimer?.cancel();
    _deadlineExtractThrottleTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      try {
        final result = await controller
            .runJavaScriptReturningResult(PortalJsScripts.deadlineExtractor);
        final jsonStr = result.toString();
        if (jsonStr.isNotEmpty && jsonStr != 'null' && jsonStr != '[]') {
          _handleExtractedDeadlines(jsonStr);
        }
      } catch (e) {
        debugPrint('[DeadlineExtractor] Error: $e');
      }
    });
  }

  Future<void> _checkAppUpdateSilently() async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;
    try {
      final updateInfo = await _updateChecker.checkForUpdate();
      if (updateInfo != null && updateInfo.hasUpdate && mounted && !_isUpdateDialogShowing) {
        _isUpdateDialogShowing = true;
        await UpdateDialog.show(
          context: context,
          updateInfo: updateInfo,
          updateService: _updateChecker,
        );
        _isUpdateDialogShowing = false;
      }
    } catch (e) {
      debugPrint('Silent update check error: $e');
    } finally {
      _isCheckingUpdate = false;
    }
  }

  void _showReleaseHistory() {
    ReleaseHistoryDialog.show(
      context: context,
      updateService: _updateChecker,
    );
  }

  Future<void> _detectLoginForm() async {
    final activeCtrl = _activeController;
    final currentActive = _activeUrl.toLowerCase();
    final bool isMyUnpam = _currentNavIndex == 1;
    final bool urlHasLogin = currentActive.contains('login') ||
        currentActive.contains('sso') ||
        currentActive.contains('auth') ||
        (isMyUnpam &&
            (currentActive.isEmpty ||
                currentActive == myUnpamUrl ||
                currentActive == 'https://my.unpam.ac.id' ||
                currentActive == 'https://my.unpam.ac.id/'));

    try {
      final res = await activeCtrl
          .runJavaScriptReturningResult(PortalJsScripts.detectLoginForm);

      Map<String, dynamic> data = {};
      if (res is String) {
        try {
          String clean = res;
          if (clean.startsWith('"') &&
              clean.endsWith('"') &&
              clean.length >= 2) {
            clean = clean.substring(1, clean.length - 1);
            clean = clean.replaceAll(r'\"', '"');
          }
          data = jsonDecode(clean) as Map<String, dynamic>;
        } catch (_) {}
      }

      final hasForm = data['hasLoginForm'] == true;
      final isLoginUrl = data['isLoginUrl'] == true || urlHasLogin;
      final hasProfile = data['hasProfileIndicator'] == true;

      final isLoginDetected = (hasForm || isLoginUrl) && !hasProfile;

      if (mounted) {
        setState(() {
          _isLoginPageDetected = isLoginDetected;
          _isLoggedOutDetected = false;
        });

        if (isLoginDetected) {
          _injectLoginCaptureScript();
        } else if (hasProfile) {
          if (_capturedNim != null && _capturedPassword != null) {
            _checkAndShowBiometricPrompt();
          }
        }

        final bioProv = context.read<BiometricProvider>();
        if (bioProv.hasSavedCredentials && bioProv.isAutoLoginEnabled) {
          if (_pendingAutoLoginAfterLoad ||
              (isLoginDetected && !_hasAutoLoggedInCurrentSession)) {
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
    }
  }

  void _handleCapturedCredentials(String rawPayload) {
    try {
      final data = jsonDecode(rawPayload) as Map<String, dynamic>;
      final event = data['event'] as String?;
      final nim = (data['nim'] ?? '').toString().trim();
      final password = (data['password'] ?? '').toString().trim();

      if (nim.isNotEmpty && password.isNotEmpty) {
        _capturedNim = nim;
        _capturedPassword = password;

        if (event == 'LOGIN_SUCCESS') {
          _checkAndShowBiometricPrompt();
        }
      }
    } catch (e) {
      debugPrint('Biometric capture payload parse error: $e');
    }
  }

  Future<void> _injectLoginCaptureScript() async {
    try {
      await _activeController.runJavaScript(PortalJsScripts.loginCapture);
    } catch (e) {
      debugPrint('Login capture script injection error: $e');
    }
  }

  Future<void> _checkAndShowBiometricPrompt() async {
    if (!mounted || _isBiometricPromptShowing) return;
    if (_capturedNim == null || _capturedPassword == null) return;

    final bioProv = context.read<BiometricProvider>();

    if (bioProv.hasSavedCredentials && bioProv.savedNim == _capturedNim) {
      return;
    }

    final isAvailable = bioProv.isAvailable;
    if (!isAvailable || !mounted) return;

    _isBiometricPromptShowing = true;
    try {
      await BiometricQuickPromptSheet.show(
        context,
        nim: _capturedNim!,
        password: _capturedPassword!,
      );
    } finally {
      _isBiometricPromptShowing = false;
      _capturedNim = null;
      _capturedPassword = null;
    }
  }

  Future<void> _performBiometricLogin({int attempt = 1}) async {
    final bioProv = context.read<BiometricProvider>();
    if (!bioProv.hasSavedCredentials) {
      BiometricVaultSheet.show(context);
      return;
    }

    final creds = await bioProv.getCredentialsForLogin();
    if (creds == null) {
      return;
    }

    final nim = (creds['nim'] ?? '').trim();
    final password = (creds['password'] ?? '').trim();

    if (nim.isEmpty || password.isEmpty) return;

    final isMyUnpam = _currentNavIndex == 1;
    final portalName = isMyUnpam ? 'MyUnpam' : 'Mentari';

    try {
      final js = PortalJsScripts.buildBiometricLoginScript(
        nim: nim,
        password: password,
        isMyUnpam: isMyUnpam,
      );

      final res = await _activeController.runJavaScriptReturningResult(js);
      final resStr = res.toString();

      if (mounted) {
        if (resStr.contains('redirecting') ||
            resStr.contains('clicked_proceed_button')) {
          setState(() {
            _pendingAutoLoginAfterLoad = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mengarahkan ke halaman login $portalName...'),
              backgroundColor: AppTheme.primaryBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (resStr.contains('inputs_not_found') && attempt < 4) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _performBiometricLogin(attempt: attempt + 1);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Mengisi kredensial dan memproses login $portalName...'),
              backgroundColor: AppTheme.primaryBlue,
              duration: const Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              _detectLoginForm();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Auto-login script injection error: $e');
    }
  }

  void _handleBiometricButtonTap(BiometricProvider bioProv) {
    if (!bioProv.hasSavedCredentials) {
      BiometricVaultSheet.show(context);
    } else {
      _showBiometricQuickMenu(bioProv);
    }
  }

  void _showBiometricQuickMenu(BiometricProvider bioProv) {
    BiometricQuickMenuDialog.show(
      context: context,
      savedNim: bioProv.savedNim,
      isMyUnpam: _currentNavIndex == 1,
      onNavigateToLogin: () {
        setState(() {
          _pendingAutoLoginAfterLoad = true;
        });
        if (_currentNavIndex == 1) {
          _ensureMyUnpamControllerInitialized();
          _myUnpamController?.loadRequest(Uri.parse(myUnpamUrl));
        } else {
          _navigateToUrl('https://mentari.unpam.ac.id/login');
        }
      },
      onPerformLoginHere: _performBiometricLogin,
      onOpenVault: () => BiometricVaultSheet.show(context),
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
                    'AI sedang menganalisis topik diskusi perkuliahan...',
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
      final raw = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          var post = document.querySelector('.forumpost .content, .discussion-content, .post-content');
          if (post) return post.innerText.trim();
          var main = document.querySelector('[role="main"], #region-main, main');
          if (main) return main.innerText.substring(0, 1500).trim();
          return document.body ? document.body.innerText.substring(0, 1500).trim() : '';
        })()
      ''');
      topicText = raw.toString();
      if (topicText.startsWith('"') && topicText.endsWith('"')) {
        topicText = jsonDecode(topicText);
      }
    } catch (e) {
      debugPrint('Gagal ekstrak topik forum: $e');
    }

    if (!mounted) return;

    String draft = '';
    try {
      draft = await context.read<AiProvider>().generateForumReply(
            courseName: _pageTitle,
            topic: topicText.isNotEmpty
                ? topicText
                : 'Topik perkuliahan pada mata kuliah $_pageTitle.',
          );
    } catch (e) {
      draft =
          'Terima kasih Bapak/Ibu dosen atas pemaparan materi perkuliahan "$_pageTitle". Menurut kajian saya, konsep ini sangat relevan untuk diimplementasikan secara sistematis dan analitis.';
    }

    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    ForumDraftDialog.show(
      context: context,
      pageTitle: _pageTitle,
      initialDraft: draft,
      onInject: _injectForumReply,
    );
  }

  Future<bool> _injectForumReply(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    try {
      final js = PortalJsScripts.buildForumReplyScript(text);
      final raw = await _activeController.runJavaScriptReturningResult(js);
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
        PortalJsScripts.extractQuizQuestions,
      );

      String extractedStr = raw.toString();
      if (extractedStr.startsWith('"') && extractedStr.endsWith('"')) {
        extractedStr = jsonDecode(extractedStr);
      }
      final List<dynamic> list = jsonDecode(extractedStr);
      extractedQuestions =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Gagal ekstrak soal kuis: $e');
    }

    if (extractedQuestions.isEmpty) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak ditemukan butir soal kuis pilihan ganda pada halaman ini. Pastikan Anda berada pada halaman kuis Mentari.'),
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
    QuizSolverDialog.show(
      context: context,
      pageTitle: _pageTitle,
      questions: extractedQuestions,
      solutions: solutions,
      onApplyHighlight: _highlightQuizInWebview,
    );
  }

  Future<int> _highlightQuizInWebview({
    required List<Map<String, dynamic>> solutions,
    required bool autoSelect,
  }) async {
    try {
      final js = PortalJsScripts.buildHighlightQuizScript(
        solutions: solutions,
        autoSelect: autoSelect,
      );
      final raw = await _controller.runJavaScriptReturningResult(js);
      final resStr = raw.toString();
      return int.tryParse(resStr) ?? solutions.length;
    } catch (e) {
      debugPrint('Gagal highlight kuis: $e');
      return 0;
    }
  }

  Future<void> _handleQuestionnaireAutoFill() async {
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
                CircularProgressIndicator(strokeWidth: 3, color: Colors.teal),
                SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Memindai butir kuesioner pada halaman web Mentari...',
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
    bool hasFeedbackField = false;

    try {
      final raw = await _controller.runJavaScriptReturningResult(
        PortalJsScripts.extractQuestionnaire,
      );

      String resStr = raw.toString();
      if (resStr.startsWith('"') && resStr.endsWith('"')) {
        resStr = jsonDecode(resStr);
      }
      final parsed = jsonDecode(resStr) as Map<String, dynamic>;
      final list = parsed['questions'] as List<dynamic>? ?? [];
      extractedQuestions =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      hasFeedbackField = parsed['hasFeedbackField'] == true;
    } catch (e) {
      debugPrint('Gagal ekstrak kuesioner: $e');
    }

    if (extractedQuestions.isEmpty) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak ditemukan butir kuesioner pada halaman ini. Pastikan Anda berada pada formulir evaluasi dosen/mata kuliah.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    QuestionnaireSolverDialog.show(
      context: context,
      pageTitle: _pageTitle,
      questions: extractedQuestions,
      hasFeedbackField: hasFeedbackField,
      onAnalyzeAi: (qs, cName) => context
          .read<AiProvider>()
          .analyzeQuestionnaire(questions: qs, courseName: cName),
      onApplyQuestionnaire: _highlightQuestionnaireInWebview,
    );
  }

  Future<int> _highlightQuestionnaireInWebview({
    required List<Map<String, dynamic>> answers,
    required String feedback,
    required bool autoCheck,
  }) async {
    try {
      final js = PortalJsScripts.buildHighlightQuestionnaireScript(
        answers: answers,
        feedback: feedback,
        autoCheck: autoCheck,
      );
      final raw = await _controller.runJavaScriptReturningResult(js);
      final resStr = raw.toString();
      return int.tryParse(resStr) ?? answers.length;
    } catch (e) {
      debugPrint('Gagal menerapkan kuesioner di webview: $e');
      return 0;
    }
  }

  void _toggleSplitAiOverlay() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isSplitAiOpen && !_isSplitAiMinimized) {
        _isSplitAiOpen = false;
        _isSplitAiMinimized = false;
      } else {
        _isSplitAiOpen = true;
        _isSplitAiMinimized = false;
      }
    });
  }

  void _cycleSplitAiHeightPreset() {
    HapticFeedback.selectionClick();
    final current = _splitAiRatioNotifier.value;
    if (current < 0.40) {
      _splitAiRatioNotifier.value = 0.50;
    } else if (current < 0.58) {
      _splitAiRatioNotifier.value = 0.65;
    } else {
      _splitAiRatioNotifier.value = 0.35;
    }
  }

  Future<String> _extractSelectedTextFromActiveWebView() async {
    try {
      final raw = await _activeController.runJavaScriptReturningResult(
        r'''(function() {
          var sel = window.getSelection ? window.getSelection().toString().trim() : '';
          return sel;
        })()''',
      );
      String text = raw.toString();
      if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
        text = jsonDecode(text);
      }
      return text.trim();
    } catch (e) {
      debugPrint('Gagal ekstrak seleksi teks: $e');
      return '';
    }
  }

  Future<String> _buildCurrentPagePrompt() async {
    String pageSnippet = '';
    try {
      final raw = await _activeController.runJavaScriptReturningResult(
        r'''(function() {
          var sel = window.getSelection ? window.getSelection().toString().trim() : '';
          if (sel && sel.length > 5) return "TEKS_DISOROT:\n" + sel;
          var main = document.querySelector('[role="main"], #region-main, main, .card-body, article');
          if (main) return main.innerText.substring(0, 1800).trim();
          return document.body ? document.body.innerText.substring(0, 1800).trim() : '';
        })()''',
      );
      pageSnippet = raw.toString();
      if (pageSnippet.startsWith('"') && pageSnippet.endsWith('"')) {
        pageSnippet = jsonDecode(pageSnippet);
      }
    } catch (e) {
      debugPrint('Ekstraksi teks gagal: $e');
    }

    final activeTitle = _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
    final portalName =
        _currentNavIndex == 1 ? 'MyUnpam (SIAKAD)' : 'Mentari (LMS)';

    if (pageSnippet.isNotEmpty) {
      return 'Saya sedang berada di halaman $portalName "$activeTitle". Berikut isi konteks halamannya:\n"""\n$pageSnippet\n"""\nTolong rangkum poin intinya dan beri arahan apa yang harus saya lakukan sebagai mahasiswa.';
    } else {
      return 'Saya sedang membuka halaman portal perkuliahan $portalName "$activeTitle".';
    }
  }

  Future<void> _openFullScreenAiAssistant({String? initialPrompt}) async {
    final activeTitle = _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
    context.read<AiProvider>().setSelectedCourse(activeTitle);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(
          initialPrompt: initialPrompt,
        ),
      ),
    );
  }

  Future<void> _openScheduleScreen({int initialTabIndex = 0}) async {
    final previousTab = _currentNavIndex;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          initialTabIndex: initialTabIndex,
          onOpenDeadlineUrl: (url) {
            Navigator.pop(context);
            setState(() => _currentNavIndex = 0);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _navigateToUrl(url);
              }
            });
          },
          onOpenMyUnpamJadwal: () {
            Navigator.pop(context);
            _ensureMyUnpamControllerInitialized();
            setState(() => _currentNavIndex = 1);
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted && _myUnpamController != null) {
                _myUnpamController!.loadRequest(
                    Uri.parse('https://my.unpam.ac.id/data-akademik/jadwal-kuliah'));
              }
            });
          },
          onOpenMentariDeadline: () {
            Navigator.pop(context);
            setState(() => _currentNavIndex = 0);
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                _controller.loadRequest(
                    Uri.parse('https://mentari.unpam.ac.id/'));
              }
            });
          },
          onSyncSchedule: () async {
            _ensureMyUnpamControllerInitialized();
            if (_myUnpamController != null) {
              try {
                await _myUnpamController!.runJavaScript(PortalJsScripts.scheduleExtractor);
              } catch (e) {
                debugPrint('[ManualScheduleSync] Error: $e');
              }
            }
          },
          onSyncDeadline: () async {
            try {
              final res = await _controller
                  .runJavaScriptReturningResult(PortalJsScripts.deadlineExtractor);
              final str = res.toString();
              if (str.isNotEmpty && str != 'null' && str != '[]') {
                _handleExtractedDeadlines(str, isManualSync: true);
              }
            } catch (e) {
              debugPrint('[ManualDeadlineSync] Error: $e');
            }
          },
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = previousTab);
      _updateHistoryState();
    }
  }

  Future<void> _consultWithAi({bool openInSplitScreen = true}) async {
    final prompt = await _buildCurrentPagePrompt();
    if (!mounted) return;

    final activeTitle = _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
    final aiProv = context.read<AiProvider>();
    aiProv.setSelectedCourse(activeTitle);

    if (openInSplitScreen) {
      setState(() {
        _isSplitAiOpen = true;
        _isSplitAiMinimized = false;
      });
      await aiProv.sendMessage(
        prompt,
        availableCourses: [activeTitle],
      );
    } else {
      _openFullScreenAiAssistant(initialPrompt: prompt);
    }
  }

  void _handleDetectedPageContext(String rawPayload,
      {required bool isMyUnpam}) {
    try {
      final ctx = WebPageDetectedContext.fromRawJson(rawPayload);
      if (mounted) {
        setState(() {
          if (isMyUnpam) {
            _myUnpamDetectedContext = ctx;
          } else {
            _mentariDetectedContext = ctx;
          }
        });
      }
    } catch (e) {
      debugPrint('Error parsing page context payload: $e');
    }
  }

  Future<void> _injectContextualPageDetectorScript(
      WebViewController controller) async {
    try {
      await controller.runJavaScript(PortalJsScripts.contextualPageDetector);
    } catch (e) {
      debugPrint('Contextual page detector script error: $e');
    }
  }

  Future<void> _executeContextualPrimaryAction(
      WebPageDetectedContext ctx) async {
    switch (ctx.type) {
      case WebPageContextType.textSelection:
        if (ctx.selectedText.isEmpty) {
          _toggleSplitAiOverlay();
          return;
        }
        final activeTitle =
            _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
        final portalName =
            _currentNavIndex == 1 ? 'MyUnpam (SIAKAD)' : 'Mentari (LMS)';
        final aiProv = context.read<AiProvider>();
        aiProv.setSelectedCourse(activeTitle);
        setState(() {
          _isSplitAiOpen = true;
          _isSplitAiMinimized = false;
        });
        await aiProv.sendMessage(
          'Saya sedang membaca halaman $portalName "$activeTitle" dan menyoroti teks berikut:\n"""\n${ctx.selectedText}\n"""\nTolong jelaskan maksud teks/soal ini secara ringkas dan akurat.',
          availableCourses: [activeTitle],
        );
        break;
      case WebPageContextType.quiz:
        await _handleLiveQuizSolver();
        break;
      case WebPageContextType.questionnaire:
        await _handleQuestionnaireAutoFill();
        break;
      case WebPageContextType.forum:
        await _handleForumAutoDraft();
        break;
      case WebPageContextType.document:
        if (ctx.documentUrl == '__DOM_CLICK_DOC_BTN__') {
          try {
            await _activeController.runJavaScript(r'''
              (function() {
                var btn = document.querySelector('[data-unpam-quick-doc-btn="1"]');
                if (btn) {
                  btn.click();
                }
              })();
            ''');
          } catch (e) {
            debugPrint('Error clicking DOM doc button: $e');
          }
        } else if (ctx.documentUrl.isNotEmpty) {
          await _handleAcademicFileDownload(
            ctx.documentUrl,
            customName: ctx.label.isNotEmpty ? ctx.label : null,
          );
        } else {
          await _consultWithAi(openInSplitScreen: true);
        }
        break;
      case WebPageContextType.academicScheduleOrGrades:
        await _consultWithAi(openInSplitScreen: true);
        break;
      case WebPageContextType.none:
        _showAiPowerToolsMenu();
        break;
    }
  }

  VoidCallback? _getContextualSecondaryAction(WebPageDetectedContext ctx) {
    switch (ctx.type) {
      case WebPageContextType.textSelection:
        return () {
          final activeTitle =
              _currentNavIndex == 1 ? _myUnpamPageTitle : _pageTitle;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiParaphraseScreen(
                initialText: ctx.selectedText,
                courseName: activeTitle,
              ),
            ),
          );
        };
      case WebPageContextType.document:
        return () => _consultWithAi(openInSplitScreen: true);
      case WebPageContextType.quiz:
      case WebPageContextType.forum:
        return _toggleSplitAiOverlay;
      case WebPageContextType.questionnaire:
      case WebPageContextType.academicScheduleOrGrades:
      case WebPageContextType.none:
        return null;
    }
  }

  String? _getContextualSecondaryLabel(WebPageDetectedContext ctx) {
    switch (ctx.type) {
      case WebPageContextType.textSelection:
        return 'Parafrase';
      case WebPageContextType.document:
        return 'Rangkum AI';
      case WebPageContextType.quiz:
      case WebPageContextType.forum:
        return _isSplitAiOpen && !_isSplitAiMinimized
            ? 'Tutup Split'
            : 'Split AI';
      case WebPageContextType.questionnaire:
      case WebPageContextType.academicScheduleOrGrades:
      case WebPageContextType.none:
        return null;
    }
  }

  IconData? _getContextualSecondaryIcon(WebPageDetectedContext ctx) {
    switch (ctx.type) {
      case WebPageContextType.textSelection:
        return Icons.auto_fix_high_rounded;
      case WebPageContextType.document:
        return Icons.summarize_rounded;
      case WebPageContextType.quiz:
      case WebPageContextType.forum:
        return Icons.vertical_split_rounded;
      case WebPageContextType.questionnaire:
      case WebPageContextType.academicScheduleOrGrades:
      case WebPageContextType.none:
        return null;
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isRefreshing) return;
    _dragStartY = event.position.dy;
    _dragStartX = event.position.dx;
    _wasAtTopOnDown = _isAtTop;
    _isPullingNotifier.value = false;
    _pullDistanceNotifier.value = 0.0;
    _hasHapticed = false;

    _activeController
        .runJavaScriptReturningResult(
            'window.scrollY || document.documentElement.scrollTop || 0;')
        .then((res) {
      final num? y = num.tryParse(res.toString());
      if (y != null && mounted) {
        final atTop = y <= 2;
        if (atTop != _isAtTop) {
          _isAtTop = atTop;
          if (!_isPullingNotifier.value) {
            _wasAtTopOnDown = atTop;
          }
        }
      }
    }).catchError((e) {
      debugPrint('Scroll query error: $e');
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isRefreshing || _dragStartY == null || _dragStartX == null) return;

    if (!_wasAtTopOnDown || !_isAtTop) {
      if (_isPullingNotifier.value) {
        _isPullingNotifier.value = false;
        _pullDistanceNotifier.value = 0.0;
      }
      return;
    }

    final double deltaY = event.position.dy - _dragStartY!;
    final double deltaX = (event.position.dx - _dragStartX!).abs();

    if (deltaX > deltaY && !_isPullingNotifier.value) {
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

      _isPullingNotifier.value = true;
      _pullDistanceNotifier.value = calculated;
    } else {
      if (_isPullingNotifier.value) {
        _isPullingNotifier.value = false;
        _pullDistanceNotifier.value = 0.0;
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

    if (_isPullingNotifier.value) {
      if (_pullDistanceNotifier.value >= _refreshTriggerDistance) {
        _startRefresh();
      } else {
        _isPullingNotifier.value = false;
        _pullDistanceNotifier.value = 0.0;
      }
    }
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing) return;
    _hasShownDeadlineSnackbarThisSession = false;
    _hasShownScheduleSnackbarThisSession = false;
    setState(() => _isRefreshing = true);
    _isPullingNotifier.value = false;
    _pullDistanceNotifier.value = 0.0;

    try {
      await _activeController.reload();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _isRefreshing) {
        setState(() => _isRefreshing = false);
      }
    });
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
            // Progress Bar menggunakan ValueListenableBuilder terisolasi (0 overhead)
            _buildLinearProgressBar(),

            // Konten Utama: WebView + Split-Screen / Floating Mini AI Overlay
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final activeContext = _activeDetectedContext;
                  final double estimatedWidth =
                      activeContext.hasActiveContext ? 148.0 : 118.0;
                  const double buttonHeight = 40.0;
                  final double maxW = constraints.maxWidth;
                  final double maxH = constraints.maxHeight;

                  _fabOffsetNotifier.value ??= Offset(
                    (maxW - estimatedWidth - 14.0).clamp(8.0, maxW),
                    (maxH - buttonHeight - 16.0).clamp(8.0, maxH),
                  );

                  final bool showDockedSplitAi =
                      _isSplitAiOpen && !_isSplitAiMinimized;
                  final double minTopWebViewHeight =
                      maxH < 340 ? maxH * 0.25 : 115.0;
                  final double maxAllowedPanelHeight =
                      (maxH - minTopWebViewHeight).clamp(150.0, maxH);
                  final double minAllowedPanelHeight =
                      maxAllowedPanelHeight < 210.0
                          ? maxAllowedPanelHeight
                          : 210.0;

                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Bagian Atas: Portal WebView dengan RepaintBoundary
                          Expanded(
                            child: Stack(
                              children: [
                                RepaintBoundary(
                                  child: IndexedStack(
                                    index: _currentNavIndex == 1 ? 1 : 0,
                                    children: [
                                      // Tab 0: Mentari
                                      Listener(
                                        behavior: HitTestBehavior.translucent,
                                        onPointerDown: _onPointerDown,
                                        onPointerMove: _onPointerMove,
                                        onPointerUp: _onPointerUp,
                                        onPointerCancel: _onPointerCancel,
                                        child: WebViewWidget(
                                            controller: _controller),
                                      ),
                                      // Tab 1: MyUnpam
                                      _myUnpamController != null
                                          ? Listener(
                                              behavior:
                                                  HitTestBehavior.translucent,
                                              onPointerDown: _onPointerDown,
                                              onPointerMove: _onPointerMove,
                                              onPointerUp: _onPointerUp,
                                              onPointerCancel: _onPointerCancel,
                                              child: WebViewWidget(
                                                  controller:
                                                      _myUnpamController!),
                                            )
                                          : const Center(
                                              child: CircularProgressIndicator(
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),

                                // Floating Pull-to-Refresh Indicator
                                PortalPullRefreshIndicator(
                                  pullDistanceNotifier: _pullDistanceNotifier,
                                  isPullingNotifier: _isPullingNotifier,
                                  isRefreshing: _isRefreshing,
                                  triggerDistance: _refreshTriggerDistance,
                                ),

                                // Tampilan Offline / Gagal Muat
                                if ((_currentNavIndex == 0 && _hasError) ||
                                    (_currentNavIndex == 1 && _myUnpamHasError))
                                  _buildErrorView(maxH),

                                // Banner Pemulihan jika terdeteksi Layar Putih / SPA Blank
                                if (_currentNavIndex == 0 &&
                                    _isWhiteScreenDetected &&
                                    !_hasError &&
                                    !_isLoading)
                                  WhiteScreenRecoveryBanner(
                                    onRefresh: () {
                                      setState(
                                          () => _isWhiteScreenDetected = false);
                                      _startRefresh();
                                    },
                                    onResetSession: _resetMentariSession,
                                  ),
                              ],
                            ),
                          ),

                          // Bagian Bawah: Split-Screen / Mini AI Overlay Panel dengan isolasi rasio
                          if (showDockedSplitAi)
                            ValueListenableBuilder<double>(
                              valueListenable: _splitAiRatioNotifier,
                              builder: (context, ratio, _) {
                                final effectiveSplitHeight = (maxH * ratio)
                                    .clamp(minAllowedPanelHeight,
                                        maxAllowedPanelHeight);

                                return SizedBox(
                                  height: effectiveSplitHeight,
                                  width: double.infinity,
                                  child: MiniAiOverlayPanel(
                                    activePortalName: _currentNavIndex == 1
                                        ? 'MyUnpam'
                                        : 'Mentari',
                                    activePageTitle: _currentNavIndex == 1
                                        ? _myUnpamPageTitle
                                        : _pageTitle,
                                    detectedContext: activeContext,
                                    onContextualPrimaryAction: () =>
                                        _executeContextualPrimaryAction(
                                            activeContext),
                                    onContextualSecondaryAction:
                                        _getContextualSecondaryAction(
                                            activeContext),
                                    contextualSecondaryLabel:
                                        _getContextualSecondaryLabel(
                                            activeContext),
                                    onClose: () {
                                      setState(() {
                                        _isSplitAiOpen = false;
                                        _isSplitAiMinimized = false;
                                      });
                                    },
                                    onMinimize: () {
                                      setState(
                                          () => _isSplitAiMinimized = true);
                                    },
                                    onExpandFullScreen: () {
                                      _openFullScreenAiAssistant();
                                    },
                                    onOpenPowerTools: _showAiPowerToolsMenu,
                                    onExtractCurrentPage: () =>
                                        _consultWithAi(openInSplitScreen: true),
                                    onExtractSelectedText:
                                        _extractSelectedTextFromActiveWebView,
                                    onInjectToWebView: _injectForumReply,
                                    onDragResizeDelta: (deltaY) {
                                      if (maxH <= 0) return;
                                      final nextRatio = ratio - (deltaY / maxH);
                                      _splitAiRatioNotifier.value =
                                          nextRatio.clamp(0.28, 0.78);
                                    },
                                    onCycleHeightPreset:
                                        _cycleSplitAiHeightPreset,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),

                      // Pill Mengambang saat Split-Screen AI diperkecil
                      if (_isSplitAiOpen && _isSplitAiMinimized)
                        MinimizedSplitAiPill(
                          onTapRestore: () {
                            setState(() => _isSplitAiMinimized = false);
                          },
                          onOpenPowerTools: _showAiPowerToolsMenu,
                          onClose: () {
                            setState(() {
                              _isSplitAiOpen = false;
                              _isSplitAiMinimized = false;
                            });
                          },
                        ),

                      // In-Page Quick Action Floating Pill (Rebuild terisolasi per frame)
                      if (!_isSplitAiOpen)
                        ValueListenableBuilder<Offset?>(
                          valueListenable: _fabOffsetNotifier,
                          builder: (context, fabOffset, _) {
                            final currentFab = fabOffset ??
                                Offset(
                                  (maxW - estimatedWidth - 14.0)
                                      .clamp(8.0, maxW),
                                  (maxH - buttonHeight - 16.0).clamp(8.0, maxH),
                                );

                            final safeX = currentFab.dx.clamp(
                              8.0,
                              (maxW - estimatedWidth - 8.0).clamp(8.0, maxW),
                            );
                            final safeY = currentFab.dy.clamp(
                              8.0,
                              (maxH - buttonHeight - 8.0).clamp(8.0, maxH),
                            );

                            return Positioned(
                              left: safeX,
                              top: safeY,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: (maxW - 16.0).clamp(110.0, maxW),
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _isDraggingFabNotifier,
                                  builder: (context, isDragging, _) {
                                    return InPageQuickActionPill(
                                      detectedContext: activeContext,
                                      isDragging: isDragging,
                                      onPanStart: (_) {
                                        _isDraggingFabNotifier.value = true;
                                      },
                                      onPanUpdate: (details) {
                                        final nextX = (currentFab.dx +
                                                details.delta.dx)
                                            .clamp(
                                                8.0,
                                                (maxW - estimatedWidth - 8.0)
                                                    .clamp(8.0, maxW));
                                        final nextY =
                                            (currentFab.dy + details.delta.dy)
                                                .clamp(
                                                    8.0,
                                                    (maxH - buttonHeight - 8.0)
                                                        .clamp(8.0, maxH));
                                        _fabOffsetNotifier.value =
                                            Offset(nextX, nextY);
                                      },
                                      onPanEnd: (_) {
                                        _isDraggingFabNotifier.value = false;
                                      },
                                      onPanCancel: () {
                                        _isDraggingFabNotifier.value = false;
                                      },
                                      onPrimaryAction: () =>
                                          _executeContextualPrimaryAction(
                                              activeContext),
                                      onSecondaryAction:
                                          _getContextualSecondaryAction(
                                              activeContext),
                                      secondaryActionLabel:
                                          _getContextualSecondaryLabel(
                                              activeContext),
                                      secondaryActionIcon:
                                          _getContextualSecondaryIcon(
                                              activeContext),
                                      onOpenAllTools: _showAiPowerToolsMenu,
                                      onOpenSplitScreen: _toggleSplitAiOverlay,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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
            if ((_currentNavIndex == 0 || _currentNavIndex == 1) &&
                (_isLoginPageDetected || _isLoggedOutDetected))
              BiometricLoginBanner(
                portalName: _currentNavIndex == 1 ? 'MyUnpam' : 'Mentari',
                isLoginPageDetected: _isLoginPageDetected,
                onLoginPressed: _performBiometricLogin,
              ),
            PortalBottomNav(
              currentIndex: _currentNavIndex,
              onDestinationSelected: (idx) async {
                if (idx == 0) {
                  setState(() => _currentNavIndex = 0);
                  _updateHistoryState();
                  _detectLoginForm();
                  _injectContextualPageDetectorScript(_controller);
                } else if (idx == 1) {
                  _ensureMyUnpamControllerInitialized();
                  setState(() => _currentNavIndex = 1);
                  _updateHistoryState();
                  _detectLoginForm();
                  if (_myUnpamController != null) {
                    _injectContextualPageDetectorScript(_myUnpamController!);
                  }
                } else if (idx == 2) {
                  final previousTab = _currentNavIndex;
                  await _openFullScreenAiAssistant();
                  if (mounted) {
                    setState(() => _currentNavIndex = previousTab);
                    _updateHistoryState();
                  }
                } else if (idx == 3) {
                  await _openScheduleScreen();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearProgressBar() {
    return ValueListenableBuilder<int>(
      valueListenable:
          _currentNavIndex == 1 ? _myUnpamProgressNotifier : _progressNotifier,
      builder: (context, progress, _) {
        final isLoading =
            _currentNavIndex == 1 ? _isMyUnpamLoading : _isLoading;
        if (!isLoading && progress >= 100) {
          return const SizedBox.shrink();
        }

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(
            begin: 0,
            end: progress > 0 ? progress / 100.0 : 0,
          ),
          builder: (_, value, __) => LinearProgressIndicator(
            value: value <= 0 ? null : value,
            minHeight: 3,
            backgroundColor: Colors.transparent,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(double maxH) {
    return Container(
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
            SizedBox(height: maxH * 0.08),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 52, color: Colors.red.shade400),
            ),
            const SizedBox(height: 18),
            Text(
              _currentNavIndex == 1
                  ? 'Gagal Memuat MyUnpam'
                  : 'Gagal Memuat Mentari',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (_currentNavIndex == 1 ? _myUnpamErrorMessage : _errorMessage)
                      .isNotEmpty
                  ? (_currentNavIndex == 1
                      ? _myUnpamErrorMessage
                      : _errorMessage)
                  : 'Periksa koneksi internet Anda atau coba muat ulang.',
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
                    setState(() {
                      if (_currentNavIndex == 1) {
                        _myUnpamHasError = false;
                      } else {
                        _hasError = false;
                      }
                    });
                    _startRefresh();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Muat Ulang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _resetMentariSession(),
                  icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: const Text('Reset Sesi & Cache'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_currentNavIndex == 1) {
                      _myUnpamController?.loadRequest(Uri.parse(myUnpamUrl));
                    } else {
                      _navigateToUrl(mentariUrl);
                    }
                  },
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: Text(_currentNavIndex == 1
                      ? 'Ke Beranda MyUnpam'
                      : 'Ke Beranda Mentari'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    final bool isMyUnpam = _currentNavIndex == 1;

    return AppBar(
      elevation: 1,
      backgroundColor: AppTheme.primaryBlue,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _canGoBack
          ? IconButton(
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
              onPressed: () async {
                await _activeController.goBack();
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
                  child: Icon(
                    isMyUnpam ? Icons.badge_rounded : Icons.school_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                ),
              ),
            ),
      titleSpacing: _canGoBack ? 0 : 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  isMyUnpam ? 'MyUnpam' : 'Mentari',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMyUnpam ? 'SIAKAD' : 'LMS',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isMyUnpam
                ? (_myUnpamPageTitle.isNotEmpty
                    ? _myUnpamPageTitle
                    : 'my.unpam.ac.id')
                : (_pageTitle.isNotEmpty ? _pageTitle : 'mentari.unpam.ac.id'),
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        Consumer<BiometricProvider>(
          builder: (ctx, bioProv, _) {
            final hasCreds = bioProv.hasSavedCredentials;
            return IconButton(
              icon: Icon(
                hasCreds
                    ? Icons.fingerprint_rounded
                    : Icons.fingerprint_outlined,
                color: hasCreds ? AppTheme.accentGold : Colors.white70,
                size: 24,
              ),
              tooltip: hasCreds
                  ? 'Biometric Auto-Login Aktif (NIM: ${bioProv.savedNim})'
                  : 'Daftarkan Biometric Login',
              onPressed: () => _handleBiometricButtonTap(bioProv),
            );
          },
        ),
        IconButton(
          tooltip: 'Riwayat Rilis & Update',
          icon:
              const Icon(Icons.history_rounded, color: Colors.white, size: 21),
          onPressed: _showReleaseHistory,
        ),
        IconButton(
          tooltip: 'The PAMs AI Tools',
          icon: const Icon(Icons.auto_awesome,
              color: AppTheme.accentGold, size: 21),
          onPressed: _showAiPowerToolsMenu,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 22),
          tooltip: 'Menu Lainnya',
          onSelected: (val) {
            if (val == 'refresh') {
              _startRefresh();
            } else if (val == 'home') {
              _navigateToUrl(isMyUnpam ? myUnpamUrl : mentariUrl);
            } else if (val == 'open_browser') {
              final current = isMyUnpam ? _myUnpamCurrentUrl : _currentUrl;
              _launchExternalUrl(current.isNotEmpty
                  ? current
                  : (isMyUnpam ? myUnpamUrl : mentariUrl));
            } else if (val == 'reset_cache') {
              _resetMentariSession();
            } else if (val == 'history') {
              _showReleaseHistory();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Muat Ulang'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'home',
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text(isMyUnpam ? 'Beranda MyUnpam' : 'Beranda Mentari'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'open_browser',
              child: Row(
                children: [
                  Icon(Icons.open_in_browser_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Buka di Peramban Luar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_cache',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Reset Sesi & Cache'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Riwayat Rilis & Update'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
