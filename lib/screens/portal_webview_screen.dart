import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';

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

  static const String mentariUrl = 'https://mentari.unpam.ac.id/';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
                _hasError = false;
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
                if (title != null && title.trim().isNotEmpty) {
                  _pageTitle = title.trim();
                }
              });
              _updateHistoryState();
            }
          },
          onWebResourceError: (error) {
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
                        'UNPAM AI Power Tools',
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

                // Opsi 1: Auto-Draft Forum
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
                    'Auto-Draft Balasan Forum',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Analisis pertanyaan diskusi dan masukkan draf jawaban langsung ke textarea',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleForumAutoDraft();
                  },
                ),

                // Opsi 2: Live Quiz Solver & Highlight
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
                    'Live Quiz Solver & Auto-Highlight',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Deteksi soal pilihan ganda di halaman dan beri highlight hijau pada opsi yang benar',
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

                // Opsi 4: Shortcut Navigasi Mentari
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  title: const Text(
                    'Shortcut Navigasi Mentari',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Lompat langsung ke Dashboard, Presensi, Deadline, Nilai, atau Forum',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMentariShortcutsSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMentariShortcutsSheet() {
    final shortcuts = [
      {
        'title': 'Dashboard Perkuliahan',
        'desc': 'Daftar seluruh mata kuliah aktif semester berjalan',
        'url': 'https://mentari.unpam.ac.id/my/',
        'icon': Icons.dashboard_rounded,
      },
      {
        'title': 'Presensi & Kehadiran',
        'desc': 'Daftar sesi absensi perkuliahan mingguan',
        'url': 'https://mentari.unpam.ac.id/mod/attendance/index.php',
        'icon': Icons.how_to_reg_rounded,
      },
      {
        'title': 'Kalender & Deadline Tugas',
        'desc': 'Jadwal tenggat waktu kuis, tugas, dan ujian',
        'url': 'https://mentari.unpam.ac.id/calendar/view.php',
        'icon': Icons.calendar_month_rounded,
      },
      {
        'title': 'Buku Nilai & KHS',
        'desc': 'Rekapitulasi perolehan nilai mata kuliah',
        'url': 'https://mentari.unpam.ac.id/grade/report/overview/index.php',
        'icon': Icons.grading_rounded,
      },
      {
        'title': 'Forum Diskusi',
        'desc': 'Daftar seluruh utas forum diskusi pertemuan',
        'url': 'https://mentari.unpam.ac.id/mod/forum/index.php',
        'icon': Icons.forum_rounded,
      },
      {
        'title': 'Profil Akun Portal',
        'desc': 'Biodata akun dan riwayat aktivitas portal Mentari',
        'url': 'https://mentari.unpam.ac.id/user/profile.php',
        'icon': Icons.account_circle_outlined,
      },
      {
        'title': 'Halaman Utama Mentari',
        'desc': 'Beranda depan portal resmi mentari.unpam.ac.id',
        'url': 'https://mentari.unpam.ac.id/',
        'icon': Icons.home_work_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shortcut Cepat Mentari',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Lompat langsung ke halaman portal tujuan Anda',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: shortcuts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                    itemBuilder: (context, idx) {
                      final item = shortcuts[idx];
                      final url = item['url'] as String;
                      final isCurrent = _currentUrl.startsWith(url) || _currentUrl == url;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primaryBlue.withOpacity(0.12)
                                : const Color(0xFFF2F5FA),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isCurrent ? AppTheme.primaryBlue : AppTheme.textDark,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? AppTheme.primaryBlue : AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          item['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Aktif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              )
                            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToUrl(url);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickNavChip(String label, String url, IconData icon) {
    final bool isCurrent = _currentUrl.startsWith(url) || (_currentUrl == url);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 15,
          color: isCurrent ? Colors.white : AppTheme.primaryBlue,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? Colors.white : AppTheme.textDark,
          ),
        ),
        backgroundColor: isCurrent ? AppTheme.primaryBlue : const Color(0xFFF0F4FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrent ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        visualDensity: VisualDensity.compact,
        onPressed: () => _navigateToUrl(url),
      ),
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
                    'Menganalisis topik forum di halaman web...',
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
                    'Draf Balasan Forum',
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
                        hintText: 'Tulis atau sesuaikan draf balasan forum...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Draf ini dapat langsung dimasukkan ke kolom komentar webview, atau disalin jika diperlukan.',
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
                                    ? 'Draf berhasil dimasukkan ke kolom balasan forum di webview.'
                                    : 'Kolom input belum terbuka di halaman. Teks telah otomatis disalin ke clipboard.',
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
                label: const Text('Inject ke Kolom Balasan'),
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
                    'Memindai butir soal kuis di halaman web...',
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
                                'Hasil Analisis Kuis (${questions.length} Soal)',
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
                            'Otomatis pilih (centang) radio button di webview',
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
                                            'Jawaban AI: $chosenText',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                          if (reason.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              reason,
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
                                            'Berhasil menyorot $count opsi jawaban kuis di halaman webview.',
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
                              'Terapkan ke Halaman Web',
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
              LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100.0 : null,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
              ),

            // Bar Navigasi Shortcut Cepat Mentari
            Container(
              height: 38,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                children: [
                  _buildQuickNavChip('Dashboard', 'https://mentari.unpam.ac.id/my/', Icons.dashboard_outlined),
                  _buildQuickNavChip('Presensi', 'https://mentari.unpam.ac.id/mod/attendance/index.php', Icons.how_to_reg_outlined),
                  _buildQuickNavChip('Deadline', 'https://mentari.unpam.ac.id/calendar/view.php', Icons.calendar_today_outlined),
                  _buildQuickNavChip('Nilai / KHS', 'https://mentari.unpam.ac.id/grade/report/overview/index.php', Icons.grading_outlined),
                  _buildQuickNavChip('Forum', 'https://mentari.unpam.ac.id/mod/forum/index.php', Icons.forum_outlined),
                  _buildQuickNavChip('Beranda', 'https://mentari.unpam.ac.id/', Icons.home_outlined),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

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
                      RefreshIndicator(
                        onRefresh: () async {
                          await _controller.reload();
                        },
                        child: WebViewWidget(controller: _controller),
                      ),

                      // Tampilan Offline / Gagal Muat
                      if (_hasError)
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                      _controller.reload();
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
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'M';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
        IconButton(
          tooltip: 'Shortcut Cepat Mentari',
          icon: const Icon(Icons.flash_on_rounded, size: 22, color: AppTheme.accentGold),
          onPressed: _showMentariShortcutsSheet,
        ),
        IconButton(
          tooltip: 'Muat Ulang Halaman',
          icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white),
          onPressed: () => _controller.reload(),
        ),
        Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            final initials = _getInitials(auth.studentName);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4, left: 4),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.accentGold,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFF0A235C),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
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
            } else if (val == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            }
          },
          itemBuilder: (ctx) => [
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
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Profil Mahasiswa'),
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
        } else if (idx == 2) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
          label: 'Profil',
        ),
      ],
    );
  }
}
