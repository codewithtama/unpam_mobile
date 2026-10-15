import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isEditingKey = false;

  @override
  void initState() {
    super.initState();
    final currentKey = context.read<AiProvider>().getGeminiApiKey();
    _apiKeyController.text = currentKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun mahasiswa?\n'
          'Sesi login Anda akan dihapus dari perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await auth.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courseProv = context.watch<CourseProvider>();
    final aiProv = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Student Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${auth.studentNim}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Mahasiswa Aktif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('Semester', courseProv.semester.isEmpty ? '-' : courseProv.semester),
                      Container(height: 24, width: 1, color: Colors.white24),
                      _buildProfileStat('Total SKS', '${courseProv.totalSks} SKS'),
                      Container(height: 24, width: 1, color: Colors.white24),
                      _buildProfileStat('Total MK', '${courseProv.courses.length} Matkul'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konfigurasi UNPAM AI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Mesin cerdas asistensi perkuliahan',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            aiProv.hasCustomApiKey ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                            color: aiProv.hasCustomApiKey ? AppTheme.successGreen : AppTheme.primaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              aiProv.hasCustomApiKey
                                  ? 'Mode Live Gemini 1.5 Flash Aktif'
                                  : 'Mode Bawaan Cerdas UNPAM Aktif (Tanpa API Key)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_isEditingKey) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            aiProv.hasCustomApiKey ? 'API Key tersimpan' : 'Ingin pakai Google Gemini API Key sendiri?',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isEditingKey = true),
                            child: Text(aiProv.hasCustomApiKey ? 'Ubah' : 'Atur API Key'),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          hintText: 'Paste Google Gemini API Key di sini...',
                          labelText: 'Google Gemini API Key (Opsional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _apiKeyController.text = aiProv.getGeminiApiKey();
                              setState(() => _isEditingKey = false);
                            },
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await aiProv.updateGeminiApiKey(_apiKeyController.text);
                              if (!mounted) return;
                              setState(() => _isEditingKey = false);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Pengaturan AI berhasil disimpan!')),
                              );
                            },
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.school_outlined, 'Institusi', 'Universitas Pamulang'),
                    const Divider(height: 16, color: AppTheme.cardBorder),
                    _buildInfoRow(Icons.laptop_chromebook_rounded, 'Program Studi', 'Teknik Informatika (S1)'),
                    const Divider(height: 16, color: AppTheme.cardBorder),
                    _buildInfoRow(Icons.verified_outlined, 'Versi Aplikasi', '1.0.0 (Native Release)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button (Aman dengan dialog)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed, size: 20),
                label: const Text(
                  'Keluar dari Akun Mahasiswa',
                  style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.dangerRed, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
