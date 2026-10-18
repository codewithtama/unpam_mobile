import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum NetworkHealthState {
  good,
  unstable,
  offline,
}

@immutable
class NetworkStabilitySnapshot {
  final NetworkHealthState state;
  final String message;
  final int? latencyMs;

  const NetworkStabilitySnapshot({
    this.state = NetworkHealthState.good,
    this.message = '',
    this.latencyMs,
  });

  static const NetworkStabilitySnapshot healthy = NetworkStabilitySnapshot(
    state: NetworkHealthState.good,
  );

  bool get hasWarning => state != NetworkHealthState.good;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkStabilitySnapshot &&
        other.state == state &&
        other.message == message &&
        other.latencyMs == latencyMs;
  }

  @override
  int get hashCode => Object.hash(state, message, latencyMs);
}

class TopNetworkStabilityBanner extends StatelessWidget {
  final NetworkStabilitySnapshot snapshot;
  final bool isDismissed;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const TopNetworkStabilityBanner({
    super.key,
    required this.snapshot,
    required this.isDismissed,
    required this.onDismiss,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = snapshot.hasWarning && !isDismissed;
    final bool isOffline = snapshot.state == NetworkHealthState.offline;

    final Color bgColor = isOffline
        ? const Color(0xFFFEF2F2)
        : AppTheme.accentGoldLight;
    final Color borderColor = isOffline
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);
    final Color accentColor = isOffline
        ? AppTheme.dangerRed
        : AppTheme.accentGold;
    final Color titleColor = isOffline
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);
    final Color subtitleColor = isOffline
        ? const Color(0xFFB91C1C)
        : const Color(0xFFB45309);

    final String titleText = isOffline
        ? 'Koneksi Internet Terputus'
        : 'Koneksi Internet Mungkin Tidak Stabil';

    final String detailText = snapshot.message.isNotEmpty
        ? snapshot.message
        : (isOffline
            ? 'Periksa jaringan Wi-Fi atau paket data seluler Anda.'
            : 'Respon jaringan ke server kampus melambat. Halaman mungkin memuat lebih lama.');

    return RepaintBoundary(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: !visible
            ? const SizedBox(width: double.infinity, height: 0)
            : Material(
                color: bgColor,
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.08),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.network_check_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    titleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                if (snapshot.latencyMs != null &&
                                    snapshot.latencyMs! > 0 &&
                                    !isOffline) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${snapshot.latencyMs} ms',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              detailText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.25,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onRetry();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: titleColor,
                          backgroundColor: accentColor.withOpacity(0.12),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(48, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text(
                          'Segarkan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup Peringatan Koneksi',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onDismiss();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: titleColor.withOpacity(0.8),
                        ),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
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
