import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unpam_mobile/features/ai_assistant/domain/models/paraphrase_model.dart';
import 'package:unpam_mobile/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:unpam_mobile/theme/app_theme.dart';
import 'ai_assistant_screen.dart';

class AiParaphraseScreen extends StatefulWidget {
  final String? initialText;
  final String? courseName;

  const AiParaphraseScreen({
    super.key,
    this.initialText,
    this.courseName,
  });

  @override
  State<AiParaphraseScreen> createState() => _AiParaphraseScreenState();
}

class _AiParaphraseScreenState extends State<AiParaphraseScreen> {
  late final TextEditingController _inputController;
  ParaphraseMode _selectedMode = ParaphraseMode.academic;
  bool _includeCitation = false;
  bool _isLoading = false;
  String? _errorMessage;
  ParaphraseResult? _result;
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _inputController.text = data.text!.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teks berhasil ditempel dari clipboard.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard kosong.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _insertSampleText() {
    setState(() {
      _inputController.text =
          'Kecerdasan buatan atau artificial intelligence merupakan salah satu teknologi yang berkembang sangat cepat di masa sekarang. Banyak mahasiswa dan akademisi memanfaatkan AI untuk mencari informasi materi perkuliahan secara instan dan efisien. Namun demikian, ketergantungan yang berlebihan tanpa adanya verifikasi kritis dapat memicu penurunan kemampuan berpikir analitis.';
    });
  }

  Future<void> _runParaphrase() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan teks atau paragraf yang ingin diparafrase.'),
        ),
      );
      return;
    }

    final words = ParaphraseResult.countWords(text);
    if (words < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teks terlalu pendek. Minimal 4 kata untuk hasil optimal.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aiProvider = context.read<AiProvider>();
      final res = await aiProvider.paraphraseText(
        text: text,
        mode: _selectedMode,
        includeCitationAdvice: _includeCitation,
        courseName: widget.courseName,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _copyResultToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hasil parafrase berhasil disalin ke papan klip!'),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendToAiChat(String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(
          initialPrompt:
              'Tolong kaji dan berikan masukan mendalam untuk draf tulisan berikut:\n\n$content',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputWords = ParaphraseResult.countWords(_inputController.text);
    final inputChars = _inputController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Parafrase Akademik'),
        actions: [
          IconButton(
            tooltip: 'Panduan Parafrase',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showGuideDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderBanner(),
              const SizedBox(height: 16),

              // Mode Selector
              _buildModeSelector(),
              const SizedBox(height: 16),

              // Input Card
              _buildInputCard(inputWords, inputChars),
              const SizedBox(height: 12),

              // Options
              _buildOptionsRow(),
              const SizedBox(height: 16),

              // Action Button
              _buildSubmitButton(inputWords),
              const SizedBox(height: 20),

              // Error or Result Display
              if (_errorMessage != null) _buildErrorCard(),
              if (_result != null) _buildResultCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parafrase & Anti-Plagiarisme',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ubah susunan kalimat tugas & esai agar bernalar ilmiah, mengalir alami, dan lolos uji orisinalitas Turnitin.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Gaya Parafrase:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ParaphraseMode.values.map((mode) {
            final isSelected = _selectedMode == mode;
            return ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                _getModeIcon(mode),
                size: 16,
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
              ),
              label: Text(mode.title),
              selected: isSelected,
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMode = mode);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedMode.description,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getModeIcon(ParaphraseMode mode) {
    switch (mode) {
      case ParaphraseMode.academic:
        return Icons.school_rounded;
      case ParaphraseMode.humanizer:
        return Icons.fingerprint_rounded;
      case ParaphraseMode.concise:
        return Icons.compress_rounded;
      case ParaphraseMode.expansive:
        return Icons.auto_stories_rounded;
    }
  }

  Widget _buildInputCard(int inputWords, int inputChars) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Teks / Paragraf Asli',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(48, 36),
                      ),
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste_rounded, size: 14),
                      label: const Text('Tempel', style: TextStyle(fontSize: 11.5)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(48, 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _inputController.clear();
                          _result = null;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded, size: 14, color: AppTheme.dangerRed),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.dangerRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              minLines: 4,
              maxLines: 10,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, height: 1.45),
              decoration: const InputDecoration(
                hintText:
                    'Ketik atau tempel draf tugas, rangkuman materi, atau isi forum diskusi di sini...',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$inputWords kata  •  $inputChars karakter',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                InkWell(
                  onTap: _insertSampleText,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Gunakan Contoh',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: const Text(
          'Sertakan Rekomendasi Format Sitasi APA',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Tambahkan contoh referensi rujukan standar penulisan ilmiah.',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        value: _includeCitation,
        activeColor: AppTheme.primaryBlue,
        onChanged: (val) {
          setState(() => _includeCitation = val);
        },
      ),
    );
  }

  Widget _buildSubmitButton(int inputWords) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _runParaphrase,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.accentGold),
        label: Text(
          _isLoading ? 'Sedang Memproses Parafrase...' : 'Mulai Parafrase Cerdas',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gagal Melakukan Parafrase',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage ?? 'Terjadi kesalahan sistem.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _runParaphrase,
                  child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _result!;
    final diff = res.resultWordCount - res.originalWordCount;
    final diffLabel = diff == 0
        ? 'Sama panjang'
        : diff > 0
            ? '+$diff kata'
            : '$diff kata';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar Result
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.accentGold, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Hasil Parafrase',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        res.mode.title,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Text(
                    '${res.originalWordCount} ➔ ${res.resultWordCount} kata ($diffLabel)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Result Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              res.paraphrasedText,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.6,
                color: AppTheme.textDark,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Citation Advice if requested
          if (res.citationAdvice != null && res.citationAdvice!.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(14),
              color: AppTheme.bgGrey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bookmark_added_rounded, size: 16, color: AppTheme.primaryLight),
                      SizedBox(width: 6),
                      Text(
                        'Rekomendasi Format Sitasi (APA 7th Edition):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    res.citationAdvice!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toggle Comparison
          if (_showComparison) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perbandingan Teks Asli:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    res.originalText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          // Action Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  onPressed: () {
                    setState(() => _showComparison = !_showComparison);
                  },
                  icon: Icon(
                    _showComparison ? Icons.visibility_off_rounded : Icons.compare_arrows_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _showComparison ? 'Tutup Perbandingan' : 'Bandingkan Asli',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  onPressed: () => _sendToAiChat(res.paraphrasedText),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Bahas di Chat', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _copyResultToClipboard(res.paraphrasedText),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin Hasil', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text('Panduan Parafrase'),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Etika & Manfaat Parafrase Akademik:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '1. Parafrase bertujuan menyampaikan kembali gagasan penulis lain menggunakan kalimat Anda sendiri tanpa mengubah makna aslinya.\n'
                '2. Hindari hanya mengganti satu atau dua kata (synonym replacement). AI ini merombak struktur kalimat secara konseptual.\n'
                '3. Tetap cantumkan sumber rujukan atau nama penulis asli pada daftar pustaka tugas Anda agar sesuai kaidah integritas akademik.',
                style: TextStyle(fontSize: 12, height: 1.45, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
