import 'package:flutter/material.dart';
import '../core/services/permission_service.dart';
import '../core/services/storage_service.dart';
import '../screens/account_onboarding_screen.dart';
import '../screens/permission_gate_screen.dart';
import '../screens/portal_webview_screen.dart';
import '../screens/user_agreement_screen.dart';
import '../theme/app_theme.dart';

enum GateDestination {
  checking,
  agreement,
  permissionGate,
  accountOnboarding,
  portal,
}

class AppGate extends StatefulWidget {
  final StorageService storageService;

  const AppGate({
    super.key,
    required this.storageService,
  });

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  GateDestination _destination = GateDestination.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateGateDestination();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _destination != GateDestination.agreement) {
      _evaluateGateDestination();
    }
  }

  Future<void> _evaluateGateDestination() async {
    // 1. Cek apakah Syarat & Ketentuan Pengguna sudah disetujui
    final isAgreementAccepted = widget.storageService.isUserAgreementAccepted();
    if (!isAgreementAccepted) {
      if (mounted) {
        setState(() => _destination = GateDestination.agreement);
      }
      return;
    }

    // 2. Cek apakah seluruh izin aplikasi wajib (Notifikasi, Kamera, Media) sudah diizinkan
    final arePermissionsGranted =
        await _permissionService.areAllPermissionsGranted();

    if (!mounted) return;
    if (!arePermissionsGranted) {
      setState(() => _destination = GateDestination.permissionGate);
      return;
    }

    final needsOnboarding = await AccountOnboardingScreen.shouldShow(widget.storageService);
    if (!mounted) return;
    setState(() {
      _destination =
          needsOnboarding ? GateDestination.accountOnboarding : GateDestination.portal;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_destination) {
      case GateDestination.checking:
        return const Scaffold(
          backgroundColor: AppTheme.bgGrey,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Image(
                    image: AssetImage('logoaplikasi.jpeg'),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(height: 12),
                Text(
                  'Menyiapkan The PAMs...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );

      case GateDestination.agreement:
        return UserAgreementScreen(
          storageService: widget.storageService,
          onAccepted: _evaluateGateDestination,
        );

      case GateDestination.permissionGate:
        return PermissionGateScreen(
          storageService: widget.storageService,
        );

      case GateDestination.accountOnboarding:
        return AccountOnboardingScreen(
          storageService: widget.storageService,
          onFinished: _evaluateGateDestination,
        );

      case GateDestination.portal:
        return const PortalWebViewScreen();
    }
  }
}
