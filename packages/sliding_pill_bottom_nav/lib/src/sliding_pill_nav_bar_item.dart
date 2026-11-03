import 'package:flutter/material.dart';

/// Visual state passed to [SlidingPillNavBarItem.iconBuilder].
@immutable
class SlidingPillNavItemVisualState {
  const SlidingPillNavItemVisualState({
    required this.active,
    required this.color,
    required this.iconSize,
  });

  final bool active;
  final Color color;
  final double iconSize;
}

typedef SlidingPillNavIconBuilder =
    Widget Function(
      BuildContext context,
      SlidingPillNavItemVisualState state,
    );

typedef SlidingPillNavLabelStyleBuilder =
    TextStyle Function(BuildContext context, {required bool active});

/// One destination in [SlidingPillBottomNavBar].
@immutable
class SlidingPillNavBarItem {
  const SlidingPillNavBarItem({
    required this.label,
    required this.semanticLabel,
    this.icon,
    this.iconBuilder,
    this.labelStyle,
    this.key,
  }) : assert(
         icon != null || iconBuilder != null,
         'Provide icon or iconBuilder',
       );

  final String label;
  final String semanticLabel;
  final IconData? icon;
  final SlidingPillNavIconBuilder? iconBuilder;
  final TextStyle? labelStyle;
  final Key? key;
}
