import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nimController = TextEditingController(text: ApiConstants.defaultNim);
  final _passwordController = TextEditingController(text: '••••••••');
  final _tokenController = TextEditingController();
  bool _obscurePassword = true;
  bool _showTokenInput = false;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool isDemo = false}) async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      nim: _nimController.text.trim(),
      password: _passwordController.text.trim(),
      manualBearerToken: isDemo ? null : _tokenController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header Kampus
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 44,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'UNPAM LMS MOBILE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Portal Perkuliahan Terpadu • Mentari & Sakura',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Card Form Login
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk Akun Mahasiswa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input NIM
                        TextField(
                          controller: _nimController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Induk Mahasiswa (NIM)',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Input Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryLight),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Switcher Input Bearer Token Manual (Kebutuhan Dosen)
                        InkWell(
                          onTap: () => setState(() => _showTokenInput = !_showTokenInput),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  _showTokenInput ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Gunakan Bearer Token Manual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Field Token jika diaktifkan
                        if (_showTokenInput) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _tokenController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Paste Bearer Token di sini',
                              hintText: 'eyJh...',
                              prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.accentGold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Tombol Submit Login
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : () => _handleLogin(isDemo: false),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('MASUK SEKARANG'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Masuk Demo Cepat (Data Dosen)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading ? null : () => _handleLogin(isDemo: true),
                            icon: const Icon(Icons.offline_bolt_rounded, size: 18, color: AppTheme.accentGold),
                            label: const Text(
                              'Masuk Mode Demo (Data Asli Dosen)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.accentGold),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Footer
                const Text(
                  'Tugas Project Mobile Programming • Teknik Informatika',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
