import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../academic/presentation/providers/academic_portal_provider.dart';
import '../../../academic/presentation/providers/finance_provider.dart';
import '../../../academic/presentation/screens/academic_hub_screen.dart';
import '../../../ai_assistant/presentation/providers/ai_provider.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_paraphrase_screen.dart';
import '../../../ai_assistant/presentation/widgets/mini_ai_overlay_panel.dart';
import '../../../auth/presentation/providers/biometric_provider.dart';
import '../../../auth/presentation/widgets/biometric_vault_sheet.dart';
import '../../../mentari/presentation/providers/mentari_provider.dart';
import '../../../mentari/presentation/screens/mentari_home_screen.dart';
import '../../../schedule/data/schedule_service.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/presentation/screens/schedule_screen.dart';
import '../../../updater/data/update_checker_service.dart';
import '../../../updater/presentation/dialogs/release_history_dialog.dart';
import '../../../updater/presentation/dialogs/update_dialog.dart';
import '../dialogs/ai_tools_menu_sheet.dart';
import '../widgets/in_page_quick_action_pill.dart';
import '../widgets/minimized_split_ai_pill.dart';
import '../widgets/portal_bottom_nav.dart';

/// Halaman navigasi utama The PAMs yang menggabungkan:
/// - Tab 0: Mentari LMS Native Hub (Kursus, Pertemuan 1-21, Materi PDF)
/// - Tab 1: MyUnpam Native Hub (Biodata, IPK, SKS, SPP, 12 Layanan Akademik)
/// - Tab 2: The PAMs AI Multi-Engine & Vision OCR
class MainNavigationScreen extends StatefulWidget {
  final String initialUrl;

  const MainNavigationScreen({
    super.key,
    this.initialUrl = 'https://mentari.unpam.ac.id/',
  });

