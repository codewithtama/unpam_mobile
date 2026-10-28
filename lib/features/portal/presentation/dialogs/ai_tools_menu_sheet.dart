import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Bottom sheet menu yang menampilkan seluruh kapabilitas The PAMs AI Tools & Fitur Cerdas.
class AiToolsMenuSheet extends StatelessWidget {
  final bool isMyUnpam;
  final String pageTitle;
  final bool isSplitAiActive;
  final VoidCallback onToggleSplitAi;
  final VoidCallback onOpenForumDraft;
  final VoidCallback onOpenQuizSolver;
  final VoidCallback onOpenQuestionnaire;
  final VoidCallback onAskPageAi;
  final VoidCallback onOpenParaphrase;
  final VoidCallback onOpenBiometricVault;

  const AiToolsMenuSheet({
    super.key,
    required this.isMyUnpam,
    required this.pageTitle,
    required this.isSplitAiActive,
    required this.onToggleSplitAi,
    required this.onOpenForumDraft,
    required this.onOpenQuizSolver,
    required this.onOpenQuestionnaire,
    required this.onAskPageAi,
    required this.onOpenParaphrase,
    required this.onOpenBiometricVault,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isMyUnpam,
    required String pageTitle,
    required bool isSplitAiActive,
    required VoidCallback onToggleSplitAi,
    required VoidCallback onOpenForumDraft,
    required VoidCallback onOpenQuizSolver,
    required VoidCallback onOpenQuestionnaire,
    required VoidCallback onAskPageAi,
    required VoidCallback onOpenParaphrase,
    required VoidCallback onOpenBiometricVault,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiToolsMenuSheet(
        isMyUnpam: isMyUnpam,
        pageTitle: pageTitle,
        isSplitAiActive: isSplitAiActive,
        onToggleSplitAi: onToggleSplitAi,
        onOpenForumDraft: onOpenForumDraft,
        onOpenQuizSolver: onOpenQuizSolver,
        onOpenQuestionnaire: onOpenQuestionnaire,
        onAskPageAi: onAskPageAi,
        onOpenParaphrase: onOpenParaphrase,
        onOpenBiometricVault: onOpenBiometricVault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The PAMs AI Tools & Fitur Cerdas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isMyUnpam ? "MyUnpam SIAKAD" : "Mentari LMS"} • $pageTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.cardBorder),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAiToolTile(
                      icon: Icons.vertical_split_rounded,
                      iconColor: AppTheme.accentGold,
                      iconBgColor: AppTheme.accentGoldLight,
                      title: isSplitAiActive
                          ? 'Tutup Split-Screen AI Overlay'
                          : 'Split-Screen / Mini AI Overlay',
                      subtitle:
                          'Konsultasi AI berdampingan langsung tanpa meninggalkan halaman Mentari / MyUnpam',
                      onTap: () {
                        Navigator.pop(context);
                        onToggleSplitAi();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.forum_rounded,
                      iconColor: AppTheme.primaryBlue,
                      iconBgColor: AppTheme.primaryBlue.withOpacity(0.1),
                      title: 'AI Forum Diskusi',
                      subtitle:
                          'Kaji topik diskusi dosen dan siapkan draf argumen bernalar akademis',
                      onTap: () {
                        Navigator.pop(context);
                        onOpenForumDraft();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.fact_check_rounded,
                      iconColor: Colors.green.shade700,
                      iconBgColor: Colors.green.shade50,
                      title: 'AI Quiz Solver & Recommender',
                      subtitle:
                          'Kaji butir soal pilihan ganda bersama ulasan konsep dan opsi rujukan',
                      onTap: () {
                        Navigator.pop(context);
                        onOpenQuizSolver();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: Colors.teal.shade700,
                      iconBgColor: Colors.teal.shade50,
                      title: 'AI Pengisi Kuesioner Dosen',
                      subtitle:
                          'Deteksi butir evaluasi dosen/perkuliahan & isi otomatis sesuai preferensi',
                      onTap: () {
                        Navigator.pop(context);
                        onOpenQuestionnaire();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: AppTheme.accentGold,
                      iconBgColor: Colors.amber.shade50,
                      title: 'Tanya AI Halaman Ini (Split-Screen)',
                      subtitle:
                          'Ekstrak isi halaman dan bahas langsung di panel Split-Screen AI bawah',
                      onTap: () {
                        Navigator.pop(context);
                        onAskPageAi();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.auto_fix_high_rounded,
                      iconColor: Colors.purple.shade700,
                      iconBgColor: Colors.purple.shade50,
                      title: 'AI Parafrase Akademik',
                      subtitle:
                          'Parafrase teks tugas atau materi modul agar bebas plagiasi & bernalar ilmiah',
                      onTap: () {
                        Navigator.pop(context);
                        onOpenParaphrase();
                      },
                    ),
                    _buildAiToolTile(
                      icon: Icons.fingerprint_rounded,
                      iconColor: AppTheme.accentGold,
                      iconBgColor: Colors.amber.shade50,
                      title: 'Biometric Auto-Login Vault',
                      subtitle:
                          'Kelola akun terenkripsi & masuk otomatis dengan sidik jari',
                      onTap: () {
                        Navigator.pop(context);
                        onOpenBiometricVault();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiToolTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder.withOpacity(0.6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}
