import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/my_unpam_session.dart';
import '../../../../../theme/app_theme.dart';
import 'portal_ai_assist.dart';
import 'sso_auth_modal.dart';

Future<void> reconnectPortal(BuildContext context, Future<void> Function() onConnected) async {
  final messenger = ScaffoldMessenger.of(context);
  final success = await SsoAuthModal.show(context);
  if (success != true) return;
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Akun Satu UNPAM & My UNPAM berhasil terhubung'),
      backgroundColor: AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ),
  );
  await onConnected();
}

class PortalPageScaffold extends StatefulWidget {
  final String title;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Widget body;
  final PortalAiContext? aiContext;

  const PortalPageScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onRefresh,
    required this.body,
    this.aiContext,
  });

  @override
  State<PortalPageScaffold> createState() => _PortalPageScaffoldState();
}

class _PortalPageScaffoldState extends State<PortalPageScaffold> {
  final GlobalKey<PortalAiAssistState> _aiKey = GlobalKey<PortalAiAssistState>();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MyUnpamSession>();
    final busy = widget.isLoading || session.isRefreshing;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.aiContext != null)
            IconButton(
              tooltip: 'The PAMs AI Tools',
              onPressed: () => _aiKey.currentState?.openTools(),
              icon: const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 21),
            ),
          IconButton(
            tooltip: 'Segarkan',
            onPressed: busy ? null : widget.onRefresh,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Hubungkan ulang akun',
            onPressed: () => reconnectPortal(context, widget.onRefresh),
            icon: const Icon(Icons.link_rounded),
          ),
        ],
        bottom: session.isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2.5),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppTheme.accentGold,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: _wrapWithAi(
        RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: widget.onRefresh,
          child: widget.body,
        ),
      ),
    );
  }

  Widget _wrapWithAi(Widget content) {
    final ai = widget.aiContext;
    if (ai == null) return content;
    return PortalAiAssist(
      key: _aiKey,
      aiContext: ai,
      child: content,
    );
  }
}

class PortalLoadingView extends StatelessWidget {
  final String message;

  const PortalLoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final refreshing = context.watch<MyUnpamSession>().isRefreshing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            refreshing ? 'Menyegarkan sesi Satu UNPAM & My UNPAM...' : message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class PortalErrorView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Future<void> Function() onRetry;

  const PortalErrorView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final needsLogin = context.watch<MyUnpamSession>().needsLogin;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (needsLogin ? AppTheme.primaryBlue : AppTheme.dangerRed).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              needsLogin ? Icons.lock_person_rounded : icon,
              size: 52,
              color: needsLogin ? AppTheme.primaryBlue : AppTheme.dangerRed,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          needsLogin ? 'Hubungkan Akun Satu UNPAM' : title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'Terjadi kendala saat memuat data dari My UNPAM.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            if (needsLogin)
              ElevatedButton.icon(
                onPressed: () => reconnectPortal(context, onRetry),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Hubungkan Akun'),
              ),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ],
    );
  }
}

class PortalSyncBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const PortalSyncBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final needsLogin = context.watch<MyUnpamSession>().needsLogin;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppTheme.accentGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppTheme.accentGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Menampilkan data tersimpan. $message',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, height: 1.3),
            ),
          ),
          TextButton(
            onPressed: needsLogin ? () => reconnectPortal(context, onRetry) : onRetry,
            child: Text(needsLogin ? 'Hubungkan' : 'Coba lagi'),
          ),
        ],
      ),
    );
  }
}
