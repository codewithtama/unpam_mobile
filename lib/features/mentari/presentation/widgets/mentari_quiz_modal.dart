import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';

class MentariQuizModal extends StatefulWidget {
  final String title;
  final String url;
  final String? courseCode;
  final String? sectionIdentifier;
  final String? activityName;
  final String? subtitle;

  const MentariQuizModal({
    super.key,
    required this.title,
    required this.url,
    this.courseCode,
    this.sectionIdentifier,
    this.activityName,
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String url,
    String? courseCode,
    String? sectionIdentifier,
    String? activityName,
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => MentariQuizModal(
        title: title,
        url: url,
        courseCode: courseCode,
        sectionIdentifier: sectionIdentifier,
        activityName: activityName,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<MentariQuizModal> createState() => _MentariQuizModalState();
}

class _MentariQuizModalState extends State<MentariQuizModal> {
  late final WebViewController _controller;
  late final StorageService _storage;
  int _progress = 0;
  bool _isLoading = true;

  String _resolvedUrl() {
    if (widget.url.isNotEmpty && widget.url.startsWith('http')) {
      return widget.url;
    }
    final code = widget.courseCode;
    if (code != null && code.isNotEmpty) {
      return '${ApiConstants.mentariBaseUrl}/u-courses/$code';
    }
    return '${ApiConstants.mentariBaseUrl}/';
  }

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    final targetUrl = _resolvedUrl();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _progress = p;
                _isLoading = p < 100;
              });
            }
          },
          onPageStarted: (_) async {
            await _injectSession();
          },
          onPageFinished: (_) async {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            await _injectSession();
            await _injectAutoNavigator();
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  Future<void> _injectSession() async {
    final token = _storage.getMentariToken() ?? '';
    if (token.isEmpty) return;
    try {
      await _controller.runJavaScript('''
(function(token) {
  try {
    if (token && token.length > 20) {
      localStorage.setItem('access_token', token);
      localStorage.setItem('token', token);
    }
  } catch (e) {}
})(${jsonEncode(token)});
''');
    } catch (_) {}
  }

  Future<void> _injectAutoNavigator() async {
    final secId = widget.sectionIdentifier ?? '';
    final actName = widget.activityName ?? widget.title;

    try {
      await _controller.runJavaScript('''
(function(secId, actName) {
  try {
    // 1. Expand accordion section yang dituju
    if (secId) {
      var sec = document.getElementById(secId);
      if (sec) {
        var summary = sec.querySelector('.op-accordion-summary') || sec.querySelector('button') || sec;
        summary.click();
        sec.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }

    // 2. Cari tombol/baris aktivitas kuis atau forum yang sesuai
    if (actName) {
      setTimeout(function() {
        var allNodes = Array.from(document.querySelectorAll('a, button, div, [role="button"], span, h6'));
        var nameLower = actName.toLowerCase();
        var matched = allNodes.find(function(el) {
          var t = (el.innerText || el.textContent || '').trim().toLowerCase();
          return (t === nameLower || t.indexOf(nameLower) !== -1) && !el.closest('.exclusive-scroll');
        });
        if (matched) {
          var clickable = matched.closest('button, a, div[role="button"]') || matched;
          clickable.scrollIntoView({ behavior: 'smooth', block: 'center' });
          clickable.click();
        }
      }, 700);
    }
  } catch (e) {}
})(${jsonEncode(secId)}, ${jsonEncode(actName)});
''');
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    final isQuiz = widget.title.toLowerCase().contains('pretest') ||
        widget.title.toLowerCase().contains('posttest') ||
        widget.title.toLowerCase().contains('kuis') ||
        widget.title.toLowerCase().contains('quiz') ||
        widget.title.toLowerCase().contains('ujian');

    if (!isQuiz) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Aktivitas?'),
        content: const Text(
          'Pastikan Anda telah mengirimkan jawaban atau menyelesaikan aktivitas kuis sebelum menutup tampilan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjutkan Pengerjaan'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppTheme.accentGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 1.5),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Muat Ulang Halaman',
                    onPressed: () {
                      _controller.reload();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    tooltip: 'Tutup',
                    onPressed: () async {
                      if (await _onWillPop()) {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100.0 : null,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: AppTheme.accentGold,
              ),
            // WebView Container
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
