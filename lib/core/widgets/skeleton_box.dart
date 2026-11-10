import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Subtle animated pulse skeleton placeholder for loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacityAnimation = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // In automated widget tests, avoid infinite repeat so pumpAndSettle can settle.
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.65;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

/// Reusable list of loading skeleton rows.
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonBox(height: 72, borderRadius: 16),
    );
  }
}

