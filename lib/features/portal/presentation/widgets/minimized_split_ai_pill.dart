import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../ai_assistant/presentation/providers/ai_provider.dart';

/// Pill mengambang di pojok bawah saat panel Split-Screen AI diperkecil (minimized).
class MinimizedSplitAiPill extends StatelessWidget {
  final VoidCallback onTapRestore;
  final VoidCallback onOpenPowerTools;
  final VoidCallback onClose;

  const MinimizedSplitAiPill({
    super.key,
    required this.onTapRestore,
    required this.onOpenPowerTools,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, aiProv, _) {
        return Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.primaryBlue,
            shadowColor: AppTheme.primaryBlue.withOpacity(0.45),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.selectionClick();
                onTapRestore();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.75),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    if (aiProv.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentGold,
                        ),
                      )
                    else
                      const Icon(
                        Icons.vertical_split_rounded,
                        color: AppTheme.accentGold,
                        size: 18,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        aiProv.isLoading
                            ? 'The PAMs AI sedang menyusun jawaban... (Ketuk untuk buka)'
                            : 'Split-Screen AI Disembunyikan • Ketuk untuk buka kembali',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Menu AI Power Tools',
                      icon: const Icon(
                        Icons.bolt_rounded,
                        color: AppTheme.accentGold,
                        size: 18,
                      ),
                      onPressed: onOpenPowerTools,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Tutup Split-Screen AI',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 17,
                      ),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
