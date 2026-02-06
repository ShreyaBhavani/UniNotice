import 'dart:math';
import 'package:flutter/material.dart';

/// Optimized floating icons background with subtle animations
class FloatingIconsBackground extends StatefulWidget {
  final Widget child;

  const FloatingIconsBackground({super.key, required this.child});

  @override
  State<FloatingIconsBackground> createState() =>
      _FloatingIconsBackgroundState();
}

class _FloatingIconsBackgroundState extends State<FloatingIconsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<IconData> academicIcons = [
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.notifications_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.lightbulb_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = Random(42);

    return Stack(
      children: [
        // Floating icons
        ...List.generate(6, (index) {
          final x = random.nextDouble() * size.width;
          final y = random.nextDouble() * size.height;
          final iconSize = 20.0 + random.nextDouble() * 16;
          final delay = index * 0.15;

          return Positioned(
            left: x,
            top: y,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = (_controller.value + delay) % 1.0;
                final offset = sin(value * 2 * pi) * 8;
                final opacity = 0.08 + 0.04 * sin(value * 2 * pi);

                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Icon(
                    academicIcons[index],
                    size: iconSize,
                    color: const Color(0xFF0088CC).withOpacity(opacity),
                  ),
                );
              },
            ),
          );
        }),
        // Main content
        widget.child,
      ],
    );
  }
}