  /// Whitelist domain navigasi resmi kampus dan SSO login UNPAM.
  static bool isAllowedInAppNavigation(String url) {
    final lower = url.trim().toLowerCase();
    if (lower.startsWith('blob:') ||
        lower.startsWith('data:') ||
        lower.startsWith('about:') ||
        lower.startsWith('javascript:')) {
      return true;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();

    // Domain resmi kampus UNPAM (*.unpam.ac.id)
    if (host == 'unpam.ac.id' || host.endsWith('.unpam.ac.id')) {
      return true;
    }

    // SSO dan verifikasi bot resmi
    if (host == 'challenges.cloudflare.com' ||
        host.endsWith('.cloudflare.com') ||
        host == 'accounts.google.com' ||
        host.endsWith('.accounts.google.com') ||
        host == 'login.microsoftonline.com') {
      return true;
    }

    return false;
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentNavIndex = 0;
  DateTime? _lastBackPressTime;
  bool _isUpdateDialogShowing = false;
  final UpdateCheckerService _updateChecker = UpdateCheckerService();

  // State Notifiers untuk Floating Pill & Split AI tanpa overhead rebuild
  final ValueNotifier<Offset?> _fabOffsetNotifier = ValueNotifier<Offset?>(null);
  final ValueNotifier<bool> _isDraggingFabNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _splitAiRatioNotifier = ValueNotifier<double>(0.46);

  bool _isSplitAiOpen = false;
  bool _isSplitAiMinimized = false;

  WebPageDetectedContext get _activeDetectedContext {
    if (_currentNavIndex == 1) {
      return const WebPageDetectedContext(
        type: WebPageContextType.academicScheduleOrGrades,
        label: 'MyUnpam Akademik',
        itemCount: 12,
      );
    }
    return const WebPageDetectedContext(
      type: WebPageContextType.document,
      label: 'Mentari LMS',
      itemCount: 21,
    );
  }

  @override
  void initState() {
    super.initState();

    // Hubungkan navigasi deadline global ke Tab Mentari
    ScheduleService.globalDeadlineNavigator = (url) {
      if (!mounted) return;
      setState(() => _currentNavIndex = 0);
    };

    // Hubungkan sinkronisasi deadline global
    ScheduleService.globalDeadlineSyncer = () async {
      if (!mounted) return;
      context.read<MentariProvider>().fetchCourses(forceRefresh: true);
      context.read<ScheduleProvider>().syncDeadlinesWithMentari();
    };

    // Inisialisasi callback notifikasi update dan deadline
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScheduleScreen(
              initialTabIndex: 2,
              onOpenDeadlineUrl: (url) {
                setState(() => _currentNavIndex = 0);
              },
            ),
          ),
        );
      },
    );

    // Cek pembaruan aplikasi otomatis di background
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
    _fabOffsetNotifier.dispose();
    _isDraggingFabNotifier.dispose();
    _splitAiRatioNotifier.dispose();
    super.dispose();
  }

  Future<void> _checkAppUpdateSilently() async {
    try {
      final info = await _updateChecker.checkForUpdate();
      if (!mounted) return;
      if (info != null && info.hasUpdate && !_isUpdateDialogShowing) {
        _isUpdateDialogShowing = true;
        UpdateDialog.show(
          context: context,
          updateInfo: info,
          updateService: _updateChecker,
        )?.then((_) {
          _isUpdateDialogShowing = false;
        });
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] Cek pembaruan gagal: $e');
    }
  }

  void _openFullScreenAiAssistant({String? initialPrompt}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(initialPrompt: initialPrompt),
      ),
    );
  }

  void _toggleSplitAiOverlay() {
    setState(() {
      _isSplitAiOpen = !_isSplitAiOpen;
      _isSplitAiMinimized = false;
    });
  }

  void _cycleSplitAiHeightPreset() {
    final current = _splitAiRatioNotifier.value;
    if (current < 0.40) {
      _splitAiRatioNotifier.value = 0.50;
    } else if (current < 0.65) {
      _splitAiRatioNotifier.value = 0.75;
    } else {
      _splitAiRatioNotifier.value = 0.35;
    }
  }

  void _showAiPowerToolsMenu() {
    AiToolsMenuSheet.show(
      context: context,
      isMyUnpam: _currentNavIndex == 1,
      pageTitle: _currentNavIndex == 1 ? 'MyUnpam SIAKAD' : 'Mentari LMS',
      isSplitAiActive: _isSplitAiOpen,
      onToggleSplitAi: _toggleSplitAiOverlay,
      onOpenForumDraft: () {
        _consultWithAi(
          openInSplitScreen: true,
          customPrompt:
              'Bantu buatkan draf jawaban forum diskusi perkuliahan yang komprehensif, akademis, dan beretika ilmiah.',
        );
      },
      onOpenQuizSolver: () {
        _consultWithAi(
          openInSplitScreen: true,
          customPrompt:
              'Bantu analisis dan pecahkan soal kuis perkuliahan ini langkah demi langkah beserta dasar teorinya.',
        );
      },
      onOpenQuestionnaire: () {
        _consultWithAi(
          openInSplitScreen: true,
          customPrompt:
              'Bantu berikan evaluasi dan masukan kuesioner perkuliahan yang santun, objektif, dan konstruktif.',
        );
      },
      onAskPageAi: () => _consultWithAi(openInSplitScreen: true),
      onOpenParaphrase: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiParaphraseScreen()),
        );
      },
      onOpenBiometricVault: _showBiometricVault,
    );
  }

  Future<void> _consultWithAi({
    bool openInSplitScreen = true,
    String? customPrompt,
  }) async {
    final isMyUnpam = _currentNavIndex == 1;
    final prompt = customPrompt ??
        (isMyUnpam
            ? 'Tolong bantu telaah status akademik dan jadwal kuliah aktif saya di MyUnpam secara ringkas.'
            : 'Tolong berikan ringkasan rencana belajar dan tenggat kuis/tugas perkuliahan saya di Mentari LMS.');

    final activeTitle = isMyUnpam ? 'MyUnpam SIAKAD' : 'Mentari LMS';
    final aiProv = context.read<AiProvider>();
    aiProv.setSelectedCourse(activeTitle);

    if (openInSplitScreen) {
      setState(() {
        _isSplitAiOpen = true;
        _isSplitAiMinimized = false;
      });
      await aiProv.sendMessage(prompt, availableCourses: [activeTitle]);
    } else {
      _openFullScreenAiAssistant(initialPrompt: prompt);
    }
  }

  void _showBiometricVault() {
    BiometricVaultSheet.show(context);
  }

  Future<void> _manualCheckUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    final info = await _updateChecker.checkForUpdate();
    if (!mounted) return;
    if (info != null && info.hasUpdate) {
      UpdateDialog.show(
        context: context,
        updateInfo: info,
        updateService: _updateChecker,
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aplikasi Anda sudah dalam versi terbaru.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppTheme.primaryBlue),
                title: const Text('Riwayat Pembaruan Rilis'),
                subtitle: const Text('Lihat changelog GitHub rilis'),
                onTap: () {
                  Navigator.pop(ctx);
                  ReleaseHistoryDialog.show(
                    context: context,
                    updateService: _updateChecker,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.spellcheck_rounded, color: AppTheme.primaryBlue),
                title: const Text('AI Parafrase Akademik'),
                subtitle: const Text('Hindari plagiarisme tugas'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiParaphraseScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue),
                title: const Text('Jadwal Kuliah & Deadline'),
                subtitle: const Text('Lihat kalender tenggat tugas'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScheduleScreen(
                        onOpenDeadlineUrl: (url) {
                          setState(() => _currentNavIndex = 0);
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.system_update_rounded, color: AppTheme.accentGold),
                title: const Text('Periksa Pembaruan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _manualCheckUpdate();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    final isMyUnpam = _currentNavIndex == 1;

    return AppBar(
      elevation: 1,
      backgroundColor: AppTheme.primaryBlue,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.only(left: 14),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMyUnpam ? Icons.badge_rounded : Icons.menu_book_rounded,
              color: AppTheme.accentGold,
              size: 20,
            ),
          ),
        ),
      ),
      titleSpacing: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                ? 'Portal Akademik Mahasiswa'
                : 'Portal Pembelajaran Daring',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: isMyUnpam ? 'Segarkan Data MyUnpam' : 'Segarkan Kursus Mentari',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 21),
          onPressed: () {
            if (isMyUnpam) {
              context.read<AcademicPortalProvider>().refreshAll();
              context.read<FinanceProvider>().refresh();
              context
                  .read<ScheduleProvider>()
                  .syncScheduleWithPortal(forceRefresh: true);
            } else {
              context.read<MentariProvider>().fetchCourses(forceRefresh: true);
            }
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isMyUnpam
                    ? 'Menyegarkan data MyUnpam...'
                    : 'Menyegarkan mata kuliah Mentari...'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        Consumer<BiometricProvider>(
          builder: (ctx, bioProv, _) {
            final hasCreds = bioProv.hasSavedCredentials;
            return IconButton(
              icon: Icon(
                hasCreds ? Icons.fingerprint_rounded : Icons.fingerprint_outlined,
                color: hasCreds ? AppTheme.accentGold : Colors.white70,
                size: 22,
              ),
              tooltip: hasCreds ? 'Biometric Login Aktif' : 'Atur Biometric Vault',
              onPressed: _showBiometricVault,
            );
          },
        ),
        IconButton(
          tooltip: 'The PAMs AI Tools',
          icon: const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 22),
          onPressed: _showAiPowerToolsMenu,
        ),
        IconButton(
          tooltip: 'Menu Opsi',
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 21),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // Tutup split screen AI jika sedang terbuka
        if (_isSplitAiOpen) {
          setState(() {
            _isSplitAiOpen = false;
            _isSplitAiMinimized = false;
          });
          return;
        }

        // Kembali ke tab Mentari jika sedang di MyUnpam
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
          return;
        }

        // Konfirmasi ketukan ganda untuk keluar
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar dari aplikasi'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildTopAppBar(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final activeContext = _activeDetectedContext;
            const double estimatedWidth = 148.0;
            const double buttonHeight = 40.0;
            final double maxW = constraints.maxWidth;
            final double maxH = constraints.maxHeight;

            _fabOffsetNotifier.value ??= Offset(
              (maxW - estimatedWidth - 14.0).clamp(8.0, maxW),
              (maxH - buttonHeight - 16.0).clamp(8.0, maxH),
            );

            final bool showDockedSplitAi =
                _isSplitAiOpen && !_isSplitAiMinimized;
            final double minTopHeight = maxH < 340 ? maxH * 0.25 : 115.0;
            final double maxAllowedPanelHeight =
                (maxH - minTopHeight).clamp(150.0, maxH);
            final double minAllowedPanelHeight =
                maxAllowedPanelHeight < 210.0 ? maxAllowedPanelHeight : 210.0;

            return Stack(
              children: [
                Column(
                  children: [
                    // Konten Utama Native Tab
                    Expanded(
                      child: IndexedStack(
                        index: _currentNavIndex == 1 ? 1 : 0,
                        children: [
                          // Tab 0: Mentari LMS Native Hub
                          MentariHomeScreen(
                            onOpenExternalUrl: (url) async {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          // Tab 1: MyUnpam Native Hub
                          AcademicHubScreen(
                            isEmbedded: true,
                            onOpenDeadlineUrl: (url) {
                              setState(() => _currentNavIndex = 0);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Panel Bawah: Split-Screen AI Terisolasi
                    if (showDockedSplitAi)
                      ValueListenableBuilder<double>(
                        valueListenable: _splitAiRatioNotifier,
                        builder: (context, ratio, _) {
                          final effectiveSplitHeight = (maxH * ratio)
                              .clamp(minAllowedPanelHeight, maxAllowedPanelHeight);

                          return SizedBox(
                            height: effectiveSplitHeight,
                            width: double.infinity,
                            child: MiniAiOverlayPanel(
                              activePortalName: _currentNavIndex == 1
                                  ? 'MyUnpam'
                                  : 'Mentari',
                              activePageTitle: _currentNavIndex == 1
                                  ? 'Portal Akademik Mahasiswa'
                                  : 'Portal Pembelajaran Daring',
                              detectedContext: activeContext,
                              onContextualPrimaryAction: () =>
                                  _consultWithAi(openInSplitScreen: true),
                              onContextualSecondaryAction: _showAiPowerToolsMenu,
                              contextualSecondaryLabel: 'Menu AI Tools',
                              onClose: () {
                                setState(() {
                                  _isSplitAiOpen = false;
                                  _isSplitAiMinimized = false;
                                });
                              },
                              onMinimize: () {
                                setState(() => _isSplitAiMinimized = true);
                              },
                              onExpandFullScreen: _openFullScreenAiAssistant,
                              onOpenPowerTools: _showAiPowerToolsMenu,
                              onExtractCurrentPage: () =>
                                  _consultWithAi(openInSplitScreen: true),
                              onExtractSelectedText: () async => '',
                              onInjectToWebView: (text) async => false,
                              onCycleHeightPreset: _cycleSplitAiHeightPreset,
                              onDragResizeDelta: (deltaY) {
                                if (maxH <= 0) return;
                                final nextRatio = ratio - (deltaY / maxH);
                                _splitAiRatioNotifier.value =
                                    nextRatio.clamp(0.28, 0.78);
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),

                // Pill Mengambang saat Split-Screen AI diminimalkan
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

                // Floating Action Pill Bantuan Cerdas AI
                if (!_isSplitAiOpen)
                  ValueListenableBuilder<Offset?>(
                    valueListenable: _fabOffsetNotifier,
                    builder: (context, fabOffset, _) {
                      final currentFab = fabOffset ??
                          Offset(
                            (maxW - estimatedWidth - 14.0).clamp(8.0, maxW),
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
                                final nextX = (currentFab.dx + details.delta.dx)
                                    .clamp(8.0,
                                        (maxW - estimatedWidth - 8.0).clamp(8.0, maxW));
                                final nextY = (currentFab.dy + details.delta.dy)
                                    .clamp(8.0,
                                        (maxH - buttonHeight - 8.0).clamp(8.0, maxH));
                                _fabOffsetNotifier.value = Offset(nextX, nextY);
                              },
                              onPanEnd: (_) {
                                _isDraggingFabNotifier.value = false;
                              },
                              onPanCancel: () {
                                _isDraggingFabNotifier.value = false;
                              },
                              onPrimaryAction: () =>
                                  _consultWithAi(openInSplitScreen: true),
                              onSecondaryAction: _showAiPowerToolsMenu,
                              secondaryActionLabel: 'Menu AI Tools',
                              secondaryActionIcon: Icons.auto_awesome,
                              onOpenAllTools: _showAiPowerToolsMenu,
                              onOpenSplitScreen: _toggleSplitAiOverlay,
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: PortalBottomNav(
          currentIndex: _currentNavIndex,
          onDestinationSelected: (idx) async {
            if (idx == 0) {
              setState(() => _currentNavIndex = 0);
            } else if (idx == 1) {
              setState(() => _currentNavIndex = 1);
            } else if (idx == 2) {
              final previousTab = _currentNavIndex;
              _openFullScreenAiAssistant();
              if (mounted) {
                setState(() => _currentNavIndex = previousTab);
              }
            }
          },
        ),
      ),
    );
  }
}
