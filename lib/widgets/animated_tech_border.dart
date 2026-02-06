import 'package:flutter/material.dart';
import 'dart:math' as math;

/// An animated border that creates a techy glowing effect around its child
class AnimatedTechBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;

  const AnimatedTechBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = 0,
  });

  @override
  State<AnimatedTechBorder> createState() => _AnimatedTechBorderState();
}

class _AnimatedTechBorderState extends State<AnimatedTechBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: CustomPaint(
            painter: TechBorderPainter(
              progress: _controller.value,
              borderWidth: widget.borderWidth,
              borderRadius: widget.borderRadius,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class TechBorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final double borderRadius;

  TechBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Base border with subtle glow
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = const Color(0xFF00d4ff).withValues(alpha: 0.5);

    canvas.drawRRect(rrect, basePaint);

    // Animated gradient sweep
    final sweepGradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + math.pi,
      colors: [
        Colors.transparent,
        const Color(0xFF00d4ff).withValues(alpha: 0.8),
        const Color(0xFF00ffff),
        const Color(0xFF00d4ff).withValues(alpha: 0.8),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = sweepGradient.createShader(rect);

    canvas.drawRRect(rrect, gradientPaint);

    // Corner accents
    _drawCornerAccents(canvas, size, progress);

    // Glowing dots at corners
    _drawGlowingDots(canvas, size, progress);
  }

  void _drawCornerAccents(Canvas canvas, Size size, double progress) {
    final accentLength = 20.0;
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 1
      ..color = Color(
        0xFF00d4ff,
      ).withValues(alpha: 0.6 + 0.4 * math.sin(progress * 2 * math.pi));

    // Top-left corner
    canvas.drawLine(Offset(0, accentLength), Offset(0, 0), accentPaint);
    canvas.drawLine(Offset(0, 0), Offset(accentLength, 0), accentPaint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - accentLength, 0),
      Offset(size.width, 0),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, accentLength),
      accentPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height - accentLength),
      Offset(size.width, size.height),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - accentLength, size.height),
      accentPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(accentLength, size.height),
      Offset(0, size.height),
      accentPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - accentLength),
      accentPaint,
    );
  }

  void _drawGlowingDots(Canvas canvas, Size size, double progress) {
    final dotRadius = 3.0;
    final glowRadius = 8.0;

    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    for (var i = 0; i < corners.length; i++) {
      final offset = corners[i];
      final phaseOffset = i * 0.25;
      final localPulse =
          0.5 + 0.5 * math.sin((progress + phaseOffset) * 4 * math.pi);

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00d4ff).withValues(alpha: 0.3 * localPulse)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          glowRadius * localPulse,
        );
      canvas.drawCircle(offset, dotRadius + glowRadius * localPulse, glowPaint);

      // Dot
      final dotPaint = Paint()
        ..color = const Color(
          0xFF00d4ff,
        ).withValues(alpha: 0.8 + 0.2 * localPulse);
      canvas.drawCircle(offset, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TechBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
