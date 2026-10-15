import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';
import 'all_pending_tasks_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load courses on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadUserCourses();
    });
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun mahasiswa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courseProv = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: AppTheme.accentGold, size: 22),
            SizedBox(width: 8),
            Text('Mentari & Sakura Mobile'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
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

                    // Quick Banner "Lihat Semua Tugas Pending"
                    _buildPendingTasksBanner(context),

                    // Section Title: Daftar Mata Kuliah
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
                              '${courseProv.courses.length} MK',
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
                    if (courseProv.errorMessage != null)
                      _buildErrorState(courseProv)
                    else if (courseProv.courses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('Tidak ada mata kuliah yang terdaftar.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courseProv.courses.length,
                        itemBuilder: (ctx, index) {
                          final course = courseProv.courses[index];
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

  String _scheduleDays(CourseProvider courseProv) {
    final days = courseProv.courses
        .map((c) => c.namaHari)
        .where((d) => d.isNotEmpty)
        .toSet();
    return days.isEmpty ? '-' : days.join(', ');
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
            ElevatedButton(
              onPressed: courseProv.isUnauthorized ? _forceRelogin : courseProv.loadUserCourses,
              child: Text(courseProv.isUnauthorized ? 'Login Ulang' : 'Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceRelogin() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

          // Stat Ringkas: Total SKS & Hari Kuliah
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
                _buildStatItem('Hari Kuliah', _scheduleDays(courseProv)),
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

  Widget _buildPendingTasksBanner(BuildContext context) {
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllPendingTasksScreen()),
            );
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Tugas & Kuis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cek semua kuis & tugas yang belum diselesaikan',
                        style: TextStyle(
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
}
