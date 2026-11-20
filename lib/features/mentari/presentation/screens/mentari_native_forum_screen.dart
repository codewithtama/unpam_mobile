import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../theme/app_theme.dart';
import '../../../academic/presentation/providers/academic_portal_provider.dart';
import '../../../ai_assistant/presentation/providers/ai_provider.dart';
import '../../../ai_assistant/presentation/screens/ai_paraphrase_screen.dart';
import '../../domain/models/mentari_interactive_models.dart';
import '../../domain/models/mentari_module_model.dart';
import '../providers/mentari_provider.dart';

class MentariNativeForumScreen extends StatefulWidget {
  final MentariModuleModel module;
  final String courseTitle;
  final String sectionTitle;

  const MentariNativeForumScreen({
    super.key,
    required this.module,
    required this.courseTitle,
    required this.sectionTitle,
  });

  @override
  State<MentariNativeForumScreen> createState() => _MentariNativeForumScreenState();
}

class _MentariNativeForumScreenState extends State<MentariNativeForumScreen> {
  final TextEditingController _replyController = TextEditingController();
  List<MentariForumPostModel> _posts = [];
  bool _isLoading = true;
  bool _isDraftingAi = false;
  bool _isSending = false;

  String get _cleanTopicPrompt {
    final raw = widget.module.description ?? '';
    final cleaned = MentariQuizQuestionModel.stripHtml(raw);
    if (cleaned.isNotEmpty) return cleaned;
    return 'Diskusikan konsep dan studi kasus utama pada ${widget.sectionTitle} mata kuliah ${widget.courseTitle}.';
  }

  @override
  void initState() {
    super.initState();
    _loadForumPosts();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadForumPosts() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<MentariProvider>();
      final loaded = await provider.service.fetchForumPosts(widget.module);
      if (!mounted) return;
      setState(() {
        _posts = loaded;
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAiDraft() async {
    if (_isDraftingAi) return;
    setState(() => _isDraftingAi = true);
    try {
      final aiProv = context.read<AiProvider>();
      final draft = await aiProv.generateForumReply(
        topic: '${widget.sectionTitle} (${widget.courseTitle}): $_cleanTopicPrompt',
        courseName: widget.courseTitle,
      );
      if (!mounted) return;
      setState(() {
        _replyController.text = draft.trim();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat draf AI: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDraftingAi = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final biodata = context.read<AcademicPortalProvider>().biodata.data;
      final provider = context.read<MentariProvider>();

      final newPost = await provider.service.submitForumReply(
        widget.module,
        authorName: biodata?.namaMahasiswa ?? 'Mahasiswa UNPAM',
        authorNim: biodata?.nim ?? '',
        content: text,
      );
      provider.markModuleCompleted(widget.module.id);

      if (!mounted) return;
      setState(() {
        _posts = [..._posts, newPost];
        _replyController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggapan diskusi berhasil dikirim ke Forum Mentari!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            tooltip: 'Parafrase Akademik',
            icon: const Icon(Icons.spellcheck_rounded, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AiParaphraseScreen(courseName: widget.courseTitle),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Verifikasi Cloudflare',
            icon: const Icon(Icons.verified_user_outlined, size: 20),
            onPressed: () {
              CloudflareClearanceModal.show(
                context,
                targetUrl: ApiConstants.mentariBaseUrl,
                portalTitle: 'Mentari LMS',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Kartu Topik Diskusi Dosen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.withOpacity(0.35), width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.forum_rounded, color: Colors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Topik Forum Diskusi',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  widget.sectionTitle,
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _cleanTopicPrompt,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textDark,
                          height: 1.45,
                        ),
                      ),
                      if (widget.module.warningAlert != null &&
                          widget.module.warningAlert!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accentGold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.module.warningAlert!,
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tanggapan Diskusi (${_posts.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isDraftingAi ? null : _generateAiDraft,
                      icon: _isDraftingAi
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.accentGold),
                      label: Text(
                        _isDraftingAi ? 'Menyusun Draf...' : 'Buat Draf AI',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_posts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada tanggapan diskusi di pertemuan ini.\nGunakan tombol "Buat Draf AI" di atas untuk menyusun tanggapan akademis pertama Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  ..._posts.map((post) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                                child: Text(
                                  post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.authorName,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(post.createdAt),
                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post.content,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Composer Balasan Native
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tulis tanggapan diskusi akademis Anda...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSending ? null : _sendReply,
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
