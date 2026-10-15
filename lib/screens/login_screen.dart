import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'mentari_web_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _showManualInput = false;

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
    final courseProv = context.read<CourseProvider>();

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MentariWebLoginScreen(
          onTokenFound: (token, {cookies, preloadCourses}) async {
            final success = await auth.loginWithToken(
              token,
              cookies: cookies,
              preloadCourses: preloadCourses,
            );
            if (success && preloadCourses != null && mounted) {
              courseProv.setInitialCourses(preloadCourses);
            }
            return success;
          },
        ),
      ),
    );
    if (ok == true && mounted) _goHome();
  }

  Future<void> _handleManualLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tempel atau masukkan Bearer Token terlebih dahulu.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithToken(token);
    if (ok && mounted) {
      _goHome();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      var raw = data!.text!.trim();
      if (raw.toLowerCase().startsWith('bearer ')) {
        raw = raw.substring(7).trim();
      }
      _tokenController.text = raw;
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
                const SizedBox(height: 28),
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
                          'Login akun My Unpam di portal resmi Mentari. '
                          'Data mata kuliah dan sesi disinkronkan otomatis.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: auth.isLoading ? null : _handleWebLogin,
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Masuk lewat Portal Mentari'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.cardBorder, height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showManualInput = !_showManualInput),
                            icon: Icon(
                              _showManualInput ? Icons.keyboard_arrow_up_rounded : Icons.vpn_key_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _showManualInput ? 'Tutup Input Manual' : 'Punya Token? Masuk dengan Token Manual',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (_showManualInput) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tokenController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Bearer Token JWT',
                              hintText: 'Tempel token eyJhbGciOi...',
                              isDense: true,
                              suffixIcon: IconButton(
                                tooltip: 'Tempel dari Clipboard',
                                icon: const Icon(Icons.content_paste_rounded, size: 20),
                                onPressed: _pasteFromClipboard,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: auth.isLoading ? null : _handleManualLogin,
                              icon: auth.isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(auth.isLoading ? 'Memverifikasi...' : 'Verifikasi & Masuk'),
                            ),
                          ),
                        ],
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.dangerRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
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
