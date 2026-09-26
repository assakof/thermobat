import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'aero_colors.dart';
import 'aero_text_styles.dart';

// Extrait de ThermoBat (frontend Flutter Web).
// La jauge du résultat final : cadran métal, aiguille rouge, reflet de verre.
// Tout est dessiné au CustomPainter, pas d'image. Oui c'est un peu rétro
// (style Windows 7), c'était voulu pour la présentation :)

/// Affiche une valeur (la charge clim en W par ex.) sur un cadran.
class SkeuomorphicGaugeWidget extends StatelessWidget {
  final double value;
  final double maxValue;
  final String unit;
  final String? label;
  final double size;

  const SkeuomorphicGaugeWidget({
    super.key,
    required this.value,
    this.maxValue = 2500,
    this.unit = 'W',
    this.label,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Si la valeur dépasse le max on agrandit l'échelle au lieu de coller
    // l'aiguille en butée. Afficher 2500 W alors qu'il en faut 4000,
    // c'est le genre d'erreur qui fait acheter une clim trop petite.
    final effectiveMax = math.max(maxValue, value * 1.2 == 0 ? maxValue : value * 1.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _AeroGaugePainter(value: value, maxValue: effectiveMax)),
        ),
        const SizedBox(height: 8),
        Text('${value.toStringAsFixed(1)} $unit', style: AeroTextStyles.headline),
        if (label != null) Text(label!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _AeroGaugePainter extends CustomPainter {
  final double value;
  final double maxValue;

  _AeroGaugePainter({required this.value, required this.maxValue});

  // Cadran sur 240°. Dans le repère du Canvas (0° = est, sens horaire)
  // ça donne un départ à 210° et un balayage de -240° (attention au signe).
  static const double _startAngleDeg = 210.0;
  static const double _sweepAngleDeg = -240.0;
  static const int _majorTicks = 5; // -> 6 graduations majeures (0..5)
  static const int _minorPerMajor = 2; // graduations mineures entre 2 majeures

  double _angleForFraction(double t) => (_startAngleDeg + _sweepAngleDeg * t) * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    _paintFace(canvas, center, radius);
    _paintHighlightArc(canvas, center, radius);
    _paintTicks(canvas, center, radius);
    _paintNeedle(canvas, center, radius);
    _paintHub(canvas, center, radius);
    _paintGlass(canvas, center, radius);
  }

  void _paintFace(Canvas canvas, Offset center, double radius) {
    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: [AeroColors.gaugeFaceInner, AeroColors.gaugeFaceOuter],
        stops: const [0.25, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, facePaint);

    final bezelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AeroColors.chromeDark;
    canvas.drawCircle(center, radius - 1.5, bezelPaint);
  }

  void _paintHighlightArc(Canvas canvas, Offset center, double radius) {
    // Arc de reflet cosmétique, fixe (ne dépend pas de la valeur) — évoque
    // le verre bombé qui accroche la lumière en haut à gauche.
    final rect = Rect.fromCircle(center: center, radius: radius * 0.92);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.22
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [AeroColors.glossHighlightSoft, Colors.transparent],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi * 0.95, math.pi * 0.55, false, paint);
  }

  void _paintTicks(Canvas canvas, Offset center, double radius) {
    final totalMinor = _majorTicks * _minorPerMajor;
    for (var i = 0; i <= totalMinor; i++) {
      final t = i / totalMinor;
      final isMajor = i % _minorPerMajor == 0;
      final angle = _angleForFraction(t);
      final dir = Offset(math.cos(angle), math.sin(angle));
      final outer = center + dir * (radius * 0.95);
      final inner = center + dir * (radius * (isMajor ? 0.78 : 0.86));

      final tickPaint = Paint()
        ..color = AeroColors.gaugeTickDark
        ..strokeWidth = isMajor ? 2.5 : 1.2;
      canvas.drawLine(inner, outer, tickPaint);

      if (isMajor) {
        final labelValue = (maxValue * t).round();
        final tp = TextPainter(
          text: TextSpan(
            text: '$labelValue',
            style: const TextStyle(fontSize: 10, color: AeroColors.gaugeTickDark, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelPos = center + dir * (radius * 0.62);
        tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _paintNeedle(Canvas canvas, Offset center, double radius) {
    final t = (value.clamp(0, maxValue)) / maxValue;
    final angle = _angleForFraction(t);

    final path = Path()
      ..moveTo(-4, 0)
      ..lineTo(0, -radius * 0.86)
      ..lineTo(4, 0)
      ..lineTo(0, radius * 0.14)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + math.pi / 2);

    // Fausse ombre : copie légèrement décalée, dessinée avant l'aiguille
    // colorée (CustomPainter n'a pas d'élévation native).
    canvas.save();
    canvas.translate(1.5, 1.5);
    canvas.drawPath(path, Paint()..color = AeroColors.umbraSoft);
    canvas.restore();

    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AeroColors.needleRedDark, AeroColors.needleRed, AeroColors.needleRedDark],
      ).createShader(const Rect.fromLTWH(-4, -80, 8, 80));
    canvas.drawPath(path, needlePaint);
    canvas.restore();
  }

  void _paintHub(Canvas canvas, Offset center, double radius) {
    final hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, AeroColors.hubChrome],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.09));
    canvas.drawCircle(center, radius * 0.09, hubPaint);
    canvas.drawCircle(
      center,
      radius * 0.09,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AeroColors.gaugeTickDark.withValues(alpha: 0.6),
    );
  }

  void _paintGlass(Canvas canvas, Offset center, double radius) {
    // Survitrage translucide par-dessus l'aiguille, comme une vraie jauge
    // sous verre bombé.
    final glassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 1.1,
        colors: [AeroColors.glossHighlightFaint, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glassPaint);
  }

  @override
  bool shouldRepaint(covariant _AeroGaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue;
}
