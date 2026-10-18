import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/ai_message_model.dart';
import '../models/ai_model_config.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import 'in_page_quick_action_pill.dart';

class MiniAiOverlayPanel extends StatefulWidget {
  final String activePortalName;
  final String activePageTitle;
  final WebPageDetectedContext detectedContext;
  final VoidCallback? onContextualPrimaryAction;
  final VoidCallback? onContextualSecondaryAction;
  final String? contextualSecondaryLabel;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onExpandFullScreen;
  final VoidCallback onOpenPowerTools;
  final Future<void> Function() onExtractCurrentPage;
  final Future<String> Function() onExtractSelectedText;
  final Future<bool> Function(String text) onInjectToWebView;
  final ValueChanged<double> onDragResizeDelta;
  final VoidCallback onCycleHeightPreset;

  const MiniAiOverlayPanel({
    super.key,
    required this.activePortalName,
    required this.activePageTitle,
    this.detectedContext = WebPageDetectedContext.empty,
    this.onContextualPrimaryAction,
    this.onContextualSecondaryAction,
    this.contextualSecondaryLabel,
    required this.onClose,
    required this.onMinimize,
    required this.onExpandFullScreen,
    required this.onOpenPowerTools,
    required this.onExtractCurrentPage,
    required this.onExtractSelectedText,
    required this.onInjectToWebView,
    required this.onDragResizeDelta,
    required this.onCycleHeightPreset,
  });

  @override
  State<MiniAiOverlayPanel> createState() => _MiniAiOverlayPanelState();
}

