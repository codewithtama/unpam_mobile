import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'mentari_web_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  bool _showTokenInput = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handleWebLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MentariWebLoginScreen(onTokenFound: auth.loginWithToken),
      ),
    );
    if (ok == true && mounted) _goHome();
  }

  Future<void> _handleTokenLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token wajib diisi.')),
      );
      return;
    }
    final ok = await context.read<AuthProvider>().loginWithToken(token);
    if (ok && mounted) _goHome();
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
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                        const SizedBox(height: 8),
                        const Text(
                          'Login memakai akun My Unpam di halaman resmi Mentari. '
                          'Verifikasi Cloudflare ditangani halaman tersebut.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: auth.isLoading ? null : _handleWebLogin,
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Masuk lewat Mentari'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _showTokenInput = !_showTokenInput),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  _showTokenInput
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: auth.isLoading ? null : _handleTokenLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Masuk dengan Token'),
                            ),
                          ),
                        ],
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tugas Project Mobile Programming • Teknik Informatika',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
