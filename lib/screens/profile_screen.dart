import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/student_profile_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nimController;
  late TextEditingController _fakultasController;
  late TextEditingController _kelasController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  String _selectedProdi = 'Teknik Informatika (S1)';
  String _selectedShift = 'Reguler C (Malam)';
  String _selectedSemester = 'Semester 4';

  bool _isEditing = false;
  bool _isSaving = false;

  static const List<String> prodiList = [
    'Teknik Informatika (S1)',
    'Sistem Informasi (S1)',
    'Sistem Komputer (S1)',
    'Manajemen (S1)',
    'Akuntansi (S1)',
    'Ilmu Hukum (S1)',
    'Teknik Elektro (S1)',
    'Teknik Mesin (S1)',
    'Teknik Industri (S1)',
    'Teknik Kimia (S1)',
    'Sastra Inggris (S1)',
    'Sastra Indonesia (S1)',
    'Matematika (S1)',
    'Pendidikan Pancasila & Kewarganegaraan (S1)',
    'Pendidikan Ekonomi (S1)',
    'D3 Akuntansi',
    'D3 Sekretari',
    'Magister Manajemen (S2)',
    'Magister Ilmu Hukum (S2)',
  ];

  static const List<String> shiftList = [
    'Reguler A (Pagi)',
    'Reguler B (Siang)',
    'Reguler C (Malam)',
    'Reguler CK (Sabtu)',
    'Kelas Eksekutif',
  ];

  static const List<String> semesterList = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
    'Semester Akhir (Tugas Akhir/Skripsi)',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _initControllers(profile);
  }

  void _initControllers(StudentProfile profile) {
    _nameController = TextEditingController(text: profile.name);
    _nimController = TextEditingController(text: profile.nim);
    _fakultasController = TextEditingController(text: profile.fakultas);
    _kelasController = TextEditingController(text: profile.kelas);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _bioController = TextEditingController(text: profile.bio);

    _selectedProdi = prodiList.contains(profile.prodi)
        ? profile.prodi
        : prodiList.first;
    _selectedShift = shiftList.contains(profile.shift)
        ? profile.shift
        : shiftList[2];
    _selectedSemester = semesterList.contains(profile.semester)
        ? profile.semester
        : semesterList[3];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _fakultasController.dispose();
    _kelasController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    final updated = auth.profile.copyWith(
      name: _nameController.text.trim(),
      nim: _nimController.text.trim(),
      prodi: _selectedProdi,
      fakultas: _fakultasController.text.trim(),
      kelas: _kelasController.text.trim(),
      shift: _selectedShift,
      semester: _selectedSemester,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    await auth.updateProfile(updated);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Profil Mahasiswa berhasil diperbarui!'),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCancelEdit() {
    final profile = context.read<AuthProvider>().profile;
    setState(() {
      _nameController.text = profile.name;
      _nimController.text = profile.nim;
      _fakultasController.text = profile.fakultas;
      _kelasController.text = profile.kelas;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _bioController.text = profile.bio;
      _selectedProdi = prodiList.contains(profile.prodi)
          ? profile.prodi
          : prodiList.first;
      _selectedShift = shiftList.contains(profile.shift)
          ? profile.shift
          : shiftList[2];
      _selectedSemester = semesterList.contains(profile.semester)
          ? profile.semester
          : semesterList[3];
      _isEditing = false;
    });
  }

  Future<void> _handleResetProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Data Profil?'),
        content: const Text(
          'Seluruh data profil mahasiswa akan dikembalikan ke data default bawaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.resetProfileToDefault();

    if (!mounted) return;
    final defaultProfile = auth.profile;
    setState(() {
      _initControllers(defaultProfile);
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil telah di-reset ke nilai default.'),
        backgroundColor: AppTheme.textDark,
      ),
    );
  }

  Future<void> _handleClearWebCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan Cache & Cookie?'),
        content: const Text(
          'Tindakan ini akan menghapus sesi login dan cookie portal Mentari UNPAM dari web engine aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache & Cookie Webview berhasil dibersihkan.'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profil Mahasiswa' : 'Profil Mahasiswa'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit Profil',
              icon: const Icon(Icons.edit_note_rounded, size: 26),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              tooltip: 'Batal Edit',
              icon: const Icon(Icons.close_rounded),
              onPressed: _handleCancelEdit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UNPAM Digital Student Card (KTM)
            _buildStudentCard(profile),
            const SizedBox(height: 16),

            // Content Mode: Form Edit ATAU Mode Detail
            if (_isEditing)
              _buildEditForm()
            else ...[
              _buildActionToolbar(),
              const SizedBox(height: 16),
              _buildAcademicDetailCard(profile),
              const SizedBox(height: 16),
              _buildContactDetailCard(profile),
              const SizedBox(height: 16),
              _buildBioCard(profile),
              const SizedBox(height: 24),
              _buildUtilitySection(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentProfile profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A235C),
            Color(0xFF143B8A),
            Color(0xFF1E4AA8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A235C).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kampus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppTheme.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIVERSITAS PAMULANG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'KARTU TANDA MAHASISWA DIGITAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.successGreen, width: 1),
                ),
                child: Text(
                  profile.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Avatar & Identitas Inti
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.accentGold,
                child: CircleAvatar(
                  radius: 31,
                  backgroundColor: const Color(0xFF0A235C),
                  child: Text(
                    _getInitials(profile.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profile.nim));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('NIM disalin ke clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NIM: ${profile.nim}',
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              color: Colors.white60,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Detail Singkat di KTM
          Row(
            children: [
              Expanded(
                child: _buildKtmSubField('PROGRAM STUDI', profile.prodi),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKtmSubField('KELAS / SHIFT', '${profile.kelas} • ${profile.shift.split(' ').first}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKtmSubField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionToolbar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text(
          'Edit Profil Mahasiswa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildAcademicDetailCard(StudentProfile profile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.school_outlined, 'Data Akademik'),
            const SizedBox(height: 14),
            _buildInfoRow('Program Studi', profile.prodi),
            _buildDivider(),
            _buildInfoRow('Fakultas', profile.fakultas),
            _buildDivider(),
            _buildInfoRow('Kelas Mahasiswa', profile.kelas),
            _buildDivider(),
            _buildInfoRow('Shift Kuliah', profile.shift),
            _buildDivider(),
            _buildInfoRow('Semester Berjalan', profile.semester),
            _buildDivider(),
            _buildInfoRow('Status Perkuliahan', profile.status),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetailCard(StudentProfile profile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.contact_mail_outlined, 'Kontak & Komunikasi'),
            const SizedBox(height: 14),
            _buildInfoRow('Email Mahasiswa', profile.email),
            _buildDivider(),
            _buildInfoRow('No. WhatsApp / HP', profile.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildBioCard(StudentProfile profile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.lightbulb_outline_rounded, 'Catatan / Peminatan'),
            const SizedBox(height: 12),
            Text(
              profile.bio.isNotEmpty
                  ? profile.bio
                  : 'Belum ada catatan peminatan akademik.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 12, thickness: 0.7, color: AppTheme.cardBorder);
  }

  Widget _buildUtilitySection() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _handleClearWebCache,
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('Bersihkan Cache & Cookie Web Portal'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textDark,
            side: const BorderSide(color: AppTheme.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _handleResetProfile,
          icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppTheme.dangerRed),
          label: const Text(
            'Reset Profil ke Default',
            style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulir Edit Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Perbarui data identitas mahasiswa Anda',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Field Nama Lengkap
              _buildFormField(
                controller: _nameController,
                label: 'Nama Lengkap Mahasiswa',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Nama tidak boleh kosong (minimal 2 huruf)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Field NIM
              _buildFormField(
                controller: _nimController,
                label: 'Nomor Induk Mahasiswa (NIM)',
                hint: 'Contoh: 221011400123',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.trim().length < 8) {
                    return 'NIM wajib diisi (minimal 8 angka)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Dropdown Program Studi
              _buildLabel('Program Studi'),
              DropdownButtonFormField<String>(
                value: _selectedProdi,
                isExpanded: true,
                decoration: _fieldDecoration(
                  hint: 'Pilih Program Studi',
                  icon: Icons.school_outlined,
                ),
                items: prodiList.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProdi = val);
                },
              ),
              const SizedBox(height: 14),

              // Field Fakultas
              _buildFormField(
                controller: _fakultasController,
                label: 'Fakultas',
                hint: 'Contoh: Fakultas Ilmu Komputer',
                icon: Icons.account_balance_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Fakultas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Field Kelas
              _buildFormField(
                controller: _kelasController,
                label: 'Kelas Mahasiswa',
                hint: 'Contoh: 04TPLP001',
                icon: Icons.class_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Kelas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Dropdown Shift Kuliah
              _buildLabel('Shift Kuliah'),
              DropdownButtonFormField<String>(
                value: _selectedShift,
                isExpanded: true,
                decoration: _fieldDecoration(
                  hint: 'Pilih Shift',
                  icon: Icons.access_time_rounded,
                ),
                items: shiftList.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedShift = val);
                },
              ),
              const SizedBox(height: 14),

              // Dropdown Semester
              _buildLabel('Semester Berjalan'),
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                isExpanded: true,
                decoration: _fieldDecoration(
                  hint: 'Pilih Semester',
                  icon: Icons.date_range_outlined,
                ),
                items: semesterList.map((sem) {
                  return DropdownMenuItem(
                    value: sem,
                    child: Text(sem, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSemester = val);
                },
              ),
              const SizedBox(height: 14),

              // Field Email
              _buildFormField(
                controller: _emailController,
                label: 'Email Mahasiswa',
                hint: 'Contoh: tama@mahasiswa.unpam.ac.id',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(val.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Field Nomor HP
              _buildFormField(
                controller: _phoneController,
                label: 'Nomor WhatsApp / HP',
                hint: 'Contoh: 081234567890',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Nomor HP minimal 10 angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Field Bio / Catatan Peminatan
              _buildFormField(
                controller: _bioController,
                label: 'Catatan / Peminatan Studi',
                hint: 'Contoh: Mobile Application & Artificial Intelligence',
                icon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Tombol Batal & Simpan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _handleCancelEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSaveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          decoration: _fieldDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryLight),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dangerRed),
      ),
    );
  }
}
