import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/biometric_auth_service.dart';
import '../core/services/my_unpam_session.dart';
import '../core/services/storage_service.dart';
import '../providers/biometric_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sso_auth_modal.dart';
import 'portal_webview_screen.dart';

class AccountOnboardingScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onFinished;
  final bool allowSkip;

  const AccountOnboardingScreen({
    super.key,
    required this.storageService,
    this.onFinished,
    this.allowSkip = true,
  });

  static Future<bool> shouldShow(StorageService storage) async {
    if (storage.isAccountOnboardingDone()) return false;
    var alreadyConnected = storage.hasMyUnpamToken;
    if (!alreadyConnected) {
      try {
        alreadyConnected =
            await BiometricAuthService(prefs: storage.rawPreferences).hasSavedCredentials();
      } catch (_) {}
    }
    if (alreadyConnected) {
      await storage.setAccountOnboardingDone(true);
      return false;
    }
    return true;
  }

  @override
  State<AccountOnboardingScreen> createState() => _AccountOnboardingScreenState();
}

enum _ConnectState { idle, connected, skipped }

class _AccountOnboardingScreenState extends State<AccountOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();

  int _step = 0;
  bool _obscurePassword = true;
  bool _enableBiometric = true;
  bool _biometricSaved = false;
  bool _isSaving = false;
  _ConnectState _connectState = _ConnectState.idle;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<MyUnpamSession>().rememberedCredentials;
    final savedNim = context.read<BiometricProvider>().savedNim;
    _nimController.text = remembered?.$1 ?? savedNim ?? '';
  }

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.storageService.setAccountOnboardingDone(true);
    if (!mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    if (!widget.allowSkip) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PortalWebViewScreen()),
    );
  }

  Future<void> _submitAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final nim = _nimController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSaving = true);
    context.read<MyUnpamSession>().rememberCredentials(nim, password);

    final biometric = context.read<BiometricProvider>();
    if (_enableBiometric && biometric.isAvailable) {
      _biometricSaved = await biometric.saveCredentials(nim: nim, password: password);
      if (_biometricSaved) await biometric.setAutoLoginEnabled(true);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _step = 1;
    });
  }

  Future<void> _connectMyUnpam() async {
    final success = await SsoAuthModal.show(context, initialNim: _nimController.text.trim());
    if (!mounted) return;
    setState(() {
      if (success == true) {
        _connectState = _ConnectState.connected;
        _step = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final biometricAvailable = context.watch<BiometricProvider>().isAvailable;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text('Hubungkan Akun UNPAM'),
        automaticallyImplyLeading: !widget.allowSkip,
        actions: [
          if (widget.allowSkip && _step < 2)
            TextButton(
              onPressed: _isSaving ? null : _finish,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Nanti saja'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildStepper(),
            const SizedBox(height: 20),
            if (_step == 0) _buildAccountStep(biometricAvailable),
            if (_step == 1) _buildConnectStep(),
            if (_step == 2) _buildDoneStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    const labels = ['Akun', 'My UNPAM', 'Selesai'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= _step ? AppTheme.primaryBlue : Colors.grey.shade300,
                  child: i < _step
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: i <= _step ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == _step ? FontWeight.bold : FontWeight.normal,
                    color: i <= _step ? AppTheme.textDark : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Container(
              width: 28,
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: i < _step ? AppTheme.primaryBlue : Colors.grey.shade300,
            ),
        ],
      ],
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAccountStep(bool biometricAvailable) {
    return Form(
      key: _formKey,
      child: _buildCard(
        icon: Icons.person_rounded,
        title: 'Akun UNPAM',
        subtitle: 'Satu akun untuk Mentari, Satu UNPAM, dan My UNPAM. Cukup diisi sekali.',
        children: [
          TextFormField(
            controller: _nimController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'NIM',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'NIM wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitAccount(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
          ),
          if (biometricAvailable) ...[
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _enableBiometric,
              onChanged: (v) => setState(() => _enableBiometric = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Aktifkan login sidik jari', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Password disimpan terenkripsi di perangkat ini.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _submitAccount,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectStep() {
    return _buildCard(
      icon: Icons.link_rounded,
      title: 'Hubungkan My UNPAM',
      subtitle:
          'NIM & password akan terisi otomatis di Satu UNPAM. Siapkan Telegram untuk kode OTP, lalu jendela akan tertutup sendiri setelah masuk My UNPAM.',
      children: [
        ElevatedButton.icon(
          onPressed: _connectMyUnpam,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          icon: const Icon(Icons.security_rounded),
          label: const Text('Hubungkan Sekarang'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() {
            _connectState = _ConnectState.skipped;
            _step = 2;
          }),
          child: const Text('Lewati, hubungkan nanti'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Ubah NIM / password'),
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    Widget row(IconData icon, Color color, String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5))),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
    }

    final connected = _connectState == _ConnectState.connected;
    return _buildCard(
      icon: Icons.check_circle_rounded,
      title: 'Siap digunakan',
      subtitle: 'Pengaturan ini bisa diubah kapan saja dari menu "Hubungkan Akun UNPAM".',
      children: [
        row(Icons.menu_book_rounded, AppTheme.successGreen, 'Mentari', 'Login otomatis'),
        row(
          Icons.school_rounded,
          connected ? AppTheme.successGreen : AppTheme.accentGold,
          'My UNPAM (Akademik)',
          connected ? 'Terhubung' : 'Dilewati',
        ),
        row(
          Icons.fingerprint_rounded,
          _biometricSaved ? AppTheme.successGreen : AppTheme.textMuted,
          'Login sidik jari',
          _biometricSaved ? 'Aktif' : 'Tidak aktif',
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _finish,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(widget.allowSkip ? 'Mulai' : 'Selesai'),
        ),
      ],
    );
  }
}
