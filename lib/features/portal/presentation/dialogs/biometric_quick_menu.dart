import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Modal bottom sheet menu cepat untuk aksi autentikasi biometrik.
class BiometricQuickMenuDialog extends StatelessWidget {
  final String? savedNim;
  final bool isMyUnpam;
  final VoidCallback onNavigateToLogin;
  final VoidCallback onPerformLoginHere;
  final VoidCallback onOpenVault;

  const BiometricQuickMenuDialog({
    super.key,
    required this.savedNim,
    required this.isMyUnpam,
    required this.onNavigateToLogin,
    required this.onPerformLoginHere,
    required this.onOpenVault,
  });

  static Future<void> show({
    required BuildContext context,
    required String? savedNim,
    required bool isMyUnpam,
    required VoidCallback onNavigateToLogin,
    required VoidCallback onPerformLoginHere,
    required VoidCallback onOpenVault,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BiometricQuickMenuDialog(
        savedNim: savedNim,
        isMyUnpam: isMyUnpam,
        onNavigateToLogin: onNavigateToLogin,
        onPerformLoginHere: onPerformLoginHere,
        onOpenVault: onOpenVault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biometric Auto-Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'NIM Terdaftar: ${savedNim ?? "-"}',
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.login_rounded, color: AppTheme.accentGold, size: 20),
              ),
              title: const Text(
                'Buka Halaman Login & Masuk Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                'Arahkan langsung ke form login ${isMyUnpam ? "MyUnpam" : "Mentari"} dan verifikasi sidik jari.',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(context);
                onNavigateToLogin();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              title: const Text(
                'Coba Isi Kredensial di Halaman Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Isi form username & password jika sudah berada di tampilan login.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(context);
                onPerformLoginHere();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined, color: AppTheme.textDark, size: 20),
              ),
              title: const Text(
                'Kelola Akun & Pengaturan Biometrik',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Ubah NIM, ganti password, atau nonaktifkan auto-login.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(context);
                onOpenVault();
              },
            ),
          ],
        ),
      ),
    );
  }
}
