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

            // Konten Utama: WebView atau Error Fallback & Draggable AI Button
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double buttonWidth = 210.0;
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

                      // Tombol Mengambang Tanya AI (Dapat Digeser Bebas ke Mana Saja)
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
                          onTap: _consultWithAi,
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
                                      'Tanya AI Halaman Ini',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
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
