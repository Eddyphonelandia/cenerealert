import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/saved_places_providers.dart';
import '../domain/saved_place.dart';
import 'saved_place_form_screen.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(savedPlacesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Luoghi salvati'),
      ),
      body: SafeArea(
        child: placesAsync.when(
          data: (places) => _buildList(context, ref, places),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.amberSignal),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Non riesco a caricare i tuoi luoghi salvati. Riprova più tardi.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: placesAsync.maybeWhen(
        data: (places) => places.length >= maxSavedPlaces
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.amberSignal,
                foregroundColor: AppColors.darkBackground,
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi luogo'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SavedPlaceFormScreen(),
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<SavedPlace> places,
  ) {
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nessun luogo salvato. Aggiungi casa, lavoro o un terreno per ricevere allerte anche quando non ti trovi lì.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.darkTextSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final place = places[index];
        return _SavedPlaceTile(
          place: place,
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SavedPlaceFormScreen(existing: place),
            ),
          ),
          onDelete: () => _confirmDelete(context, ref, place),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedPlace place,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceElevated,
        title: const Text('Rimuovere questo luogo?'),
        content: Text('Non riceverai più allerte per "${place.label}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed == true && place.id != null) {
      await ref.read(savedPlacesControllerProvider.notifier).remove(place.id!);
    }
  }
}

class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedPlace place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.place_outlined,
              color: AppColors.amberSignal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Raggio di allerta: ${place.alertRadiusKm.round()} km',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.darkTextSecondary,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.intensityIntense,
            ),
          ),
        ],
      ),
    );
  }
}
