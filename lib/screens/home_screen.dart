import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/course_card.dart';
import '../widgets/sub_section_tile.dart';
import 'course_detail_screen.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  DateTime? _lastBackPressTime;
  String _courseSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadUserCourses();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Menangani gesture swipe back / tombol kembali agar TIDAK tiba-tiba keluar aplikasi atau logout
  void _handleBackGesture(bool didPop, dynamic result) {
    if (didPop) return;

    // Jika sedang di tab lain (Tugas, AI, atau Profil), kembalikan dulu ke tab Beranda
    if (_currentIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Jika sudah di tab Beranda, minta konfirmasi swipe/tekan kedua dalam 2 detik
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan atau geser sekali lagi untuk keluar dari aplikasi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Hanya keluar dari aplikasi jika sengaja ditekan 2x (tidak logout)
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final courseProv = context.watch<CourseProvider>();
    final pendingCount = courseProv.pendingTasks.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBackGesture,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildCoursesDashboardTab(),
            _buildPendingTasksTab(),
            const AiAssistantScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() => _currentIndex = idx);
            _pageController.animateToPage(
              idx,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
          elevation: 4,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryLight.withOpacity(0.15),
          destinations: [
            const NavigationRequestDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryBlue),
              label: 'Beranda',
            ),
            NavigationRequestDestination(
              icon: pendingCount > 0
                  ? Badge(
                      label: Text('$pendingCount'),
                      backgroundColor: AppTheme.accentGold,
                      child: const Icon(Icons.assignment_outlined),
                    )
                  : const Icon(Icons.assignment_outlined),
              selectedIcon: pendingCount > 0
                  ? Badge(
                      label: Text('$pendingCount'),
                      backgroundColor: AppTheme.accentGold,
                      child: const Icon(Icons.assignment_rounded, color: AppTheme.primaryBlue),
                    )
                  : const Icon(Icons.assignment_rounded, color: AppTheme.primaryBlue),
              label: 'Tugas & Kuis',
            ),
            const NavigationRequestDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
              label: 'Asisten AI',
            ),
            const NavigationRequestDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 0: BERANDA / DASHBOARD =================
  Widget _buildCoursesDashboardTab() {
    final auth = context.watch<AuthProvider>();
    final courseProv = context.watch<CourseProvider>();

    final filteredCourses = courseProv.courses.where((c) {
      if (_courseSearchQuery.isEmpty) return true;
      return c.namaMataKuliah.toLowerCase().contains(_courseSearchQuery.toLowerCase()) ||
          c.namaDosen.toLowerCase().contains(_courseSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: AppTheme.accentGold, size: 22),
            SizedBox(width: 8),
            Text('UNPAM LMS Mobile'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => courseProv.loadUserCourses(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => courseProv.loadUserCourses(),
        child: courseProv.isLoading && courseProv.courses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    _buildStudentProfileHeader(auth, courseProv),

                    // Quick Banner: Beralih ke Tab Tugas & Kuis
                    _buildPendingTasksBanner(courseProv),

                    // Search Mata Kuliah
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: (val) => setState(() => _courseSearchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari mata kuliah atau nama dosen...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                        ),
                      ),
                    ),

                    // Section Title: Daftar Mata Kuliah
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mata Kuliah Semester Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${filteredCourses.length} MK',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List Kartu Mata Kuliah
                    if (courseProv.errorMessage != null && courseProv.courses.isEmpty)
                      _buildErrorState(courseProv)
                    else if (filteredCourses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('Tidak ada mata kuliah yang cocok.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCourses.length,
                        itemBuilder: (ctx, index) {
                          final course = filteredCourses[index];
                          return CourseCard(
                            course: course,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CourseDetailScreen(course: course),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStudentProfileHeader(AuthProvider auth, CourseProvider courseProv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIM: ${auth.studentNim}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  courseProv.semester.isEmpty ? 'Semester -' : 'Smstr ${courseProv.semester}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Mata Kuliah', '${courseProv.courses.length} MK'),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildStatItem('Beban SKS', '${courseProv.totalSks} SKS'),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildStatItem('Tugas Aktif', '${courseProv.pendingTasks.length} Pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksBanner(CourseProvider courseProv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => _currentIndex = 1);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_late_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Tugas & Kuis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        courseProv.pendingTasks.isNotEmpty
                            ? '${courseProv.pendingTasks.length} aktivitas belum diselesaikan'
                            : 'Buka daftar tugas & aktivitas modul',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(CourseProvider courseProv) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.dangerRed),
            const SizedBox(height: 12),
            Text(courseProv.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: courseProv.isUnauthorized ? _forceRelogin : courseProv.loadUserCourses,
                  icon: Icon(courseProv.isUnauthorized ? Icons.login_rounded : Icons.refresh_rounded, size: 18),
                  label: Text(courseProv.isUnauthorized ? 'Login Ulang (Web)' : 'Coba Lagi'),
                ),
                OutlinedButton.icon(
                  onPressed: _showManualTokenDialog,
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: const Text('Input Token Manual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualTokenDialog() async {
    final textCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    final courseProv = context.read<CourseProvider>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('Input Token Manual', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jika server menolak sesi browser (403), tempel Bearer token dari Local Storage / DevTools Mentari di sini:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tempel token eyJhbGciOi...',
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: 'Tempel dari Clipboard',
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      var t = data!.text!.trim();
                      if (t.toLowerCase().startsWith('bearer ')) {
                        t = t.substring(7).trim();
                      }
                      textCtrl.text = t;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = textCtrl.text.trim();
              if (token.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await auth.loginWithToken(token);
              if (ok && mounted) {
                await courseProv.loadUserCourses();
              }
            },
            child: const Text('Validasi & Muat Data'),
          ),
        ],
      ),
    );
    textCtrl.dispose();
  }

  Future<void> _forceRelogin() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ================= TAB 1: TUGAS & KUIS =================
  Widget _buildPendingTasksTab() {
    final courseProv = context.watch<CourseProvider>();
    final pending = courseProv.pendingTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas & Kuis'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFFBEB),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pending.isNotEmpty
                        ? 'Ditemukan ${pending.length} aktivitas kuis & tugas yang perlu Anda kerjakan.'
                        : 'Buka mata kuliah di beranda untuk memuat seluruh aktivitas pertemuan.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pending.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Semua Tugas Selesai!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tidak ada kuis atau tugas yang tertunda pada mata kuliah yang dibuka.',
                            style: TextStyle(color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _currentIndex = 0),
                            icon: const Icon(Icons.dashboard_rounded, size: 18),
                            label: const Text('Lihat Mata Kuliah'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: pending.length,
                    itemBuilder: (ctx, index) {
                      final item = pending[index];
                      return SubSectionTile(
                        item: item.subSection,
                        sectionTitle:
                            '${item.sectionTitle}${item.meetingTitle != null ? ' - ${item.meetingTitle}' : ''}',
                        onToggleCompletion: (_) {
                          courseProv.toggleTaskCompletion(item.subSection);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class NavigationRequestDestination extends NavigationDestination {
  const NavigationRequestDestination({
    super.key,
    required super.icon,
    super.selectedIcon,
    required super.label,
  });
}
