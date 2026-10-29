import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/ai_provider.dart';
import '../../../../../screens/ai_assistant_screen.dart';
import '../../../../../screens/ai_paraphrase_screen.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/in_page_quick_action_pill.dart';
import '../../../../../widgets/mini_ai_overlay_panel.dart';
import '../../../portal/presentation/dialogs/ai_tools_menu_sheet.dart';
import '../../../portal/presentation/dialogs/forum_draft_dialog.dart';
import '../../../auth/presentation/widgets/biometric_vault_sheet.dart';

class PortalAiContext {
  final String pageTitle;
  final String label;
  final String Function() buildPageText;

  const PortalAiContext({
    required this.pageTitle,
    required this.label,
    required this.buildPageText,
  });
}

class PortalAiAssist extends StatefulWidget {
  final PortalAiContext aiContext;
  final Widget child;

  const PortalAiAssist({super.key, required this.aiContext, required this.child});

  @override
  State<PortalAiAssist> createState() => PortalAiAssistState();
}

class PortalAiAssistState extends State<PortalAiAssist> {
  static const double _pillHeight = 50;
  static const double _pillWidth = 292;
  static Offset? _sharedPillOffset;

  bool _isSplitOpen = false;
  bool _isSplitMinimized = false;
  bool _isDraggingPill = false;
  double _splitRatio = 0.46;

  void openTools() => _showTools();

  WebPageDetectedContext get _detectedContext => WebPageDetectedContext(
        type: WebPageContextType.academicScheduleOrGrades,
        label: widget.aiContext.label,
      );

  String _buildPrompt() {
    final text = widget.aiContext.buildPageText().trim();
    final clipped = text.length > 1800 ? '${text.substring(0, 1800)}...' : text;
    final buffer = StringBuffer()
      ..writeln('Saya sedang membuka halaman My UNPAM (SIAKAD): "${widget.aiContext.pageTitle}".');
    if (clipped.isEmpty) {
      buffer.writeln('Data halaman belum dimuat. Tolong berikan panduan akademik yang relevan.');
    } else {
      buffer
        ..writeln('\nBerikut data yang tampil di layar saya:\n"""\n$clipped\n"""')
        ..writeln(
            '\nTolong telaah data di atas: berikan ringkasan, hal penting yang perlu saya perhatikan, dan saran yang tepat serta ringkas.');
    }
    return buffer.toString();
  }

  void _openSplit() {
    HapticFeedback.lightImpact();
    context.read<AiProvider>().setSelectedCourse(widget.aiContext.pageTitle);
    setState(() {
      _isSplitOpen = true;
      _isSplitMinimized = false;
    });
  }

  Future<void> _reviewPage() async {
    _openSplit();
    await context.read<AiProvider>().sendMessage(
      _buildPrompt(),
      availableCourses: [widget.aiContext.pageTitle],
    );
  }

