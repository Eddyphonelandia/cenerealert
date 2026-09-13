import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// Skeleton loader per il primo caricamento della heatmap: una forma
// sfocata e pulsante al centro, mai uno spinner circolare generico
// (requisito esplicito del design system).
class MapSkeletonLoader extends StatefulWidget {
  const MapSkeletonLoader({super.key});

  @override
  State<MapSkeletonLoader> createState() => _MapSkeletonLoaderState();
}

class _MapSkeletonLoaderState extends State<MapSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = 0.25 + (_controller.value * 0.25);
            return Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkSurfaceElevated.withOpacity(opacity),
              ),
            );
          },
        ),
      ),
    );
  }
}
