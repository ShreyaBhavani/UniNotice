import 'package:flutter/material.dart';

/// Animated Tabbar
class AnimatedTabBar extends StatefulWidget {
  final List<AnimatedTabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double height;

  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = const Color(0xFF3182CE),
    this.inactiveColor = const Color(0xFF718096),
    this.backgroundColor = Colors.white,
    this.height = 56,
  });

  @override
  State<AnimatedTabBar> createState() => _AnimatedTabBarState();
}

class _AnimatedTabBarState extends State<AnimatedTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.tabs.length, (index) {
          final isActive = index == widget.currentIndex;
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? widget.activeColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.tabs[index].icon,
                    color: isActive ? widget.activeColor : widget.inactiveColor,
                    size: 24,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: isActive ? null : 0,
                      child: Row(
                        children: [
                          if (isActive) const SizedBox(width: 8),
                          if (isActive)
                            Text(
                              widget.tabs[index].label,
                              style: TextStyle(
                                color: widget.activeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AnimatedTabItem {
  final IconData icon;
  final String label;

  const AnimatedTabItem({
    required this.icon,
    required this.label,
  });
}

/// Sliding Tab Indicator
class SlidingTabBar extends StatefulWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Color indicatorColor;

  const SlidingTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF718096),
    this.indicatorColor = const Color(0xFF3182CE),
  });

  @override
  State<SlidingTabBar> createState() => _SlidingTabBarState();
}

class _SlidingTabBarState extends State<SlidingTabBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / widget.tabs.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: tabWidth * widget.currentIndex,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.indicatorColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.indicatorColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.tabs.length, (index) {
                  final isActive = index == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isActive
                                  ? widget.activeColor
                                  : widget.inactiveColor,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            child: Text(widget.tabs[index]),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chip Tab Bar
class ChipTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;

  const ChipTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = const Color(0xFF3182CE),
    this.inactiveColor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isActive = index == currentIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF4A5568),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Segmented Control with Animation
class AnimatedSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;
  final Color backgroundColor;

  const AnimatedSegmentedControl({
    super.key,
    required this.segments,
    required this.currentIndex,
    required this.onChanged,
    this.selectedColor = const Color(0xFF3182CE),
    this.backgroundColor = const Color(0xFFF7FAFC),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(segments.length, (index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                segments[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A5568),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