  Future<void> _openFullScreen({String? initialPrompt}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => AiAssistantScreen(initialPrompt: initialPrompt)),
    );
    if (mounted && result == 'open_split_screen') _openSplit();
  }

  void _cycleHeightPreset() {
    setState(() {
      if (_splitRatio < 0.42) {
        _splitRatio = 0.48;
      } else if (_splitRatio < 0.60) {
        _splitRatio = 0.68;
      } else {
        _splitRatio = 0.36;
      }
    });
  }

  void _showTools() {
    AiToolsMenuSheet.show(
      context: context,
      isMyUnpam: true,
      pageTitle: '${widget.aiContext.label} • ${widget.aiContext.pageTitle}',
      isSplitAiActive: _isSplitOpen && !_isSplitMinimized,
      onToggleSplitAi: () {
        if (_isSplitOpen) {
          setState(() {
            _isSplitOpen = false;
            _isSplitMinimized = false;
          });
        } else {
          _openSplit();
        }
      },
      onOpenForumDraft: () {
        final prompt = _buildPrompt();
        ForumDraftDialog.show(
          context: context,
          pageTitle: widget.aiContext.pageTitle,
          initialDraft: prompt,
          onInject: (draft) async {
            await Clipboard.setData(ClipboardData(text: draft));
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Draf balasan forum berhasil disalin ke clipboard'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return true;
          },
        );
      },
      onOpenQuizSolver: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fitur Quiz Solver aktif otomatis saat membuka sesi kuis perkuliahan di portal Mentari LMS.',
            ),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onOpenQuestionnaire: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fitur Kuesioner aktif otomatis saat membuka evaluasi dosen/perkuliahan di portal.',
            ),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onAskPageAi: _reviewPage,
      onOpenParaphrase: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiParaphraseScreen(courseName: widget.aiContext.pageTitle),
          ),
        );
      },
      onOpenBiometricVault: () => BiometricVaultSheet.show(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final pillWidth = _pillWidth.clamp(0.0, maxW - 16);

        final offset = _sharedPillOffset ?? Offset(maxW - pillWidth - 14, maxH - _pillHeight - 16);
        final safeX = offset.dx.clamp(8.0, (maxW - pillWidth - 8).clamp(8.0, maxW));
        final safeY = offset.dy.clamp(8.0, (maxH - _pillHeight - 8).clamp(8.0, maxH));

        final showDocked = _isSplitOpen && !_isSplitMinimized;
        final minTop = maxH < 340 ? maxH * 0.25 : 115.0;
        final maxPanel = (maxH - minTop).clamp(150.0, maxH);
        final minPanel = maxPanel < 210.0 ? maxPanel : 210.0;
        final panelHeight = (maxH * _splitRatio).clamp(minPanel, maxPanel);

        return Stack(
          children: [
            Column(
              children: [
                Expanded(child: widget.child),
                if (showDocked)
                  SizedBox(
                    height: panelHeight,
                    width: double.infinity,
                    child: MiniAiOverlayPanel(
                      activePortalName: 'Akademik',
                      activePageTitle: widget.aiContext.pageTitle,
                      detectedContext: _detectedContext,
                      onContextualPrimaryAction: _reviewPage,
                      onClose: () => setState(() {
                        _isSplitOpen = false;
                        _isSplitMinimized = false;
                      }),
                      onMinimize: () => setState(() => _isSplitMinimized = true),
                      onExpandFullScreen: _openFullScreen,
                      onOpenPowerTools: _showTools,
                      onExtractCurrentPage: _reviewPage,
                      onExtractSelectedText: () async => '',
                      onInjectToWebView: (_) async => false,
                      onDragResizeDelta: (deltaY) {
                        if (maxH <= 0) return;
                        setState(() {
                          _splitRatio = (_splitRatio - deltaY / maxH).clamp(0.28, 0.78);
                        });
                      },
                      onCycleHeightPreset: _cycleHeightPreset,
                    ),
                  ),
              ],
            ),
            if (_isSplitOpen && _isSplitMinimized) _buildMinimizedBar(),
            if (!_isSplitOpen)
              Positioned(
                left: safeX,
                top: safeY,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (maxW - 16).clamp(180.0, maxW)),
                  child: InPageQuickActionPill(
                    detectedContext: _detectedContext,
                    isDragging: _isDraggingPill,
                    onPanStart: (_) => setState(() => _isDraggingPill = true),
                    onPanUpdate: (details) => setState(() {
                      _sharedPillOffset = Offset(safeX, safeY) + details.delta;
                    }),
                    onPanEnd: (_) => setState(() => _isDraggingPill = false),
                    onPanCancel: () => setState(() => _isDraggingPill = false),
                    onPrimaryAction: _reviewPage,
                    onOpenAllTools: _showTools,
                    onOpenSplitScreen: _openSplit,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMinimizedBar() {
    final isLoading = context.watch<AiProvider>().isLoading;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.primaryBlue,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => _isSplitMinimized = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.75), width: 1.2),
            ),
            child: Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold),
                  )
                else
                  const Icon(Icons.vertical_split_rounded, color: AppTheme.accentGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isLoading
                        ? 'The PAMs AI sedang menyusun jawaban... (Ketuk untuk buka)'
                        : 'Split-Screen AI Disembunyikan • Ketuk untuk buka kembali',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _isSplitOpen = false;
                    _isSplitMinimized = false;
                  }),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
