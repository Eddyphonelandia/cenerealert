import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../report/domain/ash_intensity.dart';
import '../application/nearby_intensity_provider.dart';
import '../domain/ash_checklists.dart';
import '../domain/checklist_item.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final intensityAsync = ref.watch(nearbyIntensityProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Cosa fare adesso'),
      ),
      body: SafeArea(
        child: intensityAsync.when(
          data: (intensity) => _buildBody(intensity),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.amberSignal),
          ),
          error: (_, __) => _buildEmptyState(errored: true),
        ),
      ),
    );
  }

  Widget _buildBody(AshIntensity? intensity) {
    final items = checklistFor(intensity);
    if (items.isEmpty || intensity == null) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _IntensityBanner(intensity: intensity),
        const SizedBox(height: 20),
        for (var i = 0; i < items.length; i++)
          _ChecklistTile(
            item: items[i],
            checked: _checked.contains(i),
            onChanged: (value) => setState(() {
              if (value) {
                _checked.add(i);
              } else {
                _checked.remove(i);
              }
            }),
          ),
      ],
    );
  }

  Widget _buildEmptyState({bool errored = false}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          errored
              ? 'Non riesco a determinare la tua posizione. Attiva la geolocalizzazione per una checklist su misura.'
              : 'Nessuna caduta di cenere rilevata di recente entro 5 km dalla tua posizione. Se dovesse arrivare, qui troverai i consigli utili in base all\'intensità.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
      ),
    );
  }
}

class _IntensityBanner extends StatelessWidget {
  const _IntensityBanner({required this.intensity});
  final AshIntensity intensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intensity.color),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: intensity.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Caduta di cenere ${intensity.label.toLowerCase()} rilevata vicino a te.',
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.checked,
    required this.onChanged,
  });

  final ChecklistItem item;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: checked ? AppColors.amberSignal : AppColors.darkBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  checked ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(checked),
                  color:
                      checked ? AppColors.amberSignal : AppColors.darkTextTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(item.icon, color: AppColors.darkTextSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.darkTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
