import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_theme.dart';

/// Dialog untuk meninjau, menyunting, menyalin, dan menyematkan draf jawaban forum diskusi Moodle.
class ForumDraftDialog extends StatefulWidget {
  final String pageTitle;
  final String initialDraft;
  final Future<bool> Function(String text) onInject;

  const ForumDraftDialog({
    super.key,
    required this.pageTitle,
    required this.initialDraft,
    required this.onInject,
  });

  static Future<void> show({
    required BuildContext context,
    required String pageTitle,
    required String initialDraft,
    required Future<bool> Function(String text) onInject,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ForumDraftDialog(
        pageTitle: pageTitle,
        initialDraft: initialDraft,
        onInject: onInject,
      ),
    );
  }

  @override
  State<ForumDraftDialog> createState() => _ForumDraftDialogState();
}

class _ForumDraftDialogState extends State<ForumDraftDialog> {
  late final TextEditingController _draftController;
  bool _isInjecting = false;

  @override
  void initState() {
    super.initState();
    _draftController = TextEditingController(text: widget.initialDraft);
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'AI Forum Diskusi',
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
                'Mata Kuliah: ${widget.pageTitle}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _draftController,
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
                  hintText: 'Tinjau atau sesuaikan tanggapan diskusi Anda...',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tanggapan ini dapat langsung disematkan ke kolom komentar perkuliahan atau disalin.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _draftController.text));
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
          onPressed: _isInjecting
              ? null
              : () async {
                  setState(() => _isInjecting = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await widget.onInject(_draftController.text);
                  navigator.pop();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Tanggapan berhasil disematkan ke kolom komentar forum.'
                            : 'Kolom input belum terbuka di halaman. Teks telah disalin ke clipboard.',
                      ),
                      backgroundColor: success ? Colors.green.shade800 : Colors.black87,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
          icon: _isInjecting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: const Text('Sematkan ke Kolom Komentar'),
        ),
      ],
    );
  }
}
