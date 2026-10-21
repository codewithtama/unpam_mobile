import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/finance_model.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../core/services/portal_ai_text.dart';
import '../widgets/portal_state_views.dart';
import '../widgets/portal_ai_assist.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanceProvider>();
      if (provider.semesters.isEmpty || !provider.hasData) provider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final data = provider.financeData;

    return PortalPageScaffold(
      title: 'Keuangan',
      isLoading: provider.isLoading,
      onRefresh: provider.refresh,
      body: _buildBody(provider, data),
      aiContext: PortalAiContext(
        pageTitle: 'Keuangan',
        label: 'Keuangan',
        buildPageText: () => PortalAiText.finance(provider.financeData),
      ),
    );
  }

  Widget _buildBody(FinanceProvider provider, FinanceResponse? data) {
    if (data == null) {
      if (provider.isLoading) {
        return const PortalLoadingView(message: 'Memuat data keuangan...');
      }
      return PortalErrorView(
        icon: Icons.account_balance_rounded,
        title: 'Gagal Memuat Keuangan',
        message: provider.errorMessage,
        onRetry: provider.refresh,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (provider.errorMessage != null)
          PortalSyncBanner(message: provider.errorMessage!, onRetry: provider.refresh),
        _buildSemesterSelectorCard(provider),
        const SizedBox(height: 14),
        _buildFinanceSummaryCard(data),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Tagihan Perkuliahan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Text(
              '${data.billings.length} Tagihan',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (data.billings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Tidak ada tagihan perkuliahan di semester ini.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ...data.billings.map((item) => _buildBillingItemCard(item)),
        if (data.otherBillings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.featured_play_list_rounded, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tagihan Lainnya',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${data.otherBillings.length} Tagihan',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.otherBillings.map((item) => _buildBillingItemCard(item)),
        ],
        if (data.spBillings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tagihan Semester Pendek (SP)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${data.spBillings.length} Tagihan',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.spBillings.map((item) => _buildBillingItemCard(item)),
        ],
      ],
    );
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

  Widget _buildSemesterSelectorCard(FinanceProvider provider) {
    final selectedItem = provider.selectedSemesterItem;
    final displayName = selectedItem?.displayName ?? provider.selectedSemesterId;
    final semesters = provider.semesters;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tahun Akademik / Semester',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ganti Semester',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.primaryBlue),
                ],
              ),
            ),
            onSelected: (val) {
              provider.selectSemester(val);
            },
            itemBuilder: (ctx) {
              if (semesters.isEmpty) {
                return [
                  PopupMenuItem<String>(
                    value: provider.selectedSemesterId,
                    child: Text(provider.selectedSemesterId),
                  ),
                ];
              }

              return semesters.map((sem) {
                final isSelected = sem.idSemesterRegistrasi == provider.selectedSemesterId;
                return PopupMenuItem<String>(
                  value: sem.idSemesterRegistrasi,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        size: 18,
                        color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sem.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sem.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.successGreen.withOpacity(0.35)),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSummaryCard(FinanceResponse data) {
    final total = data.totalBillingAmount;
    final lunas = data.totalPaidAmount;
    final belumLunas = data.totalUnpaidAmount;
    final progress = data.paidPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Biaya Kuliah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              if (data.semester != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGoldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.semester!.namaSemesterRegistrasi,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryColumn(
                  label: 'Total Tagihan',
                  amount: data.formatCurrency(total),
                  color: AppTheme.textDark,
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.cardBorder),
              Expanded(
                child: _buildSummaryColumn(
                  label: 'Sudah Dibayar',
                  amount: data.formatCurrency(lunas),
                  color: AppTheme.successGreen,
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.cardBorder),
              Expanded(
                child: _buildSummaryColumn(
                  label: 'Sisa Tagihan',
                  amount: data.formatCurrency(belumLunas),
                  color: belumLunas > 0 ? AppTheme.dangerRed : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.successGreen : AppTheme.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Pelunasan Semester',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBillingItemCard(BillingItem item) {
    final isPaid = item.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? AppTheme.cardBorder : AppTheme.accentGold.withOpacity(0.35),
          width: isPaid ? 1 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.keterangan,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    InkWell(
                      onTap: () => _copyToClipboard(item.noTagihan, 'No. Tagihan'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No: ${item.noTagihan}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid ? AppTheme.successGreen.withOpacity(0.35) : AppTheme.dangerRed.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal Tagihan',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.formattedTotal,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              if (isPaid) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.namaTempatBayar ?? 'Lunas',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (item.formattedTanggalBayar != null)
                      Text(
                        item.formattedTanggalBayar!,
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Silakan bayar via Bank BNI/Loket',
                  style: TextStyle(fontSize: 11, color: AppTheme.accentGold, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
