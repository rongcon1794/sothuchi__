import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Signature Apple-grade Brand Mark for Sổ Thu Chi.
///
/// Features a continuous Apple squircle canvas with a multi-layered
/// metallic Jade/Emerald gradient, specular glass highlight, and an
/// intersecting dual-loop finance insignia with a warm gold spark.
class SoThuChiLogo extends StatelessWidget {
  const SoThuChiLogo({
    super.key,
    this.size = 48.0,
    this.heroTag = 'app_logo_hero',
    this.showShadow = true,
  });

  final double size;
  final String? heroTag;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.235), // Apple continuous squircle ratio
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00BFA5), // Vibrant Emerald Teal
            Color(0xFF00897B), // Deep Jade Primary
            Color(0xFF004D40), // Rich Dark Forest Jade
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF004D40).withValues(alpha: 0.35),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.1),
                ),
                BoxShadow(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                  blurRadius: size * 0.1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: math.max(0.75, size * 0.02),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.235),
        child: Stack(
          children: [
            // Specular Glass Sheen (Top-left diagonal highlight)
            Positioned(
              top: -size * 0.2,
              left: -size * 0.2,
              width: size * 1.4,
              height: size * 0.7,
              child: Transform.rotate(
                angle: -math.pi / 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Custom Painted Geometric Emblem (Intersecting Cashflow Curves & Gold Vault Spark)
            Center(
              child: CustomPaint(
                size: Size(size * 0.62, size * 0.62),
                painter: _LogoEmblemPainter(),
              ),
            ),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      logo = Hero(tag: heroTag!, child: logo);
    }

    return logo;
  }
}

class _LogoEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Inflow Loop (Thu - Emerald Arc upward)
    final inflowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFB2DFDB)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final inflowPath = Path()
      ..moveTo(w * 0.2, h * 0.68)
      ..cubicTo(w * 0.15, h * 0.35, w * 0.45, h * 0.2, w * 0.75, h * 0.28);
    canvas.drawPath(inflowPath, inflowPaint);

    // 2. Outflow Loop (Chi - Intersecting Balance Arc downward)
    final outflowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFF80CBC4).withValues(alpha: 0.8),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final outflowPath = Path()
      ..moveTo(w * 0.8, h * 0.32)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.55, h * 0.8, w * 0.25, h * 0.72);
    canvas.drawPath(outflowPath, outflowPaint);

    // 3. Central Gold Diamond Spark (Wealth & Stability Accent)
    final goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.18));

    final sparkPath = Path()
      ..moveTo(w * 0.5, h * 0.32)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.68, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.32, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h * 0.32)
      ..close();

    canvas.drawPath(sparkPath, goldPaint);

    // 4. Center Micro-Gleam
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.045, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
