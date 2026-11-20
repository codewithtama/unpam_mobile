import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../theme/app_theme.dart';
import '../providers/mentari_provider.dart';
import '../widgets/mentari_auth_modal.dart';
import '../widgets/mentari_course_card.dart';
import 'mentari_course_detail_screen.dart';

class MentariHomeScreen extends StatefulWidget {
  final void Function(String url)? onOpenExternalUrl;

  const MentariHomeScreen({
    super.key,
    this.onOpenExternalUrl,
  });

  @override
  State<MentariHomeScreen> createState() => _MentariHomeScreenState();
}

class _MentariHomeScreenState extends State<MentariHomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MentariProvider>();
      if (!provider.hasCourses && !provider.isLoading) {
        provider.fetchCourses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleConnectMentari() async {
    final success = await MentariAuthModal.show(context);
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi Mentari LMS berhasil disinkronkan secara native!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<MentariProvider>().fetchCourses(forceRefresh: true);
    }
  }

  Future<void> _handleCloudflareVerify() async {
    final cleared = await CloudflareClearanceModal.show(
      context,
      targetUrl: ApiConstants.mentariBaseUrl,
      portalTitle: 'Mentari LMS',
    );
    if (cleared == true && mounted) {
      final provider = context.read<MentariProvider>();
      provider.clearCloudflareFlag();
      provider.fetchCourses(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentariProvider>();
    final allCourses = provider.courses;
    final filtered = _searchQuery.trim().isEmpty
        ? allCourses
        : allCourses
            .where((c) =>
                c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.cleanCode.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      color: AppTheme.bgGrey,
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppTheme.primaryBlue,
            backgroundColor: Colors.white,
            onRefresh: () => provider.fetchCourses(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      // Banner Verifikasi Cloudflare bila dibutuhkan
                      if (provider.needsCloudflareVerify)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.accentGold),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: AppTheme.accentGold),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Server Mentari meminta verifikasi Cloudflare Turnstile.',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGold,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _handleCloudflareVerify,
                                child: const Text('Verifikasi'),
                              ),
                            ],
                          ),
                        ),

                      // Hero Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: AppTheme.accentGold,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mentari LMS Native',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Pembelajaran Daring Universitas Pamulang',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Verifikasi Cloudflare Turnstile',
                                  onPressed: _handleCloudflareVerify,
                                  icon: const Icon(
                                    Icons.verified_user_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    allCourses.isEmpty
                                        ? 'Menunggu sinkronisasi kursus'
                                        : '${allCourses.length} Mata Kuliah Terdaftar',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.accentGold,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: _handleConnectMentari,
                                        icon: const Icon(Icons.key_rounded, size: 15),
                                        label: const Text('Akun', style: TextStyle(fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => provider.fetchCourses(forceRefresh: true),
                                        icon: const Icon(Icons.sync_rounded, size: 15),
                                        label: const Text('Sync', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari mata kuliah atau kode...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 18, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Mata Kuliah Semester Aktif',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Spacer(),
                          if (filtered.isNotEmpty)
                            Text(
                              '${filtered.length} Matkul',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filtered.isEmpty && !provider.isLoading)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.school_rounded, size: 48, color: AppTheme.accentGold),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak Ada Mata Kuliah Cocok'
                                    : (provider.hasActiveSession
                                        ? 'Belum Ada Data Mata Kuliah'
                                        : 'Belum Terhubung ke Mentari LMS'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Coba gunakan kata kunci pencarian yang lain.'
                                    : 'Masuk dengan akun Mentari secara native. WebView hanya akan dipanggil apabila Cloudflare membutuhkan verifikasi Turnstile.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 16),
                              if (_searchQuery.isEmpty)
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _handleConnectMentari,
                                      icon: const Icon(Icons.login_rounded, size: 18),
                                      label: const Text(
                                        'Login Native Mentari',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _handleCloudflareVerify,
                                      icon: const Icon(Icons.verified_user_rounded, size: 18),
                                      label: const Text('Verifikasi Cloudflare'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ]),
                  ),
                ),
                if (filtered.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final course = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MentariCourseCard(
                            course: course,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MentariCourseDetailScreen(course: course),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (provider.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: AppTheme.accentGold,
              ),
            ),
        ],
      ),
    );
  }
}