class _MiniAiOverlayPanelState extends State<MiniAiOverlayPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  int _lastMessageCount = 0;
  bool _isExtractingSelection = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = picked.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _handleGrabSelectedText() async {
    if (_isExtractingSelection) return;
    setState(() => _isExtractingSelection = true);
    try {
      final selected = await widget.onExtractSelectedText();
      if (!mounted) return;
      if (selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Blok/sorot teks pada halaman web di atas terlebih dahulu, lalu ketuk tombol ini.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        final existing = _textController.text.trim();
        if (existing.isEmpty) {
          _textController.text =
              'Jelaskan atau bantu jawab bagian teks berikut:\n"$selected"';
        } else {
          _textController.text = '$existing\n\n"$selected"';
        }
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isExtractingSelection = false);
      }
    }
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    final hasImg = _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
    if (text.isEmpty && !hasImg) return;

    final aiProv = context.read<AiProvider>();
    final activeCourse = aiProv.selectedCourseName ?? widget.activePageTitle;
    if (aiProv.selectedCourseName == null || aiProv.selectedCourseName!.isEmpty) {
      aiProv.setSelectedCourse(widget.activePageTitle);
    }

    final imgBytes = _selectedImageBytes;
    final imgMime = _selectedImageMime;

    setState(() {
      _selectedImageBytes = null;
      _selectedImageMime = null;
    });

    aiProv.sendMessage(
      text,
      availableCourses: [activeCourse],
      imageBytes: imgBytes,
      mimeType: imgMime,
    );
    if (presetText == null) {
      _textController.clear();
    }
    _scrollToBottom();
  }

  void _showQuickModelPicker(BuildContext context, AiProvider aiProv) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_alt_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pilih Mesin AI Aktif',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        widget.onExpandFullScreen();
                      },
                      icon: const Icon(Icons.key_rounded, size: 15),
                      label: const Text(
                        'Atur API Key',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: aiProv.availableModels.map((opt) {
                      final isSelected = opt.id == aiProv.activeModel.id;
                      final hasKey = aiProv.hasKeyForModel(opt);
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(
                          opt.provider == AiProviderType.freeCloud
                              ? Icons.cloud_done_rounded
                              : Icons.auto_awesome_rounded,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                        title: Text(
                          opt.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          hasKey
                              ? 'Siap digunakan'
                              : 'Butuh API Key (Ketuk Atur API Key)',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasKey
                                ? AppTheme.successGreen
                                : AppTheme.accentGold,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryBlue,
                                size: 18,
                              )
                            : null,
                        onTap: () async {
                          if (!hasKey &&
                              opt.provider != AiProviderType.freeCloud) {
                            Navigator.pop(sheetCtx);
                            widget.onExpandFullScreen();
                            return;
                          }
                          await aiProv.setActiveModel(opt.id);
                          if (sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiProvider>();
    if (aiProv.messages.length != _lastMessageCount) {
      _lastMessageCount = aiProv.messages.length;
      _scrollToBottom();
    }

    return RepaintBoundary(
      child: Material(
        elevation: 12,
        color: AppTheme.surfaceWhite,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            border: Border(
              top: BorderSide(color: AppTheme.primaryBlue, width: 2.0),
            ),
          ),
          child: Column(
            children: [
              // 1. Draggable Split Divider & Compact Header Bar
              _buildSplitHeader(context, aiProv),

              // 1b. In-Page Quick Action Banner jika ada konteks aktif di WebView atas
              if (widget.detectedContext.hasActiveContext &&
                  widget.onContextualPrimaryAction != null)
                ContextualQuickActionBanner(
                  detectedContext: widget.detectedContext,
                  onPrimaryAction: widget.onContextualPrimaryAction!,
                  onSecondaryAction: widget.onContextualSecondaryAction,
                  secondaryActionLabel: widget.contextualSecondaryLabel,
                ),

              // 2. Contextual Live WebView Action Strip
              _buildWebContextStrip(aiProv),

              // 3. Chat Messages List
              Expanded(
                child: Container(
                  color: AppTheme.bgGrey,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: aiProv.messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = aiProv.messages[index];
                      return RepaintBoundary(
                        child: _buildCompactMessageItem(ctx, msg, aiProv),
                      );
                    },
                  ),
                ),
              ),

            // 4. Thinking Indicator
            if (aiProv.isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppTheme.accentGoldLight.withOpacity(0.55),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The PAMs AI sedang menelaah & menyusun jawaban...',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Attached Screenshot Preview
            if (_selectedImageBytes != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppTheme.bgGrey,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Screenshot siap dianalisis Vision OCR',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: AppTheme.dangerRed,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImageBytes = null;
                          _selectedImageMime = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // 6. Compact Input Bar
            _buildCompactInputBar(aiProv),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSplitHeader(BuildContext context, AiProvider aiProv) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => HapticFeedback.selectionClick(),
      onVerticalDragUpdate: (details) {
        widget.onDragResizeDelta(details.delta.dy);
      },
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        widget.onCycleHeightPreset();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 6, 6),
        decoration: const BoxDecoration(
          color: AppTheme.primaryBlue,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle Pill
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite.withOpacity(0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentGold,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Split-Screen AI',
                            style: TextStyle(
                              color: AppTheme.surfaceWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showQuickModelPicker(context, aiProv),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWhite.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    aiProv.activeModel.shortName,
                                    style: const TextStyle(
                                      color: AppTheme.accentGoldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: AppTheme.accentGoldLight,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.activePortalName} • ${widget.activePageTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.surfaceWhite.withOpacity(0.75),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: 'Menu AI Power Tools (Forum, Kuis, Kuesioner)',
                  icon: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.accentGold,
                    size: 19,
                  ),
                  onPressed: widget.onOpenPowerTools,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: 'Perkecil ke Pill Mengambang',
                  icon: const Icon(
                    Icons.minimize_rounded,
                    color: AppTheme.surfaceWhite,
                    size: 18,
                  ),
                  onPressed: widget.onMinimize,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: 'Buka Layar Penuh',
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    color: AppTheme.surfaceWhite,
                    size: 16,
                  ),
                  onPressed: widget.onExpandFullScreen,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  tooltip: 'Tutup Split-Screen AI',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.surfaceWhite,
                    size: 18,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebContextStrip(AiProvider aiProv) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        children: [
          _buildContextActionChip(
            icon: Icons.find_in_page_rounded,
            label: 'Baca Halaman Ini',
            isPrimary: true,
            onTap: aiProv.isLoading
                ? null
                : () async {
                    await widget.onExtractCurrentPage();
                    _scrollToBottom();
                  },
          ),
          _buildContextActionChip(
            icon: Icons.content_cut_rounded,
            label: _isExtractingSelection ? 'Mengambil...' : 'Ambil Teks Diblok',
            onTap: _handleGrabSelectedText,
          ),
          _buildContextActionChip(
            icon: Icons.summarize_outlined,
            label: 'Rangkum Materi',
            onTap: aiProv.isLoading
                ? null
                : () => _handleSend(
                      'Rangkum poin-poin inti dari halaman "${widget.activePageTitle}" secara singkat dan jelas.',
                    ),
          ),
          _buildContextActionChip(
            icon: Icons.quiz_outlined,
            label: 'Latihan Soal',
            onTap: aiProv.isLoading
                ? null
                : () => _handleSend(
                      'Buatkan 3 soal latihan pilihan ganda beserta pembahasannya untuk topik "${widget.activePageTitle}".',
                    ),
          ),
          _buildContextActionChip(
            icon: Icons.delete_sweep_outlined,
            label: 'Reset Chat',
            onTap: () {
              aiProv.clearChat();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContextActionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : AppTheme.bgGrey,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryBlue.withOpacity(0.35)
                  : AppTheme.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isPrimary ? AppTheme.primaryBlue : AppTheme.primaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                  color:
                      isPrimary ? AppTheme.primaryBlue : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMessageItem(
    BuildContext context,
    AiMessage msg,
    AiProvider aiProv,
  ) {
    final screenW = MediaQuery.sizeOf(context).width;

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: screenW * 0.82),
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    msg.imageBytes!,
                    width: 150,
                    height: 95,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              SelectableText(
                msg.content,
                style: const TextStyle(
                  color: AppTheme.surfaceWhite,
                  fontSize: 12.5,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: screenW * 0.92),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: AppTheme.accentGold,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'The PAMs AI',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                if (msg.id != 'welcome_msg') ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
                      final injected = await widget.onInjectToWebView(
                        msg.content,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            injected
                                ? 'Jawaban AI berhasil disematkan ke kolom editor halaman web!'
                                : 'Teks disalin ke clipboard (tidak ditemukan kolom input aktif di halaman).',
                          ),
                          backgroundColor: injected
                              ? AppTheme.successGreen
                              : AppTheme.textDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.input_rounded,
                            size: 12,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Sematkan ke Web',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jawaban disalin ke clipboard.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              msg.content,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textDark,
                height: 1.42,
              ),
            ),
            if (msg.quizItems != null && msg.quizItems!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...msg.quizItems!.asMap().entries.map((entry) {
                return _buildCompactQuizCard(
                  msg.id,
                  entry.key,
                  entry.value,
                  aiProv,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuizCard(
    String messageId,
    int qIdx,
    QuizItem quiz,
    AiProvider aiProv,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latihan ${qIdx + 1}: ${quiz.question}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          ...quiz.options.asMap().entries.map((optEntry) {
            final optIdx = optEntry.key;
            final optText = optEntry.value;
            final isSelected = quiz.userSelectedIndex == optIdx;
            final isAnswered = quiz.isAnswered;
            final isCorrect = optIdx == quiz.correctIndex;

            Color bgColor = AppTheme.surfaceWhite;
            Color borderColor = AppTheme.cardBorder;
            Color textColor = AppTheme.textDark;

            if (isAnswered) {
              if (isCorrect) {
                bgColor = AppTheme.successGreen.withOpacity(0.12);
                borderColor = AppTheme.successGreen;
                textColor = AppTheme.successGreen;
              } else if (isSelected && !isCorrect) {
                bgColor = AppTheme.dangerRed.withOpacity(0.1);
                borderColor = AppTheme.dangerRed;
                textColor = AppTheme.dangerRed;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: isAnswered
                    ? null
                    : () {
                        aiProv.answerQuizOption(
                          messageId: messageId,
                          questionIndex: qIdx,
                          selectedIndex: optIdx,
                        );
                      },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAnswered
                            ? (isCorrect
                                ? Icons.check_circle_rounded
                                : (isSelected
                                    ? Icons.cancel_rounded
                                    : Icons.radio_button_unchecked))
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: textColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (quiz.isAnswered && quiz.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Pembahasan: ${quiz.explanation}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactInputBar(AiProvider aiProv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: 'Lampirkan Screenshot Soal',
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppTheme.primaryLight,
              size: 21,
            ),
            onPressed: aiProv.isLoading ? null : _pickScreenshot,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 84),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(fontSize: 12.5),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: _selectedImageBytes != null
                      ? 'Tambahkan instruksi gambar (opsional)...'
                      : 'Tanya sambil melihat halaman ${widget.activePortalName}...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.bgGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryLight,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            height: 34,
            child: Material(
              color: aiProv.isLoading
                  ? AppTheme.textMuted.withOpacity(0.4)
                  : AppTheme.primaryBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: aiProv.isLoading ? null : () => _handleSend(),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppTheme.surfaceWhite,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
