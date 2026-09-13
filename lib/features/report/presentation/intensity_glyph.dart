import 'package:flutter/material.dart';
import '../domain/ash_intensity.dart';

// Disegna una "goccia" con riempimento diverso per ciascun livello di
// intensità, così il significato non dipende solo dal colore (requisito
// di accessibilità: mai il colore come unico veicolo di informazione).
// Leggera: solo contorno. Moderata: riempimento pieno. Intensa: riempimento
// pieno + righe diagonali, distinguibile anche in scala di grigi.
class IntensityGlyph extends StatelessWidget {
  const IntensityGlyph({super.key, required this.intensity, this.size = 24});

  final AshIntensity intensity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DropPainter(intensity: intensity),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  _DropPainter({required this.intensity});
  final AshIntensity intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _dropPath(size);
    final color = intensity.color;

    switch (intensity) {
      case AshIntensity.light:
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.09;
        canvas.drawPath(path, stroke);
        break;

      case AshIntensity.moderate:
        final fill = Paint()..color = color;
        canvas.drawPath(path, fill);
        break;

      case AshIntensity.intense:
        final fill = Paint()..color = color;
        canvas.save();
        canvas.clipPath(path);
        canvas.drawPath(path, fill);
        final stripe = Paint()
          ..color = Colors.black.withOpacity(0.28)
          ..strokeWidth = size.width * 0.09;
        for (double x = -size.width; x < size.width * 2; x += size.width * 0.22) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.width, 0),
            stripe,
          );
        }
        canvas.restore();
        break;
    }
  }

  Path _dropPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.9, h * 0.45, w * 0.85, h * 0.75, w * 0.5, h)
      ..cubicTo(w * 0.15, h * 0.75, w * 0.1, h * 0.45, w * 0.5, 0)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DropPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
