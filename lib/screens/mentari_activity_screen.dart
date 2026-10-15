import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_detail_model.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'ai_assistant_screen.dart';

class MentariActivityScreen extends StatefulWidget {
  final SubSection item;
  final String? courseKode;
  final String? courseName;
  final String? sectionTitle;

  const MentariActivityScreen({
    super.key,
    required this.item,
    this.courseKode,
    this.courseName,
    this.sectionTitle,
  });

  @override
  State<MentariActivityScreen> createState() => _MentariActivityScreenState();
}

class _MentariActivityScreenState extends State<MentariActivityScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = _resolveTargetUrl();
    _initWebView();
  }

  String _resolveTargetUrl() {
    final item = widget.item;

    // 1. Jika ada link langsung (file materi, PDF, atau link luar)
    if (item.link != null && item.link!.trim().isNotEmpty) {
      return item.link!.trim();
    }

    // 2. Jika ada referensi file Sakura
    if (item.file != null && item.file!.trim().isNotEmpty) {
      final f = item.file!.trim();
      if (f.startsWith('http://') || f.startsWith('https://')) return f;
      return 'https://sakura.unpam.ac.id/api/file/$f';
    }

    // 3. Jika ada ID spesifik kuis, tugas, atau forum
    if (item.id != null && item.id!.trim().isNotEmpty) {
      final id = item.id!.trim();
      switch (item.tipe) {
        case 'QUIZ':
          return 'https://mentari.unpam.ac.id/quiz/$id';
        case 'ASSIGNMENT':
          return 'https://mentari.unpam.ac.id/assignment/$id';
        case 'FORUM':
          return 'https://mentari.unpam.ac.id/forum/$id';
        case 'QUESIONER':
          return 'https://mentari.unpam.ac.id/questionnaire/$id';
      }
    }

    // 4. Fallback ke halaman kelas mata kuliah di Mentari
    if (widget.courseKode != null && widget.courseKode!.trim().isNotEmpty) {
      return 'https://mentari.unpam.ac.id/course/${Uri.encodeComponent(widget.courseKode!.trim())}';
    }

    return 'https://mentari.unpam.ac.id/';
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ActivityBridge',
        onMessageReceived: _handleBridgeMessage,
      )
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
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
            _injectSubmissionWatcher();
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
            _injectSubmissionWatcher();
          },
          onNavigationRequest: (req) {
            // Jika link video conference (Google Meet / Zoom), buka aplikasi native
            final url = req.url.toLowerCase();
            if (url.contains('meet.google.com') || url.contains('zoom.us')) {
              launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _injectSubmissionWatcher() {
    const script = '''
(function() {
  if (window._unpamActivityWatcher) return;
  window._unpamActivityWatcher = true;

  function postMsg(data) {
    try {
      if (window.ActivityBridge) {
        window.ActivityBridge.postMessage(JSON.stringify(data));
      }
    } catch(e) {}
  }

  // Monitor interaksi submit / pengiriman jawaban
  document.addEventListener('click', function(e) {
    var el = e.target;
    if (!el) return;
    var txt = (el.innerText || el.value || '').toLowerCase();
    if (txt.includes('kirim') || txt.includes('submit') || txt.includes('simpan') || txt.includes('selesaikan')) {
      postMsg({ type: 'submission_detected', label: txt });
    }
  }, true);

  // Monitor AJAX status
  var origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.send = function() {
    this.addEventListener('load', function() {
      if (this.status >= 200 && this.status < 300) {
        if (String(this._url || '').includes('submit') || String(this._url || '').includes('quiz') || String(this._url || '').includes('answer')) {
          postMsg({ type: 'auto_completed' });
        }
      }
    });
    return origSend.apply(this, arguments);
  };
})();
''';
    _controller.runJavaScript(script);
  }

  void _handleBridgeMessage(JavaScriptMessage msg) {
    try {
      final decoded = jsonDecode(msg.message);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type']?.toString();
      if (type == 'auto_completed' || type == 'submission_detected') {
        if (!widget.item.completion && mounted) {
          context.read<CourseProvider>().toggleTaskCompletion(widget.item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aktivitas "${widget.item.judul}" terdeteksi telah dikerjakan!'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {}
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
          return document.body.innerText.substring(0, 1000);
        })()
        ''',
      );
      extracted = raw.toString();
      if (extracted.startsWith('"') && extracted.endsWith('"')) {
        extracted = jsonDecode(extracted);
      }
    } catch (_) {}

    final buffer = StringBuffer();
    buffer.writeln('Saya sedang mengerjakan tugas/kuis perkuliahan UNPAM di layar ini:');
    if (widget.courseName != null) {
      buffer.writeln('• Mata Kuliah: ${widget.courseName}');
    }
    if (widget.sectionTitle != null) {
      buffer.writeln('• Sesi Pertemuan: ${widget.sectionTitle}');
    }
    buffer.writeln('• Tipe: ${widget.item.typeLabel}');
    buffer.writeln('• Judul: ${widget.item.judul}');

    if (widget.item.warningAlert != null && widget.item.warningAlert!.isNotEmpty) {
      buffer.writeln('• Instruksi Dosen: ${widget.item.warningAlert}');
    }

    if (extracted.trim().isNotEmpty) {
      buffer.writeln('\nKonten/Pertanyaan yang tampil pada halaman saat ini:\n"""\n$extracted\n"""');
    }

    buffer.writeln(
      '\nMohon bantu saya memahami materi/soal ini, berikan pembahasan konsep akademis yang relevan, serta langkah atau draf jawaban yang tepat.',
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(initialPrompt: buffer.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.item.completion;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.judul,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.sectionTitle ?? widget.item.typeLabel,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tanya Solusi AI untuk Soal Ini',
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accentGold),
            onPressed: _consultWithAi,
          ),
          IconButton(
            tooltip: 'Muat Ulang Halaman',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress / 100.0 : null,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Banner Status Sesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.successGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sesi Chromium aktif • Terhubung tanpa blokir Cloudflare',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.successGreen.withOpacity(0.12) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? AppTheme.successGreen : const Color(0xFFFDE68A),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isCompleted ? 'Selesai' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppTheme.successGreen : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Chromium WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),

          // Action Toolbar Bawah
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _consultWithAi,
                      icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF78350F)),
                      label: const Text(
                        'Bahas Soal dengan AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<CourseProvider>().toggleTaskCompletion(widget.item);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.item.completion
                                ? 'Tugas "${widget.item.judul}" ditandai selesai!'
                                : 'Tugas "${widget.item.judul}" ditandai belum selesai.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 18,
                      color: isCompleted ? AppTheme.successGreen : AppTheme.textMuted,
                    ),
                    label: Text(
                      isCompleted ? 'Selesai' : 'Tandai Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.successGreen : AppTheme.textDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isCompleted ? AppTheme.successGreen : AppTheme.cardBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
