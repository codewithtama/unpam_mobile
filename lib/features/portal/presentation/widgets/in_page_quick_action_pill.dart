import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unpam_mobile/theme/app_theme.dart';

enum WebPageContextType {
  none,
  textSelection,
  quiz,
  questionnaire,
  forum,
  document,
  academicScheduleOrGrades,
}

@immutable
class WebPageDetectedContext {
  final WebPageContextType type;
  final int itemCount;
  final String label;
  final String selectedText;
  final String documentUrl;
  final String pageUrl;

  const WebPageDetectedContext({
    this.type = WebPageContextType.none,
    this.itemCount = 0,
    this.label = '',
    this.selectedText = '',
    this.documentUrl = '',
    this.pageUrl = '',
  });

  static const WebPageDetectedContext empty = WebPageDetectedContext();

  bool get hasActiveContext => type != WebPageContextType.none;

  factory WebPageDetectedContext.fromRawJson(String raw) {
    try {
      String cleaned = raw.trim();
      if (cleaned.startsWith('"') && cleaned.endsWith('"') && cleaned.length >= 2) {
        cleaned = jsonDecode(cleaned) as String;
      }
      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        return WebPageDetectedContext.empty;
      }
      return WebPageDetectedContext.fromMap(decoded);
    } catch (_) {
      return WebPageDetectedContext.empty;
    }
  }

  factory WebPageDetectedContext.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? 'none').toString().toLowerCase().trim();
    final int count = (map['itemCount'] as num?)?.toInt() ?? 0;
    final String label = (map['label'] ?? '').toString().trim();
    final String selectedText = (map['selectedText'] ?? '').toString().trim();
    final String documentUrl = (map['documentUrl'] ?? '').toString().trim();
    final String pageUrl = (map['pageUrl'] ?? '').toString().trim();

    WebPageContextType parsedType;
    switch (rawType) {
      case 'selection':
        parsedType = selectedText.length >= 8
            ? WebPageContextType.textSelection
            : WebPageContextType.none;
        break;
      case 'quiz':
        parsedType = WebPageContextType.quiz;
        break;
      case 'questionnaire':
        parsedType = WebPageContextType.questionnaire;
        break;
      case 'forum':
        parsedType = WebPageContextType.forum;
        break;
      case 'document':
        parsedType = WebPageContextType.document;
        break;
      case 'academic':
        parsedType = WebPageContextType.academicScheduleOrGrades;
        break;
      default:
        parsedType = WebPageContextType.none;
    }

    return WebPageDetectedContext(
      type: parsedType,
      itemCount: count,
      label: label,
      selectedText: selectedText,
      documentUrl: documentUrl,
      pageUrl: pageUrl,
    );
  }

  String get badgeTitle {
    switch (type) {
      case WebPageContextType.textSelection:
        return 'TEKS DIBLOK';
      case WebPageContextType.quiz:
        return itemCount > 0 ? 'KUIS • $itemCount SOAL' : 'KUIS TERDETEKSI';
      case WebPageContextType.questionnaire:
        return itemCount > 0
            ? 'KUESIONER • $itemCount BUTIR'
            : 'KUESIONER DOSEN';
      case WebPageContextType.forum:
        return 'FORUM DISKUSI';
      case WebPageContextType.document:
        return 'DOKUMEN & MODUL';
      case WebPageContextType.academicScheduleOrGrades:
        return 'DATA AKADEMIK';
      case WebPageContextType.none:
        return 'AI TOOLS';
    }
  }

  String get primaryActionTitle {
    switch (type) {
      case WebPageContextType.textSelection:
        return 'Tanya AI';
      case WebPageContextType.quiz:
        return itemCount > 0 ? 'Bantu Jawab ($itemCount Soal)' : 'Bantu Jawab Kuis';
      case WebPageContextType.questionnaire:
        return itemCount > 0
            ? 'Isi Otomatis ($itemCount Butir)'
            : 'Isi Kuesioner Otomatis';
      case WebPageContextType.forum:
        return 'Buat Draf Balasan AI';
      case WebPageContextType.document:
        if (documentUrl.isNotEmpty) {
          return label.isNotEmpty ? label : 'Unduh Dokumen PDF';
        }
        return 'Rangkum Materi Ini';
      case WebPageContextType.academicScheduleOrGrades:
        return label.isNotEmpty ? 'Telaah $label' : 'Telaah Data Akademik';
      case WebPageContextType.none:
        return 'The PAMs AI Tools';
    }
  }

  String get compactActionTitle {
    switch (type) {
      case WebPageContextType.textSelection:
        return 'Tanya AI';
      case WebPageContextType.quiz:
        return itemCount > 0 ? 'Kuis ($itemCount)' : 'Kuis';
      case WebPageContextType.questionnaire:
        return itemCount > 0 ? 'Kuesioner ($itemCount)' : 'Kuesioner';
      case WebPageContextType.forum:
        return 'Draf Forum';
      case WebPageContextType.document:
        return 'Rangkum';
      case WebPageContextType.academicScheduleOrGrades:
        return 'Akademik';
      case WebPageContextType.none:
        return 'PAMs AI';
    }
  }

  IconData get primaryIcon {
    switch (type) {
      case WebPageContextType.textSelection:
        return Icons.format_quote_rounded;
      case WebPageContextType.quiz:
        return Icons.fact_check_rounded;
      case WebPageContextType.questionnaire:
        return Icons.assignment_turned_in_rounded;
      case WebPageContextType.forum:
        return Icons.forum_rounded;
      case WebPageContextType.document:
        return documentUrl.isNotEmpty
            ? Icons.download_for_offline_rounded
            : Icons.summarize_rounded;
      case WebPageContextType.academicScheduleOrGrades:
        return Icons.analytics_rounded;
      case WebPageContextType.none:
        return Icons.auto_awesome;
    }
  }

  Color get backgroundColor {
    switch (type) {
      case WebPageContextType.textSelection:
        return AppTheme.textDark;
      case WebPageContextType.quiz:
        return const Color(0xFF15803D);
      case WebPageContextType.questionnaire:
        return const Color(0xFF0F766E);
      case WebPageContextType.forum:
        return AppTheme.primaryBlue;
      case WebPageContextType.document:
        return const Color(0xFF1E40AF);
      case WebPageContextType.academicScheduleOrGrades:
        return AppTheme.primaryBlue;
      case WebPageContextType.none:
        return AppTheme.primaryBlue;
    }
  }

  Color get accentColor {
    switch (type) {
      case WebPageContextType.textSelection:
        return AppTheme.accentGold;
      case WebPageContextType.quiz:
        return AppTheme.accentGoldLight;
      case WebPageContextType.questionnaire:
        return AppTheme.accentGoldLight;
      case WebPageContextType.forum:
        return AppTheme.accentGold;
      case WebPageContextType.document:
        return AppTheme.accentGold;
      case WebPageContextType.academicScheduleOrGrades:
        return AppTheme.accentGold;
      case WebPageContextType.none:
        return AppTheme.accentGold;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebPageDetectedContext &&
        other.type == type &&
        other.itemCount == itemCount &&
        other.label == label &&
        other.selectedText == selectedText &&
        other.documentUrl == documentUrl &&
        other.pageUrl == pageUrl;
  }

  @override
  int get hashCode => Object.hash(
        type,
        itemCount,
        label,
        selectedText,
        documentUrl,
        pageUrl,
      );
}

