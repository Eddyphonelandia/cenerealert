import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../application/vona_feed_providers.dart';
import '../domain/vona_feed_entry.dart';

// Card "FEED UFFICIALE": riassunto in linguaggio semplice dell'ultimo
// bollettino VONA, con link alla fonte originale sempre visibile — mai
// nascosto, anche quando il riassunto non è disponibile (parsing fallito
// o comunicato in un formato che la Edge Function non ha riconosciuto).
class VonaFeedCard extends ConsumerWidget {
  const VonaFeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(vonaFeedProvider);

    return feed.when(
      data: (entry) =>
          entry == null ? const SizedBox.shrink() : _Card(entry: entry),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.entry});
  final VonaFeedEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.volcano,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amberSignal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(entry.receivedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.parsingSucceeded
                ? entry.simplifiedText
                : "Nuovo comunicato dell'INGV. Riassunto non disponibile.",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkTextPrimary,
              height: 1.3,
            ),
          ),
          if (entry.pdfUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(entry.pdfUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text(
                'Leggi il comunicato originale →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberSignal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
