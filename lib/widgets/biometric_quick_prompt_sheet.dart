import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';
import '../theme/app_theme.dart';

class BiometricQuickPromptSheet extends StatefulWidget {
  final String nim;
  final String password;

  const BiometricQuickPromptSheet({
    super.key,
    required this.nim,
    required this.password,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String nim,
    required String password,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BiometricQuickPromptSheet(
        nim: nim,
        password: password,
      ),
    );
  }

  @override
  State<BiometricQuickPromptSheet> createState() => _BiometricQuickPromptSheetState();
}

class _BiometricQuickPromptSheetState extends State<BiometricQuickPromptSheet> {
  bool _isLoading = false;
  bool _dontAskAgain = false;
  String? _errorMessage;

  Future<void> _handleActivate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bioProv = context.read<BiometricProvider>();
    final success = await bioProv.saveCredentials(
      nim: widget.nim,
      password: widget.password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Verifikasi sidik jari dibatalkan atau tidak cocok. Coba lagi atau pilih Nanti Saja.';
      });
    }
  }

  Future<void> _handleDismiss() async {
    if (_dontAskAgain) {
      final bioProv = context.read<BiometricProvider>();
      await bioProv.setPromptDismissed(true);
    }
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Visual Fingerprint Badge
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppTheme.primaryBlue,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Aktifkan Akses Cepat Biometrik?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Masuk ke akun NIM ${widget.nim} berikutnya jadi lebih instan dan aman hanya dengan sentuhan sidik jari tanpa perlu mengetik ulang sandi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Benefits Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Column(
                  children: [
                    _BenefitItem(
                      icon: Icons.bolt_rounded,
                      iconColor: AppTheme.accentGold,
                      title: 'Login Instan 1 Detik',
                      subtitle: 'Lewati form pengisian NIM dan kata sandi saat membuka aplikasi.',
                    ),
                    SizedBox(height: 10),
                    _BenefitItem(
                      icon: Icons.shield_rounded,
                      iconColor: AppTheme.successGreen,
                      title: 'Keamanan Tingkat Hardware',
                      subtitle: 'Kredensial disimpan terenkripsi di dalam Keystore perangkat Anda.',
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.dangerRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.dangerRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Primary Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleActivate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Aktifkan Sekarang',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),

              // Secondary Button
              TextButton(
                onPressed: _isLoading ? null : _handleDismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: AppTheme.textMuted,
                ),
                child: const Text('Nanti Saja'),
              ),

              // Checkbox option
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _dontAskAgain = !_dontAskAgain;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _dontAskAgain,
                            activeColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _dontAskAgain = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Jangan tanyakan lagi di perangkat ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
