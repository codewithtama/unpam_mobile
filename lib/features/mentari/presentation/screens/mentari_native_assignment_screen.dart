import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/file_download_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../domain/models/mentari_interactive_models.dart';
import '../../domain/models/mentari_module_model.dart';
import '../providers/mentari_provider.dart';

class MentariNativeAssignmentScreen extends StatefulWidget {
  final MentariModuleModel module;
  final String courseTitle;
  final String sectionTitle;

  const MentariNativeAssignmentScreen({
    super.key,
    required this.module,
    required this.courseTitle,
    required this.sectionTitle,
  });

  @override
  State<MentariNativeAssignmentScreen> createState() =>
      _MentariNativeAssignmentScreenState();
}

class _MentariNativeAssignmentScreenState
    extends State<MentariNativeAssignmentScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _isSubmitted = false;

  String get _cleanInstructions {
    final raw = widget.module.description ?? '';
    final cleaned = MentariQuizQuestionModel.stripHtml(raw);
    if (cleaned.isNotEmpty) return cleaned;
    return 'Kerjakan penugasan terstruktur pada ${widget.sectionTitle} sesuai arahan dosen pengampu mata kuliah ${widget.courseTitle}.';
  }

  @override
  void initState() {
    super.initState();
    _isSubmitted = widget.module.isCompleted;
  }

  @override
  void dispose() {
    _answerController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _submitAssignment() {
    final answer = _answerController.text.trim();
    final link = _linkController.text.trim();
    if (answer.isEmpty && link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi jawaban teks atau tautan berkas tugas terlebih dahulu.'),
          backgroundColor: AppTheme.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<MentariProvider>().markModuleCompleted(widget.module.id);
    setState(() => _isSubmitted = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penugasan terstruktur berhasil disimpan dan ditandai selesai!'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment =
        (widget.module.fileUrl != null && widget.module.fileUrl!.isNotEmpty) ||
            widget.module.url.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.name,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.sectionTitle} • ${widget.courseTitle}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu Instruksi Tugas
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: AppTheme.accentGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.module.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            _isSubmitted ? 'Status: Telah Dikumpulkan' : 'Status: Belum Dikumpulkan',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _isSubmitted ? AppTheme.successGreen : AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Instruksi / Deskripsi Penugasan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _cleanInstructions,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                    height: 1.45,
                  ),
                ),
                if (hasAttachment) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      final target = widget.module.fileUrl ?? widget.module.url;
                      FileDownloadService().downloadAndOpenFile(
                        url: target,
                        customFileName: widget.module.fileName ?? '${widget.module.name}.pdf',
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Unduh Lampiran Soal'),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AiAssistantScreen(
                          initialPrompt:
                              'Tolong bantu jelaskan dan buatkan kerangka jawaban untuk tugas "${widget.module.name}" pada ${widget.sectionTitle} mata kuliah ${widget.courseTitle}: $_cleanInstructions',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.accentGold),
                  label: const Text('Bahas & Kerjakan Bersama The PAMs AI'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form Pengumpulan Jawaban Native
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lembar Pengumpulan Tugas',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Tautan Berkas / Google Drive / GitHub (Opsional)',
                    hintText: 'https://drive.google.com/...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _answerController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban / Catatan Penyelesaian Tugas',
                    hintText: 'Tuliskan jawaban atau ringkasan pengerjaan tugas Anda...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitAssignment,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(_isSubmitted ? 'Perbarui Pengumpulan Tugas' : 'Kirim Penugasan Sekarang'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
