import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/models/seminar_certificate_model.dart';
import '../providers/academic_portal_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../widgets/portal_state_views.dart';
import '../widgets/portal_ai_assist.dart';

class SeminarCertificateScreen extends StatefulWidget {
  const SeminarCertificateScreen({super.key});

  @override
  State<SeminarCertificateScreen> createState() =>
      _SeminarCertificateScreenState();
}

class _SeminarCertificateScreenState extends State<SeminarCertificateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AcademicPortalProvider>();
      if (!provider.certificates.hasData) {
        provider.fetchCertificates();
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCertificateDialog(SeminarCertificateItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Detail Sertifikat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.namaEvent,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogRow('Jenis Kegiatan', item.jenisEvent ?? 'Seminar'),
            _buildDialogRow('Tanggal Pelaksanaan', item.formattedDate),
            _buildDialogRow(
              'Status Sertifikat',
              item.isVerified ? 'Terverifikasi (Approved)' : 'Pending',
              isSuccess: item.isVerified,
            ),
            const SizedBox(height: 10),
            const Text(
              'Nomor Barcode / ID Sertifikat:',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nomorBarcode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(item.nomorBarcode, 'Nomor Barcode'),
                    child: const Icon(Icons.copy_rounded,
                        size: 16, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSuccess ? AppTheme.successGreen : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final resource = provider.certificates;

    return PortalPageScaffold(
      title: 'Seminar & Sertifikat',
      isLoading: resource.isLoading,
      onRefresh: () => provider.fetchCertificates(forceRefresh: true),
      body: _buildBody(provider, resource),
      aiContext: PortalAiContext(
        pageTitle: 'Seminar & Sertifikat',
        label: 'Sertifikat',
        buildPageText: () => PortalAiText.certificates(provider.certificates.data),
      ),
    );
  }

  Widget _buildBody(AcademicPortalProvider provider, PortalResource<List<SeminarCertificateItem>> resource) {
    final certificates = resource.data;
    Future<void> retry() => provider.fetchCertificates(forceRefresh: true);

    if (certificates == null) {
      if (resource.isLoading) {
        return const PortalLoadingView(message: 'Memuat riwayat seminar...');
      }
      return PortalErrorView(
        icon: Icons.card_membership_rounded,
        title: 'Gagal Memuat Sertifikat',
        message: resource.error,
        onRetry: retry,
      );
    }


    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (resource.error != null)
          PortalSyncBanner(message: resource.error!, onRetry: retry),
        _buildHeroSummaryCard(certificates),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Kegiatan (${certificates.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (certificates.isEmpty)
          _buildEmptyCertificates()
        else
          ...certificates.map((item) => _buildCertificateCard(item)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroSummaryCard(List<SeminarCertificateItem> certificates) {
    final verifiedCount = certificates.where((c) => c.isVerified).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              size: 32,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portofolio Sertifikat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$verifiedCount dari ${certificates.length} sertifikat kegiatan telah terverifikasi.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(SeminarCertificateItem item) {
    final isVerified = item.isVerified;

    return InkWell(
      onTap: () => _showCertificateDialog(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.jenisEvent ?? 'Seminar',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.accentGoldLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVerified
                          ? AppTheme.successGreen.withOpacity(0.35)
                          : AppTheme.accentGold.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                        size: 12,
                        color: isVerified
                            ? AppTheme.successGreen
                            : AppTheme.accentGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Terverifikasi' : 'Pending',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isVerified
                              ? AppTheme.successGreen
                              : AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.namaEvent,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      item.formattedDate,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      item.shortBarcode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCertificates() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 52, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum ada sertifikat seminar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Sertifikat kegiatan atau seminar akan muncul di sini',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
