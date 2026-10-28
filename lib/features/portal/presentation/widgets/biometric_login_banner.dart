import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../auth/presentation/providers/biometric_provider.dart';

/// Banner melayang di atas bottom nav saat terdeteksi form login pada WebView.
class BiometricLoginBanner extends StatelessWidget {
  final String portalName;
  final bool isLoginPageDetected;
  final VoidCallback onLoginPressed;

  const BiometricLoginBanner({
    super.key,
    required this.portalName,
    required this.isLoginPageDetected,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricProvider>(
      builder: (ctx, bioProv, _) {
        final hasCreds = bioProv.hasSavedCredentials;
        if (!hasCreds || !isLoginPageDetected) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Form Login $portalName Terdeteksi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'NIM: ${bioProv.savedNim ?? ""}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(48, 36),
                ),
                onPressed: onLoginPressed,
                icon: const Icon(
                  Icons.login_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Login Sidik Jari',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
