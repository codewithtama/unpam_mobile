import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/student_profile_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  State<StudentProfileSetupScreen> createState() => _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _fakultasController = TextEditingController(text: 'Fakultas Ilmu Komputer');
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedProdi = 'Sistem Informasi (S1)';
  String _selectedShift = 'Reguler CK (Sabtu)';
  String _selectedSemester = 'Semester 1';
  bool _isSubmitting = false;

  static const List<String> prodiList = [
    'Sistem Informasi (S1)',
    'Teknik Informatika (S1)',
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
    'Reguler CK (Sabtu)',
    'Reguler A (Pagi)',
    'Reguler B (Siang)',
    'Reguler C (Malam)',
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

  void _onProdiChanged(String? newProdi) {
    if (newProdi == null) return;
    setState(() {
      _selectedProdi = newProdi;
      if (newProdi.contains('Informatika') ||
          newProdi.contains('Sistem Informasi') ||
          newProdi.contains('Sistem Komputer')) {
        _fakultasController.text = 'Fakultas Ilmu Komputer';
      } else if (newProdi.contains('Manajemen') || newProdi.contains('Akuntansi')) {
        _fakultasController.text = 'Fakultas Ekonomi dan Bisnis';
      } else if (newProdi.contains('Hukum')) {
        _fakultasController.text = 'Fakultas Hukum';
      } else if (newProdi.contains('Teknik')) {
        _fakultasController.text = 'Fakultas Teknik';
      } else if (newProdi.contains('Sastra')) {
        _fakultasController.text = 'Fakultas Sastra';
      } else if (newProdi.contains('Pendidikan') || newProdi.contains('Matematika')) {
        _fakultasController.text = 'Fakultas Keguruan dan Ilmu Pendidikan';
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newProfile = StudentProfile(
      name: _nameController.text.trim(),
      nim: _nimController.text.trim(),
      prodi: _selectedProdi,
      fakultas: _fakultasController.text.trim(),
      kelas: _kelasController.text.trim(),
      shift: _selectedShift,
      semester: _selectedSemester,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      status: 'Mahasiswa Aktif',
      bio: _bioController.text.trim(),
    );

    final auth = context.read<AuthProvider>();
    await auth.updateProfile(newProfile);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mahasiswa berhasil disimpan. Selamat datang di UNPAM Mobile.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Aktivasi Profil Mahasiswa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'UNIVERSITAS PAMULANG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Silakan lengkapi profil akademik Anda di bawah ini sebelum menggunakan aplikasi UNPAM Mobile dan mengakses portal Mentari.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Data Identitas Akademik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 14),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Lengkap
                      _buildLabel('Nama Lengkap Mahasiswa *'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Dimas Alfa Pratama',
                          icon: Icons.person_outline_rounded,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (val) {
                          if (val == null || val.trim().length < 2) {
                            return 'Nama lengkap wajib diisi (minimal 2 karakter)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // NIM
                      _buildLabel('Nomor Induk Mahasiswa (NIM) *'),
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: 241011750041',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 8) {
                            return 'NIM wajib diisi (minimal 8 angka)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Program Studi
                      _buildLabel('Program Studi *'),
                      DropdownButtonFormField<String>(
                        value: _selectedProdi,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
                          hint: 'Pilih Program Studi',
                          icon: Icons.school_outlined,
                        ),
                        items: prodiList.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: _onProdiChanged,
                      ),
                      const SizedBox(height: 16),

                      // Fakultas
                      _buildLabel('Fakultas *'),
                      TextFormField(
                        controller: _fakultasController,
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Fakultas Ilmu Komputer',
                          icon: Icons.account_balance_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Fakultas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kelas
                      _buildLabel('Kelas Mahasiswa *'),
                      TextFormField(
                        controller: _kelasController,
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: 04SIFE001',
                          icon: Icons.meeting_room_outlined,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Kelas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Shift Kuliah
                      _buildLabel('Shift Kuliah *'),
                      DropdownButtonFormField<String>(
                        value: _selectedShift,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
                          hint: 'Pilih Shift Kuliah',
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
                      const SizedBox(height: 16),

                      // Semester
                      _buildLabel('Semester Berjalan *'),
                      DropdownButtonFormField<String>(
                        value: _selectedSemester,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
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
                      const SizedBox(height: 16),

                      // Email Mahasiswa (Opsional)
                      _buildLabel('Email Mahasiswa (Opsional)'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hint: 'nama@mahasiswa.unpam.ac.id',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$');
                            if (!regex.hasMatch(val.trim())) {
                              return 'Format email tidak valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nomor WhatsApp / HP (Opsional)
                      _buildLabel('Nomor WhatsApp / HP (Opsional)'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Catatan Akademik / Peminatan
                      _buildLabel('Catatan Akademik / Peminatan (Opsional)'),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Peminatan Mobile Programming & Rekayasa Perangkat Lunak',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Profil & Buka Aplikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
