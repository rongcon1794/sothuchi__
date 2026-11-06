import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Signature Apple-grade Brand Mark for Sổ Thu Chi.
///
/// Features a continuous Apple squircle canvas with a modern 2D flat design:
/// clean emerald jade background, financial ledger book symbolism, dynamic
/// dual-loop cashflow curves (Thu & Chi), and a warm gold coin accent.
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
    final squircleRadius = BorderRadius.circular(size * 0.235);

    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: squircleRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF004D40).withValues(alpha: 0.18),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: size * 0.08,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: squircleRadius,
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A826C), // Vibrant Emerald Jade Top
                  Color(0xFF063A33), // Deep Forest Jade Bottom
                ],
              ),
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.65, size * 0.65),
                painter: _LogoEmblemPainter(),
              ),
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      logo = Hero(tag: heroTag!, child: logo);
    }

    return logo;
  }
}

/// 2D Flat Fallback Emblem Painter representing the Ledger (Sổ),
/// Cashflow Curves (Thu & Chi), and Wealth Coin.
class _LogoEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Ledger Cover Outline & Spine (Sổ - 2D Flat Geometric Notebook)
    final ledgerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ledgerPath = Path()
      ..moveTo(w * 0.22, h * 0.18)
      ..lineTo(w * 0.78, h * 0.18)
      ..quadraticBezierTo(w * 0.86, h * 0.18, w * 0.86, h * 0.26)
      ..lineTo(w * 0.86, h * 0.78)
      ..quadraticBezierTo(w * 0.86, h * 0.86, w * 0.78, h * 0.86)
      ..lineTo(w * 0.22, h * 0.86)
      ..close();
    canvas.drawPath(ledgerPath, ledgerPaint);

    // Ledger Spine line
    final spinePaint = Paint()
      ..color = const Color(0xFF80CBC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.06)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.36, h * 0.22), Offset(w * 0.36, h * 0.82), spinePaint);

    // 2. Dynamic Cashflow Growth Curve (Thu & Chi - Upward Flow)
    final flowPaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.10)
      ..strokeCap = StrokeCap.round;

    final flowPath = Path()
      ..moveTo(w * 0.44, h * 0.68)
      ..cubicTo(w * 0.52, h * 0.68, w * 0.56, h * 0.48, w * 0.74, h * 0.38);
    canvas.drawPath(flowPath, flowPaint);

    // 3. Central Gold Coin (Tài sản & Thịnh vượng)
    final coinPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.62, h * 0.44), w * 0.14, coinPaint);

    final innerCoinPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.04);
    canvas.drawCircle(Offset(w * 0.62, h * 0.44), w * 0.09, innerCoinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
