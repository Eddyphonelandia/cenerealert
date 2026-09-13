import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/reports_feed_providers.dart';
import '../application/time_filter.dart';

// Selettore del filtro temporale (1h/3h/6h/24h): superficie semitrasparente
// che "galleggia" sulla mappa, coerente col resto della UI.
class TimeFilterChips extends ConsumerWidget {
  const TimeFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(timeFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final filter in TimeFilter.values)
            _FilterChip(
              filter: filter,
              selected: filter == selected,
              onTap: () =>
                  ref.read(timeFilterProvider.notifier).state = filter,
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final TimeFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.amberSignal : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.darkBackground
                : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}