class InPageQuickActionPill extends StatelessWidget {
  final WebPageDetectedContext detectedContext;
  final bool isDragging;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureDragCancelCallback onPanCancel;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback onOpenAllTools;
  final VoidCallback onOpenSplitScreen;

  const InPageQuickActionPill({
    super.key,
    required this.detectedContext,
    required this.isDragging,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    required this.onOpenAllTools,
    required this.onOpenSplitScreen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isContextual = detectedContext.hasActiveContext;
    final Color bgColor = detectedContext.backgroundColor;
    final Color badgeAccent = detectedContext.accentColor;

    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedScale(
        scale: isDragging ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Material(
          elevation: isDragging ? 10 : (isContextual ? 6 : 4),
          borderRadius: BorderRadius.circular(22),
          shadowColor: bgColor.withOpacity(0.45),
          color: bgColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDragging
                    ? AppTheme.accentGold
                    : (isContextual
                        ? AppTheme.accentGold.withOpacity(0.9)
                        : AppTheme.accentGold.withOpacity(0.4)),
                width: isDragging || isContextual ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle geser ringkas
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.55),
                ),
                const SizedBox(width: 4),

                // Tombol aksi utama ringkas
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onPrimaryAction();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          detectedContext.primaryIcon,
                          color: badgeAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          detectedContext.compactActionTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Aksi sekunder kontekstual (ikon mini) jika ada
                if (isContextual && onSecondaryAction != null && secondaryActionLabel != null) ...[
                  const SizedBox(width: 2),
                  Tooltip(
                    message: secondaryActionLabel!,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSecondaryAction!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          secondaryActionIcon ?? Icons.auto_fix_high_rounded,
                          size: 14,
                          color: AppTheme.accentGoldLight,
                        ),
                      ),
                    ),
                  ),
                ],

                // Divider tipis
                Container(
                  height: 16,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.white.withOpacity(0.2),
                ),

                // Tombol Menu Semua Tools AI
                Tooltip(
                  message: 'Menu The PAMs AI',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenAllTools();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        isContextual ? Icons.apps_rounded : Icons.more_vert_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContextualQuickActionBanner extends StatelessWidget {
  final WebPageDetectedContext detectedContext;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  const ContextualQuickActionBanner({
    super.key,
    required this.detectedContext,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (!detectedContext.hasActiveContext) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.accentGoldLight.withOpacity(0.65),
        border: const Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: detectedContext.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              detectedContext.primaryIcon,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terdeteksi di Layar Atas: ${detectedContext.badgeTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                if (detectedContext.type == WebPageContextType.textSelection &&
                    detectedContext.selectedText.isNotEmpty)
                  Text(
                    '"${detectedContext.selectedText}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (onSecondaryAction != null && secondaryActionLabel != null) ...[
            OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 30),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(secondaryActionLabel!),
            ),
            const SizedBox(width: 6),
          ],
          ElevatedButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(detectedContext.primaryIcon, size: 13),
            label: Text(detectedContext.primaryActionTitle),
            style: ElevatedButton.styleFrom(
              backgroundColor: detectedContext.backgroundColor,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
