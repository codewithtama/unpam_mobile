import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';
import '../theme/app_theme.dart';

class BiometricVaultSheet extends StatefulWidget {
  const BiometricVaultSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BiometricVaultSheet(),
    );
  }

  @override
  State<BiometricVaultSheet> createState() => _BiometricVaultSheetState();
}

class _BiometricVaultSheetState extends State<BiometricVaultSheet> {
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nim = _nimController.text.trim();
    final pass = _passwordController.text.trim();

    if (nim.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = 'NIM dan Password tidak boleh kosong.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final bioProv = context.read<BiometricProvider>();
    final success = await bioProv.saveCredentials(nim: nim, password: pass);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kredensial UNPAM berhasil disimpan dengan aman via Biometrik!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage =
            'Verifikasi sidik jari dibatalkan atau tidak cocok. Kredensial tidak disimpan.';
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kredensial?'),
        content: const Text(
          'Akun UNPAM yang tersimpan di perangkat ini akan dihapus secara permanen dari Secure Storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BiometricProvider>().clearCredentials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kredensial berhasil dihapus.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioProv = context.watch<BiometricProvider>();
    final hasCreds = bioProv.hasSavedCredentials && !_isEditing;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric Auto-Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Login cepat Mentari UNPAM dengan Sidik Jari',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (hasCreds) ...[
                // Tampilan Ketika Kredensial Sudah Tersimpan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppTheme.successGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kredensial Terenkripsi Aktif',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIM: ${bioProv.savedNim ?? "-"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Deteksi Otomatis Halaman Login',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Tampilkan prompt sidik jari instan saat form login Mentari terbuka.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        value: bioProv.isAutoLoginEnabled,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) {
                          bioProv.setAutoLoginEnabled(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                            _nimController.text = bioProv.savedNim ?? '';
                            _passwordController.clear();
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Ubah Akun', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppTheme.dangerRed,
                          side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.5)),
                        ),
                        onPressed: bioProv.isLoading ? null : _handleDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Hapus Kredensial', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Form Input Kredensial Baru / Edit
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kredensial disimpan aman dalam Keystore perangkat dan dilindungi biometrik.',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nimController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Induk Mahasiswa (NIM)',
                    hintText: 'Contoh: 201011400000',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password Mentari UNPAM',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.dangerRed),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (_isEditing) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: bioProv.isLoading ? null : _handleSave,
                        icon: const Icon(Icons.fingerprint_rounded, size: 20),
                        label: Text(
                          bioProv.isLoading ? 'Menyimpan...' : 'Simpan & Kunci Sidik Jari',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
