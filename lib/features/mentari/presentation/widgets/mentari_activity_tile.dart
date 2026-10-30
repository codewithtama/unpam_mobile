import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/file_download_service.dart';
import '../../domain/models/mentari_module_model.dart';

class MentariActivityTile extends StatelessWidget {
  final MentariModuleModel module;
  final void Function(MentariModuleModel module)? onTap;
  final void Function(String url)? onOpenInAppBrowser;

  const MentariActivityTile({
    super.key,
    required this.module,
    this.onTap,
    this.onOpenInAppBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTap != null) {
              onTap!(module);
            } else if (module.type == MentariModuleType.resource && module.fileUrl != null) {
              FileDownloadService().downloadAndOpenFile(
                url: module.fileUrl!,
                customFileName: module.fileName ?? '${module.name}.pdf',
              );
            } else if (onOpenInAppBrowser != null && module.url.isNotEmpty) {
              onOpenInAppBrowser!(module.url);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: module.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, color: module.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: module.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              module.typeLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: module.color,
                              ),
                            ),
                          ),
                          if (module.formattedFileSize.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              module.formattedFileSize,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                          if (module.isCompleted) ...[
                            const Spacer(),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppTheme.successGreen,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (module.type == MentariModuleType.resource)
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue, size: 20),
                    tooltip: 'Unduh Berkas',
                    onPressed: () {
                      final url = module.fileUrl ?? module.url;
                      if (url.isNotEmpty) {
                        FileDownloadService().downloadAndOpenFile(
                          url: url,
                          customFileName: module.fileName ?? '${module.name}.pdf',
                        );
                      }
                    },
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
