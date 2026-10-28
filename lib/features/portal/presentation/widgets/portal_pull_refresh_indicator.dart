import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Indikator visual swipe pull-to-refresh kustom dengan animasi rotasi dan progress melingkar.
class PortalPullRefreshIndicator extends StatelessWidget {
  final ValueNotifier<double> pullDistanceNotifier;
  final ValueNotifier<bool> isPullingNotifier;
  final bool isRefreshing;
  final double triggerDistance;

  const PortalPullRefreshIndicator({
    super.key,
    required this.pullDistanceNotifier,
    required this.isPullingNotifier,
    required this.isRefreshing,
    this.triggerDistance = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pullDistanceNotifier, isPullingNotifier]),
      builder: (context, _) {
        final bool pulling = isPullingNotifier.value;
        final double distance = pullDistanceNotifier.value;
        final double topPos;
        if (isRefreshing) {
          topPos = 16.0;
        } else if (pulling) {
          topPos = ((distance - 38.0) * 0.72).clamp(-50.0, 44.0);
        } else {
          topPos = -60.0;
        }

        return AnimatedPositioned(
          duration: pulling ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          top: topPos,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: (pulling || isRefreshing) ? 1.0 : 0.0,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.cardBorder,
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(9),
                child: isRefreshing
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      )
                    : Transform.rotate(
                        angle: (distance / triggerDistance) * 3.14159 * 1.5,
                        child: CircularProgressIndicator(
                          value: (distance / triggerDistance).clamp(0.08, 0.88),
                          strokeWidth: 2.8,
                          backgroundColor: AppTheme.primaryLight.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            distance >= triggerDistance
                                ? AppTheme.accentGold
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
