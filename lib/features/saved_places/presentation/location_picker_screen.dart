import '../../../core/config/map_style_path.dart'
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/theme/app_colors.dart';

const _etnaCenter = LatLng(37.7510, 14.9934);

// Selettore di posizione: la mappa si muove, un pin resta fisso al centro
// dello schermo. Confermando, si usa il centro corrente della camera —
// pattern robusto e multipiattaforma, senza dover gestire marker
// trascinabili o gesture di tap personalizzate.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialPosition});

  final LatLng? initialPosition;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MaplibreMapController? _controller;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? _etnaCenter;
  }

  void _onCameraIdle() {
    final target = _controller?.cameraPosition?.target;
    if (target != null) {
      setState(() => _center = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          MaplibreMap(
            styleString: mapStylePath,
            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
            myLocationEnabled: false,
            compassEnabled: false,
            onMapCreated: (controller) => _controller = controller,
            onCameraIdle: _onCameraIdle,
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_pin,
                  size: 44,
                  color: AppColors.amberSignal,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: _RoundIconButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amberSignal,
                    foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(_center),
                  child: const Text('Conferma questa posizione'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.darkTextSecondary),
      ),
    );
  }
}
