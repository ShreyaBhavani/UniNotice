import 'package:flutter/material.dart';

/// Animated Card with Hover/Tap Effects
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color backgroundColor;
  final double elevation;
  final EdgeInsets padding;
  final Duration animationDuration;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.backgroundColor = Colors.white,
    this.elevation = 4,
    this.padding = const EdgeInsets.all(16),
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? widget.elevation * 3 : widget.elevation,
                spreadRadius: _isHovered ? 2 : 0,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Flip Card Animation
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final VoidCallback? onFlip;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 500),
    this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFrontVisible = _animation.value < 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? widget.front
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// Expandable Card with Animation
class ExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget body;
  final bool initiallyExpanded;
  final Duration animationDuration;
  final Color backgroundColor;
  final double borderRadius;

  const ExpandableCard({
    super.key,
    required this.header,
    required this.body,
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.backgroundColor = Colors.white,
    this.borderRadius = 16,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(widget.borderRadius),
              bottomRight: Radius.circular(widget.borderRadius),
            ),
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable Card
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftAction;
  final Widget? rightAction;
  final double threshold;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftAction,
    this.rightAction,
    this.threshold = 0.4,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * widget.threshold;

    if (_dragExtent.abs() > threshold) {
      if (_dragExtent > 0) {
        // Swiped right
        _slideAnimation = Tween<Offset>(
          begin: Offset(_dragExtent / screenWidth, 0),
          end: const Offset(1.5, 0),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward().then((_) {
          widget.onSwipeRight?.call();
          _reset();
        });
      } else {
        // Swiped left
        _slideAnimation = Tween<Offset>(
          begin: Offset(_dragExtent / screenWidth, 0),
          end: const Offset(-1.5, 0),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward().then((_) {
          widget.onSwipeLeft?.call();
          _reset();
        });
      }
    } else {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _dragExtent = 0;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Background actions
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  color: Colors.green.withOpacity(0.2),
                  child: widget.rightAction ?? const Icon(Icons.check, color: Colors.green),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.withOpacity(0.2),
                  child: widget.leftAction ?? const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        // Swipeable card
        SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: Transform.rotate(
                angle: _dragExtent / screenWidth * 0.1,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tilt Card (3D effect on hover/touch)
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Color backgroundColor;
  final double borderRadius;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 10,
    this.backgroundColor = Colors.white,
    this.borderRadius = 16,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _handlePanUpdate(DragUpdateDetails details) {
    final size = context.size!;
    setState(() {
      _rotateY = (details.localPosition.dx - size.width / 2) / size.width * widget.maxTilt;
      _rotateX = -(details.localPosition.dy - size.height / 2) / size.height * widget.maxTilt;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX * 3.14159 / 180)
          ..rotateY(_rotateY * 3.14159 / 180),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(_rotateY, _rotateX),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
