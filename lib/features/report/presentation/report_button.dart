import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/report_providers.dart';
import '../data/report_repository.dart';
import '../domain/ash_intensity.dart';
import 'intensity_glyph.dart';

// Il pulsante SEGNALA: elemento iconico dell'app, come da design system.
// Stato chiuso: cerchio ambra raggiungibile col pollice (88dp).
// Tap: si apre un selettore con le 3 intensità.
// Scelta: haptic + invio + animazione di conferma ad anello.
class ReportButton extends ConsumerStatefulWidget {
  const ReportButton({super.key});

  @override
  ConsumerState<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends ConsumerState<ReportButton>
    with SingleTickerProviderStateMixin {
  bool _selectorOpen = false;
  late final AnimationController _confirmController;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _confirmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _openSelector() {
    HapticFeedback.selectionClick();
    setState(() => _selectorOpen = true);
  }

  void _closeSelector() {
    setState(() => _selectorOpen = false);
  }

  Future<void> _select(AshIntensity intensity) async {
    HapticFeedback.mediumImpact();
    _closeSelector();

    final controller = ref.read(reportSubmissionControllerProvider.notifier);
    await controller.submit(intensity);
    if (!mounted) return;

    final state = ref.read(reportSubmissionControllerProvider);
    state.when(
      data: (report) {
        if (report != null) {
          HapticFeedback.lightImpact();
          _confirmController.forward(from: 0);
          _showFeedback('Segnalazione inviata. Grazie del contributo.');
        }
      },
      loading: () {},
      error: (error, _) {
        final message = error is ReportException
            ? error.message
            : 'Qualcosa non ha funzionato. Riprova tra poco.';
        _showFeedback(message);
      },
    );
  }

  void _showFeedback(String message) {
    setState(() => _feedbackMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(reportSubmissionControllerProvider);
    final isLoading = submission.isLoading;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (_feedbackMessage != null)
          Positioned(
            bottom: 200,
            right: 0,
            child: _FeedbackPill(message: _feedbackMessage!),
          ),
        Positioned(
          bottom: 100,
          right: 0,
          child: AnimatedOpacity(
            opacity: _selectorOpen ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !_selectorOpen,
              child: _buildSelectorRow(),
            ),
          ),
        ),
        _buildConfirmationRing(),
        _buildMainButton(isLoading),
      ],
    );
  }

  Widget _buildSelectorRow() {
    const options = AshIntensity.values;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final intensity in options) ...[
          _IntensityOption(
            intensity: intensity,
            onTap: () => _select(intensity),
          ),
          if (intensity != options.last) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildConfirmationRing() {
    return AnimatedBuilder(
      animation: _confirmController,
      builder: (context, child) {
        final value = _confirmController.value;
        if (value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: (1 - value).clamp(0, 1),
          child: Transform.scale(
            scale: 1 + value * 0.6,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amberSignal, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : (_selectorOpen ? _closeSelector : _openSelector),
      child: AnimatedScale(
        scale: _selectorOpen ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amberSignal, width: 1.5),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amberSignal,
                    ),
                  )
                : Icon(
                    _selectorOpen ? Icons.close : Icons.water_drop_outlined,
                    color: AppColors.amberSignal,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}

class _IntensityOption extends StatelessWidget {
  const _IntensityOption({required this.intensity, required this.onTap});

  final AshIntensity intensity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: intensity.color, width: 1.5),
            ),
            child: Center(
              child: IntensityGlyph(intensity: intensity, size: 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            intensity.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.darkTextPrimary),
      ),
    );
  }
}
