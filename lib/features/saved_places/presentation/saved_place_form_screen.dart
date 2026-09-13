import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/theme/app_colors.dart';
import '../application/saved_places_providers.dart';
import '../domain/saved_place.dart';
import 'location_picker_screen.dart';

const _presetLabels = ['Casa', 'Lavoro', 'Terreno agricolo'];

// Form per creare o modificare un luogo salvato. Se "existing" è nullo,
// crea un nuovo luogo; altrimenti lo aggiorna mantenendo lo stesso id.
class SavedPlaceFormScreen extends ConsumerStatefulWidget {
  const SavedPlaceFormScreen({super.key, this.existing});

  final SavedPlace? existing;

  @override
  ConsumerState<SavedPlaceFormScreen> createState() =>
      _SavedPlaceFormScreenState();
}

class _SavedPlaceFormScreenState extends ConsumerState<SavedPlaceFormScreen> {
  late String _label;
  late bool _isCustomLabel;
  final _customLabelController = TextEditingController();
  late double _radiusKm;
  LatLng? _position;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _isCustomLabel = existing != null && !_presetLabels.contains(existing.label);
    _label = existing != null && !_isCustomLabel ? existing.label : _presetLabels.first;
    if (_isCustomLabel) _customLabelController.text = existing!.label;
    _radiusKm = existing?.alertRadiusKm ?? 5;
    _position =
        existing != null ? LatLng(existing.latitude, existing.longitude) : null;
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: _position),
      ),
    );
    if (result != null) {
      setState(() => _position = result);
    }
  }

  Future<void> _save() async {
    final label = _isCustomLabel ? _customLabelController.text.trim() : _label;
    if (label.isEmpty) {
      setState(() => _error = 'Dai un nome a questo luogo.');
      return;
    }
    if (_position == null) {
      setState(() => _error = 'Scegli una posizione sulla mappa.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final place = SavedPlace(
      id: widget.existing?.id,
      label: label,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      alertRadiusKm: _radiusKm,
    );

    try {
      final controller = ref.read(savedPlacesControllerProvider.notifier);
      if (widget.existing == null) {
        await controller.add(place);
      } else {
        await controller.updatePlace(place);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _error = 'Non è stato possibile salvare il luogo. Riprova.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: Text(widget.existing == null ? 'Nuovo luogo' : 'Modifica luogo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Nome', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in _presetLabels)
                  ChoiceChip(
                    label: Text(preset),
                    selected: !_isCustomLabel && _label == preset,
                    onSelected: (_) => setState(() {
                      _isCustomLabel = false;
                      _label = preset;
                    }),
                    selectedColor: AppColors.amberSignal,
                    backgroundColor: AppColors.darkSurfaceElevated,
                    labelStyle: TextStyle(
                      color: !_isCustomLabel && _label == preset
                          ? AppColors.darkBackground
                          : AppColors.darkTextSecondary,
                    ),
                  ),
                ChoiceChip(
                  label: const Text('Altro'),
                  selected: _isCustomLabel,
                  onSelected: (_) => setState(() => _isCustomLabel = true),
                  selectedColor: AppColors.amberSignal,
                  backgroundColor: AppColors.darkSurfaceElevated,
                  labelStyle: TextStyle(
                    color: _isCustomLabel
                        ? AppColors.darkBackground
                        : AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
            if (_isCustomLabel) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customLabelController,
                style: const TextStyle(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Es. Casa dei nonni',
                  hintStyle: const TextStyle(color: AppColors.darkTextTertiary),
                  filled: true,
                  fillColor: AppColors.darkSurfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text('Posizione', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amberSignal,
                side: const BorderSide(color: AppColors.amberSignal),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.map_outlined),
              label: Text(
                _position == null
                    ? 'Scegli sulla mappa'
                    : '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Raggio di allerta: ${_radiusKm.round()} km',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _radiusKm,
              min: 3,
              max: 10,
              divisions: 7,
              activeColor: AppColors.amberSignal,
              inactiveColor: AppColors.darkBorder,
              label: '${_radiusKm.round()} km',
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
            const Text(
              'Riceverai una notifica quando arrivano segnalazioni validate entro questa distanza da questo luogo, anche se non ti trovi lì.',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.intensityIntense),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amberSignal,
                  foregroundColor: AppColors.darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
